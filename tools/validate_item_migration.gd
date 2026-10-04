extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const DROPPED_ITEM_SCENE_PATH := "res://scenes/dropped_item.tscn"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_legacy_adapter()
	_test_dropped_item_resolution()
	await _test_live_player_inventory_boundary()
	await _clean_tree()

	if _failures.is_empty():
		print("Item migration validation passed: item.wood pickup/inventory compatibility is valid.")
		_finish.call_deferred(0)
	else:
		for failure in _failures:
			printerr("ITEM MIGRATION FAILURE: %s" % failure)
		_finish.call_deferred(1)


func _test_legacy_adapter() -> void:
	var inventory := {"Gỗ": 2}
	_expect(LegacyItemAdapter.to_content_id("Gỗ") == &"item.wood", "legacy wood mapping failed")
	_expect(LegacyItemAdapter.to_legacy_key(&"item.wood") == "Gỗ", "stable wood reverse mapping failed")
	_expect(LegacyItemAdapter.get_count(inventory, &"item.wood") == 2, "stable read from legacy inventory failed")
	_expect(LegacyItemAdapter.add(inventory, &"item.wood", 3), "stable add should succeed")
	_expect(inventory["Gỗ"] == 5, "stable add must update the single legacy source of truth")
	_expect(not inventory.has("item.wood"), "adapter must not create a parallel stable-key entry")
	_expect(not LegacyItemAdapter.add(inventory, &"item.wood", 0), "zero add must be rejected")
	_expect(not LegacyItemAdapter.add(inventory, &"item.unknown", 1), "unmapped stable ID must be rejected")


func _test_dropped_item_resolution() -> void:
	var packed_drop: PackedScene = load(DROPPED_ITEM_SCENE_PATH) as PackedScene
	if packed_drop == null:
		_failures.append("unable to load dropped item scene")
		return
	var drop: Node = packed_drop.instantiate()
	drop.set("item_name", "Gỗ")
	_expect(drop.call("get_resolved_item_id") == &"item.wood", "legacy wood drop should resolve to stable ID")
	drop.set("item_name", "Đá")
	drop.set("item_id", &"")
	_expect(StringName(drop.call("get_resolved_item_id")).is_empty(), "unmigrated stone drop must stay on legacy fallback")
	drop.set("item_id", &"item.wood")
	_expect(drop.call("get_resolved_item_id") == &"item.wood", "explicit stable drop ID should win")
	drop.free()
	drop = null
	packed_drop = null


func _test_live_player_inventory_boundary() -> void:
	var packed_main: PackedScene = load(MAIN_SCENE_PATH) as PackedScene
	if packed_main == null:
		_failures.append("unable to load main scene")
		return
	var main_scene: Node = packed_main.instantiate()
	root.add_child(main_scene)
	for frame in range(5):
		await process_frame

	var player: Node = get_first_node_in_group("player")
	if player == null:
		_failures.append("main scene did not register a player")
		return
	var player_parent := player.get_parent()
	player_parent.remove_child(player)
	player.set("base_manager_ref", null)

	var inventory: Dictionary = player.get("inventory")
	var initial_count := int(player.call("get_item_count_by_id", &"item.wood"))
	_expect(bool(player.call("add_item_by_id", &"item.wood", 4)), "Player stable add failed")
	_expect(int(player.call("get_item_count_by_id", &"item.wood")) == initial_count + 4, "Player stable count mismatch")
	_expect(int(inventory.get("Gỗ", 0)) == initial_count + 4, "legacy consumers must see stable add")
	_expect(not inventory.has("item.wood"), "Player must retain one inventory source of truth")
	_expect(bool(player.call("add_item", "Gỗ", 2)), "legacy Player add should remain compatible")
	_expect(int(player.call("get_item_count_by_id", &"item.wood")) == initial_count + 6, "legacy add must be visible by stable read")
	_expect(not bool(player.call("add_item_by_id", &"item.unknown", 1)), "unknown stable item should fail closed")
	player.free()
	player = null
	main_scene = null
	packed_main = null


func _clean_tree() -> void:
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(exit_code: int) -> void:
	quit(exit_code)
