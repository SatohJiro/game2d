class_name SaveValidationResult
extends RefCounted

enum Status { VALID, INVALID }

var status: Status
var errors: PackedStringArray


func _init(p_status: Status, p_errors: PackedStringArray = PackedStringArray()) -> void:
	status = p_status
	errors = p_errors.duplicate()


func is_valid() -> bool:
	return status == Status.VALID
