class_name ChunkAdmissionCoordinator
extends RefCounted

var center := Vector2i.ZERO
var revision: int = 0
var _active_records: Dictionary = {}


func update_world_position(world_position: Vector2, observed_revision: int = -1) -> ChunkAdmissionDelta:
	if not world_position.is_finite():
		return ChunkAdmissionDelta.new(ChunkAdmissionDelta.Status.INVALID, center)
	var request_revision := revision if observed_revision < 0 else observed_revision
	var next_center := ChunkCoordinate.from_world_position(world_position)
	var delta := ChunkAdmissionPolicy.resolve(
		ChunkAdmissionRequest.new(next_center, get_active_keys(), request_revision),
		revision
	)
	if not delta.is_changed():
		return delta

	# Admit first so a crossing never exposes a hole in the active neighborhood.
	for key in delta.admitted_keys:
		var parsed: Array[Vector2i] = []
		if not ChunkCoordinate.try_parse_key(key, parsed):
			return ChunkAdmissionDelta.new(ChunkAdmissionDelta.Status.INVALID, center)
		_active_records[key] = ChunkActiveRecord.new(parsed[0], delta.to_revision)
	for key in delta.unloaded_keys:
		_active_records.erase(key)
	center = next_center
	revision = delta.to_revision
	return delta


func get_active_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for key in _active_records.keys():
		keys.append(key as StringName)
	keys.sort()
	return keys


func create_debug_snapshot() -> Dictionary:
	var records: Array[Dictionary] = []
	for key in get_active_keys():
		var record := _active_records[key] as ChunkActiveRecord
		records.append(record.to_debug_dto())
	return {
		"center": [center.x, center.y],
		"center_key": String(ChunkCoordinate.to_key(center)),
		"revision": revision,
		"active_count": records.size(),
		"active_chunks": records,
	}
