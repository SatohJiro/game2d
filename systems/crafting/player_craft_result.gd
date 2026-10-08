class_name PlayerCraftResult
extends RefCounted

enum Status { ACCEPTED, UNKNOWN_RECIPE, LOCKED, INSUFFICIENT_ITEMS, INVALID_DEFINITION }

var status: Status
var definition: PlayerCraftDefinition
var missing_item_id: StringName


func _init(result_status: Status, result_definition: PlayerCraftDefinition = null, result_missing_item_id: StringName = &"") -> void:
	status = result_status
	definition = result_definition
	missing_item_id = result_missing_item_id


func is_accepted() -> bool:
	return status == Status.ACCEPTED and definition != null
