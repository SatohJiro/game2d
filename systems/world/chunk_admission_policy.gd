class_name ChunkAdmissionPolicy
extends RefCounted

const ADMISSION_RADIUS := 1


static func resolve(request: ChunkAdmissionRequest, current_revision: int) -> ChunkAdmissionDelta:
	if request == null or current_revision < 0 or request.observed_revision < 0:
		return ChunkAdmissionDelta.new(ChunkAdmissionDelta.Status.INVALID, Vector2i.ZERO)
	if request.observed_revision != current_revision:
		return ChunkAdmissionDelta.new(
			ChunkAdmissionDelta.Status.STALE,
			request.center,
			[], [], request.active_keys, current_revision, current_revision
		)
	if not _keys_are_valid_and_unique(request.active_keys):
		return ChunkAdmissionDelta.new(ChunkAdmissionDelta.Status.INVALID, request.center)

	var desired := desired_keys(request.center)
	var admitted: Array[StringName] = []
	var unloaded: Array[StringName] = []
	for key in desired:
		if not request.active_keys.has(key):
			admitted.append(key)
	for key in request.active_keys:
		if not desired.has(key):
			unloaded.append(key)
	admitted.sort()
	unloaded.sort()
	if admitted.is_empty() and unloaded.is_empty():
		return ChunkAdmissionDelta.new(
			ChunkAdmissionDelta.Status.NO_CHANGE,
			request.center,
			[], [], desired, current_revision, current_revision
		)
	return ChunkAdmissionDelta.new(
		ChunkAdmissionDelta.Status.CHANGED,
		request.center,
		admitted,
		unloaded,
		desired,
		current_revision,
		current_revision + 1
	)


static func desired_keys(center: Vector2i) -> Array[StringName]:
	var keys: Array[StringName] = []
	for y in range(center.y - ADMISSION_RADIUS, center.y + ADMISSION_RADIUS + 1):
		for x in range(center.x - ADMISSION_RADIUS, center.x + ADMISSION_RADIUS + 1):
			keys.append(ChunkCoordinate.to_key(Vector2i(x, y)))
	keys.sort()
	return keys


static func _keys_are_valid_and_unique(keys: Array[StringName]) -> bool:
	var seen: Dictionary = {}
	for key in keys:
		var parsed: Array[Vector2i] = []
		if seen.has(key) or not ChunkCoordinate.try_parse_key(key, parsed):
			return false
		seen[key] = true
	return true
