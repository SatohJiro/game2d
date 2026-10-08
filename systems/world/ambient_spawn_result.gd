class_name AmbientSpawnResult
extends RefCounted

enum Status { APPLIED, NO_CHANGE, STALE, INVALID }

var status: Status
var admitted: Array[AmbientSpawnSpec]
var unloaded_ids: Array[StringName]
var next_ids: Array[StringName]
var chunk_revision: int


func _init(p_status: Status, p_admitted: Array[AmbientSpawnSpec] = [], p_unloaded_ids: Array[StringName] = [], p_next_ids: Array[StringName] = [], p_chunk_revision: int = 0) -> void:
	status = p_status
	admitted = p_admitted.duplicate()
	unloaded_ids = p_unloaded_ids.duplicate()
	next_ids = p_next_ids.duplicate()
	chunk_revision = p_chunk_revision


func is_success() -> bool:
	return status == Status.APPLIED or status == Status.NO_CHANGE
