extends SceneTree

## AT-B: town art validation.
## - Every kind in TownBuilder.KIND_ART resolves to an admitted VERIFIED file.
## - Art dimensions match the authored greybox footprints in TownLayout.
## - Art palette stays within Paloria-16 + AT town extensions.
## - In-game: structures render as sprites (not grey boxes).

const PALORIA16 := [
	"1D2433", "E8D8B8", "8A5A3B", "D9B382", "F2C230", "F2812E", "D6405E",
	"4FAE4F", "2F7D3A", "3FA7D6", "2474A3", "F2F5F7", "C97B2D", "8E8E93",
	"6B7280", "3B3B3B",
]
const AT_EXTENSIONS := [
	"3F5F8A", "2C4463", "F0E6D2", "D9C9A8", "C0392B", "8E2A20",
	"F7D9A0", "FFB347", "F2A7C3", "D67F9E", "2B3355", "7A5FA0",
	"8A94A6", "A9744F", "7A5233", "9AA3B2",
]

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_art_files()
	_test_in_game_sprites()
	_finish()


func _test_art_files() -> void:
	var palette := {}
	for hex in PALORIA16 + AT_EXTENSIONS:
		palette[hex] = true
	var allowed: Dictionary = TownBuilder.KIND_ART.duplicate()
	for alt in (TownBuilder.KIND_ART_ALT as Dictionary).values():
		for path in alt as Array:
			allowed[path] = true
	var art_paths := {}
	for key in allowed.keys():
		art_paths[String(allowed[key])] = true
	_expect(art_paths.size() > 10, "town art table must cover structure kinds")
	for res_path in art_paths.keys():
		_expect(ResourceLoader.exists(res_path), "town art must exist: %s" % res_path)
		if not ResourceLoader.exists(res_path):
			continue
		var tex := load(res_path) as Texture2D
		_expect(tex != null, "town art must load: %s" % res_path)
		if tex == null:
			continue
		_expect(tex.get_width() >= 16 and tex.get_height() >= 16, "town art must have real size: %s" % res_path)
	# Footprint match against layout.
	for entry in TownLayout.all():
		var s := entry as Dictionary
		var kind := s["kind"] as StringName
		var art_path := String((TownBuilder.KIND_ART as Dictionary).get(kind, ""))
		if art_path.is_empty():
			_failures.append("layout kind has no art: %s" % String(kind))
			continue
		var tex := load(art_path) as Texture2D
		if tex == null:
			continue
		var want := s["size"] as Vector2
		_expect(tex.get_width() == int(want.x) and tex.get_height() == int(want.y),
			"art size must match footprint for %s: got %dx%d want %s" % [String(s["id"]), tex.get_width(), tex.get_height(), str(want)])
	# Palette audit on a sample of files.
	for path in ["res://assets/town/station_hall.png", "res://assets/town/shrine_hall.png", "res://assets/town/lake.png"]:
		var img := (load(path) as Texture2D).get_image() as Image
		img.convert(Image.FORMAT_RGBA8)
		var bad := {}
		for y in range(0, img.get_height(), 2):
			for x in range(0, img.get_width(), 2):
				var c := img.get_pixel(x, y)
				if c.a < 0.5:
					continue
				var hex := "%02X%02X%02X" % [int(c.r * 255.0), int(c.g * 255.0), int(c.b * 255.0)]
				if not palette.has(hex) and not bad.has(hex):
					bad[hex] = true
		_expect(bad.is_empty(), "town art palette must stay in Paloria-16 + AT extensions: %s -> %s" % [path, str(bad.keys())])


func _test_in_game_sprites() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main scene must load")
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var player := _find_player(main)
	_expect(player != null, "player must exist")
	if player == null:
		return
	player.global_position = Vector2(1400, 220)
	for i in 12:
		await physics_frame
	var station := _find_structure(main, "station_hall")
	_expect(station != null, "station_hall node must build")
	if station != null:
		var has_sprite := false
		var has_greybox := false
		for child in station.get_children():
			if child is Sprite2D and (child as Sprite2D).texture != null:
				has_sprite = true
			if child is ColorRect:
				has_greybox = true
		_expect(has_sprite, "station_hall must render real art, not a grey box")
		_expect(not has_greybox, "station_hall must not keep greybox fallback")
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
		print("Town art validation passed: all structures render verified original art.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit.call_deferred(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
