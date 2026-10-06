class_name SaveRepositoryResult
extends RefCounted

enum Status { SAVED, LOADED_PRIMARY, RECOVERED_BACKUP, NOT_FOUND, INVALID_DATA, IO_ERROR }

var status: Status
var snapshot: Dictionary
var errors: PackedStringArray


func _init(p_status: Status, p_snapshot: Dictionary = {}, p_errors: PackedStringArray = PackedStringArray()) -> void:
	status = p_status
	snapshot = p_snapshot.duplicate(true)
	errors = p_errors.duplicate()


func is_success() -> bool:
	return status == Status.SAVED or status == Status.LOADED_PRIMARY or status == Status.RECOVERED_BACKUP
