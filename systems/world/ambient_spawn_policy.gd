class_name AmbientSpawnPolicy
extends RefCounted

const POSITION_MARGIN := 160


static func pick_species(table: BiomeSpawnTable, entropy: int) -> StringName:
	var total := table.total_weight()
	var roll := absi(entropy) % total
	var cumulative := 0
	for i in table.species_ids.size():
		cumulative += table.species_weights[i]
		if roll < cumulative:
			return table.species_ids[i]
	return table.species_ids[table.species_ids.size() - 1]


static func pick_level(table: BiomeSpawnTable, entropy: int) -> int:
	return table.level_min + (absi(entropy) / 17) % (table.level_max - table.level_min + 1)


static func resolve(request: AmbientSpawnRequest, applied_revision: int) -> AmbientSpawnResult:
	if not _is_valid_request(request):
		return AmbientSpawnResult.new(AmbientSpawnResult.Status.INVALID, [], [], [], applied_revision)
	if request.chunk_revision < applied_revision:
		return AmbientSpawnResult.new(AmbientSpawnResult.Status.STALE, [], [], [], applied_revision)
	if request.chunk_revision > applied_revision + 1:
		return AmbientSpawnResult.new(AmbientSpawnResult.Status.INVALID, [], [], [], applied_revision)
	var table := BiomeSpawnTable.get_for_biome(request.biome_id)
	if table == null or not table.is_valid():
		return AmbientSpawnResult.new(AmbientSpawnResult.Status.INVALID, [], [], [], applied_revision)
	var active_lookup: Dictionary = {}
	for key in request.active_keys: active_lookup[key] = true
	var unloaded: Array[StringName] = []
	var survivors: Array[StringName] = []
	for raw_id in request.existing_chunks:
		var instance_id := raw_id as StringName
		if active_lookup.has(request.existing_chunks[instance_id]): survivors.append(instance_id)
		else: unloaded.append(instance_id)
	unloaded.sort()
	survivors.sort()
	while survivors.size() > request.budget:
		unloaded.append(survivors.pop_back())
	unloaded.sort()
	var admitted: Array[AmbientSpawnSpec] = []
	var next_ids := survivors.duplicate()
	var blocked_lookup: Dictionary = {}
	for blocked_id in request.blocked_instance_ids: blocked_lookup[blocked_id] = true
	for key in _priority_keys(request.active_keys, request.center):
		for slot in range(table.slots_per_chunk):
			if next_ids.size() >= request.budget: break
			var instance_id := _instance_id(key, slot)
			if request.existing_chunks.has(instance_id): continue
			if blocked_lookup.has(instance_id): continue
			var spec := _create_spec(key, slot, request, table)
			if spec == null or not spec.is_valid():
				return AmbientSpawnResult.new(AmbientSpawnResult.Status.INVALID, [], [], [], applied_revision)
			admitted.append(spec)
			next_ids.append(instance_id)
	next_ids.sort()
	var status := AmbientSpawnResult.Status.NO_CHANGE if admitted.is_empty() and unloaded.is_empty() else AmbientSpawnResult.Status.APPLIED
	return AmbientSpawnResult.new(status, admitted, unloaded, next_ids, request.chunk_revision)


static func _is_valid_request(request: AmbientSpawnRequest) -> bool:
	if request == null or ContentId.domain_of(request.biome_id) != &"biome" or request.time_bucket < 0 or request.time_bucket > 3 or request.budget < 0 or request.budget > 64 or request.chunk_revision < 1:
		return false
	var seen: Dictionary = {}
	for key in request.active_keys:
		var parsed: Array[Vector2i] = []
		if seen.has(key) or not ChunkCoordinate.try_parse_key(key, parsed): return false
		seen[key] = true
	if not seen.has(ChunkCoordinate.to_key(request.center)): return false
	for raw_id in request.existing_chunks:
		var instance_id := raw_id as StringName
		var existing_coordinate: Array[Vector2i] = []
		if not ContentId.is_valid(instance_id) or not ChunkCoordinate.try_parse_key(request.existing_chunks[instance_id] as StringName, existing_coordinate): return false
	var seen_blocked := {}
	for blocked_id in request.blocked_instance_ids:
		if seen_blocked.has(blocked_id) or not AmbientCooldownState.is_valid_slot_id(blocked_id): return false
		seen_blocked[blocked_id] = true
	return true


static func _priority_keys(keys: Array[StringName], center: Vector2i) -> Array[StringName]:
	var result := keys.duplicate()
	result.sort_custom(func(a: StringName, b: StringName) -> bool:
		var a_out: Array[Vector2i] = []
		var b_out: Array[Vector2i] = []
		ChunkCoordinate.try_parse_key(a, a_out)
		ChunkCoordinate.try_parse_key(b, b_out)
		var a_distance: int = abs(a_out[0].x - center.x) + abs(a_out[0].y - center.y)
		var b_distance: int = abs(b_out[0].x - center.x) + abs(b_out[0].y - center.y)
		return String(a) < String(b) if a_distance == b_distance else a_distance < b_distance
	)
	return result


static func _instance_id(chunk_key: StringName, slot: int) -> StringName:
	return StringName("ambient.%s_s%d" % [String(chunk_key).trim_prefix("chunk.").replace(".", "_"), slot])


static func _create_spec(chunk_key: StringName, slot: int, request: AmbientSpawnRequest, table: BiomeSpawnTable) -> AmbientSpawnSpec:
	var parsed: Array[Vector2i] = []
	if not ChunkCoordinate.try_parse_key(chunk_key, parsed): return null
	var entropy := _stable_entropy("%s|%s|%s|%s" % [chunk_key, slot, request.time_bucket, request.seed])
	var usable_x := ChunkCoordinate.CHUNK_SIZE.x - POSITION_MARGIN * 2
	var usable_y := ChunkCoordinate.CHUNK_SIZE.y - POSITION_MARGIN * 2
	var local := Vector2(POSITION_MARGIN + entropy % usable_x, POSITION_MARGIN + (entropy / 97) % usable_y)
	var species_id := pick_species(table, entropy)
	var level := pick_level(table, entropy)
	return AmbientSpawnSpec.new(_instance_id(chunk_key, slot), chunk_key, species_id, ChunkCoordinate.world_origin(parsed[0]) + local, level)


static func _stable_entropy(value: String) -> int:
	var hash_value: int = 2166136261
	for index in value.length():
		hash_value = int((hash_value ^ value.unicode_at(index)) * 16777619) & 0x7fffffff
	return hash_value
