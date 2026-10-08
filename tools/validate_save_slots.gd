extends SceneTree

const TEST_DIR := "user://save_slot_test_u33"

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIR + "/autosave.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIR + "/autosave.json.bak"))
	_test_slot_manager_pure()
	await _test_slot_roundtrip()
	await _test_autosave()
	await _test_panel()
	if _failures.is_empty():
		print("Save slot validation passed: multi-slot save/load/delete, autosave policy and slot panel intents are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _test_slot_manager_pure() -> void:
	_expect(SaveSlotManager.is_valid_slot_id(&"slot_1"), "slot_1 must be valid")
	_expect(SaveSlotManager.is_valid_slot_id(&"slot_3"), "slot_3 must be valid")
	_expect(SaveSlotManager.is_valid_slot_id(&"autosave"), "autosave must be valid")
	_expect(not SaveSlotManager.is_valid_slot_id(&"bogus"), "unknown ids must be rejected")
	_expect(String(SaveSlotManager.save_id_for_slot(&"slot_2")) == "save.slot_2", "save id must derive from the slot")
	_expect(String(SaveSlotManager.save_id_for_slot(&"autosave")) == "save.autosave", "autosave save id must derive from the slot")
	var manager = SaveSlotManager.new(TEST_DIR)
	_expect(manager.primary_path_for(&"slot_3") == TEST_DIR + "/slot_3.json", "slot path must live in the base directory")
	_expect(manager.delete_slot(&"slot_1") == false, "deleting an empty slot must report false")
	_expect(manager.delete_slot(&"bogus") == false, "deleting an unknown slot must report false")
	var slots = manager.list_slots()
	_expect(slots.size() == 4, "slot list must cover 3 manual slots plus autosave")
	_expect(slots.all(func(slot: Dictionary) -> bool: return not bool(slot.get("exists", true))), "fresh directory must report no saves")


func _make_main() -> Node2D:
	var packed = load("res://scenes/main.tscn") as PackedScene
	var main = packed.instantiate()
	main.save_slot_manager = SaveSlotManager.new(TEST_DIR)
	root.add_child(main)
	await process_frame
	main.set_process(false)
	return main


func _test_slot_roundtrip() -> void:
	var main = await _make_main()
	var player: Node2D = main.get("player")
	(player.get("inventory") as Dictionary)["Gỗ"] = 7
	var saved = main.save_game_to_slot(&"slot_2", 1700000000)
	_expect(saved.is_success(), "saving to slot_2 must succeed")
	_expect(String(main.get("current_save_slot")) == "slot_2", "saving must track the current slot")
	var slots = main.list_save_slots()
	var slot_2 = slots.filter(func(slot: Dictionary) -> bool: return String(slot.get("slot_id", "")) == "slot_2")[0]
	_expect(bool(slot_2["exists"]), "slot_2 must be listed as existing")
	_expect(int(slot_2["saved_at_unix"]) == 1700000000, "slot metadata must carry the saved timestamp")
	_expect(int(slot_2["player_level"]) >= 1, "slot metadata must carry the player level")
	var slot_1 = slots.filter(func(slot: Dictionary) -> bool: return String(slot.get("slot_id", "")) == "slot_1")[0]
	_expect(not bool(slot_1["exists"]), "untouched slots must stay empty")
	(player.get("inventory") as Dictionary)["Gỗ"] = 0
	var loaded = main.load_game_from_slot(&"slot_2")
	_expect(loaded.is_loaded(), "loading slot_2 must succeed")
	_expect(int((player.get("inventory") as Dictionary).get("Gỗ", -1)) == 7, "loading must restore the slot snapshot")
	var bad_save = main.save_game_to_slot(&"bogus", 1)
	_expect(bad_save.status == SaveCoordinatorResult.Status.SNAPSHOT_FAILED, "invalid slot save must fail closed")
	var bad_load = main.load_game_from_slot(&"bogus")
	_expect(bad_load.status == SaveCoordinatorResult.Status.REPOSITORY_FAILED, "invalid slot load must fail closed")
	_expect(main.delete_save_slot(&"slot_2"), "deleting an existing slot must report true")
	_expect(not bool(main.list_save_slots()[1]["exists"]), "deleted slot must disappear from the list")
	_expect(not main.delete_save_slot(&"slot_2"), "deleting twice must report false")
	main.queue_free()
	await process_frame


func _test_autosave() -> void:
	var main = await _make_main()
	_expect(main.get("autosave_enabled") == false, "autosave must be off by default")
	main.set_autosave_enabled(true)
	_expect(main.get("autosave_enabled") == true, "autosave toggle must take effect")
	_expect(not main.try_autosave_tick(1.0), "autosave must wait for its interval")
	_expect(not bool(main.list_save_slots()[3]["exists"]), "no autosave file before the interval")
	main.set("autosave_interval", 0.5)
	_expect(main.try_autosave_tick(0.6), "autosave must fire once the interval elapses")
	_expect(bool(main.list_save_slots()[3]["exists"]), "autosave must write its own slot")
	_expect(String(main.get("current_save_slot")) != "autosave", "autosave must not hijack the current slot")
	_expect(float(main.get("_autosave_elapsed")) == 0.0, "autosave must reset its timer after saving")
	main.delete_save_slot(&"autosave")
	var hud: CanvasLayer = main.get("hud")
	hud.toggle_crafting(true)
	_expect(not main.is_autosave_safe(), "an open modal must block autosave")
	_expect(not main.try_autosave_tick(5.0), "autosave must stay blocked while a modal is open")
	_expect(not bool(main.list_save_slots()[3]["exists"]), "blocked autosave must not write")
	hud.toggle_crafting(false)
	main.set("night_raid_state", null)
	var raid = NightRaidState.new()
	raid.lifecycle_id = NightRaidState.ACTIVE
	main.set("night_raid_state", raid)
	_expect(not main.is_autosave_safe(), "an active night raid must block autosave")
	_expect(not main.try_autosave_tick(5.0), "autosave must stay blocked during a raid")
	main.set("autosave_enabled", false)
	_expect(not main.try_autosave_tick(99.0), "autosave must stop when disabled")
	main.queue_free()
	await process_frame


func _find_check_button(node: Node) -> CheckButton:
	if node is CheckButton:
		return node
	for child in node.get_children():
		var found := _find_check_button(child)
		if found != null:
			return found
	return null


func _find_button_text(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var found = _find_button_text(child, text)
		if found != null:
			return found
	return null


func _test_panel() -> void:
	var packed = load("res://scenes/save_slots.tscn") as PackedScene
	var panel = packed.instantiate()
	root.add_child(panel)
	await process_frame
	var loaded_ids: Array = []
	var saved_ids: Array = []
	var deleted_ids: Array = []
	var autosave_states: Array = []
	panel.load_requested.connect(func(slot_id: StringName) -> void: loaded_ids.append(slot_id))
	panel.save_requested.connect(func(slot_id: StringName) -> void: saved_ids.append(slot_id))
	panel.delete_requested.connect(func(slot_id: StringName) -> void: deleted_ids.append(slot_id))
	panel.autosave_toggled.connect(func(enabled: bool) -> void: autosave_states.append(enabled))
	var slot_list: Array[Dictionary] = [
		{"slot_id": "slot_1", "exists": true, "player_level": 4, "base_level": 2, "clock_seconds": 3600.0},
		{"slot_id": "slot_2", "exists": false},
	]
	panel.render_slots(slot_list, false, &"slot_1")
	_expect(panel.is_open() == false, "slot panel must start closed")
	panel.toggle()
	_expect(panel.is_open() and panel.visible, "toggle must open the slot panel")
	var load_button = _find_button_text(panel, "Tải")
	_expect(load_button != null, "existing slot must show a load button")
	load_button.pressed.emit()
	_expect(loaded_ids == [&"slot_1"], "load button must emit its slot intent")
	var save_button = _find_button_text(panel, "Lưu mới")
	_expect(save_button != null, "empty slot must show a new-save button")
	save_button.pressed.emit()
	_expect(saved_ids == [&"slot_2"], "save button must emit its slot intent")
	var delete_button = _find_button_text(panel, "Xóa")
	delete_button.pressed.emit()
	_expect(deleted_ids.is_empty(), "first delete press must arm the confirm, not emit")
	_expect(delete_button.text == "Nhấn lại để xóa", "armed delete must change its label")
	delete_button.pressed.emit()
	_expect(deleted_ids == [&"slot_1"], "second delete press must emit the delete intent")
	var autosave_check := _find_check_button(panel)
	_expect(autosave_check != null, "slot panel must show the autosave check")
	autosave_check.toggled.emit(true)
	_expect(autosave_states == [true], "autosave check must emit its toggle intent")
	panel.toggle()
	_expect(not panel.is_open(), "toggle must close the slot panel")
	panel.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
