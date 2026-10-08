class_name StaticContentManifest
extends RefCounted

## Per-chunk authored static decoration manifest (U2.9, data only).
##
## Lists deterministic decoration placements for one chunk. Each placement is
## a Dictionary: {"content_id": String, "kind": String, "local_position": Vector2,
## "scale": float}. Content IDs are stable (static.<chunk>_<kind>_<index>);
## positions are local to the chunk origin and always inside chunk bounds.
## Manifests are produced by StaticContentCatalog; ChunkPlaceholder spawns
## them as children so chunk unload frees every decoration (no leaks).

var chunk_key: StringName
var coordinate: Vector2i
var placements: Array[Dictionary]


func _init(p_chunk_key: StringName, p_coordinate: Vector2i, p_placements: Array[Dictionary] = []) -> void:
	chunk_key = p_chunk_key
	coordinate = p_coordinate
	placements = p_placements.duplicate(true)


func is_valid() -> bool:
	var parsed: Array[Vector2i] = []
	if not ChunkCoordinate.try_parse_key(chunk_key, parsed) or parsed[0] != coordinate:
		return false
	var seen := {}
	for placement in placements:
		if not StaticContentManifest.is_valid_placement(placement, coordinate):
			return false
		var content_id := String(placement.get("content_id", ""))
		if seen.has(content_id):
			return false
		seen[content_id] = true
	return true


static func is_valid_placement(placement: Variant, coordinate: Vector2i) -> bool:
	if typeof(placement) != TYPE_DICTIONARY:
		return false
	var entry: Dictionary = placement
	var content_id := StringName(entry.get("content_id", ""))
	if ContentId.domain_of(content_id) != &"static":
		return false
	var expected_prefix := "static.%s_" % String(ChunkCoordinate.to_key(coordinate)).trim_prefix("chunk.").replace(".", "_")
	if not String(content_id).begins_with(expected_prefix):
		return false
	if not StaticContentCatalog.is_known_kind(String(entry.get("kind", ""))):
		return false
	var local: Variant = entry.get("local_position")
	if typeof(local) != TYPE_VECTOR2 or not (local as Vector2).is_finite():
		return false
	var pos := local as Vector2
	var size := Vector2(ChunkCoordinate.CHUNK_SIZE)
	if pos.x < 0.0 or pos.y < 0.0 or pos.x >= size.x or pos.y >= size.y:
		return false
	var scale_value: Variant = entry.get("scale", 1.0)
	if typeof(scale_value) != TYPE_FLOAT and typeof(scale_value) != TYPE_INT:
		return false
	if not is_finite(float(scale_value)) or float(scale_value) <= 0.0:
		return false
	return true


static func content_id_for(coordinate: Vector2i, kind: String, index: int) -> StringName:
	var chunk_part := String(ChunkCoordinate.to_key(coordinate)).trim_prefix("chunk.").replace(".", "_")
	return StringName("static.%s_%s_%d" % [chunk_part, kind, index])
