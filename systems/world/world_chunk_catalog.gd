class_name WorldChunkCatalog
extends RefCounted

const ORIGIN_CHUNK_ID := &"chunk.paloria_origin"
const DEFAULT_BIOME_ID := &"biome.paloria_meadow"
const ORIGIN_DEFINITION := preload("res://data/definitions/chunks/paloria_origin.tres")


static func resolve_world_position(world_position: Vector2) -> WorldChunkContext:
	if not world_position.is_finite():
		return null
	var coordinate := ChunkCoordinate.from_world_position(world_position)
	return WorldChunkContext.new(coordinate, ORIGIN_CHUNK_ID, DEFAULT_BIOME_ID)


static func get_origin_definition() -> ChunkDefinition:
	return ORIGIN_DEFINITION as ChunkDefinition
