class_name InventoryTransactionResult
extends RefCounted

enum Status {
	OK,
	INVALID_ITEM,
	INVALID_AMOUNT,
	INSUFFICIENT_ITEMS,
	CAPACITY_EXCEEDED,
}

var status: Status
var item_id: StringName
var requested_amount: int
var applied_amount: int


func _init(
	result_status: Status,
	result_item_id: StringName,
	result_requested_amount: int,
	result_applied_amount: int = 0
) -> void:
	status = result_status
	item_id = result_item_id
	requested_amount = result_requested_amount
	applied_amount = result_applied_amount


func is_success() -> bool:
	return status == Status.OK
