class_name ChunkActiveRecord
extends RefCounted

var coordinate: Vector2i
var chunk_key: StringName
var admitted_revision: int


func _init(p_coordinate: Vector2i, p_admitted_revision: int) -> void:
	coordinate = p_coordinate
	chunk_key = ChunkCoordinate.to_key(coordinate)
	admitted_revision = p_admitted_revision


func to_debug_dto() -> Dictionary:
	return {
		"chunk_key": String(chunk_key),
		"coordinate": [coordinate.x, coordinate.y],
		"admitted_revision": admitted_revision,
	}
