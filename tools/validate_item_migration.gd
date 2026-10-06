extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const DROPPED_ITEM_SCENE_PATH := "res://scenes/dropped_item.tscn"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_legacy_adapter()
	_test_inventory_transactions()
	_test_finite_capacity_and_batch()
	_test_dropped_item_resolution()
	await _test_live_player_inventory_boundary()
	await _clean_tree()

	if _failures.is_empty():
		print("Item migration validation passed: U1.4b capacity, batch transfer and chest compatibility are valid.")
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
	_expect(LegacyItemAdapter.set_count(inventory, &"item.wood", 1), "mapped count set should succeed")
	_expect(inventory["Gỗ"] == 1, "count set must update the legacy source of truth")
	_expect(not LegacyItemAdapter.set_count(inventory, &"item.wood", -1), "negative count set must be rejected")
	var sphere_inventory := {"Cầu Thu Phục": 2, "Mega Sphere": 1, "Giga Sphere": 1}
	var sphere_transaction := InventoryTransaction.new(sphere_inventory)
	_expect(sphere_transaction.get_count(&"item.pal_sphere.basic") == 2, "basic sphere stable read mismatch")
	_expect(sphere_transaction.remove(&"item.pal_sphere.mega", 1).is_success(), "mega sphere stable remove failed")
	_expect(sphere_inventory["Mega Sphere"] == 0, "mega sphere remove must mutate legacy backing store")
	_expect(sphere_transaction.add(&"item.pal_sphere.giga", 1).is_success(), "giga sphere stable add failed")
	_expect(sphere_inventory["Giga Sphere"] == 2, "giga sphere add must mutate legacy backing store")


func _test_inventory_transactions() -> void:
	var source_store := {"Gỗ": 5}
	var target_store := {"Gỗ": 1}
	var source := InventoryTransaction.new(source_store)
	var target := InventoryTransaction.new(target_store)
	_expect(
		source.get_capacity_policy() == InventoryTransaction.CapacityPolicy.UNLIMITED,
		"U1.4a must expose the unlimited capacity policy explicitly"
	)

	var invalid_item := source.add(&"item.unknown", 2)
	_expect(invalid_item.status == InventoryTransactionResult.Status.INVALID_ITEM, "unknown item status mismatch")
	_expect(source_store["Gỗ"] == 5, "unknown add must not mutate source")
	var invalid_amount := source.remove(&"item.wood", 0)
	_expect(invalid_amount.status == InventoryTransactionResult.Status.INVALID_AMOUNT, "invalid amount status mismatch")
	_expect(source_store["Gỗ"] == 5, "invalid remove must not mutate source")
	var insufficient := source.remove(&"item.wood", 6)
	_expect(insufficient.status == InventoryTransactionResult.Status.INSUFFICIENT_ITEMS, "insufficient status mismatch")
	_expect(source_store["Gỗ"] == 5, "insufficient remove must not partially mutate")

	var removed := source.remove(&"item.wood", 2)
	_expect(removed.is_success() and removed.applied_amount == 2, "valid remove should apply requested amount")
	_expect(source_store["Gỗ"] == 3, "valid remove count mismatch")
	var total_before := int(source_store["Gỗ"]) + int(target_store["Gỗ"])
	var transferred := source.transfer_to(target, &"item.wood", 2)
	_expect(transferred.is_success(), "valid transfer should succeed")
	_expect(source_store["Gỗ"] == 1 and target_store["Gỗ"] == 3, "valid transfer counts mismatch")
	_expect(int(source_store["Gỗ"]) + int(target_store["Gỗ"]) == total_before, "transfer must conserve total count")

	var source_before_failure := int(source_store["Gỗ"])
	var target_before_failure := int(target_store["Gỗ"])
	var failed_transfer := source.transfer_to(target, &"item.wood", 5)
	_expect(failed_transfer.status == InventoryTransactionResult.Status.INSUFFICIENT_ITEMS, "failed transfer status mismatch")
	_expect(int(source_store["Gỗ"]) == source_before_failure, "failed transfer must preserve source")
	_expect(int(target_store["Gỗ"]) == target_before_failure, "failed transfer must preserve target")


func _test_finite_capacity_and_batch() -> void:
	var max_stacks := {&"item.wood": 5, &"item.pal_ore": 2, &"item.berry": 10}
	var finite_store := {"Gỗ": 5, "Quặng Pal": 2, "Quả Mọng Hồi Máu": 0}
	var finite := InventoryTransaction.new(
		finite_store, InventoryTransaction.CapacityPolicy.STACK_SLOTS, 3, max_stacks
	)
	_expect(finite.get_used_slots() == 2, "finite capacity initial slot count mismatch")
	_expect(finite.add(&"item.wood", 1).is_success(), "finite capacity should open a second wood stack")
	_expect(finite.get_used_slots() == 3, "finite capacity slot count after add mismatch")
	var full_result := finite.add(&"item.berry", 1)
	_expect(full_result.status == InventoryTransactionResult.Status.CAPACITY_EXCEEDED, "full inventory status mismatch")
	_expect(finite_store["Quả Mọng Hồi Máu"] == 0, "capacity failure must not mutate")

	var missing_definition := InventoryTransaction.new(
		{"Gỗ": 0, "Quặng Pal": 0},
		InventoryTransaction.CapacityPolicy.STACK_SLOTS,
		2,
		{&"item.wood": 5}
	).add(&"item.pal_ore", 1)
	_expect(missing_definition.status == InventoryTransactionResult.Status.MISSING_DEFINITION, "missing max-stack definition must fail closed")

	var source_store := {"Gỗ": 2, "Quặng Pal": 2, "Quả Mọng Hồi Máu": 0}
	var target_store := {"Gỗ": 4, "Quặng Pal": 0, "Quả Mọng Hồi Máu": 0}
	var source := InventoryTransaction.new(source_store)
	var target := InventoryTransaction.new(target_store, InventoryTransaction.CapacityPolicy.STACK_SLOTS, 2, max_stacks)
	var failed_batch := source.transfer_batch_to(target, {&"item.wood": 2, &"item.pal_ore": 2})
	_expect(failed_batch.status == InventoryTransactionResult.Status.CAPACITY_EXCEEDED, "batch capacity failure status mismatch")
	_expect(source_store["Gỗ"] == 2 and source_store["Quặng Pal"] == 2, "failed batch must preserve source")
	_expect(target_store["Gỗ"] == 4 and target_store["Quặng Pal"] == 0, "failed batch must preserve target")

	var roomy_target := InventoryTransaction.new(target_store, InventoryTransaction.CapacityPolicy.STACK_SLOTS, 3, max_stacks)
	var successful_batch := source.transfer_batch_to(roomy_target, {&"item.wood": 2, &"item.pal_ore": 2})
	_expect(successful_batch.is_success() and successful_batch.applied_amount == 4, "valid batch should commit all items")
	_expect(source_store["Gỗ"] == 0 and source_store["Quặng Pal"] == 0, "successful batch source mismatch")
	_expect(target_store["Gỗ"] == 6 and target_store["Quặng Pal"] == 2, "successful batch target mismatch")


func _test_dropped_item_resolution() -> void:
	var packed_drop: PackedScene = load(DROPPED_ITEM_SCENE_PATH) as PackedScene
	if packed_drop == null:
		_failures.append("unable to load dropped item scene")
		return
	var drop: Node = packed_drop.instantiate()
	drop.set("item_name", "Gỗ")
	_expect(drop.call("get_resolved_item_id") == &"item.wood", "legacy wood drop should resolve to stable ID")
	drop.set("item_name", "Chưa Có Mapping")
	drop.set("item_id", &"")
	_expect(StringName(drop.call("get_resolved_item_id")).is_empty(), "unmapped drop must stay on legacy fallback")
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
	_test_chest_transfer_boundary()
	await _test_rejected_drop_stays_in_world(main_scene, player)
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
	_expect(bool(player.call("remove_item_by_id", &"item.wood", 3)), "Player stable remove failed")
	_expect(int(player.call("get_item_count_by_id", &"item.wood")) == initial_count + 3, "Player stable remove count mismatch")
	_expect(not bool(player.call("remove_item_by_id", &"item.wood", initial_count + 4)), "Player insufficient remove should fail")
	_expect(int(player.call("get_item_count_by_id", &"item.wood")) == initial_count + 3, "failed Player remove must not mutate")
	_expect(not bool(player.call("add_item_by_id", &"item.unknown", 1)), "unknown stable item should fail closed")
	player.free()
	player = null
	main_scene = null
	packed_main = null


func _test_chest_transfer_boundary() -> void:
	var packed_chest := load("res://scenes/building_chest.tscn") as PackedScene
	if packed_chest == null:
		_failures.append("unable to load chest scene")
		return
	var chest := packed_chest.instantiate()
	chest.set("inventory_slots", 3)
	var source := {"Gỗ": 2, "Quặng Pal": 1, "Quả Mọng Hồi Máu": 1, "Chưa Có Mapping": 5}
	var deposit: InventoryTransactionResult = chest.call("deposit_mapped_from", source)
	_expect(deposit.is_success() and deposit.applied_amount == 4, "chest mapped deposit should commit atomically")
	_expect(source["Gỗ"] == 0 and source["Quặng Pal"] == 0 and source["Quả Mọng Hồi Máu"] == 0, "chest deposit source mismatch")
	_expect(source["Chưa Có Mapping"] == 5, "chest transaction must not touch an unmapped item")
	var stored: Dictionary = chest.get("stored_items")
	_expect(stored["Gỗ"] == 2 and stored["Quặng Pal"] == 1 and stored["Quả Mọng Hồi Máu"] == 1, "chest deposit target mismatch")

	var withdrawal_target := {"Gỗ": 0, "Quặng Pal": 0, "Quả Mọng Hồi Máu": 0}
	var withdrawal: InventoryTransactionResult = chest.call("withdraw_mapped_to", withdrawal_target, 1)
	_expect(withdrawal.is_success() and withdrawal.applied_amount == 3, "chest withdrawal should transfer capped batch")
	_expect(withdrawal_target["Gỗ"] == 1 and withdrawal_target["Quặng Pal"] == 1 and withdrawal_target["Quả Mọng Hồi Máu"] == 1, "chest withdrawal target mismatch")
	chest.free()


func _test_rejected_drop_stays_in_world(main_scene: Node, player: Node) -> void:
	var packed_drop := load(DROPPED_ITEM_SCENE_PATH) as PackedScene
	if packed_drop == null:
		_failures.append("unable to load rejected dropped item scene")
		return
	var drop := packed_drop.instantiate()
	drop.set("item_name", "Unknown")
	drop.set("item_id", &"item.unknown")
	main_scene.add_child(drop)
	await process_frame
	drop.set("target_player", player)
	drop.call("collect")
	_expect(is_instance_valid(drop) and not drop.is_queued_for_deletion(), "rejected pickup must stay in world")
	main_scene.remove_child(drop)
	drop.free()


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
