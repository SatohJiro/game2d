class_name FastTravelDestinationCatalog
extends RefCounted

## Stable destination identity for fast travel.
##
## A destination ID lives in the `fast_travel` domain and deterministically
## maps to one canonical chunk key: `fast_travel.<chunk_key>`, e.g.
## `fast_travel.chunk.p1.p0`. No localized text, asset path or scene path is
## ever used as identity; the chunk key grammar from ChunkCoordinate is the
## single source of truth and non-canonical keys are rejected.

const DOMAIN := &"fast_travel"


static func destination_id_for_chunk(chunk_key: StringName) -> StringName:
	var parsed: Array[Vector2i] = []
	if not ChunkCoordinate.try_parse_key(chunk_key, parsed):
		return &""
	if ChunkCoordinate.to_key(parsed[0]) != chunk_key:
		return &""
	var candidate := StringName("%s.%s" % [String(DOMAIN), String(chunk_key)])
	return candidate if ContentId.is_valid(candidate) else &""


static func is_destination_id(value: StringName) -> bool:
	return chunk_key_for_destination(value) != &""


static func chunk_key_for_destination(destination_id: StringName) -> StringName:
	if not ContentId.is_valid(destination_id):
		return &""
	if ContentId.domain_of(destination_id) != DOMAIN:
		return &""
	var prefix := String(DOMAIN) + "."
	var text := String(destination_id)
	if not text.begins_with(prefix):
		return &""
	var chunk_key := StringName(text.substr(prefix.length()))
	var parsed: Array[Vector2i] = []
	if not ChunkCoordinate.try_parse_key(chunk_key, parsed):
		return &""
	if ChunkCoordinate.to_key(parsed[0]) != chunk_key:
		return &""
	return chunk_key


## Landing position is the geometric center of the destination chunk.
## Navigation/physics safety of the exact tile is owned by chunk content
## packages; the domain only guarantees a deterministic, finite position.
static func try_landing_position(chunk_key: StringName, output: Array[Vector2]) -> bool:
	output.clear()
	var parsed: Array[Vector2i] = []
	if not ChunkCoordinate.try_parse_key(chunk_key, parsed):
		return false
	var origin := ChunkCoordinate.world_origin(parsed[0])
	var half := Vector2(ChunkCoordinate.CHUNK_SIZE) * 0.5
	var landing := origin + half
	if not landing.is_finite():
		return false
	output.append(landing)
	return true
