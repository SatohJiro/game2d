extends SceneTree

const Schema = preload("res://systems/save/save_v1_schema.gd")
const Registry = preload("res://systems/save/save_migration_registry.gd")
const MigrationStep = preload("res://systems/save/save_migration_step.gd")
const MigrationResult = preload("res://systems/save/save_migration_result.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	_run()


func _run() -> void:
	_test_current_no_op()
	_test_injected_route()
	_test_failure_paths()
	if _failures.is_empty():
		print("Save migration validation passed: current no-op and fail-closed routing are valid.")
		quit(0)
	else:
		for failure in _failures:
			printerr("SAVE MIGRATION VALIDATION FAILURE: %s" % failure)
		quit(1)


func _test_current_no_op() -> void:
	var current := Schema.create_empty(&"save.slot_1", 10)
	var result: RefCounted = Registry.new().migrate(current)
	_expect(result.status == MigrationResult.Status.CURRENT and result.applied_versions.is_empty(), "current v1 must be a validated no-op")
	result.snapshot["saved_at_unix"] = 999
	_expect(current["saved_at_unix"] == 10, "migration result must not alias source")
	var invalid_current := current.duplicate(true)
	invalid_current["player"]["hp"] = 999
	_expect(Registry.new().migrate(invalid_current).status == MigrationResult.Status.INVALID_OUTPUT, "invalid current schema must fail closed")


func _test_injected_route() -> void:
	var step := MigrationStep.new(0, 1, _test_v0_to_v1)
	var source := {"schema_version": 0, "save_id": "save.legacy_test", "wood": 3}
	var result: RefCounted = Registry.new(1, [step]).migrate(source)
	_expect(result.status == MigrationResult.Status.MIGRATED and result.applied_versions == PackedInt32Array([0]), "injected v0 route must reach current exactly once")
	_expect(result.snapshot.get("inventory", {}).get("item.wood") == 3 and source.get("wood") == 3, "migration must transform a deep copy")


func _test_failure_paths() -> void:
	_expect(Registry.new().migrate({"schema_version": 2}).status == MigrationResult.Status.FUTURE_VERSION, "future version must fail closed")
	_expect(Registry.new().migrate({"schema_version": 0}).status == MigrationResult.Status.MISSING_STEP, "missing route must fail closed")
	var cycle_steps: Array[RefCounted] = [
		MigrationStep.new(0, 2, _set_version.bind(2)),
		MigrationStep.new(2, 0, _set_version.bind(0)),
	]
	_expect(Registry.new(1, cycle_steps).migrate({"schema_version": 0}).status == MigrationResult.Status.CYCLE, "cyclic route must fail closed")
	var bad_output: Array[RefCounted] = [MigrationStep.new(0, 1, _set_version.bind(7))]
	_expect(Registry.new(1, bad_output).migrate({"schema_version": 0}).status == MigrationResult.Status.INVALID_OUTPUT, "step output version mismatch must fail closed")
	var duplicate: Array[RefCounted] = [MigrationStep.new(0, 1, _test_v0_to_v1), MigrationStep.new(0, 1, _test_v0_to_v1)]
	_expect(Registry.new(1, duplicate).migrate({"schema_version": 0}).status == MigrationResult.Status.INVALID_REGISTRY, "ambiguous route must fail closed")


func _test_v0_to_v1(source: Dictionary) -> Dictionary:
	var current := Schema.create_empty(StringName(source.get("save_id", "save.test")), 0)
	current["inventory"] = {"item.wood": int(source.get("wood", 0))}
	return current


func _set_version(source: Dictionary, version: int) -> Dictionary:
	source["schema_version"] = version
	return source


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
