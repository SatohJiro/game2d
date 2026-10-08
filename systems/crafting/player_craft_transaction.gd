class_name PlayerCraftTransaction
extends RefCounted


static func commit(legacy_inventory: Dictionary, result: PlayerCraftResult) -> bool:
	if result == null or not result.is_accepted() or not result.definition.is_valid(): return false
	var shadow := legacy_inventory.duplicate(true)
	var transaction := InventoryTransaction.new(shadow)
	var inputs := result.definition.input_amounts()
	var item_ids: Array[StringName] = []
	for raw_id in inputs: item_ids.append(StringName(raw_id))
	item_ids.sort()
	for item_id in item_ids:
		if not transaction.remove(item_id, int(inputs[item_id])).is_success(): return false
	if result.definition.result_kind == PlayerCraftDefinition.RESULT_ITEM:
		if not transaction.add(result.definition.result_id, result.definition.result_amount).is_success(): return false
	legacy_inventory.clear()
	legacy_inventory.merge(shadow, true)
	return true
