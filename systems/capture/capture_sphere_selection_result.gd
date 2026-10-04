class_name CaptureSphereSelectionResult
extends RefCounted

enum Status { OK, NONE_AVAILABLE }

var status: Status
var item_id: StringName
var catch_multiplier: float


func _init(result_status: Status, result_item_id: StringName = &"", result_multiplier: float = 0.0) -> void:
	status = result_status
	item_id = result_item_id
	catch_multiplier = result_multiplier


func is_selected() -> bool:
	return status == Status.OK
