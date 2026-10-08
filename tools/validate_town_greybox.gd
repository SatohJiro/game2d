extends SceneTree

## AT-A: town district data + greybox layout validation.
## - District DB covers the 3x3 town chunks with valid rects and name keys.
## - Every structure sits inside its district rect and maps to the right chunk.
## - Main scene builds greybox structures under admitted chunk nodes.

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Localization.set_locale("vi")
	_test_district_db()
	_test_layout()
	_test_greybox_build()
	_finish()


func _test_district_db() -> void:
	var districts := TownDistrictDB.all()
	_expect(districts.size() == 10, "town must define 10 districts, found %d" % districts.size())
	var chunks := {}
	for entry in districts:
		var d := entry as Dictionary
		_expect(d.has("id") and d.has("chunk") and d.has("rect") and d.has("name_key"), "district must have id/chunk/rect/name_key")
		var coord := d["chunk"] as Vector2i
		_expect(coord.x >= 0 and coord.x <= 2 and coord.y >= -1 and coord.y <= 1, "district chunk must be in town 3x3: %s" % str(coord))
		chunks[ChunkCoordinate.to_key(coord)] = true
		var text := Localization.text(String(d["name_key"]))
		_expect(text != String(d["name_key"]), "district name key must localize: %s" % String(d["name_key"]))
	_expect(chunks.size() == 9, "districts must cover 9 town chunks, found %d" % chunks.size())
	var anchor := TownDistrictDB.anchor_by_id(&"town_station")
	_expect(not anchor.is_empty(), "town_station anchor must resolve")
	_expect((anchor["position"] as Vector2).x > 1024.0, "town_station must be east of spawn")


func _test_layout() -> void:
	var structures := TownLayout.all()
	_expect(structures.size() >= 15, "town must place at least 15 structures, found %d" % structures.size())
	var ids := {}
	for entry in structures:
		var s := entry as Dictionary
		_expect(not ids.has(String(s["id"])), "structure id must be unique: %s" % String(s["id"]))
		ids[String(s["id"])] = true
		var district := TownDistrictDB.find(s["district"])
		_expect(not district.is_empty(), "structure district must exist: %s" % String(s["id"]))
		if district.is_empty():
			continue
		var rect := district["rect"] as Rect2
		_expect(rect.has_point(s["position"] as Vector2), "structure must sit inside its district: %s" % String(s["id"]))
		# Chunk mapping consistency.
		var chunk_structs := TownLayout.for_chunk(district["chunk"])
		var found := false
		for cs in chunk_structs:
			if String((cs as Dictionary)["id"]) == String(s["id"]):
				found = true
		_expect(found, "structure must map to its district chunk: %s" % String(s["id"]))


func _test_greybox_build() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main scene must load")
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_expect(main.get("town_builder") != null, "main must own a TownBuilder")
	var player := _find_player(main)
	_expect(player != null, "player must exist")
	if player == null:
		return
	# Teleport near the station plaza and let chunk admission run.
	player.global_position = Vector2(1400, 220)
	for i in 12:
		await physics_frame
	var station_node := _find_structure(main, "station_hall")
	_expect(station_node != null, "greybox station_hall must build under its chunk node")
	if station_node != null:
		var gp := (station_node as Node2D).global_position
		_expect(gp.distance_to(Vector2(1400, 220)) < 2.0,
			"station_hall must sit at its authored world position, got %s" % str(gp))
	var shrine_node := _find_structure(main, "shrine_hall")
	# Shrine is in chunk (1,-1); may not be admitted from the station position.
	if shrine_node == null:
		player.global_position = Vector2(1536, -700)
		for i in 12:
			await physics_frame
		shrine_node = _find_structure(main, "shrine_hall")
	_expect(shrine_node != null, "greybox shrine_hall must build when its chunk admits")
	main.queue_free()


func _find_player(node: Node) -> Node:
	if node.get_script() != null and String(node.get_script().resource_path).ends_with("player.gd"):
		return node
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null


func _find_structure(node: Node, structure_id: String) -> Node:
	if node.name == "TownStructure_%s" % structure_id:
		return node
	for child in node.get_children():
		var found := _find_structure(child, structure_id)
		if found != null:
			return found
	return null


func _finish() -> void:
	if _failures.is_empty():
		print("Town greybox validation passed: districts, layout and chunk-streamed greybox are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit.call_deferred(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
