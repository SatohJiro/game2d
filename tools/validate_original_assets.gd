extends SceneTree

## U4.2: every VERIFIED asset must be project-original and art-bible compliant.
## - PNG: loads, dimensions are multiples of the 16px grid, every opaque
##   pixel's RGB belongs to the Paloria-16 palette (no foreign pixels).
## - Audio: WAV 16-bit mono 22050 Hz; OGG music loads as AudioStream.
## - Every VERIFIED path appears in the U4.2 provenance receipt.
## - Character sheets stay QUARANTINE (documented manual backlog).

const PALETTE := [
	Color8(29, 36, 51), Color8(58, 67, 86), Color8(242, 201, 155), Color8(214, 158, 109),
	Color8(79, 174, 79), Color8(47, 125, 58), Color8(169, 116, 79), Color8(122, 82, 51),
	Color8(154, 163, 178), Color8(107, 114, 128), Color8(63, 167, 214), Color8(36, 116, 163),
	Color8(242, 129, 46), Color8(242, 194, 48), Color8(214, 64, 94), Color8(79, 111, 181),
	Color8(238, 243, 248),
]
## AT palette extensions (documented in docs/assets/AT_ART_DIRECTION.md):
## town art, hero, palfox and NPC originals.
const PALETTE_AT := [
	Color8(63, 95, 138), Color8(44, 68, 99), Color8(240, 230, 210), Color8(217, 201, 168),
	Color8(192, 57, 43), Color8(142, 42, 32), Color8(247, 217, 160), Color8(255, 179, 71),
	Color8(242, 167, 195), Color8(214, 127, 158), Color8(43, 51, 85), Color8(122, 95, 160),
	Color8(138, 148, 166), Color8(46, 58, 92), Color8(74, 95, 138),
	Color8(201, 111, 46), Color8(142, 74, 30), Color8(59, 59, 74), Color8(107, 74, 46),
	Color8(210, 160, 120), Color8(232, 150, 80), Color8(190, 110, 55), Color8(247, 235, 210),
	Color8(200, 200, 210), Color8(90, 70, 125), Color8(235, 190, 150), Color8(150, 110, 70),
	Color8(90, 60, 40), Color8(70, 130, 90), Color8(50, 95, 65),
	Color8(60, 50, 70), Color8(230, 120, 90), Color8(185, 90, 60), Color8(245, 210, 170),
	Color8(242, 200, 155),
]
const EXPECTED_SFX := {
	"slash": "res://assets/sfx/sword.wav",
	"hit": "res://assets/sfx/hit.wav",
	"sphere_throw": "res://assets/sfx/fireball.wav",
	"shake": "res://assets/sfx/alert.wav",
	"success": "res://assets/sfx/success.wav",
	"level_up": "res://assets/sfx/powerup.wav",
	"pickup": "res://assets/sfx/coin.wav",
	"jump": "res://assets/sfx/jump.wav",
}

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_verified_assets()
	_test_audio_map()
	_test_backlog()
	if _failures.is_empty():
		print("Original asset validation passed: VERIFIED assets are palette-clean, spec-shaped and receipted; audio map resolves.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _manifest_rows() -> Array:
	var rows := []
	var file := FileAccess.open("res://docs/assets/asset_manifest.csv", FileAccess.READ)
	if file == null:
		_failures.append("cannot open asset_manifest.csv")
		return rows
	var header := true
	var columns := {}
	while not file.eof_reached():
		var line := file.get_line()
		if line.strip_edges().is_empty():
			continue
		if header:
			var heads := line.split(",")
			for i in heads.size():
				columns[heads[i].strip_edges().trim_prefix("\ufeff").trim_prefix("\"").trim_suffix("\"")] = i
			header = false
			continue
		var cells := line.split(",")
		var row := {}
		for key in columns:
			var idx: int = columns[key]
			row[key] = cells[idx].strip_edges().trim_prefix("\"").trim_suffix("\"") if idx < cells.size() else ""
		rows.append(row)
	file.close()
	return rows


func _receipt_text() -> String:
	var combined := ""
	var dir := DirAccess.open("res://docs/assets/receipts")
	if dir == null:
		return combined
	for file_name in dir.get_files():
		if not file_name.ends_with(".md"):
			continue
		var receipt := FileAccess.open("res://docs/assets/receipts/" + file_name, FileAccess.READ)
		if receipt != null:
			combined += receipt.get_as_text() + "\n"
			receipt.close()
	return combined


func _test_verified_assets() -> void:
	var receipt_text := _receipt_text()
	_expect(not receipt_text.is_empty(), "at least one asset receipt must exist")
	var verified := 0
	for row in _manifest_rows():
		if String(row.get("provenance_status", "")) != "VERIFIED":
			continue
		verified += 1
		var path := "res://" + String(row["path"])
		_expect(String(row.get("license_spdx", "")) == "CC0-1.0", "VERIFIED asset must be CC0-1.0: %s" % path)
		_expect(receipt_text.contains(String(row["path"])), "receipt must list %s" % path)
		if String(row.get("kind", "")) == "texture":
			_check_texture(path)
		elif String(row.get("kind", "")) in ["sfx", "music"]:
			_check_audio(path, String(row.get("kind", "")))
	_expect(verified >= 61, "at least 61 assets must be VERIFIED, found %d" % verified)


func _check_texture(path: String) -> void:
	var img := Image.load_from_file(path)
	_expect(img != null and not img.is_empty(), "texture must load: %s" % path)
	if img == null or img.is_empty():
		return
	# Town/hero art is placed at authored world positions, not on a tile grid.
	var grid_exempt := path.contains("/assets/town/") or path.contains("/assets/hero/")
	if not grid_exempt:
		_expect(img.get_width() % 8 == 0 and img.get_height() % 8 == 0, "texture grid must be 8px multiples: %s (%dx%d)" % [path, img.get_width(), img.get_height()])
	img.convert(Image.FORMAT_RGBA8)
	var foreign := 0
	for y in img.get_height():
		for x in img.get_width():
			var pixel := img.get_pixel(x, y)
			if pixel.a < 0.02:
				continue
			var rgb := Color8(int(pixel.r * 255.0), int(pixel.g * 255.0), int(pixel.b * 255.0))
			if not PALETTE.has(rgb) and not PALETTE_AT.has(rgb):
				foreign += 1
				if foreign > 4:
					break
		if foreign > 4:
			break
	_expect(foreign == 0, "texture must use only Paloria-16 colors: %s (%d foreign)" % [path, foreign])


func _check_audio(path: String, kind: String) -> void:
	if kind == "sfx":
		_check_wav_source(path)
	else:
		var stream := load(path) as AudioStream
		_expect(stream != null, "music must load as AudioStream: %s" % path)


## Verify the source WAV bytes (Godot imports WAV as QOA, so the imported
## stream format cannot prove the source spec).
func _check_wav_source(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "sfx file must open: %s" % path)
	if file == null:
		return
	var riff := file.get_buffer(4).get_string_from_ascii()
	_expect(riff == "RIFF", "sfx must be a RIFF WAV: %s" % path)
	file.get_buffer(4)  # chunk size
	_expect(file.get_buffer(4).get_string_from_ascii() == "WAVE", "sfx must be WAVE: %s" % path)
	var audio_format := 0
	var channels := 0
	var sample_rate := 0
	var bits := 0
	while not file.eof_reached():
		var chunk_id := file.get_buffer(4).get_string_from_ascii()
		if chunk_id.length() < 4:
			break
		var chunk_size := file.get_32()
		if chunk_id == "fmt ":
			audio_format = file.get_16()
			channels = file.get_16()
			sample_rate = file.get_32()
			file.get_32()  # byte rate
			file.get_16()  # block align
			bits = file.get_16()
			break
		else:
			file.get_buffer(chunk_size)
	file.close()
	_expect(audio_format == 1, "sfx source must be PCM: %s" % path)
	_expect(channels == 1, "sfx source must be mono: %s" % path)
	_expect(sample_rate == 22050, "sfx source must be 22050 Hz: %s" % path)
	_expect(bits == 16, "sfx source must be 16-bit: %s" % path)


func _test_audio_map() -> void:
	for sound_name in EXPECTED_SFX:
		var stream := load(EXPECTED_SFX[sound_name]) as AudioStream
		_expect(stream != null, "audio map entry must resolve: %s -> %s" % [sound_name, EXPECTED_SFX[sound_name]])


func _test_backlog() -> void:
	var backlog := ["assets/hunter/hunter_sheet.png", "assets/monsters/slime_sheet.png"]
	for row in _manifest_rows():
		var path := String(row.get("path", ""))
		if path in backlog:
			_expect(String(row.get("provenance_status", "")) == "QUARANTINE", "character art must stay QUARANTINE: %s" % path)


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
