class_name WorldChunkContext
extends RefCounted

var coordinate: Vector2i
var chunk_key: StringName
var definition_id: StringName
var biome_id: StringName


func _init(p_coordinate: Vector2i, p_definition_id: StringName, p_biome_id: StringName) -> void:
	coordinate = p_coordinate
	chunk_key = ChunkCoordinate.to_key(coordinate)
	definition_id = p_definition_id
	biome_id = p_biome_id


func is_valid() -> bool:
	return (
		ContentId.domain_of(chunk_key) == &"chunk"
		and ContentId.domain_of(definition_id) == &"chunk"
		and ContentId.domain_of(biome_id) == &"biome"
	)
