class_name ChunkDiscoveryState
extends RefCounted

var revision: int = 0
var _discovered: Dictionary = {}


func discover(request: ChunkDiscoveryRequest) -> ChunkDiscoveryResult:
	if request == null or request.observed_revision < 0:
		return ChunkDiscoveryResult.new(ChunkDiscoveryResult.Status.INVALID, &"", revision)
	var parsed: Array[Vector2i] = []
	if not ChunkCoordinate.try_parse_key(request.chunk_key, parsed):
		return ChunkDiscoveryResult.new(ChunkDiscoveryResult.Status.INVALID, request.chunk_key, revision)
	if request.observed_revision != revision:
		return ChunkDiscoveryResult.new(ChunkDiscoveryResult.Status.STALE, request.chunk_key, revision)
	if _discovered.has(request.chunk_key):
		return ChunkDiscoveryResult.new(ChunkDiscoveryResult.Status.NO_CHANGE, request.chunk_key, revision)
	_discovered[request.chunk_key] = true
	revision += 1
	return ChunkDiscoveryResult.new(ChunkDiscoveryResult.Status.DISCOVERED, request.chunk_key, revision)


func get_discovered_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for key in _discovered: keys.append(key as StringName)
	keys.sort()
	return keys


func create_view_snapshot(center: Vector2i, active_keys: Array[StringName]) -> Dictionary:
	var union: Dictionary = {}
	for key in get_discovered_keys(): union[key] = true
	for key in active_keys: union[key] = true
	var keys: Array[StringName] = []
	for key in union: keys.append(key as StringName)
	keys.sort()
	var tiles: Array[Dictionary] = []
	for key in keys:
		var parsed: Array[Vector2i] = []
		if not ChunkCoordinate.try_parse_key(key, parsed): continue
		tiles.append({
			"chunk_key": String(key),
			"coordinate": [parsed[0].x, parsed[0].y],
			"discovered": _discovered.has(key),
			"active": active_keys.has(key),
			"current": parsed[0] == center,
		})
	return {
		"revision": revision,
		"center_key": String(ChunkCoordinate.to_key(center)),
		"discovered_count": _discovered.size(),
		"tiles": tiles,
	}


func to_dto() -> Dictionary:
	var keys: Array[String] = []
	for key in get_discovered_keys(): keys.append(String(key))
	return {"revision": revision, "discovered_chunks": keys}


static func from_dto(value: Variant) -> ChunkDiscoveryState:
	if value == null:
		return ChunkDiscoveryState.new()
	if not value is Dictionary:
		return null
	var dto := value as Dictionary
	if dto.is_empty():
		return ChunkDiscoveryState.new()
	if dto.size() != 2 or not dto.has("revision") or not dto.has("discovered_chunks") or not dto["discovered_chunks"] is Array:
		return null
	var parsed_revision: Variant = _parse_nonnegative_integer(dto["revision"])
	if parsed_revision == null: return null
	var state := ChunkDiscoveryState.new()
	for raw_key in dto["discovered_chunks"] as Array:
		if not raw_key is String: return null
		var key := StringName(raw_key as String)
		var coordinate: Array[Vector2i] = []
		if state._discovered.has(key) or not ChunkCoordinate.try_parse_key(key, coordinate): return null
		state._discovered[key] = true
	if parsed_revision as int != state._discovered.size(): return null
	state.revision = parsed_revision as int
	return state


static func _parse_nonnegative_integer(value: Variant) -> Variant:
	if value is int and value >= 0: return value
	if value is float and is_finite(value) and value >= 0.0 and value == floor(value): return int(value)
	return null
