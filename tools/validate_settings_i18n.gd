extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_localization_pure()
	_test_game_settings()
	_test_remap()
	await _test_settings_panel()
	await _test_context_prompt()
	await _test_ui_scale()
	if _failures.is_empty():
		print("Settings/i18n validation passed: localization tables, settings persist/apply, key remap, settings panel intents, context prompt and UI scale are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _test_localization_pure() -> void:
	_expect(Localization.load_locale("vi"), "vi table must load")
	Localization.set_locale("vi")
	_expect(Localization.text("settings.title") == "CÀI ĐẶT", "vi lookup must return Vietnamese text")
	Localization.set_locale("en")
	_expect(Localization.text("settings.title") == "SETTINGS", "en lookup must return English text")
	_expect(Localization.text("no.such.key") == "no.such.key", "missing key must fall back to the key itself")
	Localization.set_locale("vi")
	_expect(Localization.text("slots.loaded", {"slot": "slot_1"}) == "Đã tải slot_1.", "replacements must format into the text")
	_expect(not Localization.load_locale("xx"), "unknown locale must fail to load")
	_expect(Localization.text("prompt.interact_hint", {"key": "E", "target": "X"}) == "[E] X", "prompt template must format")


func _test_game_settings() -> void:
	GameSettings.reset_to_defaults()
	GameSettings.master_volume = 0.5
	GameSettings.ui_scale = 1.25
	GameSettings.reduce_motion = true
	GameSettings.locale = "en"
	GameSettings.input_remap = {"player.action.interact": KEY_T}
	GameSettings.save()
	GameSettings.reset_to_defaults()
	_expect(GameSettings.master_volume == 0.8, "reset must restore defaults")
	GameSettings.load()
	_expect(GameSettings.master_volume == 0.5, "volume must persist")
	_expect(GameSettings.ui_scale == 1.25, "ui scale must persist")
	_expect(GameSettings.reduce_motion, "reduce motion must persist")
	_expect(GameSettings.locale == "en", "locale must persist")
	_expect(int(GameSettings.input_remap.get("player.action.interact", 0)) == KEY_T, "remap must persist")
	GameSettings.apply()
	_expect(Localization.get_locale() == "en", "apply must switch the locale")
	_expect(PlayerActionInputMapper.action_key(PlayerActionIntent.ACTION_INTERACT) == KEY_T, "apply must push the remap to the mapper")
	var bus_db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	_expect(absf(bus_db - linear_to_db(0.5)) < 0.01, "apply must set the master bus volume")
	GameSettings.reset_to_defaults()
	GameSettings.apply()
	GameSettings.save()


func _test_remap() -> void:
	PlayerActionInputMapper.apply_remap({})
	_expect(PlayerActionInputMapper.action_key(PlayerActionIntent.ACTION_INTERACT) == KEY_E, "default interact key must be E")
	_expect(PlayerActionInputMapper.is_remappable(PlayerActionIntent.ACTION_ROLL), "roll must be remappable")
	_expect(not PlayerActionInputMapper.is_remappable(PlayerActionIntent.ACTION_TOGGLE_CRAFTING), "crafting toggle must stay fixed")
	PlayerActionInputMapper.apply_remap({"player.action.interact": KEY_T, "bogus.action": KEY_Z})
	_expect(PlayerActionInputMapper.action_key(PlayerActionIntent.ACTION_INTERACT) == KEY_T, "remap must change the effective key")
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_T
	_expect(PlayerActionInputMapper.map_event(event, false).action_id == PlayerActionIntent.ACTION_INTERACT, "remapped key must dispatch the interact intent")
	event.keycode = KEY_E
	_expect(PlayerActionInputMapper.map_event(event, false).action_id == &"", "old default must no longer dispatch after remap")
	PlayerActionInputMapper.apply_remap({})


func _find_slider(node: Node) -> HSlider:
	if node is HSlider:
		return node
	for child in node.get_children():
		var found := _find_slider(child)
		if found != null:
			return found
	return null


func _find_check(node: Node) -> CheckButton:
	if node is CheckButton:
		return node
	for child in node.get_children():
		var found := _find_check(child)
		if found != null:
			return found
	return null


func _find_option(node: Node) -> OptionButton:
	if node is OptionButton:
		return node
	for child in node.get_children():
		var found := _find_option(child)
		if found != null:
			return found
	return null


func _find_button_by_text(node: Node, label: String) -> Button:
	if node is Button and node.text == label:
		return node
	for child in node.get_children():
		var found := _find_button_by_text(child, label)
		if found != null:
			return found
	return null


func _test_settings_panel() -> void:
	Localization.set_locale("vi")
	var packed := load("res://scenes/settings.tscn") as PackedScene
	var panel = packed.instantiate()
	root.add_child(panel)
	await process_frame
	var volumes: Array = []
	var scales: Array = []
	var motions: Array = []
	var locales: Array = []
	var remaps: Array = []
	panel.volume_changed.connect(func(value: float) -> void: volumes.append(value))
	panel.ui_scale_changed.connect(func(value: float) -> void: scales.append(value))
	panel.reduce_motion_toggled.connect(func(enabled: bool) -> void: motions.append(enabled))
	panel.locale_selected.connect(func(locale: String) -> void: locales.append(locale))
	panel.remap_changed.connect(func(action_id: StringName, keycode: int) -> void: remaps.append([action_id, keycode]))
	panel.render({
		"master_volume": 0.8, "ui_scale": 1.0, "reduce_motion": false, "locale": "vi",
		"input_remap": {},
		"remap_actions": [{"id": PlayerActionIntent.ACTION_INTERACT, "label_key": "settings.remap_interact"}],
	})
	_expect(not panel.is_open(), "settings panel must start closed")
	panel.toggle()
	_expect(panel.is_open() and panel.visible, "toggle must open the settings panel")
	var slider := _find_slider(panel)
	slider.value_changed.emit(50.0)
	_expect(volumes == [0.5], "volume slider must emit a 0..1 intent")
	var check := _find_check(panel)
	check.toggled.emit(true)
	_expect(motions == [true], "reduce-motion check must emit its intent")
	var option := _find_option(panel)
	option.item_selected.emit(1)
	_expect(locales == ["en"], "locale option must emit the locale code")
	var remap_button := _find_button_by_text(panel, "E")
	_expect(remap_button != null, "remap button must show the current key")
	remap_button.pressed.emit()
	_expect(remap_button.text == Localization.text("settings.press_key"), "remap button must arm the capture mode")
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_X
	panel._unhandled_input(key_event)
	_expect(remaps == [[PlayerActionIntent.ACTION_INTERACT, KEY_X]], "captured key must emit the remap intent")
	_expect(remap_button.text == "X", "remap button must show the new key")
	panel.toggle()
	_expect(not panel.is_open(), "toggle must close the settings panel")
	panel.queue_free()
	await process_frame


func _make_main() -> Node2D:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	return main


func _test_context_prompt() -> void:
	Localization.set_locale("vi")
	GameSettings.reset_to_defaults()
	GameSettings.apply()
	var main := await _make_main()
	var player: Node2D = main.get("player")
	var hud: CanvasLayer = main.get("hud")
	var pot = main.get_node("Environment/BaseCamp/StarterCookingPot")
	pot.global_position = player.global_position + Vector2(30, 0)
	for i in 6:
		await physics_frame
	var target = player.get_interaction_target()
	_expect(target == pot, "player must detect the nearby pot as interaction target")
	main._update_context_prompt()
	var prompt = main.get("context_prompt")
	_expect(prompt.visible, "prompt must show near an interactable")
	_expect(String(prompt.text).contains("Nồi nấu ăn"), "prompt must use the localized target name")
	_expect(String(prompt.text).contains("[E]"), "prompt must show the interact key")
	player.global_position = player.global_position + Vector2(5000, 5000)
	for i in 6:
		await physics_frame
	_expect(player.get_interaction_target() == null, "no interactable must be in range far from camp")
	main._update_context_prompt()
	_expect(not prompt.visible, "prompt must hide with no target in range")
	player.global_position = player.global_position + Vector2(-5000, -5000)
	pot.global_position = player.global_position + Vector2(30, 0)
	for i in 6:
		await physics_frame
	hud.toggle_crafting(true)
	main._update_context_prompt()
	_expect(not prompt.visible, "prompt must hide while a modal is open")
	hud.toggle_crafting(false)
	main.queue_free()
	await process_frame


func _test_ui_scale() -> void:
	GameSettings.reset_to_defaults()
	var main := await _make_main()
	var hud: CanvasLayer = main.get("hud")
	GameSettings.ui_scale = 1.25
	main._apply_ui_scale()
	var applied: Vector2 = hud.transform.get_scale()
	_expect(applied.distance_to(Vector2(1.25, 1.25)) < 0.001, "UI scale must apply to the HUD transform")
	GameSettings.ui_scale = 1.0
	main._apply_ui_scale()
	applied = hud.transform.get_scale()
	_expect(applied.distance_to(Vector2.ONE) < 0.001, "UI scale 1.0 must restore the HUD transform")
	main.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
