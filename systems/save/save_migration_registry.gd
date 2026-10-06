class_name SaveMigrationRegistry
extends RefCounted

const Schema = preload("res://systems/save/save_v1_schema.gd")
const MigrationResult = preload("res://systems/save/save_migration_result.gd")

var current_version: int
var steps: Array[RefCounted]


func _init(p_current_version: int = Schema.SCHEMA_VERSION, p_steps: Array[RefCounted] = []) -> void:
	current_version = p_current_version
	steps = p_steps.duplicate()


func migrate(source: Variant) -> RefCounted:
	if typeof(source) != TYPE_DICTIONARY:
		return MigrationResult.new(MigrationResult.Status.INVALID_INPUT, {}, PackedInt32Array(), PackedStringArray(["save root must be a Dictionary"]))
	var working: Dictionary = source.duplicate(true)
	var version_value: Variant = working.get("schema_version")
	if not _is_non_negative_integer(version_value):
		return MigrationResult.new(MigrationResult.Status.INVALID_INPUT, {}, PackedInt32Array(), PackedStringArray(["schema_version must be a non-negative integer"]))
	var version := int(version_value)
	if version > current_version:
		return MigrationResult.new(MigrationResult.Status.FUTURE_VERSION, {}, PackedInt32Array(), PackedStringArray(["save version %d is newer than current %d" % [version, current_version]]))
	if version == current_version:
		return _validate_current(working, MigrationResult.Status.CURRENT, PackedInt32Array())

	var visited := {}
	var applied := PackedInt32Array()
	while version != current_version:
		if visited.has(version):
			return MigrationResult.new(MigrationResult.Status.CYCLE, {}, applied, PackedStringArray(["migration cycle at version %d" % version]))
		visited[version] = true
		var matches: Array[RefCounted] = []
		for step in steps:
			if step != null and step.get("from_version") == version:
				matches.append(step)
		if matches.is_empty():
			return MigrationResult.new(MigrationResult.Status.MISSING_STEP, {}, applied, PackedStringArray(["missing migration step from version %d" % version]))
		if matches.size() != 1 or not matches[0].has_method("is_valid") or not matches[0].is_valid():
			return MigrationResult.new(MigrationResult.Status.INVALID_REGISTRY, {}, applied, PackedStringArray(["migration route from version %d must have one valid step" % version]))
		var step := matches[0]
		var output: Variant = step.apply(working)
		if typeof(output) != TYPE_DICTIONARY or not _is_non_negative_integer(output.get("schema_version")) or int(output["schema_version"]) != int(step.get("to_version")):
			return MigrationResult.new(MigrationResult.Status.INVALID_OUTPUT, {}, applied, PackedStringArray(["migration step from version %d returned invalid version output" % version]))
		applied.append(version)
		working = (output as Dictionary).duplicate(true)
		version = int(working["schema_version"])
	return _validate_current(working, MigrationResult.Status.MIGRATED, applied)


func _validate_current(snapshot: Dictionary, success_status: int, applied: PackedInt32Array) -> RefCounted:
	var validation: RefCounted = Schema.validate(snapshot)
	if not validation.is_valid():
		return MigrationResult.new(MigrationResult.Status.INVALID_OUTPUT, {}, applied, validation.errors)
	return MigrationResult.new(success_status, snapshot, applied)


func _is_non_negative_integer(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and float(value) >= 0.0 and is_equal_approx(float(value), floor(float(value)))
