class_name InventoryTransaction
extends RefCounted

enum CapacityPolicy {
	UNLIMITED,
	STACK_SLOTS,
}

var _backing_store: Dictionary
var _capacity_policy: CapacityPolicy
var _max_slots: int
var _max_stack_by_item: Dictionary


func _init(
	backing_store: Dictionary,
	capacity_policy: CapacityPolicy = CapacityPolicy.UNLIMITED,
	max_slots: int = 0,
	max_stack_by_item: Dictionary = {}
) -> void:
	_backing_store = backing_store
	_capacity_policy = capacity_policy
	_max_slots = max_slots
	_max_stack_by_item = max_stack_by_item


func get_count(item_id: StringName) -> int:
	return LegacyItemAdapter.get_count(_backing_store, item_id)


func can_add(item_id: StringName, amount: int) -> InventoryTransactionResult:
	var input_error := _validate_input(item_id, amount)
	if input_error != null:
		return input_error
	if _capacity_policy == CapacityPolicy.STACK_SLOTS:
		if _get_max_stack(item_id) <= 0:
			return InventoryTransactionResult.new(
				InventoryTransactionResult.Status.MISSING_DEFINITION,
				item_id,
				amount
			)
		var used_after_add := _calculate_used_slots(item_id, get_count(item_id) + amount)
		if used_after_add < 0:
			return InventoryTransactionResult.new(
				InventoryTransactionResult.Status.MISSING_DEFINITION,
				item_id,
				amount
			)
		if _max_slots <= 0 or used_after_add > _max_slots:
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


func transfer_batch_to(target: InventoryTransaction, amounts: Dictionary) -> InventoryTransactionResult:
	if target == null or amounts.is_empty():
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INVALID_AMOUNT,
			&"",
			0
		)
	var item_ids: Array[StringName] = []
	for raw_item_id in amounts.keys():
		item_ids.append(StringName(raw_item_id))
	item_ids.sort()

	var source_shadow_store := _backing_store.duplicate(true)
	var target_shadow_store := target._backing_store.duplicate(true)
	var source_shadow := InventoryTransaction.new(
		source_shadow_store, _capacity_policy, _max_slots, _max_stack_by_item
	)
	var target_shadow := InventoryTransaction.new(
		target_shadow_store, target._capacity_policy, target._max_slots, target._max_stack_by_item
	)
	var requested_total := 0
	for item_id in item_ids:
		var amount := int(amounts[item_id])
		requested_total += amount
		var preview := source_shadow.transfer_to(target_shadow, item_id, amount)
		if not preview.is_success():
			return preview

	var source_before := _backing_store.duplicate(true)
	var target_before := target._backing_store.duplicate(true)
	for item_id in item_ids:
		if not LegacyItemAdapter.set_count(_backing_store, item_id, LegacyItemAdapter.get_count(source_shadow_store, item_id)):
			_restore_store(_backing_store, source_before)
			_restore_store(target._backing_store, target_before)
			return InventoryTransactionResult.new(InventoryTransactionResult.Status.INVALID_ITEM, item_id, int(amounts[item_id]))
		if not LegacyItemAdapter.set_count(target._backing_store, item_id, LegacyItemAdapter.get_count(target_shadow_store, item_id)):
			_restore_store(_backing_store, source_before)
			_restore_store(target._backing_store, target_before)
			return InventoryTransactionResult.new(InventoryTransactionResult.Status.INVALID_ITEM, item_id, int(amounts[item_id]))
	return InventoryTransactionResult.new(InventoryTransactionResult.Status.OK, &"", requested_total, requested_total)


func get_capacity_policy() -> CapacityPolicy:
	return _capacity_policy


func get_used_slots() -> int:
	if _capacity_policy == CapacityPolicy.UNLIMITED:
		return 0
	return _calculate_used_slots(&"", -1)


func get_max_slots() -> int:
	return _max_slots


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


func _calculate_used_slots(override_item_id: StringName, override_count: int) -> int:
	var used_slots := 0
	for raw_item_id in LegacyItemAdapter.CONTENT_ID_TO_LEGACY.keys():
		var item_id := raw_item_id as StringName
		var count := override_count if item_id == override_item_id else get_count(item_id)
		if count <= 0:
			continue
		var max_stack := _get_max_stack(item_id)
		if max_stack <= 0:
			return -1
		used_slots += ceili(float(count) / float(max_stack))
	return used_slots


func _get_max_stack(item_id: StringName) -> int:
	return int(_max_stack_by_item.get(item_id, 0))


func _restore_store(store: Dictionary, snapshot: Dictionary) -> void:
	store.clear()
	store.merge(snapshot, true)
