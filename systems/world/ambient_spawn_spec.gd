class_name AmbientSpawnSpec
extends RefCounted

var instance_id: StringName
var chunk_key: StringName
var species_id: StringName
var position: Vector2
var level: int


func _init(p_instance_id: StringName, p_chunk_key: StringName, p_species_id: StringName, p_position: Vector2, p_level: int) -> void:
	instance_id = p_instance_id
	chunk_key = p_chunk_key
	species_id = p_species_id
	position = p_position
	level = p_level


func is_valid() -> bool:
	var parsed: Array[Vector2i] = []
	return ContentId.is_valid(instance_id) \
		and ChunkCoordinate.try_parse_key(chunk_key, parsed) \
		and LegacySpeciesAdapter.is_supported(species_id) \
		and species_id != LegacySpeciesAdapter.DRAGON_ID \
		and position.is_finite() \
		and ChunkCoordinate.from_world_position(position) == parsed[0] \
		and level >= 1 and level <= 5


func to_debug_dto() -> Dictionary:
	return {"instance_id": String(instance_id), "chunk_key": String(chunk_key), "species_id": String(species_id), "position": position, "level": level}
