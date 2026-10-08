class_name ChunkDeltaEnvelope
extends RefCounted

const KIND_BUILDING := &"world_entity.building"
const KIND_RESOURCE := &"world_entity.resource"

var chunk_key: StringName
var coordinate: Vector2i
var entries: Array[Dictionary]

func _init(p_coordinate: Vector2i, p_entries: Array[Dictionary]) -> void:
	coordinate = p_coordinate
	chunk_key = ChunkCoordinate.to_key(coordinate)
	entries = p_entries.duplicate(true)

func is_valid() -> bool:
	var parsed: Array[Vector2i] = []
	if not ChunkCoordinate.try_parse_key(chunk_key, parsed) or parsed[0] != coordinate: return false
	var seen: Dictionary = {}
	for entry in entries:
		var kind_id := StringName(entry.get("kind_id", ""))
		var instance_id := StringName(entry.get("instance_id", ""))
		var position: Variant = _position_from_dto(entry.get("position"))
		if kind_id not in [KIND_BUILDING, KIND_RESOURCE] or position == null or ChunkCoordinate.from_world_position(position) != coordinate: return false
		if seen.has(instance_id): return false
		seen[instance_id] = true
		var payload: Variant = entry.get("payload")
		if kind_id == KIND_BUILDING and BuildingPlacementRecord.from_dto(payload) == null: return false
		if kind_id == KIND_RESOURCE and ResourceDepletionRecord.from_dto(payload) == null: return false
		if StringName((payload as Dictionary).get("instance_id", "")) != instance_id: return false
	return true

func to_dto() -> Dictionary:
	return {"chunk_key": String(chunk_key), "coordinate": {"x": coordinate.x, "y": coordinate.y}, "entries": entries.duplicate(true)}

static func from_dto(value: Variant) -> ChunkDeltaEnvelope:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	var coordinate_value: Variant = data.get("coordinate")
	if typeof(coordinate_value) != TYPE_DICTIONARY or typeof(data.get("entries")) != TYPE_ARRAY: return null
	for axis: Variant in [coordinate_value.get("x"), coordinate_value.get("y")]:
		if (typeof(axis) not in [TYPE_INT, TYPE_FLOAT]) or not is_finite(float(axis)) or not is_equal_approx(float(axis), floor(float(axis))): return null
	var typed_entries: Array[Dictionary] = []
	for entry: Variant in data["entries"]:
		if typeof(entry) != TYPE_DICTIONARY: return null
		typed_entries.append(_normalize_json_numbers(entry) as Dictionary)
	var envelope := ChunkDeltaEnvelope.new(Vector2i(int(coordinate_value["x"]), int(coordinate_value["y"])), typed_entries)
	if StringName(data.get("chunk_key", "")) != envelope.chunk_key: return null
	return envelope if envelope.is_valid() else null

static func _position_from_dto(value: Variant) -> Variant:
	if typeof(value) != TYPE_DICTIONARY: return null
	if (typeof(value.get("x")) not in [TYPE_INT, TYPE_FLOAT]) or (typeof(value.get("y")) not in [TYPE_INT, TYPE_FLOAT]): return null
	var position := Vector2(float(value["x"]), float(value["y"]))
	return position if position.is_finite() else null

static func _normalize_json_numbers(value: Variant) -> Variant:
	if typeof(value) == TYPE_FLOAT and is_finite(value) and is_equal_approx(value, floor(value)):
		return int(value)
	if typeof(value) == TYPE_DICTIONARY:
		var normalized: Dictionary = {}
		for key: Variant in value.keys(): normalized[key] = _normalize_json_numbers(value[key])
		return normalized
	if typeof(value) == TYPE_ARRAY:
		var normalized: Array = []
		for item: Variant in value: normalized.append(_normalize_json_numbers(item))
		return normalized
	return value
