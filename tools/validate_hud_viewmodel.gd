extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_theme_tokens()
	_test_viewmodel_mapping()
	await _test_render_empty()
	await _test_main_integration()
	if _failures.is_empty():
		print("HUD ViewModel validation passed: theme tokens, ViewModel mapping, empty render and damage-to-HUD wiring are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _test_theme_tokens() -> void:
	_expect(PaloriaTheme.card_stylebox().bg_color == PaloriaTheme.CARD_BG, "card stylebox must use the card token")
	_expect(PaloriaTheme.card_stylebox().corner_radius_top_left == PaloriaTheme.RADIUS_CARD, "card radius must use the token")
	_expect(PaloriaTheme.cooking_card_stylebox().border_color == PaloriaTheme.COOKING_CARD_BORDER, "cooking card must use its border token")
	_expect(PaloriaTheme.minimap_panel_stylebox().bg_color == PaloriaTheme.MINIMAP_BG, "minimap panel must use its tokens")
	_expect(PaloriaTheme.panel_stylebox() is StyleBoxFlat, "panel factory must return a StyleBoxFlat")
	_expect(PaloriaTheme.FONT_TITLE > PaloriaTheme.FONT_NORMAL and PaloriaTheme.FONT_NORMAL > PaloriaTheme.FONT_SMALL, "type scale must be ordered")
	var first := PaloriaTheme.card_stylebox()
	var second := PaloriaTheme.card_stylebox()
	_expect(not is_same(first, second), "factories must return fresh instances")


func _test_viewmodel_mapping() -> void:
	var null_vm := HUDViewModel.from_player(null)
	_expect(null_vm.hp == 100 and null_vm.level == 1, "null player must yield safe defaults")
	_expect(not null_vm.pet_visible, "null player must have no pet section")


func _make_main() -> Node:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	return main


func _test_render_empty() -> void:
	var packed := load("res://scenes/hud.tscn") as PackedScene
	var hud := packed.instantiate()
	root.add_child(hud)
	await process_frame
	hud.render_view_model(HUDViewModel.empty())
	hud.render_view_model(null)
	await process_frame
	_expect(hud.get_node("TopLeft/PlayerCard/Margin/HBox/VBox/HpBar").max_value == 100, "empty ViewModel must render safe bar defaults")
	hud.queue_free()
	await process_frame


func _test_main_integration() -> void:
	var main := await _make_main()
	var player: Node2D = main.get("player")
	var hud: CanvasLayer = main.get("hud")
	var hp_bar: ProgressBar = hud.get_node("TopLeft/PlayerCard/Margin/HBox/VBox/HpBar")

	var vm := HUDViewModel.from_player(player)
	_expect(vm.hp == int(player.get("hp")) and vm.max_hp == int(player.get("max_hp")), "ViewModel must mirror player vitals")
	_expect(vm.level == int(player.get("level")) and vm.exp_val == int(player.get("exp_val")), "ViewModel must mirror progression")
	_expect(vm.stats.get("str") == (player.get("stats") as Dictionary).get("str"), "ViewModel must snapshot stats")
	_expect(vm.inventory == player.get("inventory"), "ViewModel must snapshot inventory")
	_expect(vm.weapon_text == "%s (Sát thương %d)" % [String(player.get("weapon_name")), int(player.get("weapon_damage")) + int((player.get("stats") as Dictionary).get("str", 0)) * 3], "ViewModel must format the weapon line")
	_expect(vm.buff_text == "Khỏe mạnh", "default buff text must match the legacy fallback")
	vm.stats["str"] = 9999
	_expect(int((player.get("stats") as Dictionary).get("str")) != 9999, "ViewModel stats must be a detached copy")

	var hp_before: float = hp_bar.value
	player.call("take_damage", 10, player.get("global_position"))
	player.call("update_hud")
	await process_frame
	_expect(hp_bar.value == hp_before - 10.0, "damage must flow player -> ViewModel -> HUD bars")
	_expect(hp_bar.max_value == float(player.get("max_hp")), "HUD bar range must track the ViewModel")
	# Let the damage floating-text tween finish so the headless scene frees cleanly.
	for _i in 90:
		await process_frame
	main.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
