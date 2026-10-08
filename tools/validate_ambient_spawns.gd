extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_pure_policy()
	await _test_main_adapter()
	if _failures.is_empty():
		print("Ambient spawn validation passed: deterministic budget, chunk ownership and encounter exclusion are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _test_pure_policy() -> void:
	var keys := ChunkAdmissionPolicy.desired_keys(Vector2i.ZERO)
	var request := AmbientSpawnRequest.new(Vector2i.ZERO, keys, {}, WorldChunkCatalog.DEFAULT_BIOME_ID, 2, 10, 730201, 1)
	var first := AmbientSpawnPolicy.resolve(request, 0)
	var replay := AmbientSpawnPolicy.resolve(request, 0)
	_expect(first.status == AmbientSpawnResult.Status.APPLIED and first.admitted.size() == 10, "initial pure policy must fill exact budget")
	_expect(_spec_dtos(first) == _spec_dtos(replay), "same seed/time/chunks must replay exact specs")
	var unique: Dictionary = {}
	for spec in first.admitted:
		unique[spec.instance_id] = true
		_expect(spec.is_valid(), "resolved ambient spec must be valid: %s" % spec.to_debug_dto())
		_expect(spec.species_id != LegacySpeciesAdapter.DRAGON_ID, "ambient policy must exclude boss species")
	_expect(unique.size() == 10, "ambient instance identity must be unique")
	var existing: Dictionary = {}
	for spec in first.admitted: existing[spec.instance_id] = spec.chunk_key
	var no_change := AmbientSpawnPolicy.resolve(AmbientSpawnRequest.new(Vector2i.ZERO, keys, existing, WorldChunkCatalog.DEFAULT_BIOME_ID, 3, 10, 99, 1), 1)
	_expect(no_change.status == AmbientSpawnResult.Status.NO_CHANGE and no_change.next_ids.size() == 10, "full same-chunk population must not reroll on time/seed change")
	var duplicate_keys := keys.duplicate()
	duplicate_keys.append(keys[0])
	var duplicate := AmbientSpawnPolicy.resolve(AmbientSpawnRequest.new(Vector2i.ZERO, duplicate_keys, {}, WorldChunkCatalog.DEFAULT_BIOME_ID, 0, 10, 1, 1), 0)
	_expect(duplicate.status == AmbientSpawnResult.Status.INVALID, "duplicate active chunk keys must fail closed")


func _test_main_adapter() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_failures.append("unable to load main scene for ambient spawn validation")
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var initial := main.call("get_ambient_spawn_debug_snapshot") as Dictionary
	_expect(initial.get("active_count") == 10, "Main must own exact ambient budget after initial admission")
	var initial_ids := _snapshot_ids(initial)
	_expect(initial_ids.size() == 10, "initial runtime ambient IDs must be unique")
	_expect(bool(main.call("maintain_creatures")), "same-chunk maintenance must succeed")
	_expect(_snapshot_ids(main.call("get_ambient_spawn_debug_snapshot")) == initial_ids, "same-chunk maintenance must not reroll actors")

	var boss_fixture := Node2D.new()
	boss_fixture.add_to_group("persistent_world_bosses")
	main.get("creature_container").add_child(boss_fixture)
	var raid_fixture := Node2D.new()
	raid_fixture.add_to_group("persistent_night_raid_actors")
	main.get("creature_container").add_child(raid_fixture)
	_expect((main.call("get_ambient_spawn_debug_snapshot") as Dictionary).get("active_count") == 10, "boss and raid actors must not consume ambient budget")
	_expect(bool(main.call("maintain_creatures")), "maintenance with encounter actors must succeed")
	_expect((main.call("get_ambient_spawn_debug_snapshot") as Dictionary).get("active_count") == 10, "encounter actors must remain excluded after maintenance")

	_expect(bool(main.call("update_chunk_admission", Vector2(-0.1, 1024.0))), "signed chunk crossing must reconcile ambient ownership")
	var crossed := main.call("get_ambient_spawn_debug_snapshot") as Dictionary
	_expect(crossed.get("active_count") == 10, "crossing must refill exact ambient budget")
	var active_chunks: Array[StringName] = main.get("chunk_admission").get_active_keys()
	for record: Dictionary in crossed.get("actors", []):
		_expect(active_chunks.has(StringName(record.get("chunk_key", ""))), "ambient actor must belong to an active chunk")
	var adapter := main.get("ambient_spawn_adapter") as AmbientSpawnAdapter
	var stale_request := adapter.create_request(main.get("chunk_admission").center, active_chunks, WorldChunkCatalog.DEFAULT_BIOME_ID, 0, 10, 1, 1)
	var before_stale := _snapshot_ids(main.call("get_ambient_spawn_debug_snapshot"))
	_expect(adapter.reconcile(stale_request).status == AmbientSpawnResult.Status.STALE, "stale chunk revision must not mutate ambient ownership")
	_expect(before_stale == _snapshot_ids(main.call("get_ambient_spawn_debug_snapshot")), "stale reconcile must preserve actor IDs")

	main.queue_free()
	await process_frame
	await process_frame
	_expect(adapter.create_debug_snapshot().get("active_count") == 0, "Main exit must release ambient actor ownership")


func _spec_dtos(result: AmbientSpawnResult) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	for spec in result.admitted: values.append(spec.to_debug_dto())
	return values


func _snapshot_ids(snapshot: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for record: Dictionary in snapshot.get("actors", []): ids.append(StringName(record.get("instance_id", "")))
	ids.sort()
	return ids


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
