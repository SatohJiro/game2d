class_name AmbientSpawnRequest
extends RefCounted

var center: Vector2i
var active_keys: Array[StringName]
var existing_chunks: Dictionary
var blocked_instance_ids: Array[StringName]
var biome_id: StringName
var time_bucket: int
var budget: int
var seed: int
var chunk_revision: int


func _init(p_center: Vector2i, p_active_keys: Array[StringName], p_existing_chunks: Dictionary, p_blocked_instance_ids: Array[StringName], p_biome_id: StringName, p_time_bucket: int, p_budget: int, p_seed: int, p_chunk_revision: int) -> void:
	center = p_center
	active_keys = p_active_keys.duplicate()
	existing_chunks = p_existing_chunks.duplicate()
	blocked_instance_ids = p_blocked_instance_ids.duplicate()
	biome_id = p_biome_id
	time_bucket = p_time_bucket
	budget = p_budget
	seed = p_seed
	chunk_revision = p_chunk_revision
