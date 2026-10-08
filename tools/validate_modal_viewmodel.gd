extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_viewmodels_pure()
	await _test_intent_boundary()
	await _test_pot_integration()
	if _failures.is_empty():
		print("Modal ViewModel validation passed: card ViewModels, intent-only buttons and pot coordinator wiring are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _crafting_recipes() -> Array:
	return [
		{"id": "test_plank", "name": "Ván Gỗ", "desc": "Vật liệu", "req": {"Gỗ": 2}, "base_lvl": 1},
		{"id": "test_sword", "name": "Kiếm Sắt", "desc": "Vũ khí", "req": {"Thỏi Sắt": 3}, "base_lvl": 2},
	]


func _test_viewmodels_pure() -> void:
	var affordable := CraftingViewModel.from_recipes(_crafting_recipes(), {"Gỗ": 5, "Thỏi Sắt": 3}, 2)
	_expect(affordable.cards.size() == 2, "crafting ViewModel must build one card per recipe")
	_expect(bool(affordable.cards[0]["can_afford"]), "stocked recipe must be affordable")
	_expect(String(affordable.cards[0]["cost_text"]) == "Gỗ: 5/2", "crafting cost text must show have/need")
	var poor := CraftingViewModel.from_recipes(_crafting_recipes(), {"Gỗ": 1}, 2)
	_expect(not bool(poor.cards[0]["can_afford"]), "missing materials must block affordability")
	_expect(String(poor.cards[0]["cost_text"]) == "Gỗ: 1/2", "shortfall must be visible in cost text")
	var low_base := CraftingViewModel.from_recipes(_crafting_recipes(), {"Thỏi Sắt": 9}, 1)
	_expect(not bool(low_base.cards[1]["can_afford"]), "insufficient base level must block affordability")
	_expect(String(low_base.cards[1]["cost_text"]).contains("[Cần Căn Cứ Lv.2]"), "base requirement must appear in cost text")
	var mixed := CraftingViewModel.from_recipes([{"id": "ok"}, "junk", 42], {}, 1)
	_expect(mixed.cards.size() == 1, "non-dictionary recipes must be skipped")

	var cooking := CookingViewModel.from_recipes([{"id": "water", "name": "Nước", "cost": {"Gỗ": 1}}], {"Gỗ": 2})
	_expect(bool(cooking.cards[0]["can_afford"]), "stocked cooking recipe must be affordable")
	_expect(String(cooking.cards[0]["cost_text"]) == "Nguyên liệu: Gỗ: 2/1", "cooking cost text must list materials")
	var broke := CookingViewModel.from_recipes([{"id": "water", "name": "Nước", "cost": {"Gỗ": 1}}], {})
	_expect(not bool(broke.cards[0]["can_afford"]), "empty inventory must block cooking")


func _make_hud() -> CanvasLayer:
	var packed := load("res://scenes/hud.tscn") as PackedScene
	var hud := packed.instantiate() as CanvasLayer
	root.add_child(hud)
	await process_frame
	return hud


func _first_card_button(grid: GridContainer, only_enabled: bool = false) -> Button:
	for card in grid.get_children():
		var button := _find_button(card)
		if button != null and (not only_enabled or not button.disabled):
			return button
	return null


func _find_button(node: Node) -> Button:
	if node is Button:
		return node
	for child in node.get_children():
		var found := _find_button(child)
		if found != null:
			return found
	return null


func _test_intent_boundary() -> void:
	var hud := await _make_hud()
	_expect(hud.get("active_cooking_pot") == null and hud.get("active_player_ref") == null, "HUD must not hold domain references")
	var crafted: Array = []
	hud.recipe_crafted.connect(func(recipe_id: String) -> void: crafted.append(recipe_id))
	hud.set_recipes(_crafting_recipes())
	hud.toggle_crafting(true)
	await process_frame
	var craft_button := _first_card_button(hud.get_node("CraftingModal/Margin/VBox/Scroll/RecipeGrid"))
	_expect(craft_button != null, "crafting cards must render buttons")
	craft_button.pressed.emit()
	_expect(crafted == ["test_plank"], "craft button must emit exactly its recipe intent")

	var cooked: Array = []
	hud.cooking_requested.connect(func(recipe_id: String) -> void: cooked.append(recipe_id))
	hud.open_cooking_modal([{"id": "water", "name": "Nước", "cost": {"Gỗ": 1}}])
	await process_frame
	_expect(hud.is_cooking_modal_visible(), "cooking modal must open from a recipe list")
	var cook_button := _first_card_button(hud.get_node("CookingModal/Margin/VBox/Scroll/RecipeGrid"))
	_expect(cook_button != null, "cooking cards must render buttons")
	cook_button.pressed.emit()
	_expect(cooked == ["water"], "cook button must emit exactly its recipe intent")
	hud.queue_free()
	await process_frame


func _test_pot_integration() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var player: Node2D = main.get("player")
	var hud: CanvasLayer = main.get("hud")
	(player.get("inventory") as Dictionary)["Gỗ"] = 5
	var pot := main.get_node("Environment/BaseCamp/StarterCookingPot")
	pot.call("open_cooking_menu", player)
	await process_frame
	_expect(hud.is_cooking_modal_visible(), "pot must open the cooking modal")
	_expect(pot.get("is_cooking") == false, "pot must be idle before the intent")
	var cook_button := _first_card_button(hud.get_node("CookingModal/Margin/VBox/Scroll/RecipeGrid"), true)
	_expect(cook_button != null, "affordable recipe button must be enabled")
	cook_button.pressed.emit()
	await process_frame
	_expect(bool(pot.get("is_cooking")), "cooking intent must start the pot through the coordinator")
	_expect(not hud.is_cooking_modal_visible(), "modal must close after cooking starts")
	_expect(int((player.get("inventory") as Dictionary).get("Gỗ", -1)) == 4, "cooking must deduct exactly the recipe cost")
	pot.call("_on_cooking_requested", "nope")
	_expect(bool(pot.get("is_cooking")), "unknown recipe intent must not disturb the pot")
	# Let cooking floating-text tweens finish so the headless scene frees cleanly.
	for _i in 90:
		await process_frame
	main.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
