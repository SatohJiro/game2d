class_name ChunkNavigationAdapter
extends RefCounted

var navigation_map: RID
var applied_revision: int = 0
var _regions: Dictionary = {}
var _created_count: int = 0
var _freed_count: int = 0


func _init(p_navigation_map: RID) -> void:
	navigation_map = p_navigation_map


func apply(request: ChunkNavigationRequest) -> ChunkNavigationResult:
	if request == null or not navigation_map.is_valid():
		return _result(ChunkNavigationResult.Status.INVALID)
	if request.observed_revision != applied_revision:
		return _result(ChunkNavigationResult.Status.STALE)
	if request.kind == ChunkNavigationRequest.Kind.UPDATE_OBSTACLE:
		return _apply_obstacle(request)
	if request.kind != ChunkNavigationRequest.Kind.SYNC_REGIONS:
		return _result(ChunkNavigationResult.Status.INVALID)
	return _apply_sync(request)


func _apply_sync(request: ChunkNavigationRequest) -> ChunkNavigationResult:
	if request.target_revision == applied_revision:
		if request.admitted_keys.is_empty() and request.unloaded_keys.is_empty() and get_active_keys() == request.next_active_keys:
			return _result(ChunkNavigationResult.Status.NO_CHANGE)
		return _result(ChunkNavigationResult.Status.INVALID)
	if request.target_revision != applied_revision + 1:
		return _result(ChunkNavigationResult.Status.INVALID)
	if not _keys_are_unique(request.admitted_keys) or not _keys_are_unique(request.unloaded_keys) or not _keys_are_unique(request.next_active_keys):
		return _result(ChunkNavigationResult.Status.INVALID)
	for key in request.admitted_keys:
		if _regions.has(key):
			return _result(ChunkNavigationResult.Status.INVALID)
	for key in request.unloaded_keys:
		if not _regions.has(key):
			return _result(ChunkNavigationResult.Status.INVALID)
	var projected := get_active_keys()
	for key in request.unloaded_keys: projected.erase(key)
	for key in request.admitted_keys: projected.append(key)
	projected.sort()
	if projected != request.next_active_keys:
		return _result(ChunkNavigationResult.Status.INVALID)

	var staged: Dictionary = {}
	for key in request.admitted_keys:
		var parsed: Array[Vector2i] = []
		if not ChunkCoordinate.try_parse_key(key, parsed):
			_free_staged(staged)
			return _result(ChunkNavigationResult.Status.INVALID)
		var region := NavigationServer2D.region_create()
		if not region.is_valid():
			_free_staged(staged)
			return _result(ChunkNavigationResult.Status.INVALID)
		NavigationServer2D.region_set_map(region, navigation_map)
		NavigationServer2D.region_set_transform(region, Transform2D(0.0, ChunkCoordinate.world_origin(parsed[0])))
		NavigationServer2D.region_set_navigation_polygon(region, _create_placeholder_polygon())
		staged[key] = {"rid": region, "coordinate": parsed[0], "obstacle_revision": 0, "blocked": false}
	for key in staged:
		_regions[key] = staged[key]
		_created_count += 1
	for key in request.unloaded_keys:
		_free_region(key)
	applied_revision = request.target_revision
	return _result(ChunkNavigationResult.Status.APPLIED)


func _apply_obstacle(request: ChunkNavigationRequest) -> ChunkNavigationResult:
	if request.target_revision != applied_revision or not _regions.has(request.chunk_key) or request.obstacle_revision < 1:
		return _result(ChunkNavigationResult.Status.INVALID)
	var record := _regions[request.chunk_key] as Dictionary
	var current_revision := int(record["obstacle_revision"])
	if request.obstacle_revision <= current_revision:
		return _result(ChunkNavigationResult.Status.STALE)
	if request.obstacle_revision != current_revision + 1:
		return _result(ChunkNavigationResult.Status.INVALID)
	NavigationServer2D.region_set_enabled(record["rid"] as RID, not request.blocked)
	record["obstacle_revision"] = request.obstacle_revision
	record["blocked"] = request.blocked
	return _result(ChunkNavigationResult.Status.APPLIED)


func get_active_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for key in _regions.keys(): keys.append(key as StringName)
	keys.sort()
	return keys


func create_debug_snapshot() -> Dictionary:
	var chunks: Array[Dictionary] = []
	for key in get_active_keys():
		var record := _regions[key] as Dictionary
		chunks.append({
			"chunk_key": String(key),
			"coordinate": record["coordinate"],
			"obstacle_revision": record["obstacle_revision"],
			"blocked": record["blocked"]
		})
	return {
		"revision": applied_revision,
		"active_count": _regions.size(),
		"created_count": _created_count,
		"freed_count": _freed_count,
		"active_chunks": chunks
	}


func cleanup() -> void:
	for key in get_active_keys(): _free_region(key)
	navigation_map = RID()


func _free_region(key: StringName) -> void:
	var record := _regions.get(key) as Dictionary
	if record == null: return
	var region := record["rid"] as RID
	NavigationServer2D.region_set_map(region, RID())
	NavigationServer2D.free_rid(region)
	_regions.erase(key)
	_freed_count += 1


func _free_staged(staged: Dictionary) -> void:
	for record: Dictionary in staged.values():
		var region := record["rid"] as RID
		NavigationServer2D.region_set_map(region, RID())
		NavigationServer2D.free_rid(region)


func _create_placeholder_polygon() -> NavigationPolygon:
	const EDGE_INSET := 2.0
	var maximum := Vector2(ChunkCoordinate.CHUNK_SIZE) - Vector2.ONE * EDGE_INSET
	var polygon := NavigationPolygon.new()
	polygon.vertices = PackedVector2Array([
		Vector2.ONE * EDGE_INSET,
		Vector2(maximum.x, EDGE_INSET),
		maximum,
		Vector2(EDGE_INSET, maximum.y)
	])
	polygon.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	return polygon


func _keys_are_unique(keys: Array[StringName]) -> bool:
	var seen: Dictionary = {}
	for key in keys:
		if seen.has(key): return false
		seen[key] = true
	return true


func _result(status: ChunkNavigationResult.Status) -> ChunkNavigationResult:
	return ChunkNavigationResult.new(status, applied_revision, _regions.size())
