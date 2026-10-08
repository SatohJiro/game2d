extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_state_pure()
	_test_policy_blocked()
	await _test_defeat_save_load_cycle()
	await _test_legacy_and_corrupt()
	if _failures.is_empty():
		print("Ambient cooldown validation passed: typed cooldown state, blocked-slot policy, defeat/capture save round-trip and legacy handling are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _test_state_pure() -> void:
	var state := AmbientCooldownState.new()
	_expect(state.register(&"ambient.p0_p0_s0", 130.0), "valid slot registration must succeed")
	_expect(not state.register(&"item.pal_sphere.basic", 130.0), "non-ambient slot ID must be rejected")
	_expect(not state.register(&"ambient.p0_p0_s0", -5.0), "negative expiry must be rejected")
	_expect(not state.register(&"ambient.p0_p0_s0", INF), "non-finite expiry must be rejected")
	_expect(state.is_cooling_down(&"ambient.p0_p0_s0", 100.0), "slot must cool down before expiry")
	_expect(not state.is_cooling_down(&"ambient.p0_p0_s0", 130.0), "slot must stop cooling down at expiry")
	_expect(state.is_empty(), "expired entries must be pruned on query")
	state.register(&"ambient.p1_p0_s1", 200.0)
	state.register(&"ambient.p1_p0_s1", 250.0)
	_expect(state.expires_at(&"ambient.p1_p0_s1") == 250.0, "re-registration must keep the latest expiry")
	var round_tripped := AmbientCooldownState.from_dto(state.to_dto())
	_expect(round_tripped != null and round_tripped.to_dto() == state.to_dto(), "cooldown DTO must round-trip exactly")
	_expect(AmbientCooldownState.from_dto(null).is_empty(), "legacy null DTO must restore an empty state")
	_expect(AmbientCooldownState.from_dto({}).is_empty(), "legacy empty DTO must restore an empty state")
	_expect(AmbientCooldownState.from_dto({"cooldowns": [{"slot_id": "bogus", "expires_at_seconds": 5.0}]}) == null, "non-ambient slot DTO must fail closed")
	_expect(AmbientCooldownState.from_dto({"cooldowns": [{"slot_id": "ambient.p0_p0_s0", "expires_at_seconds": -1.0}]}) == null, "negative expiry DTO must fail closed")
	_expect(AmbientCooldownState.from_dto({"cooldowns": ["ambient.p0_p0_s0"]}) == null, "non-dictionary entry must fail closed")
	_expect(AmbientCooldownState.from_dto({"cooldowns": "nope"}) == null, "non-array payload must fail closed")
	_expect(AmbientCooldownState.from_dto([]) == null, "non-dictionary root must fail closed")


func _test_policy_blocked() -> void:
	var keys: Array[StringName] = [&"chunk.p0.p0", &"chunk.p1.p0", &"chunk.p0.p1", &"chunk.n1.p0", &"chunk.p0.n1"]
	var blocked: Array[StringName] = [&"ambient.p0_p0_s0", &"ambient.p1_p0_s1"]
	var request := AmbientSpawnRequest.new(Vector2i.ZERO, keys, {}, blocked, WorldChunkCatalog.DEFAULT_BIOME_ID, 2, 10, 730201, 1)
	var result := AmbientSpawnPolicy.resolve(request, 0)
	_expect(result.is_success(), "blocked-slot request must stay valid")
	for spec in result.admitted:
		_expect(not blocked.has(spec.instance_id), "policy must never admit a cooling-down slot")
	_expect(result.admitted.size() == 8, "all unblocked slots must still be admitted")
	var invalid := AmbientSpawnRequest.new(Vector2i.ZERO, keys, {}, [&"item.bad"] as Array[StringName], WorldChunkCatalog.DEFAULT_BIOME_ID, 2, 10, 730201, 1)
	_expect(AmbientSpawnPolicy.resolve(invalid, 0).status == AmbientSpawnResult.Status.INVALID, "invalid blocked ID must fail the request")
	var duplicated := AmbientSpawnRequest.new(Vector2i.ZERO, keys, {}, [&"ambient.p0_p0_s0", &"ambient.p0_p0_s0"] as Array[StringName], WorldChunkCatalog.DEFAULT_BIOME_ID, 2, 10, 730201, 1)
	_expect(AmbientSpawnPolicy.resolve(duplicated, 0).status == AmbientSpawnResult.Status.INVALID, "duplicated blocked ID must fail the request")


func _make_main() -> Node:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	return main


func _ambient_actor(main: Node) -> Node2D:
	var container := main.get("creature_container") as Node
	for child in container.get_children():
		if child is Node2D and child.has_meta("ambient_spawn_id"):
			return child
	return null


func _test_defeat_save_load_cycle() -> void:
	var main := await _make_main()
	var directory := "user://ambient_cooldown_test_%d" % Time.get_ticks_usec()
	var primary := "%s/slot_1.json" % directory
	main.call("configure_save_path", primary)
	main.set("day_time", 50.0)
	_expect(bool(main.call("maintain_creatures")), "ambient reconcile must succeed")
	var actor := _ambient_actor(main)
	_expect(actor != null, "ambient actor must exist after reconcile")
	var slot_id := actor.get_meta("ambient_spawn_id") as StringName
	var adapter := main.get("ambient_spawn_adapter") as AmbientSpawnAdapter
	actor.call("take_damage", 99999, actor.global_position, null)
	await process_frame
	await process_frame
	_expect(adapter.cooldown_state.is_cooling_down(slot_id, 50.0), "defeat must register a cooldown for the slot")
	_expect(adapter.cooldown_state.expires_at(slot_id) == 50.0 + AmbientCooldownState.COOLDOWN_SECONDS, "cooldown must last COOLDOWN_SECONDS of world clock")
	_expect(main.call("save_game", 700, &"save.slot_1").is_success(), "cooldown save must succeed")
	var snapshot := _read_json(primary)
	var persisted := AmbientCooldownState.from_dto(snapshot.get("world", {}).get("ambient_cooldowns"))
	_expect(persisted != null and persisted.is_cooling_down(slot_id, 50.0), "snapshot must contain the exact cooldown DTO")
	_expect(bool(main.call("maintain_creatures")), "post-defeat reconcile must succeed")
	_expect(not adapter.get_active_ids().has(slot_id), "cooling-down slot must not respawn during cooldown")
	_expect(not adapter.get_active_ids().is_empty(), "other slots must keep spawning during cooldown")
	var load_result: RefCounted = main.call("load_game")
	_expect(load_result.is_loaded(), "cooldown load must succeed")
	_expect(adapter.cooldown_state.is_cooling_down(slot_id, 50.0), "load must restore the cooldown")
	# Capture path through the real removed signal.
	var victim := _ambient_actor(main)
	_expect(victim != null, "a live ambient actor must exist for the capture path")
	var captured_slot := victim.get_meta("ambient_spawn_id") as StringName
	victim.removed.emit(victim, &"", &"creature.removal.captured")
	_expect(adapter.cooldown_state.is_cooling_down(captured_slot, 50.0), "capture must register a cooldown for the slot")
	main.set("day_time", 50.0 + AmbientCooldownState.COOLDOWN_SECONDS + 1.0)
	_expect(bool(main.call("maintain_creatures")), "post-cooldown reconcile must succeed")
	_expect(adapter.get_active_ids().has(slot_id), "slot must respawn after its cooldown expires")
	_expect(adapter.cooldown_state.is_empty(), "expired cooldowns must be pruned on reconcile")
	main.queue_free()
	await process_frame
	await process_frame
	_cleanup(directory)


func _test_legacy_and_corrupt() -> void:
	var main := await _make_main()
	var directory := "user://ambient_cooldown_legacy_%d" % Time.get_ticks_usec()
	var primary := "%s/slot_1.json" % directory
	main.call("configure_save_path", primary)
	var adapter := main.get("ambient_spawn_adapter") as AmbientSpawnAdapter
	adapter.cooldown_state.register(&"ambient.p9_p9_s0", 999.0)
	_expect(main.call("save_game", 701, &"save.slot_1").is_success(), "fixture save must succeed")
	var snapshot := _read_json(primary)

	var legacy: Dictionary = snapshot.duplicate(true)
	legacy["world"].erase("ambient_cooldowns")
	_expect(SaveV1Schema.validate(legacy).is_valid(), "legacy save without cooldowns must stay schema-valid")
	_write_json(primary, legacy)
	adapter.cooldown_state.register(&"ambient.p8_p8_s0", 888.0)
	var legacy_load: RefCounted = main.call("load_game")
	_expect(legacy_load.is_loaded() and adapter.cooldown_state.is_empty(), "legacy missing field must restore an empty cooldown state")

	var corrupt: Dictionary = snapshot.duplicate(true)
	corrupt["world"]["ambient_cooldowns"] = {"cooldowns": [{"slot_id": "bogus", "expires_at_seconds": 5.0}]}
	_expect(not SaveV1Schema.validate(corrupt).is_valid(), "corrupt cooldown DTO must fail schema")
	_write_json(primary, corrupt)
	adapter.cooldown_state.register(&"ambient.p7_p7_s0", 777.0)
	var corrupt_load: RefCounted = main.call("load_game")
	_expect(not corrupt_load.is_loaded() and adapter.cooldown_state.is_cooling_down(&"ambient.p7_p7_s0", 10.0), "corrupt cooldown load must preserve runtime state")
	_expect(not adapter.import_cooldown_dto({"cooldowns": "nope"}, 0.0), "malformed import must fail closed")
	_expect(adapter.cooldown_state.is_cooling_down(&"ambient.p7_p7_s0", 10.0), "failed import must not mutate the state")
	main.queue_free()
	await process_frame
	await process_frame
	_cleanup(directory)


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return value as Dictionary if value is Dictionary else {}


func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("unable to write fixture: %s" % path)
		return
	file.store_string(JSON.stringify(value))
	file.close()


func _cleanup(directory: String) -> void:
	for suffix in ["slot_1.json", "slot_1.json.bak", "slot_1.json.tmp"]:
		var path := "%s/%s" % [directory, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
