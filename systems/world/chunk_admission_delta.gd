class_name ChunkAdmissionDelta
extends RefCounted

enum Status { CHANGED, NO_CHANGE, STALE, INVALID }

var status: Status
var center: Vector2i
var admitted_keys: Array[StringName]
var unloaded_keys: Array[StringName]
var next_active_keys: Array[StringName]
var from_revision: int
var to_revision: int


func _init(
	p_status: Status,
	p_center: Vector2i,
	p_admitted_keys: Array[StringName] = [],
	p_unloaded_keys: Array[StringName] = [],
	p_next_active_keys: Array[StringName] = [],
	p_from_revision: int = 0,
	p_to_revision: int = 0
) -> void:
	status = p_status
	center = p_center
	admitted_keys = p_admitted_keys.duplicate()
	unloaded_keys = p_unloaded_keys.duplicate()
	next_active_keys = p_next_active_keys.duplicate()
	from_revision = p_from_revision
	to_revision = p_to_revision


func is_changed() -> bool:
	return status == Status.CHANGED
