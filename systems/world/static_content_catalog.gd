class_name StaticContentCatalog
extends RefCounted

## Authored static decoration catalog (U2.9).
##
## Defines the decoration kinds (texture + per-chunk density) and generates
## deterministic per-chunk manifests. Placement uses the same FNV-1a stable
## hash approach as the ambient spawn policy, keyed by chunk coordinate,
## kind and index — every chunk gets authored-style decorations without
## hand-authoring infinite chunks, and manifests never change between runs.

const POSITION_MARGIN := 80.0

const KINDS := {
	"flowers": {"texture": "res://assets/tilesets/nature_flowers.png", "count": 4},
	"bush": {"texture": "res://assets/tilesets/nature_bush.png", "count": 3},
	"mushrooms": {"texture": "res://assets/tilesets/nature_mushrooms.png", "count": 2},
	"stump": {"texture": "res://assets/tilesets/nature_stump.png", "count": 2},
}

static var _texture_cache: Dictionary = {}


static func is_known_kind(kind: String) -> bool:
	return KINDS.has(kind)


static func kind_texture_path(kind: String) -> String:
	if not KINDS.has(kind):
		return ""
	return String((KINDS[kind] as Dictionary).get("texture", ""))


static func texture_for_kind(kind: String) -> Texture2D:
	if _texture_cache.has(kind):
		return _texture_cache[kind] as Texture2D
	var path := kind_texture_path(kind)
	if path.is_empty():
		return null
	var texture := load(path) as Texture2D
	if texture != null:
		_texture_cache[kind] = texture
	return texture


static func manifest_for_chunk(coordinate: Vector2i) -> StaticContentManifest:
	var chunk_key := ChunkCoordinate.to_key(coordinate)
	var placements: Array[Dictionary] = []
	var kinds: Array = KINDS.keys()
	kinds.sort()
	for kind in kinds:
		var kind_name := String(kind)
		var count := int((KINDS[kind] as Dictionary).get("count", 0))
		for index in count:
			placements.append({
				"content_id": String(StaticContentManifest.content_id_for(coordinate, kind_name, index)),
				"kind": kind_name,
				"local_position": _placement_position(coordinate, kind_name, index),
				"scale": 1.0,
			})
	var manifest := StaticContentManifest.new(chunk_key, coordinate, placements)
	if not manifest.is_valid():
		push_error("StaticContentCatalog produced an invalid manifest for %s" % String(chunk_key))
		return StaticContentManifest.new(chunk_key, coordinate, [])
	return manifest


static func _placement_position(coordinate: Vector2i, kind: String, index: int) -> Vector2:
	var entropy := _stable_entropy("static|%d|%d|%s|%d" % [coordinate.x, coordinate.y, kind, index])
	var size := Vector2(ChunkCoordinate.CHUNK_SIZE)
	var usable := size - Vector2(POSITION_MARGIN * 2.0, POSITION_MARGIN * 2.0)
	return Vector2(
		POSITION_MARGIN + float(entropy % int(usable.x)),
		POSITION_MARGIN + float((entropy / 97) % int(usable.y))
	)


static func _stable_entropy(value: String) -> int:
	var hash_value: int = 2166136261
	for index in value.length():
		hash_value = int((hash_value ^ value.unicode_at(index)) * 16777619) & 0x7fffffff
	return hash_value
