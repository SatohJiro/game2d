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
	if not load_static_content():
		return false
	queue_redraw()
	return true


func load_static_content() -> bool:
	var manifest := StaticContentCatalog.manifest_for_chunk(coordinate)
	if not manifest.is_valid():
		return false
	for placement in manifest.placements:
		var decoration := Sprite2D.new()
		decoration.name = String(placement.get("content_id", "decoration"))
		decoration.texture = StaticContentCatalog.texture_for_kind(String(placement.get("kind", "")))
		if decoration.texture == null:
			decoration.free()
			return false
		decoration.position = placement.get("local_position", Vector2.ZERO)
		decoration.scale = Vector2.ONE * float(placement.get("scale", 1.0))
		decoration.set_meta("static_content_id", StringName(placement.get("content_id", "")))
		decoration.add_to_group("chunk_static_decor")
		add_child(decoration)
	return true


func get_static_decoration_count() -> int:
	var count := 0
	for child in get_children():
		if child is Sprite2D and child.is_in_group("chunk_static_decor"):
			count += 1
	return count

func _draw() -> void:
	if chunk_key.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO, Vector2(ChunkCoordinate.CHUNK_SIZE)), Color(0.2, 0.8, 1.0, 0.12), false, 2.0)
