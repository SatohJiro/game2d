class_name PlayerActionInputMapper
extends RefCounted

## Basic key remapping (U3.4). GameSettings persists action_id -> keycode and
## calls apply_remap; action_key exposes the effective binding (also used by
## the context prompt to display the interact key).
const REMAPPABLE_DEFAULTS := {
	PlayerActionIntent.ACTION_INTERACT: KEY_E,
	PlayerActionIntent.ACTION_ROLL: KEY_SPACE,
	PlayerActionIntent.ACTION_CAPTURE_THROW: KEY_Q,
}

static var key_remap: Dictionary = {}


static func is_remappable(action_id: StringName) -> bool:
	return REMAPPABLE_DEFAULTS.has(action_id)


static func action_key(action_id: StringName) -> int:
	return int(key_remap.get(String(action_id), REMAPPABLE_DEFAULTS.get(action_id, KEY_NONE)))


static func apply_remap(remap: Dictionary) -> void:
	key_remap.clear()
	for action_id in remap:
		if is_remappable(StringName(action_id)):
			key_remap[String(action_id)] = int(remap[action_id])


static func map_event(event: InputEvent, is_building: bool) -> PlayerActionIntent:
	if event == null:
		return PlayerActionIntent.new()

	if is_building:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_BUILD_PLACE)
		if (
			event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_RIGHT
			and event.pressed
		) or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_BUILD_CANCEL)

	if event.is_action_pressed(&"ui_focus_next"):
		return PlayerActionIntent.new(PlayerActionIntent.ACTION_CAPTURE_THROW)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		return PlayerActionIntent.new(PlayerActionIntent.ACTION_CAPTURE_THROW)

	if not event is InputEventKey or not event.pressed or event.echo:
		return PlayerActionIntent.new()

	for action_id in REMAPPABLE_DEFAULTS:
		if event.keycode == action_key(action_id):
			return PlayerActionIntent.new(action_id)

	match event.keycode:
		KEY_C:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_TOGGLE_CRAFTING)
		KEY_P:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_TOGGLE_CHARACTER)
		KEY_R:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_PET_COMMAND)
		KEY_G:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_PET_SKILL)
		KEY_H:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_USE_ELIXIR)
		KEY_F:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_USE_FOOD)
		KEY_B:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_BUILD_START, -1, &"wood_fence")
		KEY_1, KEY_2, KEY_3:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_PET_SELECT, event.keycode - KEY_1)
		_:
			return PlayerActionIntent.new()
