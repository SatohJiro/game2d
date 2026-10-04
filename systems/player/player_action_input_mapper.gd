class_name PlayerActionInputMapper
extends RefCounted


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

	match event.keycode:
		KEY_Q:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_CAPTURE_THROW)
		KEY_C:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_TOGGLE_CRAFTING)
		KEY_P:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_TOGGLE_CHARACTER)
		KEY_E:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_INTERACT)
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
		KEY_SPACE:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_ROLL)
		KEY_1, KEY_2, KEY_3:
			return PlayerActionIntent.new(PlayerActionIntent.ACTION_PET_SELECT, event.keycode - KEY_1)
		_:
			return PlayerActionIntent.new()
