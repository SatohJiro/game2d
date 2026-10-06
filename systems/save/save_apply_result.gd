class_name SaveApplyResult
extends RefCounted

enum Status { APPLIED, INVALID_TARGET, INVALID_SNAPSHOT, UNSUPPORTED_REFERENCE, COMMIT_FAILED }

var status: Status
var world_clock_seconds: float
var errors: PackedStringArray


func _init(p_status: Status, p_world_clock_seconds: float = 0.0, p_errors: PackedStringArray = PackedStringArray()) -> void:
	status = p_status
	world_clock_seconds = p_world_clock_seconds
	errors = p_errors.duplicate()


func is_applied() -> bool:
	return status == Status.APPLIED
