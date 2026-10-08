extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_manifest()
	await _test_chunk_lifecycle()
	await _test_save_load_no_duplicates()
	if _failures.is_empty():
		print("Static content validation passed: deterministic manifests, chunk lifecycle ownership and save/load stability are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _test_manifest() -> void:
	var origin := StaticContentCatalog.manifest_for_chunk(Vector2i(0, 0))
	_expect(origin.is_valid(), "origin manifest must be valid")
	_expect(origin.placements.size() == 11, "manifest must carry the authored density (4+3+2+2)")
	var repeat := StaticContentCatalog.manifest_for_chunk(Vector2i(0, 0))
	_expect(_placements_signature(origin) == _placements_signature(repeat), "manifests must be deterministic per chunk")
	var east := StaticContentCatalog.manifest_for_chunk(Vector2i(1, 0))
	_expect(east.is_valid(), "east manifest must be valid")
	_expect(_placements_signature(origin) != _placements_signature(east), "different chunks must get different decorations")
	var signed := StaticContentCatalog.manifest_for_chunk(Vector2i(-2, -3))
	_expect(signed.is_valid(), "signed-coordinate manifest must be valid")
	for placement in origin.placements:
		var pos: Vector2 = placement["local_position"]
		_expect(pos.x >= 0.0 and pos.y >= 0.0 and pos.x < 1024.0 and pos.y < 1024.0, "placements must stay inside chunk bounds")
	_expect(not StaticContentManifest.is_valid_placement({"content_id": "item.bad", "kind": "flowers", "local_position": Vector2(10, 10), "scale": 1.0}, Vector2i.ZERO), "non-static content ID must be rejected")
	_expect(not StaticContentManifest.is_valid_placement({"content_id": "static.p1_p0_flowers_0", "kind": "flowers", "local_position": Vector2(10, 10), "scale": 1.0}, Vector2i.ZERO), "foreign chunk prefix must be rejected")
	_expect(not StaticContentManifest.is_valid_placement({"content_id": "static.p0_p0_nope_0", "kind": "nope", "local_position": Vector2(10, 10), "scale": 1.0}, Vector2i.ZERO), "unknown kind must be rejected")
	_expect(not StaticContentManifest.is_valid_placement({"content_id": "static.p0_p0_flowers_0", "kind": "flowers", "local_position": Vector2(-5, 10), "scale": 1.0}, Vector2i.ZERO), "out-of-bounds placement must be rejected")
	_expect(not StaticContentManifest.is_valid_placement({"content_id": "static.p0_p0_flowers_0", "kind": "flowers", "local_position": Vector2(10, 10), "scale": 0.0}, Vector2i.ZERO), "non-positive scale must be rejected")
	_expect(not StaticContentCatalog.texture_for_kind("nope"), "unknown kind must have no texture")
	_expect(StaticContentCatalog.texture_for_kind("flowers") != null, "known kind must resolve a texture")


func _placements_signature(manifest: StaticContentManifest) -> String:
	var parts: Array[String] = []
	for placement in manifest.placements:
		parts.append("%s|%s|%s" % [String(placement["content_id"]), String(placement["kind"]), str(placement["local_position"])])
	parts.sort()
	return "|".join(parts)


func _make_main() -> Node:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	return main


func _chunk_nodes(main: Node) -> Array:
	var container := main.get_node("ChunkPlaceholders")
	return container.get_children()


func _decoration_count(main: Node) -> int:
	return get_nodes_in_group("chunk_static_decor").size()


func _test_chunk_lifecycle() -> void:
	var main := await _make_main()
	var adapter := main.get("chunk_scene_adapter") as ChunkSceneAdapter
	_expect(adapter.get_active_keys().size() == 9, "admission must own exactly nine chunks")
	_expect(_chunk_nodes(main).size() == 9, "container must hold nine chunk nodes")
	for chunk_node in _chunk_nodes(main):
		_expect((chunk_node as ChunkPlaceholder).get_static_decoration_count() == 11, "every chunk must spawn its full decoration set")
	_expect(_decoration_count(main) == 99, "all decorations must register in the sway group")

	main.call("update_chunk_admission", Vector2(1024.0, 0.0))
	await process_frame
	await process_frame
	_expect(adapter.get_active_keys().size() == 9, "crossing must keep nine active chunks")
	_expect(_chunk_nodes(main).size() == 9, "unloaded chunk nodes must be freed, not orphaned")
	for chunk_node in _chunk_nodes(main):
		_expect((chunk_node as ChunkPlaceholder).coordinate.x >= 0, "west column chunks must be unloaded on east crossing")
		_expect((chunk_node as ChunkPlaceholder).get_static_decoration_count() == 11, "newly admitted chunks must spawn decorations")
	_expect(_decoration_count(main) == 99, "decoration count must be stable across chunk crossing")
	var active_lookup := {}
	for key in adapter.get_active_keys():
		active_lookup[key] = true
	for decor in get_nodes_in_group("chunk_static_decor"):
		var owner := decor.get_parent()
		_expect(owner is ChunkPlaceholder and active_lookup.has((owner as ChunkPlaceholder).chunk_key), "every decoration must be owned by an active chunk node")
	# Ambient budget must be unaffected by static decorations.
	_expect(bool(main.call("maintain_creatures")), "ambient reconcile must succeed alongside statics")
	var ambient_ids := (main.get("ambient_spawn_adapter") as AmbientSpawnAdapter).get_active_ids()
	_expect(ambient_ids.size() <= int(main.get("max_wild_creatures")), "static content must not consume the ambient budget")
	main.queue_free()
	await process_frame
	await process_frame


func _test_save_load_no_duplicates() -> void:
	var main := await _make_main()
	var directory := "user://static_content_test_%d" % Time.get_ticks_usec()
	var primary := "%s/slot_1.json" % directory
	main.call("configure_save_path", primary)
	var before := _decoration_count(main)
	_expect(before == 99, "fixture must start with a full decoration set")
	_expect(main.call("save_game", 800, &"save.slot_1").is_success(), "save with static content must succeed")
	var load_result: RefCounted = main.call("load_game")
	_expect(load_result.is_loaded(), "load must succeed")
	_expect(_decoration_count(main) == before, "save/load must not duplicate static decorations")
	var seen := {}
	for decor in get_nodes_in_group("chunk_static_decor"):
		var content_id := String(decor.get_meta("static_content_id", ""))
		_expect(not content_id.is_empty() and not seen.has(content_id), "static content IDs must stay unique after load")
		seen[content_id] = true
	main.queue_free()
	await process_frame
	await process_frame
	for suffix in ["slot_1.json", "slot_1.json.bak", "slot_1.json.tmp"]:
		var path := "%s/%s" % [directory, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
