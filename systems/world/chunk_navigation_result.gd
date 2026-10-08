class_name ChunkNavigationResult
extends RefCounted

enum Status { APPLIED, NO_CHANGE, STALE, INVALID }

var status: Status
var revision: int
var active_count: int


func _init(p_status: Status, p_revision: int, p_active_count: int) -> void:
	status = p_status
	revision = p_revision
	active_count = p_active_count


func is_success() -> bool:
	return status == Status.APPLIED or status == Status.NO_CHANGE
