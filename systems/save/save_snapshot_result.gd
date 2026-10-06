class_name SaveSnapshotResult
extends RefCounted

enum Status { ACCEPTED, INVALID_SOURCE, UNMAPPED_ITEM, INVALID_SNAPSHOT }

var status: Status
var snapshot: Dictionary
var errors: PackedStringArray


func _init(p_status: Status, p_snapshot: Dictionary = {}, p_errors: PackedStringArray = PackedStringArray()) -> void:
	status = p_status
	snapshot = p_snapshot.duplicate(true)
	errors = p_errors.duplicate()


func is_accepted() -> bool:
	return status == Status.ACCEPTED
