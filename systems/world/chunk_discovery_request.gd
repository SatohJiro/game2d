class_name ChunkDiscoveryRequest
extends RefCounted

var chunk_key: StringName
var observed_revision: int


func _init(p_chunk_key: StringName, p_observed_revision: int) -> void:
	chunk_key = p_chunk_key
	observed_revision = p_observed_revision
