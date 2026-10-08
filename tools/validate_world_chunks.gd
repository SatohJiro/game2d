extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_coordinate_boundaries()
	_test_key_round_trip()
	_test_definitions_and_catalog()
	_test_admission_policy_and_coordinator()
	_test_persistent_delta_projection()
	await _test_main_read_adapter()
	if _failures.is_empty():
		print("World chunk validation passed: typed definitions, signed keys, scene admission and revision-guarded navigation ownership are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)

func _test_coordinate_boundaries() -> void:
	_expect(ChunkCoordinate.from_world_position(Vector2.ZERO) == Vector2i.ZERO, "origin must resolve to chunk zero")
	_expect(ChunkCoordinate.from_world_position(Vector2(1023.999, 1023.999)) == Vector2i.ZERO, "positive inner edge must stay in origin chunk")
	_expect(ChunkCoordinate.from_world_position(Vector2(1024.0, 1024.0)) == Vector2i.ONE, "positive boundary must enter next chunk")
	_expect(ChunkCoordinate.from_world_position(Vector2(-0.001, -0.001)) == Vector2i(-1, -1), "negative fraction must floor into negative chunk")
	_expect(ChunkCoordinate.from_world_position(Vector2(-1024.0, -1024.0)) == Vector2i(-1, -1), "negative exact boundary mismatch")
	_expect(ChunkCoordinate.world_origin(Vector2i(-2, 3)) == Vector2(-2048.0, 3072.0), "chunk origin projection mismatch")

func _test_key_round_trip() -> void:
	for coordinate in [Vector2i.ZERO, Vector2i(1, -1), Vector2i(-42, 73)]:
		var key := ChunkCoordinate.to_key(coordinate)
		_expect(ContentId.is_valid(key), "chunk key must satisfy stable ID grammar: %s" % key)
		var parsed: Array[Vector2i] = []
		_expect(ChunkCoordinate.try_parse_key(key, parsed), "chunk key must parse: %s" % key)
		_expect(parsed.size() == 1 and parsed[0] == coordinate, "chunk key round trip mismatch: %s" % key)
	var rejected: Array[Vector2i] = []
	_expect(not ChunkCoordinate.try_parse_key(&"chunk.-1.0", rejected), "raw signed numeric key must be rejected")
	_expect(not ChunkCoordinate.try_parse_key(&"chunk.n0.p0", rejected), "negative zero key must be rejected")
	_expect(not ChunkCoordinate.try_parse_key(&"biome.p0.p0", rejected), "wrong key domain must be rejected")

func _test_definitions_and_catalog() -> void:
	var biome := load("res://data/definitions/biomes/paloria_meadow.tres") as BiomeDefinition
	var chunk := WorldChunkCatalog.get_origin_definition()
	_expect(biome != null and biome.get_validation_errors().is_empty(), "Paloria biome canary must be valid")
	_expect(chunk != null and chunk.get_validation_errors().is_empty(), "origin chunk canary must be valid")
	if chunk != null:
		_expect(chunk.coordinate == Vector2i.ZERO, "origin definition coordinate mismatch")
		_expect(chunk.biome_id == WorldChunkCatalog.DEFAULT_BIOME_ID, "origin definition biome mismatch")
	var context := WorldChunkCatalog.resolve_world_position(Vector2(-1.0, 1024.0))
	_expect(context != null and context.is_valid(), "catalog must produce a valid context")
	_expect(context.coordinate == Vector2i(-1, 1), "catalog coordinate mismatch")
	_expect(context.chunk_key == &"chunk.n1.p1", "catalog key mismatch")

func _test_admission_policy_and_coordinator() -> void:
	var desired := ChunkAdmissionPolicy.desired_keys(Vector2i.ZERO)
	_expect(desired.size() == 9, "3x3 policy must produce nine keys")
	_expect(desired == ChunkAdmissionPolicy.desired_keys(Vector2i.ZERO), "desired key snapshot must be stable")
	var sorted := desired.duplicate()
	sorted.sort()
	_expect(desired == sorted, "desired keys must use deterministic lexical order")
	_expect(desired.has(&"chunk.n1.n1") and desired.has(&"chunk.p1.p1"), "origin neighborhood must cover signed corners")

	var coordinator := ChunkAdmissionCoordinator.new()
	var initial := coordinator.update_world_position(Vector2.ZERO)
	_expect(initial.is_changed() and initial.admitted_keys.size() == 9, "initial admission must add nine records")
	_expect(initial.unloaded_keys.is_empty() and coordinator.revision == 1, "initial admission revision mismatch")
	var initial_keys := coordinator.get_active_keys()
	var no_change := coordinator.update_world_position(Vector2(900.0, 900.0))
	_expect(no_change.status == ChunkAdmissionDelta.Status.NO_CHANGE, "movement inside one chunk must be no-op")
	_expect(coordinator.revision == 1 and coordinator.get_active_keys() == initial_keys, "no-op must preserve coordinator state")

	var crossing := coordinator.update_world_position(Vector2(1024.0, 0.0))
	_expect(crossing.is_changed(), "positive boundary crossing must change admission")
	_expect(crossing.admitted_keys.size() == 3 and crossing.unloaded_keys.size() == 3, "one-axis crossing must swap three chunks")
	_expect(coordinator.center == Vector2i(1, 0) and coordinator.get_active_keys().size() == 9, "crossing must preserve a 3x3 neighborhood")
	var snapshot := coordinator.create_debug_snapshot()
	_expect(snapshot["active_count"] == 9 and snapshot["revision"] == 2, "debug snapshot metadata mismatch")

	var before_stale := coordinator.create_debug_snapshot()
	var stale := coordinator.update_world_position(Vector2(-0.1, -0.1), 1)
	_expect(stale.status == ChunkAdmissionDelta.Status.STALE, "stale observed revision must be rejected")
	_expect(coordinator.create_debug_snapshot() == before_stale, "stale request must not mutate coordinator")
	var duplicate_keys: Array[StringName] = [&"chunk.p0.p0", &"chunk.p0.p0"]
	var duplicate_request := ChunkAdmissionRequest.new(Vector2i.ZERO, duplicate_keys, 0)
	var duplicate_result := ChunkAdmissionPolicy.resolve(duplicate_request, 0)
	_expect(duplicate_result.status == ChunkAdmissionDelta.Status.INVALID, "duplicate active keys must be rejected")

func _test_persistent_delta_projection() -> void:
	var building := BuildingPlacementRecord.new(&"building.instance_boundary", &"building.workbench", Transform2D(0.0, Vector2(1024.0, -0.1))).to_dto()
	var resource_payload := ResourceDepletionRecord.new(&"resource.tree_boundary", ResourceDepletionRecord.TREE_ID, ResourceDepletionState.new(37, 0.0, ResourceDepletionState.TREE_MAX_HEALTH)).to_dto()
	var resources: Array = [{"position": {"x": -0.1, "y": 1024.0}, "payload": resource_payload}]
	var projected := ChunkDeltaProjector.project([building], resources)
	_expect(projected.size() == 2, "cross-boundary records must project into two chunk envelopes")
	var decoded: Variant = JSON.parse_string(JSON.stringify(projected))
	_expect(ChunkDeltaEnvelope.from_dto(decoded[0]) != null, "first decoded chunk envelope invalid: %s" % decoded[0])
	_expect(ChunkDeltaEnvelope.from_dto(decoded[1]) != null, "second decoded chunk envelope invalid: %s" % decoded[1])
	var flattened := ChunkDeltaProjector.flatten(decoded)
	_expect((flattened.get("buildings", []) as Array).size() == 1 and (flattened.get("resources", []) as Array).size() == 1, "chunk delta JSON round trip must preserve building/resource payloads: %s" % flattened)
	var keys: Array[String] = []
	for value: Dictionary in projected: keys.append(value["chunk_key"])
	_expect(keys.has("chunk.p1.n1") and keys.has("chunk.n1.p1"), "positive/negative boundary attribution mismatch")
	var mismatched: Array = projected.duplicate(true)
	mismatched[0]["coordinate"]["x"] = 99
	_expect(ChunkDeltaProjector.flatten(mismatched).is_empty(), "chunk key/coordinate mismatch must fail closed")
	var duplicated: Array = projected.duplicate(true)
	duplicated.append(projected[0].duplicate(true))
	_expect(ChunkDeltaProjector.flatten(duplicated).is_empty(), "cross-chunk duplicate entity identity must fail closed")

func _test_main_read_adapter() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_failures.append("unable to load main scene")
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var context := main.call("get_world_chunk_context", Vector2(1024.0, -0.1)) as WorldChunkContext
	_expect(context != null and context.coordinate == Vector2i(1, -1), "Main read adapter coordinate mismatch")
	_expect(context != null and context.biome_id == WorldChunkCatalog.DEFAULT_BIOME_ID, "Main read adapter biome mismatch")
	var debug_snapshot := main.call("get_chunk_admission_debug_snapshot") as Dictionary
	_expect(debug_snapshot.get("active_count") == 9, "Main admission adapter must expose nine active records")
	var navigation_snapshot := main.call("get_chunk_navigation_debug_snapshot") as Dictionary
	_expect(navigation_snapshot.get("active_count") == 9, "Main navigation adapter must own nine regions")
	_expect(navigation_snapshot.get("revision") == debug_snapshot.get("revision"), "scene and navigation revisions must match")
	_expect(not _contains_rid(navigation_snapshot), "navigation debug snapshot must not retain RID values")
	var mutable_records := debug_snapshot.get("active_chunks") as Array
	mutable_records.clear()
	var fresh_snapshot := main.call("get_chunk_admission_debug_snapshot") as Dictionary
	_expect((fresh_snapshot.get("active_chunks") as Array).size() == 9, "Main debug snapshot must be detached from coordinator state")
	var container := main.get_node("ChunkPlaceholders") as Node2D
	_expect(container.get_child_count() == 9, "Main must instantiate exactly nine placeholder chunks")
	var origin_node := (main.get("chunk_scene_adapter") as ChunkSceneAdapter).get_node_for_key(&"chunk.p0.p0")
	_expect(is_instance_valid(origin_node) and origin_node.position == Vector2.ZERO, "origin placeholder transform mismatch")
	var node_ids: Array[int] = []
	for child in container.get_children(): node_ids.append(child.get_instance_id())
	var navigation_before_noop := main.call("get_chunk_navigation_debug_snapshot") as Dictionary
	_expect(bool(main.call("update_chunk_admission", main.get("player").global_position)), "same-chunk scene update must succeed")
	var no_churn_ids: Array[int] = []
	for child in container.get_children(): no_churn_ids.append(child.get_instance_id())
	_expect(node_ids == no_churn_ids, "same-chunk update must not churn placeholder Nodes")
	_expect(main.call("get_chunk_navigation_debug_snapshot") == navigation_before_noop, "same-chunk update must not churn navigation regions")
	_expect(bool(main.call("update_chunk_admission", Vector2(-0.1, 1024.0))), "negative crossing scene update must succeed")
	await process_frame
	_expect(container.get_child_count() == 9, "crossing must retain exactly nine placeholder Nodes")
	var crossed_adapter := main.get("chunk_scene_adapter") as ChunkSceneAdapter
	var corner := crossed_adapter.get_node_for_key(&"chunk.n2.p2")
	_expect(crossed_adapter.get_active_keys().size() == 9 and is_instance_valid(corner), "negative crossing must own nine unique signed keys")
	_expect(corner.position == ChunkCoordinate.world_origin(Vector2i(-2, 2)), "crossed placeholder transform must match chunk origin")
	var crossed_navigation := main.call("get_chunk_navigation_debug_snapshot") as Dictionary
	_expect(crossed_navigation.get("active_count") == 9, "crossing must retain exactly nine navigation regions")
	var replaced_count := 9 - _navigation_keys(navigation_before_noop).filter(func(key: StringName) -> bool: return _navigation_keys(crossed_navigation).has(key)).size()
	_expect(int(crossed_navigation.get("created_count")) - int(navigation_before_noop.get("created_count")) == replaced_count, "crossing created count must equal exact ownership difference")
	_expect(int(crossed_navigation.get("freed_count")) - int(navigation_before_noop.get("freed_count")) == replaced_count, "crossing freed count must equal exact ownership difference")
	_expect((main.get("chunk_navigation_adapter") as ChunkNavigationAdapter).get_active_keys() == crossed_adapter.get_active_keys(), "scene and navigation adapters must own identical keys")
	var obstacle_result := main.call("update_chunk_obstacle", &"chunk.n2.p2", 1, true) as ChunkNavigationResult
	_expect(obstacle_result.status == ChunkNavigationResult.Status.APPLIED, "current obstacle revision must apply")
	var obstacle_snapshot := main.call("get_chunk_navigation_debug_snapshot") as Dictionary
	var blocked_record := _find_navigation_record(obstacle_snapshot, &"chunk.n2.p2")
	_expect(blocked_record.get("blocked") == true and blocked_record.get("obstacle_revision") == 1, "obstacle state must appear in detached debug data")
	var duplicate_obstacle := main.call("update_chunk_obstacle", &"chunk.n2.p2", 1, false) as ChunkNavigationResult
	_expect(duplicate_obstacle.status == ChunkNavigationResult.Status.STALE, "duplicate obstacle revision must be stale")
	_expect(main.call("get_chunk_navigation_debug_snapshot") == obstacle_snapshot, "stale obstacle request must not mutate navigation state")
	var missing_obstacle := main.call("update_chunk_obstacle", &"chunk.p99.p99", 1, true) as ChunkNavigationResult
	_expect(missing_obstacle.status == ChunkNavigationResult.Status.INVALID, "inactive chunk obstacle update must be rejected")
	var stale_sync := ChunkNavigationRequest.new(ChunkNavigationRequest.Kind.SYNC_REGIONS, 1, 2, [], [], (main.get("chunk_navigation_adapter") as ChunkNavigationAdapter).get_active_keys())
	var stale_sync_result := (main.get("chunk_navigation_adapter") as ChunkNavigationAdapter).apply(stale_sync)
	_expect(stale_sync_result.status == ChunkNavigationResult.Status.STALE, "stale navigation sync must be rejected")
	_expect(not bool(main.get("chunk_debug_overlay").visible), "chunk overlay must default hidden")
	_expect(bool(main.call("toggle_chunk_debug_overlay")), "chunk overlay toggle must show")
	var revision_before_overlay := int((main.call("get_chunk_admission_debug_snapshot") as Dictionary)["revision"])
	main.get("chunk_debug_overlay").call("render_snapshot", {"center_key": "tampered", "revision": 99, "active_count": 0})
	_expect(int((main.call("get_chunk_admission_debug_snapshot") as Dictionary)["revision"]) == revision_before_overlay, "overlay render must not mutate coordinator")
	var navigation_adapter := main.get("chunk_navigation_adapter") as ChunkNavigationAdapter
	main.queue_free()
	await process_frame
	await process_frame
	_expect(navigation_adapter.create_debug_snapshot().get("active_count") == 0, "Main exit must release all navigation region ownership")

func _find_navigation_record(snapshot: Dictionary, key: StringName) -> Dictionary:
	for record: Dictionary in snapshot.get("active_chunks", []):
		if StringName(record.get("chunk_key", "")) == key:
			return record
	return {}

func _navigation_keys(snapshot: Dictionary) -> Array[StringName]:
	var keys: Array[StringName] = []
	for record: Dictionary in snapshot.get("active_chunks", []):
		keys.append(StringName(record.get("chunk_key", "")))
	return keys

func _contains_rid(value: Variant) -> bool:
	if value is RID: return true
	if value is Dictionary:
		for child in (value as Dictionary).values():
			if _contains_rid(child): return true
	if value is Array:
		for child in value as Array:
			if _contains_rid(child): return true
	return false

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
