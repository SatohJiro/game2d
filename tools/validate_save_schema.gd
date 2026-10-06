extends SceneTree

const Schema = preload("res://systems/save/save_v1_schema.gd")
const ValidationResult = preload("res://systems/save/save_validation_result.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_valid_envelope_and_round_trip()
	_test_identity_and_shape_guards()
	_test_non_serializable_guards()
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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
