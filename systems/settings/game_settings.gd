class_name GameSettings
extends RefCounted

## User settings (U3.4), stored separately from game saves.
##
## Static state so gameplay code (player shake, input mapper) can read it
## without plumbing. Main loads at startup, applies, and persists on change.
## Config file: user://settings.cfg — never mixed with save slots.

const PATH := "user://settings.cfg"

static var master_volume := 0.8
static var ui_scale := 1.0
static var reduce_motion := false
static var locale := "vi"
## action_id String -> keycode int (see PlayerActionInputMapper.REMAPPABLE_DEFAULTS)
static var input_remap: Dictionary = {}


static func reset_to_defaults() -> void:
	master_volume = 0.8
	ui_scale = 1.0
	reduce_motion = false
	locale = "vi"
	input_remap = {}


static func load() -> void:
	reset_to_defaults()
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	ui_scale = clampf(float(config.get_value("ui", "ui_scale", ui_scale)), 0.75, 1.5)
	reduce_motion = bool(config.get_value("accessibility", "reduce_motion", reduce_motion))
	var saved_locale := String(config.get_value("language", "locale", locale))
	locale = saved_locale if saved_locale in ["vi", "en"] else "vi"
	input_remap = {}
	if config.has_section("input"):
		for key in config.get_section_keys("input"):
			var action_id := StringName(key)
			if PlayerActionInputMapper.is_remappable(action_id):
				input_remap[String(action_id)] = int(config.get_value("input", key, 0))


static func save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("ui", "ui_scale", ui_scale)
	config.set_value("accessibility", "reduce_motion", reduce_motion)
	config.set_value("language", "locale", locale)
	for action_id in input_remap:
		config.set_value("input", String(action_id), int(input_remap[action_id]))
	config.save(PATH)


static func apply() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(maxf(master_volume, 0.001)))
	Localization.set_locale(locale)
	PlayerActionInputMapper.apply_remap(input_remap)
