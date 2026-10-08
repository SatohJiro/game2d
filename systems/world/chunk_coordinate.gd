class_name ChunkCoordinate
extends RefCounted

const CHUNK_SIZE := Vector2i(1024, 1024)


static func from_world_position(world_position: Vector2) -> Vector2i:
	if not world_position.is_finite():
		return Vector2i.ZERO
	return Vector2i(
		floori(world_position.x / float(CHUNK_SIZE.x)),
		floori(world_position.y / float(CHUNK_SIZE.y))
	)


static func world_origin(coordinate: Vector2i) -> Vector2:
	return Vector2(coordinate.x * CHUNK_SIZE.x, coordinate.y * CHUNK_SIZE.y)


static func to_key(coordinate: Vector2i) -> StringName:
	return StringName("chunk.%s.%s" % [_encode_axis(coordinate.x), _encode_axis(coordinate.y)])


static func try_parse_key(key: StringName, output: Array[Vector2i]) -> bool:
	output.clear()
	if ContentId.domain_of(key) != &"chunk":
		return false
	var parts := String(key).split(".")
	if parts.size() != 3:
		return false
	var x: Variant = _decode_axis(parts[1])
	var y: Variant = _decode_axis(parts[2])
	if x == null or y == null:
		return false
	output.append(Vector2i(x as int, y as int))
	return true


static func _encode_axis(value: int) -> String:
	return ("p%d" % value) if value >= 0 else ("n%d" % abs(value))


static func _decode_axis(value: String) -> Variant:
	if value.length() < 2 or (value[0] != "p" and value[0] != "n"):
		return null
	var digits := value.substr(1)
	if not digits.is_valid_int() or (digits.length() > 1 and digits.begins_with("0")):
		return null
	var magnitude := digits.to_int()
	if value[0] == "n" and magnitude == 0:
		return null
	return magnitude if value[0] == "p" else -magnitude
