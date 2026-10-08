class_name ChunkDiscoveryResult
extends RefCounted

enum Status { DISCOVERED, NO_CHANGE, STALE, INVALID }

var status: Status
var chunk_key: StringName
var revision: int


func _init(p_status: Status, p_chunk_key: StringName, p_revision: int) -> void:
	status = p_status
	chunk_key = p_chunk_key
	revision = p_revision


func is_success() -> bool:
	return status == Status.DISCOVERED or status == Status.NO_CHANGE
