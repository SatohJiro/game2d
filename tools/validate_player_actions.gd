extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_key_mapping()
	_test_mouse_and_build_precedence()
	_test_release_echo_unknown_and_determinism()
	_test_action_policy()
	await _test_player_adapter()
	await _clean_tree()
	if _failures.is_empty():
		print("Player action validation passed: stable intents, mapping precedence, guards and Player dispatch adapter are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			printerr("PLAYER ACTION VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _test_key_mapping() -> void:
	var expected := {
		KEY_Q: PlayerActionIntent.ACTION_CAPTURE_THROW,
		KEY_C: PlayerActionIntent.ACTION_TOGGLE_CRAFTING,
		KEY_P: PlayerActionIntent.ACTION_TOGGLE_CHARACTER,
		KEY_E: PlayerActionIntent.ACTION_INTERACT,
		KEY_R: PlayerActionIntent.ACTION_PET_COMMAND,
		KEY_G: PlayerActionIntent.ACTION_PET_SKILL,
		KEY_H: PlayerActionIntent.ACTION_USE_ELIXIR,
		KEY_F: PlayerActionIntent.ACTION_USE_FOOD,
		KEY_B: PlayerActionIntent.ACTION_BUILD_START,
		KEY_SPACE: PlayerActionIntent.ACTION_ROLL,
	}
	for keycode in expected:
		var intent := PlayerActionInputMapper.map_event(_key_event(keycode), false)
		_expect(intent.action_id == expected[keycode], "key %s action mapping mismatch" % keycode)
	_expect(PlayerActionInputMapper.map_event(_key_event(KEY_B), false).target_id == &"wood_fence", "quick-build target payload mismatch")
	for index in range(3):
		var intent := PlayerActionInputMapper.map_event(_key_event(KEY_1 + index), false)
		_expect(intent.action_id == PlayerActionIntent.ACTION_PET_SELECT, "pet slot action mapping mismatch")
		_expect(intent.slot_index == index, "pet slot payload mismatch for slot %d" % index)


func _test_mouse_and_build_precedence() -> void:
	var left_world := PlayerActionInputMapper.map_event(_mouse_event(MOUSE_BUTTON_LEFT), false)
	_expect(not left_world.is_valid(), "world left press is held-attack input, not a discrete event")
	var right_world := PlayerActionInputMapper.map_event(_mouse_event(MOUSE_BUTTON_RIGHT), false)
	_expect(right_world.action_id == PlayerActionIntent.ACTION_CAPTURE_THROW, "world right press must map to capture throw")
	var left_build := PlayerActionInputMapper.map_event(_mouse_event(MOUSE_BUTTON_LEFT), true)
	_expect(left_build.action_id == PlayerActionIntent.ACTION_BUILD_PLACE, "build left press must take placement precedence")
	var right_build := PlayerActionInputMapper.map_event(_mouse_event(MOUSE_BUTTON_RIGHT), true)
	_expect(right_build.action_id == PlayerActionIntent.ACTION_BUILD_CANCEL, "build right press must take cancel precedence")
	var escape_build := PlayerActionInputMapper.map_event(_key_event(KEY_ESCAPE), true)
	_expect(escape_build.action_id == PlayerActionIntent.ACTION_BUILD_CANCEL, "build Escape must map to cancel")

	var focus_next := InputEventAction.new()
	focus_next.action = &"ui_focus_next"
	focus_next.pressed = true
	var action_intent := PlayerActionInputMapper.map_event(focus_next, false)
	_expect(action_intent.action_id == PlayerActionIntent.ACTION_CAPTURE_THROW, "ui_focus_next compatibility mapping mismatch")


func _test_release_echo_unknown_and_determinism() -> void:
	var released := _key_event(KEY_E)
	released.pressed = false
	_expect(not PlayerActionInputMapper.map_event(released, false).is_valid(), "released key must be ignored")
	var echoed := _key_event(KEY_E)
	echoed.echo = true
	_expect(not PlayerActionInputMapper.map_event(echoed, false).is_valid(), "echoed key must be ignored")
	_expect(not PlayerActionInputMapper.map_event(_key_event(KEY_Z), false).is_valid(), "unknown key must be a no-op")

	var first := PlayerActionInputMapper.map_event(_key_event(KEY_2), false)
	var second := PlayerActionInputMapper.map_event(_key_event(KEY_2), false)
	_expect(first.action_id == second.action_id and first.slot_index == second.slot_index, "same event/context must map deterministically")


func _test_action_policy() -> void:
	var attack := PlayerActionIntent.new(PlayerActionIntent.ACTION_ATTACK)
	var roll := PlayerActionIntent.new(PlayerActionIntent.ACTION_ROLL)
	var place := PlayerActionIntent.new(PlayerActionIntent.ACTION_BUILD_PLACE)
	_expect(PlayerActionPolicy.is_allowed(attack, false, false, false), "attack should be allowed in normal gameplay")
	_expect(not PlayerActionPolicy.is_allowed(attack, true, false, false), "build mode must block held attack")
	_expect(not PlayerActionPolicy.is_allowed(attack, false, true, false), "modal must block held attack")
	_expect(not PlayerActionPolicy.is_allowed(attack, false, false, true), "roll must block held attack")
	_expect(PlayerActionPolicy.is_allowed(roll, false, false, false), "roll should be allowed in normal gameplay")
	_expect(not PlayerActionPolicy.is_allowed(roll, true, false, false), "build mode must block roll")
	_expect(not PlayerActionPolicy.is_allowed(roll, false, true, false), "modal must block roll")
	_expect(PlayerActionPolicy.is_allowed(place, true, false, false), "placement requires build mode")
	_expect(not PlayerActionPolicy.is_allowed(place, false, false, false), "placement outside build mode must be blocked")
	_expect(not PlayerActionPolicy.is_allowed(PlayerActionIntent.new(), false, false, false), "empty intent must be blocked")


func _test_player_adapter() -> void:
	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	if packed_main == null:
		_failures.append("unable to load main scene")
		return
	var main_scene := packed_main.instantiate()
	root.add_child(main_scene)
	for frame in range(5):
		await process_frame

	var player := get_first_node_in_group("player")
	_expect(player != null and player.has_method("dispatch_action_intent"), "Player action dispatch adapter is missing")
	if player != null:
		_expect(not bool(player.call("dispatch_action_intent", PlayerActionIntent.new())), "Player must reject empty intent")
		var blocked_place := PlayerActionIntent.new(PlayerActionIntent.ACTION_BUILD_PLACE)
		_expect(not bool(player.call("dispatch_action_intent", blocked_place)), "Player adapter must apply build placement policy")


func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event


func _mouse_event(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _clean_tree() -> void:
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
