extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_catalog()
	_test_policy()
	_test_cost_conservation()
	await _test_main_integration()
	if _failures.is_empty():
		print("Fast travel validation passed: stable destination IDs, pure policy guards, atomic cost commit and Main teleport are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _test_catalog() -> void:
	var origin_id := FastTravelDestinationCatalog.destination_id_for_chunk(&"chunk.p0.p0")
	_expect(origin_id == &"fast_travel.chunk.p0.p0", "destination ID must use the fast_travel domain with canonical chunk key")
	_expect(FastTravelDestinationCatalog.chunk_key_for_destination(origin_id) == &"chunk.p0.p0", "destination ID must resolve back to its chunk key")
	_expect(FastTravelDestinationCatalog.is_destination_id(origin_id), "generated destination ID must be recognized")
	_expect(FastTravelDestinationCatalog.destination_id_for_chunk(&"chunk.-1.0") == &"", "noncanonical chunk key must not produce a destination ID")
	_expect(FastTravelDestinationCatalog.destination_id_for_chunk(&"item.wood") == &"", "non-chunk ID must not produce a destination ID")
	_expect(FastTravelDestinationCatalog.chunk_key_for_destination(&"fast_travel.nope") == &"", "malformed destination must resolve to empty key")
	_expect(FastTravelDestinationCatalog.chunk_key_for_destination(&"item.wood") == &"", "foreign domain must resolve to empty key")
	_expect(FastTravelDestinationCatalog.chunk_key_for_destination(&"fast_travel.chunk.p01.p0") == &"", "non-canonical embedded key must be rejected")
	_expect(not FastTravelDestinationCatalog.is_destination_id(&"fast_travel.chunk.p1"), "truncated destination must not be recognized")
	var landing: Array[Vector2] = []
	_expect(FastTravelDestinationCatalog.try_landing_position(&"chunk.p1.p0", landing) and landing[0] == Vector2(1536.0, 512.0), "landing must be the destination chunk center")
	landing.clear()
	_expect(FastTravelDestinationCatalog.try_landing_position(&"chunk.n1.p1", landing) and landing[0] == Vector2(-512.0, -512.0), "signed chunk landing must be deterministic")
	landing.clear()
	_expect(not FastTravelDestinationCatalog.try_landing_position(&"bogus", landing) and landing.is_empty(), "invalid chunk key must not produce a landing")


func _make_discovery(keys: Array[StringName]) -> ChunkDiscoveryState:
	var state := ChunkDiscoveryState.new()
	for key in keys:
		var parsed: Array[Vector2i] = []
		if ChunkCoordinate.try_parse_key(key, parsed):
			state.discover(ChunkDiscoveryRequest.new(key, state.revision))
	return state


func _policy_counts(spheres: int) -> Dictionary:
	return {FastTravelPolicy.COST_ITEM_ID: spheres}


func _test_policy() -> void:
	var discovery := _make_discovery([&"chunk.p0.p0", &"chunk.p1.p0"])
	var dest_p1 := FastTravelDestinationCatalog.destination_id_for_chunk(&"chunk.p1.p0")
	_expect(discovery.revision == 2, "fixture discovery must hold two chunks")
	var ok := FastTravelPolicy.resolve(
		FastTravelRequest.new(dest_p1, 2), discovery, &"chunk.p0.p0",
		_policy_counts(3), false, 0, 1000
	)
	_expect(ok.status == FastTravelResult.Status.OK and ok.is_success(), "valid travel must resolve OK")
	_expect(ok.chunk_key == &"chunk.p1.p0" and ok.landing_position == Vector2(1536.0, 512.0), "OK result must carry chunk key and landing")
	_expect(ok.cost_item_id == FastTravelPolicy.COST_ITEM_ID and ok.cost_amount == FastTravelPolicy.COST_AMOUNT, "OK result must carry explicit cost")
	var unknown := FastTravelPolicy.resolve(
		FastTravelRequest.new(&"fast_travel.nope", 2), discovery, &"chunk.p0.p0",
		_policy_counts(3), false, 0, 1000
	)
	_expect(unknown.status == FastTravelResult.Status.UNKNOWN_DESTINATION and not unknown.is_success(), "unknown destination must fail closed")
	var stale := FastTravelPolicy.resolve(
		FastTravelRequest.new(dest_p1, 1), discovery, &"chunk.p0.p0",
		_policy_counts(3), false, 0, 1000
	)
	_expect(stale.status == FastTravelResult.Status.STALE_DISCOVERY, "stale discovery revision must fail closed")
	var undiscovered := FastTravelPolicy.resolve(
		FastTravelRequest.new(FastTravelDestinationCatalog.destination_id_for_chunk(&"chunk.p5.p5"), 2),
		discovery, &"chunk.p0.p0", _policy_counts(3), false, 0, 1000
	)
	_expect(undiscovered.status == FastTravelResult.Status.UNDISCOVERED, "undiscovered chunk must fail closed")
	var same := FastTravelPolicy.resolve(
		FastTravelRequest.new(FastTravelDestinationCatalog.destination_id_for_chunk(&"chunk.p0.p0"), 2),
		discovery, &"chunk.p0.p0", _policy_counts(3), false, 0, 1000
	)
	_expect(same.status == FastTravelResult.Status.SAME_DESTINATION, "current chunk must fail as same destination")
	var guard := FastTravelPolicy.resolve(
		FastTravelRequest.new(dest_p1, 2), discovery, &"chunk.p0.p0",
		_policy_counts(3), true, 0, 1000
	)
	_expect(guard.status == FastTravelResult.Status.ENCOUNTER_GUARD, "active encounter must block travel")
	var cooldown := FastTravelPolicy.resolve(
		FastTravelRequest.new(dest_p1, 2), discovery, &"chunk.p0.p0",
		_policy_counts(3), false, 5000, 1000
	)
	_expect(cooldown.status == FastTravelResult.Status.COOLDOWN_ACTIVE, "travel during cooldown must fail closed")
	var poor := FastTravelPolicy.resolve(
		FastTravelRequest.new(dest_p1, 2), discovery, &"chunk.p0.p0",
		_policy_counts(0), false, 0, 1000
	)
	_expect(poor.status == FastTravelResult.Status.INSUFFICIENT_COST, "missing cost must fail closed")
	var invalid := FastTravelPolicy.resolve(null, discovery, &"chunk.p0.p0", _policy_counts(3), false, 0, 1000)
	_expect(invalid.status == FastTravelResult.Status.INVALID, "null request must fail closed")
	var before := discovery.to_dto()
	FastTravelPolicy.resolve(FastTravelRequest.new(dest_p1, 0), discovery, &"chunk.p0.p0", _policy_counts(3), false, 0, 1000)
	_expect(discovery.to_dto() == before, "policy must never mutate discovery state")


func _test_cost_conservation() -> void:
	var store := {"Cầu Thu Phục": 3}
	var transaction := InventoryTransaction.new(store)
	var before: int = transaction.get_count(FastTravelPolicy.COST_ITEM_ID)
	_expect(before == 3, "fixture inventory must hold three spheres")
	var spend := transaction.remove(FastTravelPolicy.COST_ITEM_ID, FastTravelPolicy.COST_AMOUNT)
	_expect(spend.is_success() and transaction.get_count(FastTravelPolicy.COST_ITEM_ID) == 2, "cost spend must deduct exactly one sphere")
	var refund := transaction.add(FastTravelPolicy.COST_ITEM_ID, FastTravelPolicy.COST_AMOUNT)
	_expect(refund.is_success() and transaction.get_count(FastTravelPolicy.COST_ITEM_ID) == before, "rollback refund must restore the exact pre-spend count")


func _clear_creatures(main: Node) -> void:
	var container := main.get("creature_container") as Node
	for child in container.get_children():
		if is_instance_valid(child):
			child.queue_free()
	await process_frame
	await process_frame


func _test_main_integration() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_failures.append("unable to load main scene for fast travel validation")
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var player := main.get("player")
	var inventory: Dictionary = player.get("inventory")
	InventoryTransaction.new(inventory).add(FastTravelPolicy.COST_ITEM_ID, 2)
	_expect(bool(main.call("update_chunk_admission", Vector2(1024.0, 0.0))), "crossing must discover chunk.p1.p0")
	var discovery_before: Dictionary = (main.get("chunk_discovery_adapter") as ChunkDiscoveryAdapter).export_dto()
	var dest_p1 := FastTravelDestinationCatalog.destination_id_for_chunk(&"chunk.p1.p0")
	var dest_origin := FastTravelDestinationCatalog.destination_id_for_chunk(&"chunk.p0.p0")
	var spheres_before: int = InventoryTransaction.new(inventory).get_count(FastTravelPolicy.COST_ITEM_ID)

	# Deterministic guard baseline: no wild creature may target the player.
	await _clear_creatures(main)
	_expect(not bool(main.call("is_fast_travel_encounter_blocked")), "encounter guard must be clear at rest")

	# A live creature targeting the player must raise the guard deterministically.
	await _clear_creatures(main)
	_expect(bool(main.call("maintain_creatures")), "ambient director must respawn creatures after cleanup")
	var container := main.get("creature_container") as Node
	var ambient: Array = container.get_children()
	if ambient.is_empty():
		_failures.append("ambient director must own creatures after admission")
	else:
		ambient[0].set("target", player)
		_expect(bool(main.call("is_fast_travel_encounter_blocked")), "creature targeting the player must raise the encounter guard")
		await _clear_creatures(main)
		_expect(not bool(main.call("is_fast_travel_encounter_blocked")), "guard must clear once no creature targets the player")

	var first: FastTravelResult = main.call("try_fast_travel", dest_p1)
	_expect(first != null and first.is_success(), "Main travel to discovered chunk must succeed")
	_expect((player.get("global_position") as Vector2) == Vector2(1536.0, 512.0), "player must land on the destination chunk center")
	_expect(InventoryTransaction.new(inventory).get_count(FastTravelPolicy.COST_ITEM_ID) == spheres_before - 1, "successful travel must spend exactly one sphere")
	_expect(int(main.get("fast_travel_cooldown_until_msec")) > 0, "successful travel must arm the cooldown")
	_expect((main.get("chunk_discovery_adapter") as ChunkDiscoveryAdapter).export_dto() == discovery_before, "travel must not mutate discovery state")
	_expect((main.call("get_chunk_navigation_debug_snapshot") as Dictionary).get("active_count") == 9, "travel must keep exact navigation ownership")
	_expect((main.call("get_ambient_spawn_debug_snapshot") as Dictionary).get("active_count") == 10, "travel must keep exact ambient budget")

	await _clear_creatures(main)
	var immediate: FastTravelResult = main.call("try_fast_travel", dest_origin)
	_expect(immediate.status == FastTravelResult.Status.COOLDOWN_ACTIVE, "immediate second travel must hit cooldown")

	main.set("fast_travel_cooldown_until_msec", 0)
	await _clear_creatures(main)
	var back: FastTravelResult = main.call("try_fast_travel", dest_origin)
	_expect(back.is_success() and (player.get("global_position") as Vector2) == Vector2(512.0, 512.0), "travel back to origin must succeed after cooldown reset")

	var duplicate: FastTravelResult = main.call("try_fast_travel", dest_origin)
	_expect(duplicate.status == FastTravelResult.Status.SAME_DESTINATION, "duplicate intent to current chunk must fail as same destination")

	main.set("fast_travel_cooldown_until_msec", 0)
	await _clear_creatures(main)
	var undiscovered: FastTravelResult = main.call("try_fast_travel", FastTravelDestinationCatalog.destination_id_for_chunk(&"chunk.p5.p5"))
	_expect(undiscovered.status == FastTravelResult.Status.UNDISCOVERED, "Main must reject undiscovered destinations")
	var unknown: FastTravelResult = main.call("try_fast_travel", &"fast_travel.nope")
	_expect(unknown.status == FastTravelResult.Status.UNKNOWN_DESTINATION, "Main must reject unknown destination IDs")

	main.set("world_boss_state", WorldBossState.new(WorldBossState.ACTIVE, WorldBossState.INSTANCE_ID, 100, Vector2(10.0, 10.0)))
	_expect(bool(main.call("is_fast_travel_encounter_blocked")), "active world boss must raise the encounter guard")
	var blocked: FastTravelResult = main.call("try_fast_travel", dest_p1)
	_expect(blocked.status == FastTravelResult.Status.ENCOUNTER_GUARD, "Main must block travel during an active encounter")
	main.set("world_boss_state", WorldBossState.new())
	_expect(not bool(main.call("is_fast_travel_encounter_blocked")), "encounter guard must clear when the boss is gone")
	_expect((main.get("chunk_discovery_adapter") as ChunkDiscoveryAdapter).export_dto() == discovery_before, "guarded attempts must leave discovery untouched")
	main.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
