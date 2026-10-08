extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_repository_round_trip()
	if _failures.is_empty():
		print("Discovery save validation passed: primary, backup, legacy and failure atomicity are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _test_repository_round_trip() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_failures.append("unable to load Main scene")
		return
	var directory := "user://discovery_save_test_%d" % Time.get_ticks_usec()
	var primary := "%s/slot_1.json" % directory
	var backup := "%s.bak" % primary
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	world.set_process(false)
	world.call("configure_save_path", primary)
	world.call("update_chunk_admission", Vector2(1024.0, 0.0))
	world.call("update_chunk_admission", Vector2(-0.1, 1024.0))
	var adapter := world.get("chunk_discovery_adapter") as ChunkDiscoveryAdapter
	var saved_a := adapter.export_dto()
	_expect(saved_a.get("revision") == 3, "fixture must discover origin plus signed crossings")
	_expect(world.call("save_game", 610, &"save.slot_1").is_success(), "first discovery save must succeed")
	var snapshot_a := _read_json(primary)
	var persisted_discovery := ChunkDiscoveryState.from_dto(snapshot_a.get("world", {}).get("discovery_state"))
	_expect(persisted_discovery != null and persisted_discovery.to_dto() == saved_a, "snapshot must contain exact normalized discovery DTO")
	var ownership_before := _ownership_snapshot(world)
	adapter.observe_center(Vector2i(9, 9))
	var primary_load: RefCounted = world.call("load_game")
	_expect(primary_load.status == SaveCoordinatorResult.Status.LOADED_PRIMARY and adapter.export_dto() == saved_a, "primary load must restore exact discovery set")
	_expect(_ownership_snapshot(world) == ownership_before, "primary discovery restore must not mutate chunk/navigation/spawn ownership")

	adapter.observe_center(Vector2i(8, 8))
	var saved_b := adapter.export_dto()
	_expect(world.call("save_game", 611, &"save.slot_1").is_success(), "second discovery save must create backup")
	_write_text(primary, "{broken json")
	adapter.observe_center(Vector2i(7, 7))
	var backup_load: RefCounted = world.call("load_game")
	_expect(backup_load.status == SaveCoordinatorResult.Status.LOADED_BACKUP and adapter.export_dto() == saved_a, "backup recovery must restore prior discovery commit")
	_expect(adapter.export_dto() != saved_b, "backup recovery must not expose corrupt primary state")

	# A schema-valid but unsupported inventory reference reaches apply failure.
	var unsupported: Dictionary = snapshot_a.duplicate(true)
	unsupported["inventory"] = {"item.not_admitted": 1}
	_write_json(primary, unsupported)
	_delete_if_exists(backup)
	adapter.observe_center(Vector2i(6, 6))
	var before_apply_failure := adapter.export_dto()
	var apply_failure: RefCounted = world.call("load_game")
	_expect(apply_failure.status == SaveCoordinatorResult.Status.APPLY_FAILED, "unsupported reference must reach apply failure")
	_expect(adapter.export_dto() == before_apply_failure, "apply failure must preserve runtime discovery")

	var invalid_discovery: Dictionary = snapshot_a.duplicate(true)
	invalid_discovery["world"]["discovery_state"] = {"revision": 2, "discovered_chunks": ["chunk.p0.p0", "chunk.p0.p0"]}
	_expect(not SaveV1Schema.validate(invalid_discovery).is_valid(), "duplicate discovery DTO must fail schema")
	_write_json(primary, invalid_discovery)
	var before_corrupt := adapter.export_dto()
	var corrupt_load: RefCounted = world.call("load_game")
	_expect(not corrupt_load.is_loaded() and adapter.export_dto() == before_corrupt, "corrupt discovery load must preserve runtime state")

	var legacy: Dictionary = snapshot_a.duplicate(true)
	legacy["world"].erase("discovery_state")
	_expect(SaveV1Schema.validate(legacy).is_valid(), "legacy save missing discovery field must remain valid")
	_write_json(primary, legacy)
	var legacy_load: RefCounted = world.call("load_game")
	_expect(legacy_load.is_loaded() and adapter.export_dto() == {"revision": 0, "discovered_chunks": []}, "legacy missing field must restore conservative empty discovery")

	world.queue_free()
	await process_frame
	await process_frame
	_cleanup(directory, primary, backup)


func _ownership_snapshot(world: Node) -> Dictionary:
	return {
		"admission": world.call("get_chunk_admission_debug_snapshot"),
		"navigation": world.call("get_chunk_navigation_debug_snapshot"),
		"ambient_ids": _ambient_ids(world.call("get_ambient_spawn_debug_snapshot")),
	}


func _ambient_ids(snapshot: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for actor: Dictionary in snapshot.get("actors", []): ids.append(actor.get("instance_id", ""))
	ids.sort()
	return ids


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return value as Dictionary if value is Dictionary else {}


func _write_json(path: String, value: Dictionary) -> void:
	_write_text(path, JSON.stringify(value))


func _write_text(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("unable to write fixture: %s" % path)
		return
	file.store_string(value)
	file.close()


func _delete_if_exists(path: String) -> void:
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _cleanup(directory: String, primary: String, backup: String) -> void:
	_delete_if_exists(primary)
	_delete_if_exists(backup)
	_delete_if_exists("%s.tmp" % primary)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
