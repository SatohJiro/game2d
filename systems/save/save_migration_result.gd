class_name SaveMigrationResult
extends RefCounted

enum Status { CURRENT, MIGRATED, INVALID_INPUT, FUTURE_VERSION, MISSING_STEP, CYCLE, INVALID_OUTPUT, INVALID_REGISTRY }

var status: Status
var snapshot: Dictionary
var applied_versions: PackedInt32Array
var errors: PackedStringArray


func _init(
	p_status: Status,
	p_snapshot: Dictionary = {},
	p_applied_versions: PackedInt32Array = PackedInt32Array(),
	p_errors: PackedStringArray = PackedStringArray()
) -> void:
	status = p_status
	snapshot = p_snapshot.duplicate(true)
	applied_versions = p_applied_versions.duplicate()
	errors = p_errors.duplicate()


func is_success() -> bool:
	return status == Status.CURRENT or status == Status.MIGRATED
