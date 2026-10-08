extends SceneTree

const OLD_SPECIES: Array[StringName] = [&"creature.flam", &"creature.slime", &"creature.mushroom", &"creature.beast"]

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_table_lookup()
	_test_pick_helpers()
	_test_bit_for_bit_reproduction()
	_test_biome_request_handling()
	await _test_main_integration()
	if _failures.is_empty():
		print("Biome table validation passed: authored lookup, weighted picks, exact legacy reproduction and Main spawn wiring are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _test_table_lookup() -> void:
	var meadow := BiomeSpawnTable.get_for_biome(WorldChunkCatalog.DEFAULT_BIOME_ID)
	_expect(meadow != null and meadow.is_valid(), "default meadow table must exist and be valid")
	_expect(meadow.biome_id == WorldChunkCatalog.DEFAULT_BIOME_ID, "meadow lookup must return the meadow table")
	_expect(meadow.slots_per_chunk == 2 and meadow.level_min == 1 and meadow.level_max == 3, "meadow table must carry the legacy tuning")
	var fallback := BiomeSpawnTable.get_for_biome(&"biome.mystery_depths")
	_expect(fallback != null and fallback.biome_id == WorldChunkCatalog.DEFAULT_BIOME_ID, "unknown biome must fall back to the default table")
	_expect(not _table([&"creature.flam"], [1], 1, 3, 2, &"item.x").is_valid(), "non-biome table ID must be invalid")
	_expect(not _table([&"creature.flam", &"creature.slime"], [1], 1, 3, 2).is_valid(), "mismatched species/weight sizes must be invalid")
	_expect(not _table([&"creature.flam"], [0], 1, 3, 2).is_valid(), "zero weight must be invalid")
	_expect(not _table([&"creature.flam"], [-2], 1, 3, 2).is_valid(), "negative weight must be invalid")
	_expect(not _table([&"creature.nope"], [1], 1, 3, 2).is_valid(), "unsupported species must be invalid")
	_expect(not _table([LegacySpeciesAdapter.DRAGON_ID], [1], 1, 3, 2).is_valid(), "boss species must be invalid in ambient tables")
	_expect(not _table([&"creature.flam"], [1], 3, 1, 2).is_valid(), "inverted level range must be invalid")
	_expect(not _table([&"creature.flam"], [1], 0, 3, 2).is_valid(), "level below 1 must be invalid")
	_expect(not _table([&"creature.flam"], [1], 1, 6, 2).is_valid(), "level above 5 must be invalid")
	_expect(not _table([&"creature.flam"], [1], 1, 3, 0).is_valid(), "zero slots per chunk must be invalid")
	_expect(not _table([], [], 1, 3, 2).is_valid(), "empty species pool must be invalid")


func _table(species: Array, weights: Array, level_min: int, level_max: int, slots: int, biome_id: StringName = WorldChunkCatalog.DEFAULT_BIOME_ID) -> BiomeSpawnTable:
	var ids: Array[StringName] = []
	for raw in species: ids.append(raw)
	var w: Array[int] = []
	for raw in weights: w.append(int(raw))
	return BiomeSpawnTable.new(biome_id, ids, w, level_min, level_max, slots)


func _test_pick_helpers() -> void:
	var table := _table([&"creature.flam", &"creature.slime"], [3, 1], 2, 4, 2)
	var first_count := 0
	for entropy in range(400):
		var picked := AmbientSpawnPolicy.pick_species(table, entropy)
		_expect(picked == &"creature.flam" or picked == &"creature.slime", "weighted pick must return a pool species")
		if picked == &"creature.flam":
			first_count += 1
		var level := AmbientSpawnPolicy.pick_level(table, entropy)
		_expect(level >= 2 and level <= 4, "level roll must stay inside the table range")
		_expect(AmbientSpawnPolicy.pick_species(table, entropy) == picked, "species pick must be deterministic")
		_expect(AmbientSpawnPolicy.pick_level(table, entropy) == level, "level roll must be deterministic")
	_expect(first_count == 300, "weights [3, 1] must pick the first species exactly 75% of the time")


func _stable_entropy(value: String) -> int:
	var hash_value: int = 2166136261
	for index in value.length():
		hash_value = int((hash_value ^ value.unicode_at(index)) * 16777619) & 0x7fffffff
	return hash_value


func _test_bit_for_bit_reproduction() -> void:
	var keys: Array[StringName] = []
	for x in range(-1, 2):
		for y in range(-1, 2):
			keys.append(ChunkCoordinate.to_key(Vector2i(x, y)))
	for bucket in range(4):
		for seed in [1, 730201]:
			var request := AmbientSpawnRequest.new(Vector2i.ZERO, keys, {}, [], WorldChunkCatalog.DEFAULT_BIOME_ID, bucket, 64, seed, 1)
			var result := AmbientSpawnPolicy.resolve(request, 0)
			_expect(result.is_success(), "reproduction request must succeed")
			for spec in result.admitted:
				var slot := int(String(spec.instance_id).get_slice("_s", 1))
				var entropy := _stable_entropy("%s|%s|%s|%s" % [String(spec.chunk_key), slot, bucket, seed])
				var expected_species := OLD_SPECIES[entropy % OLD_SPECIES.size()]
				var expected_level := 1 + (entropy / 17) % 3
				_expect(spec.species_id == expected_species, "table-driven species must match the legacy formula")
				_expect(spec.level == expected_level, "table-driven level must match the legacy formula")
				_expect(spec.is_valid(), "reproduced spec must stay valid")


func _test_biome_request_handling() -> void:
	var keys: Array[StringName] = [&"chunk.p0.p0"]
	var unknown := AmbientSpawnRequest.new(Vector2i.ZERO, keys, {}, [], &"biome.mystery_depths", 0, 10, 7, 1)
	var unknown_result := AmbientSpawnPolicy.resolve(unknown, 0)
	_expect(unknown_result.is_success(), "unknown biome request must fall back instead of failing")
	for spec in unknown_result.admitted:
		_expect(spec.is_valid(), "fallback specs must be valid")
	var bad_domain := AmbientSpawnRequest.new(Vector2i.ZERO, keys, {}, [], &"item.not_a_biome", 0, 10, 7, 1)
	_expect(AmbientSpawnPolicy.resolve(bad_domain, 0).status == AmbientSpawnResult.Status.INVALID, "non-biome domain must fail the request")
	var first := AmbientSpawnPolicy.resolve(unknown, 0)
	var second := AmbientSpawnPolicy.resolve(unknown, 0)
	_expect(_specs_signature(first) == _specs_signature(second), "fallback resolution must be deterministic")


func _specs_signature(result: AmbientSpawnResult) -> String:
	var parts: Array[String] = []
	for spec in result.admitted:
		parts.append("%s|%s|%d|%s" % [String(spec.instance_id), String(spec.species_id), spec.level, str(spec.position)])
	parts.sort()
	return "|".join(parts)


func _test_main_integration() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	_expect(bool(main.call("maintain_creatures")), "reconcile with biome tables must succeed")
	var snapshot: Dictionary = main.call("get_ambient_spawn_debug_snapshot")
	var per_chunk := {}
	for actor in snapshot.get("actors", []):
		var species_id := StringName(actor.get("species_id", ""))
		_expect(OLD_SPECIES.has(species_id), "spawned ambient must come from the meadow table pool")
		var chunk_key := String(actor.get("chunk_key", ""))
		per_chunk[chunk_key] = int(per_chunk.get(chunk_key, 0)) + 1
	for chunk_key in per_chunk:
		_expect(per_chunk[chunk_key] <= 2, "per-chunk spawns must respect the table slot budget")
	var debug_actors: Array = snapshot.get("actors", [])
	_expect(not debug_actors.is_empty(), "ambient population must spawn through the table")
	main.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
