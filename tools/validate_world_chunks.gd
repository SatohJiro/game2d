extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_coordinate_boundaries()
	_test_key_round_trip()
	_test_definitions_and_catalog()
	await _test_main_read_adapter()
	if _failures.is_empty():
		print("World chunk validation passed: typed biome/chunk definitions, signed coordinate keys and read-only Main adapter are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)

func _test_coordinate_boundaries() -> void:
	_expect(ChunkCoordinate.from_world_position(Vector2.ZERO) == Vector2i.ZERO, "origin must resolve to chunk zero")
	_expect(ChunkCoordinate.from_world_position(Vector2(1023.999, 1023.999)) == Vector2i.ZERO, "positive inner edge must stay in origin chunk")
	_expect(ChunkCoordinate.from_world_position(Vector2(1024.0, 1024.0)) == Vector2i.ONE, "positive boundary must enter next chunk")
	_expect(ChunkCoordinate.from_world_position(Vector2(-0.001, -0.001)) == Vector2i(-1, -1), "negative fraction must floor into negative chunk")
	_expect(ChunkCoordinate.from_world_position(Vector2(-1024.0, -1024.0)) == Vector2i(-1, -1), "negative exact boundary mismatch")
	_expect(ChunkCoordinate.world_origin(Vector2i(-2, 3)) == Vector2(-2048.0, 3072.0), "chunk origin projection mismatch")

func _test_key_round_trip() -> void:
	for coordinate in [Vector2i.ZERO, Vector2i(1, -1), Vector2i(-42, 73)]:
		var key := ChunkCoordinate.to_key(coordinate)
		_expect(ContentId.is_valid(key), "chunk key must satisfy stable ID grammar: %s" % key)
		var parsed: Array[Vector2i] = []
		_expect(ChunkCoordinate.try_parse_key(key, parsed), "chunk key must parse: %s" % key)
		_expect(parsed.size() == 1 and parsed[0] == coordinate, "chunk key round trip mismatch: %s" % key)
	var rejected: Array[Vector2i] = []
	_expect(not ChunkCoordinate.try_parse_key(&"chunk.-1.0", rejected), "raw signed numeric key must be rejected")
	_expect(not ChunkCoordinate.try_parse_key(&"chunk.n0.p0", rejected), "negative zero key must be rejected")
	_expect(not ChunkCoordinate.try_parse_key(&"biome.p0.p0", rejected), "wrong key domain must be rejected")

func _test_definitions_and_catalog() -> void:
	var biome := load("res://data/definitions/biomes/paloria_meadow.tres") as BiomeDefinition
	var chunk := WorldChunkCatalog.get_origin_definition()
	_expect(biome != null and biome.get_validation_errors().is_empty(), "Paloria biome canary must be valid")
	_expect(chunk != null and chunk.get_validation_errors().is_empty(), "origin chunk canary must be valid")
	if chunk != null:
		_expect(chunk.coordinate == Vector2i.ZERO, "origin definition coordinate mismatch")
		_expect(chunk.biome_id == WorldChunkCatalog.DEFAULT_BIOME_ID, "origin definition biome mismatch")
	var context := WorldChunkCatalog.resolve_world_position(Vector2(-1.0, 1024.0))
	_expect(context != null and context.is_valid(), "catalog must produce a valid context")
	_expect(context.coordinate == Vector2i(-1, 1), "catalog coordinate mismatch")
	_expect(context.chunk_key == &"chunk.n1.p1", "catalog key mismatch")

func _test_main_read_adapter() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_failures.append("unable to load main scene")
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	var context := main.call("get_world_chunk_context", Vector2(1024.0, -0.1)) as WorldChunkContext
	_expect(context != null and context.coordinate == Vector2i(1, -1), "Main read adapter coordinate mismatch")
	_expect(context != null and context.biome_id == WorldChunkCatalog.DEFAULT_BIOME_ID, "Main read adapter biome mismatch")
	main.queue_free()
	await process_frame
	await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
