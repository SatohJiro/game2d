extends SceneTree

## AT-D: hero + pet visual validation.
## - Sheets have the exact gameplay-contract dimensions.
## - No missing/empty frames; left/right facings are mirrors.
## - Palette stays within the project palette.
## - Player and pet scenes use the new original art.

const HERO_EXTRA := ["2E3A5C", "4A5F8A", "F2C89B", "D2A078", "C96F2E", "8E4A1E", "A9744F", "3B3B4A", "6B4A2E"]
const FOX_EXTRA := ["E89650", "BE6E37", "F7EBD2"]

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_sheet("res://assets/hero/hero_sheet.png", 4, 7, HERO_EXTRA, "hero")
	_test_sheet("res://assets/hero/palfox_sheet.png", 4, 4, FOX_EXTRA, "palfox")
	_test_mirrors("res://assets/hero/hero_sheet.png", 4, 7)
	_test_scenes()
	_finish()


func _palette() -> Dictionary:
	var p := {}
	for hex in ["1D2433", "E8D8B8", "8A5A3B", "D9B382", "F2C230", "F2812E", "D6405E",
			"4FAE4F", "2F7D3A", "3FA7D6", "2474A3", "F2F5F7", "C97B2D", "8E8E93",
			"6B7280", "3B3B3B", "3F5F8A", "2C4463", "F0E6D2", "D9C9A8", "C0392B",
			"F7D9A0", "FFB347"] + HERO_EXTRA + FOX_EXTRA:
		p[hex] = true
	return p


func _load_image(path: String) -> Image:
	var tex := load(path) as Texture2D
	if tex == null:
		_failures.append("cannot load " + path)
		return null
	var img := tex.get_image() as Image
	img.convert(Image.FORMAT_RGBA8)
	return img


func _test_sheet(path: String, cols: int, rows: int, _extra: Array, label: String) -> void:
	_expect(ResourceLoader.exists(path), label + " sheet must exist: " + path)
	var img := _load_image(path)
	if img == null:
		return
	_expect(img.get_width() == cols * 16 and img.get_height() == rows * 16,
		"%s sheet must be %dx%d, got %dx%d" % [label, cols * 16, rows * 16, img.get_width(), img.get_height()])
	var palette := _palette()
	var bad := {}
	for r in rows:
		for c in cols:
			var filled := 0
			for y in range(r * 16, r * 16 + 16):
				for x in range(c * 16, c * 16 + 16):
					var px := img.get_pixel(x, y)
					if px.a > 0.5:
						filled += 1
						var hex := "%02X%02X%02X" % [int(px.r * 255.0), int(px.g * 255.0), int(px.b * 255.0)]
						if not palette.has(hex) and not bad.has(hex):
							bad[hex] = true
			_expect(filled >= 40, "%s frame (%d,%d) must not be empty (filled=%d)" % [label, c, r, filled])
	_expect(bad.is_empty(), "%s palette must stay in project palette, bad=%s" % [label, str(bad.keys())])


func _test_mirrors(path: String, cols: int, rows: int) -> void:
	var img := _load_image(path)
	if img == null:
		return
	# Col 2 (left) mirrored must approximate col 3 (right) for walk rows.
	for r in 4:
		var diff := 0
		for y in 16:
			for x in 16:
				var a := img.get_pixel(2 * 16 + x, r * 16 + y)
				var b := img.get_pixel(3 * 16 + (15 - x), r * 16 + y)
				if (a.a > 0.5) != (b.a > 0.5):
					diff += 1
		_expect(diff < 60, "hero walk row %d: left/right must be mirrors (diff=%d)" % [r, diff])


func _test_scenes() -> void:
	var player_packed := load("res://scenes/player.tscn") as PackedScene
	_expect(player_packed != null, "player scene must load")
	var player = player_packed.instantiate()
	var sprite := _find_sprite(player)
	_expect(sprite != null, "player must have a sprite")
	if sprite != null:
		_expect((sprite as Sprite2D).hframes == 4 and (sprite as Sprite2D).vframes == 7,
			"player sprite must keep the 4x7 contract")
		var tex := (sprite as Sprite2D).texture as Texture2D
		_expect(tex != null and tex.resource_path == "res://assets/hero/hero_sheet.png",
			"player must use the new hero sheet")
	player.queue_free()
	var pet_packed := load("res://scenes/pet.tscn") as PackedScene
	_expect(pet_packed != null, "pet scene must load")
	var pet = pet_packed.instantiate()
	var pet_sprite := _find_sprite(pet)
	_expect(pet_sprite != null, "pet must have a sprite")
	if pet_sprite != null:
		var ptex := (pet_sprite as Sprite2D).texture as Texture2D
		_expect(ptex != null and ptex.resource_path == "res://assets/hero/palfox_sheet.png",
			"pet must use the new palfox sheet")
	pet.queue_free()
	for i in 90:
		await process_frame


func _find_sprite(node: Node) -> Node:
	if node is Sprite2D and (node as Sprite2D).hframes == 4:
		return node
	for child in node.get_children():
		var found := _find_sprite(child)
		if found != null:
			return found
	return null


func _finish() -> void:
	if _failures.is_empty():
		print("Hero art validation passed: hero + palfox sheets meet the animation contract.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit.call_deferred(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
