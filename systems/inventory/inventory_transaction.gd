class_name InventoryTransaction
extends RefCounted

enum CapacityPolicy {
	UNLIMITED,
}

var _backing_store: Dictionary
var _capacity_policy: CapacityPolicy


func _init(
	backing_store: Dictionary,
	capacity_policy: CapacityPolicy = CapacityPolicy.UNLIMITED
) -> void:
	_backing_store = backing_store
	_capacity_policy = capacity_policy


func get_count(item_id: StringName) -> int:
	return LegacyItemAdapter.get_count(_backing_store, item_id)


func can_add(item_id: StringName, amount: int) -> InventoryTransactionResult:
	var input_error := _validate_input(item_id, amount)
	if input_error != null:
		return input_error
	if _capacity_policy != CapacityPolicy.UNLIMITED:
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.CAPACITY_EXCEEDED,
			item_id,
			amount
		)
	return InventoryTransactionResult.new(
		InventoryTransactionResult.Status.OK,
		item_id,
		amount,
		amount
	)


func add(item_id: StringName, amount: int) -> InventoryTransactionResult:
	var result := can_add(item_id, amount)
	if not result.is_success():
		return result
	LegacyItemAdapter.set_count(_backing_store, item_id, get_count(item_id) + amount)
	return result


func can_remove(item_id: StringName, amount: int) -> InventoryTransactionResult:
	var input_error := _validate_input(item_id, amount)
	if input_error != null:
		return input_error
	if get_count(item_id) < amount:
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INSUFFICIENT_ITEMS,
			item_id,
			amount
		)
	return InventoryTransactionResult.new(
		InventoryTransactionResult.Status.OK,
		item_id,
		amount,
		amount
	)


func remove(item_id: StringName, amount: int) -> InventoryTransactionResult:
	var result := can_remove(item_id, amount)
	if not result.is_success():
		return result
	LegacyItemAdapter.set_count(_backing_store, item_id, get_count(item_id) - amount)
	return result


func transfer_to(
	target: InventoryTransaction,
	item_id: StringName,
	amount: int
) -> InventoryTransactionResult:
	var source_check := can_remove(item_id, amount)
	if not source_check.is_success():
		return source_check
	if target == null:
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INVALID_ITEM,
			item_id,
			amount
		)
	var target_check := target.can_add(item_id, amount)
	if not target_check.is_success():
		return target_check

	var source_before := get_count(item_id)
	var target_before := target.get_count(item_id)
	if not LegacyItemAdapter.set_count(_backing_store, item_id, source_before - amount):
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INVALID_ITEM,
			item_id,
			amount
		)
	if not LegacyItemAdapter.set_count(target._backing_store, item_id, target_before + amount):
		LegacyItemAdapter.set_count(_backing_store, item_id, source_before)
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INVALID_ITEM,
			item_id,
			amount
		)
	return InventoryTransactionResult.new(
		InventoryTransactionResult.Status.OK,
		item_id,
		amount,
		amount
	)


func get_capacity_policy() -> CapacityPolicy:
	return _capacity_policy


func _validate_input(item_id: StringName, amount: int) -> InventoryTransactionResult:
	if not ContentId.is_valid(item_id) or not LegacyItemAdapter.is_mapped(item_id):
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INVALID_ITEM,
			item_id,
			amount
		)
	if amount <= 0:
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INVALID_AMOUNT,
			item_id,
			amount
		)
	return null
