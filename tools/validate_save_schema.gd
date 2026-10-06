extends SceneTree

const Schema = preload("res://systems/save/save_v1_schema.gd")
const ValidationResult = preload("res://systems/save/save_validation_result.gd")
const SnapshotAdapter = preload("res://systems/save/save_snapshot_adapter.gd")
const SnapshotResult = preload("res://systems/save/save_snapshot_result.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_valid_envelope_and_round_trip()
	_test_identity_and_shape_guards()
	_test_non_serializable_guards()
	await _test_runtime_snapshot_adapter()
	if _failures.is_empty():
		print("Save schema validation passed: v1 envelope is JSON-safe and stable-ID references are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			printerr("SAVE SCHEMA VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _test_valid_envelope_and_round_trip() -> void:
	var save := Schema.create_empty(&"save.slot_1", 1000)
	save["inventory"] = {"item.wood": 12, "item.berry": 3}
	save["player"]["active_pet_instance_id"] = "pet.instance_1"
	save["pets"] = [{
		"instance_id": "pet.instance_1",
		"species_id": "creature.flam",
		"level": 2,
		"exp": 25,
		"stance_id": "pet.stance.follow_protect",
	}]
	var valid: RefCounted = Schema.validate(save)
	_expect(valid.is_valid() and valid.errors.is_empty(), "valid v1 envelope must pass")
	var encoded := JSON.stringify(save)
	var decoded: Variant = JSON.parse_string(encoded)
	_expect(typeof(decoded) == TYPE_DICTIONARY and Schema.validate(decoded).is_valid(), "JSON round trip must preserve a valid envelope")
	_expect(save["schema_version"] == 1 and save["save_id"] == "save.slot_1", "factory must stamp version and stable save ID")


func _test_identity_and_shape_guards() -> void:
	var wrong_version := Schema.create_empty(&"save.slot_1", 1)
	wrong_version["schema_version"] = 2
	_expect(not Schema.validate(wrong_version).is_valid(), "unknown schema version must fail closed")
	var localized_inventory := Schema.create_empty(&"save.slot_1", 1)
	localized_inventory["inventory"] = {"Gỗ": 2}
	_expect(not Schema.validate(localized_inventory).is_valid(), "localized inventory key must not become save identity")
	var duplicate := Schema.create_empty(&"save.slot_1", 1)
	duplicate["pets"] = [
		{"instance_id": "pet.same", "species_id": "creature.flam", "level": 1, "exp": 0, "stance_id": "pet.stance.auto_work"},
		{"instance_id": "pet.same", "species_id": "creature.slime", "level": 1, "exp": 0, "stance_id": "pet.stance.auto_work"},
	]
	_expect(not Schema.validate(duplicate).is_valid(), "duplicate pet instance ID must fail")
	var stale_active := Schema.create_empty(&"save.slot_1", 1)
	stale_active["player"]["active_pet_instance_id"] = "pet.missing"
	_expect(not Schema.validate(stale_active).is_valid(), "active pet must reference roster")
	var negative_count := Schema.create_empty(&"save.slot_1", 1)
	negative_count["inventory"] = {"item.wood": -1}
	_expect(not Schema.validate(negative_count).is_valid(), "negative inventory count must fail")


func _test_non_serializable_guards() -> void:
	var vector_value := Schema.create_empty(&"save.slot_1", 1)
	vector_value["player"]["position"] = Vector2.ONE
	_expect(not Schema.validate(vector_value).is_valid(), "Vector2 must not cross DTO boundary")
	var node_value := Schema.create_empty(&"save.slot_1", 1)
	var transient_node := Node.new()
	node_value["world"]["entity_deltas"].append(transient_node)
	_expect(not Schema.validate(node_value).is_valid(), "Node must not cross DTO boundary")
	transient_node.free()
	var callable_value := Schema.create_empty(&"save.slot_1", 1)
	callable_value["world"]["callback"] = _expect
	_expect(not Schema.validate(callable_value).is_valid(), "Callable must not cross DTO boundary")


func _test_runtime_snapshot_adapter() -> void:
	var packed_player := load("res://scenes/player.tscn") as PackedScene
	if packed_player == null:
		_failures.append("unable to load Player scene for save snapshot")
		return
	var fixture := Node2D.new()
	root.add_child(fixture)
	var player := packed_player.instantiate()
	fixture.add_child(player)
	await process_frame
	player.set("hud_ref", null)
	player.set("base_manager_ref", null)
	player.global_position = Vector2(12.5, -7.25)
	var party: Array[Dictionary] = player.get("pet_party")
	var species := LegacySpeciesAdapter.create_stable_snapshot(0, {"name": "Flam", "element": "Lửa", "power": 20, "max_hp": 100, "speed": 100.0})
	party.append({"instance_id": &"pet.snapshot_1", "species_id": LegacySpeciesAdapter.FLAM_ID, "species_data": species, "level": 3, "rarity_badge": "★", "trait": "Test"})
	player.call("swap_active_pet", 0)
	var active_pet: Node = player.get("active_pet_node")
	active_pet.call("apply_pet_command", &"pet.command.follow_protect")
	var source_inventory: Dictionary = player.get("inventory")
	var inventory_before := source_inventory.duplicate(true)
	var party_before := party.duplicate(true)
	var result: RefCounted = SnapshotAdapter.create_player_snapshot(player, &"save.slot_1", 1234, 45.5)
	_expect(result.is_accepted(), "default Player runtime must project to valid Save v1")
	if result.is_accepted():
		var snapshot: Dictionary = result.snapshot
		_expect(snapshot["inventory"].get("item.stone") == 8 and snapshot["inventory"].has("item.iron_ingot"), "legacy stone/iron must project to stable IDs")
		_expect(snapshot["pets"][0]["stance_id"] == "pet.stance.follow_protect", "active pet stance projection mismatch")
		_expect(snapshot["player"]["position"] == {"x": 12.5, "y": -7.25} and snapshot["world"]["clock_seconds"] == 45.5, "position/world clock projection mismatch")
		snapshot["inventory"]["item.wood"] = 9999
		_expect(source_inventory == inventory_before and party == party_before, "mutating snapshot must not mutate runtime source")
	source_inventory["Chưa Có Mapping"] = 1
	var unmapped: RefCounted = SnapshotAdapter.create_player_snapshot(player, &"save.slot_1", 1234)
	_expect(unmapped.status == SnapshotResult.Status.UNMAPPED_ITEM and unmapped.snapshot.is_empty(), "unmapped inventory key must fail without partial snapshot")
	source_inventory.erase("Chưa Có Mapping")
	root.remove_child(fixture)
	fixture.free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
