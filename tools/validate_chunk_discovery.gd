extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_state_and_dto()
	await _test_main_adapter()
	if _failures.is_empty():
		print("Chunk discovery validation passed: center-only discovery, DTO and isolated fog snapshots are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _test_state_and_dto() -> void:
	var state := ChunkDiscoveryState.new()
	var origin := state.discover(ChunkDiscoveryRequest.new(&"chunk.p0.p0", 0))
	_expect(origin.status == ChunkDiscoveryResult.Status.DISCOVERED and state.revision == 1, "origin discovery must increment revision once")
	var no_change := state.discover(ChunkDiscoveryRequest.new(&"chunk.p0.p0", 1))
	_expect(no_change.status == ChunkDiscoveryResult.Status.NO_CHANGE and state.revision == 1, "duplicate discovery must be no-op")
	var stale := state.discover(ChunkDiscoveryRequest.new(&"chunk.p1.p0", 0))
	_expect(stale.status == ChunkDiscoveryResult.Status.STALE and state.get_discovered_keys() == [&"chunk.p0.p0"], "stale discovery must not mutate state")
	var invalid := state.discover(ChunkDiscoveryRequest.new(&"chunk.-1.0", 1))
	_expect(invalid.status == ChunkDiscoveryResult.Status.INVALID and state.revision == 1, "noncanonical chunk key must fail closed")
	var negative := state.discover(ChunkDiscoveryRequest.new(&"chunk.n1.p1", 1))
	_expect(negative.status == ChunkDiscoveryResult.Status.DISCOVERED and state.revision == 2, "signed discovery must be accepted")
	var decoded: Variant = JSON.parse_string(JSON.stringify(state.to_dto()))
	var restored := ChunkDiscoveryState.from_dto(decoded)
	_expect(restored != null and restored.to_dto() == state.to_dto(), "discovery DTO must survive JSON round trip")
	_expect(ChunkDiscoveryState.from_dto(null).to_dto() == {"revision": 0, "discovered_chunks": []}, "missing legacy field must produce empty discovery")
	_expect(ChunkDiscoveryState.from_dto({}).to_dto() == {"revision": 0, "discovered_chunks": []}, "legacy empty object must produce empty discovery")
	_expect(ChunkDiscoveryState.from_dto({"revision": 2, "discovered_chunks": ["chunk.p0.p0", "chunk.p0.p0"]}) == null, "duplicate DTO keys must be rejected")
	_expect(ChunkDiscoveryState.from_dto({"revision": 9, "discovered_chunks": ["chunk.p0.p0"]}) == null, "DTO revision/count mismatch must be rejected")
	var view := state.create_view_snapshot(Vector2i.ZERO, ChunkAdmissionPolicy.desired_keys(Vector2i.ZERO))
	_expect((view.get("tiles") as Array).size() == 9, "view must union active fog tiles with discovered tiles without duplicates")
	_expect(view.get("discovered_count") == 2, "view discovery count mismatch")
	(view.get("tiles") as Array).clear()
	_expect((state.create_view_snapshot(Vector2i.ZERO, ChunkAdmissionPolicy.desired_keys(Vector2i.ZERO)).get("tiles") as Array).size() == 9, "view snapshot must be detached from state")


func _test_main_adapter() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_failures.append("unable to load main scene for discovery validation")
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var initial := main.call("get_chunk_discovery_view_snapshot") as Dictionary
	_expect(initial.get("revision") == 1 and initial.get("discovered_count") == 1, "Main initial admission must discover only its center")
	_expect(_count_flag(initial, "active") == 9 and _count_flag(initial, "discovered") == 1, "initial view must expose nine active tiles but one discovered tile")
	var initial_center := StringName(initial.get("center_key", ""))
	_expect(bool(main.call("update_chunk_admission", main.get("player").global_position)), "same-chunk Main update must succeed")
	_expect((main.call("get_chunk_discovery_view_snapshot") as Dictionary).get("revision") == 1, "same-chunk update must not increment discovery revision")
	_expect(bool(main.call("update_chunk_admission", Vector2(1024.0, 0.0))), "positive crossing must succeed")
	_expect(bool(main.call("update_chunk_admission", Vector2(-0.1, 1024.0))), "negative signed crossing must succeed")
	var crossed := main.call("get_chunk_discovery_view_snapshot") as Dictionary
	_expect(crossed.get("revision") == 3 and crossed.get("discovered_count") == 3, "two crossings must add exactly two discovered centers")
	_expect(_snapshot_has_key(crossed, initial_center) and _snapshot_has_key(crossed, &"chunk.p1.p0") and _snapshot_has_key(crossed, &"chunk.n1.p1"), "positive/negative center keys must remain discovered")
	_expect((main.call("get_chunk_navigation_debug_snapshot") as Dictionary).get("active_count") == 9, "discovery must not alter navigation ownership")
	_expect((main.call("get_ambient_spawn_debug_snapshot") as Dictionary).get("active_count") == 10, "discovery must not alter ambient budget")
	var adapter := main.get("chunk_discovery_adapter") as ChunkDiscoveryAdapter
	var before_stale := adapter.export_dto()
	_expect(adapter.observe_center(Vector2i(9, 9), 1).status == ChunkDiscoveryResult.Status.STALE, "stale adapter request must be rejected")
	_expect(adapter.export_dto() == before_stale, "stale adapter request must preserve state")
	(crossed.get("tiles") as Array).clear()
	_expect(not (main.call("get_chunk_discovery_view_snapshot") as Dictionary).get("tiles", []).is_empty(), "Main view snapshot must be detached")
	main.queue_free()
	await process_frame
	await process_frame


func _count_flag(snapshot: Dictionary, field: String) -> int:
	var count := 0
	for tile: Dictionary in snapshot.get("tiles", []):
		if bool(tile.get(field, false)): count += 1
	return count


func _snapshot_has_key(snapshot: Dictionary, key: StringName) -> bool:
	for tile: Dictionary in snapshot.get("tiles", []):
		if StringName(tile.get("chunk_key", "")) == key and bool(tile.get("discovered", false)): return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
