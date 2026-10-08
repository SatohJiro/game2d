class_name ChunkPlaceholder
extends Node2D

var chunk_key: StringName
var coordinate: Vector2i
var admitted_revision: int

func configure(p_chunk_key: StringName, p_coordinate: Vector2i, p_revision: int) -> bool:
	var parsed: Array[Vector2i] = []
	if not ChunkCoordinate.try_parse_key(p_chunk_key, parsed) or parsed[0] != p_coordinate or p_revision <= 0:
		return false
	chunk_key = p_chunk_key
	coordinate = p_coordinate
	admitted_revision = p_revision
	name = "Chunk_%s" % String(chunk_key).replace(".", "_")
	position = ChunkCoordinate.world_origin(coordinate)
	set_meta("chunk_key", chunk_key)
	queue_redraw()
	return true

func _draw() -> void:
	if chunk_key.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO, Vector2(ChunkCoordinate.CHUNK_SIZE)), Color(0.2, 0.8, 1.0, 0.12), false, 2.0)
