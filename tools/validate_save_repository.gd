extends SceneTree

const Schema = preload("res://systems/save/save_v1_schema.gd")
const Repository = preload("res://systems/save/save_repository.gd")
const RepositoryResult = preload("res://systems/save/save_repository_result.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	_run()


func _run() -> void:
	var directory := "user://save_repository_test_%d" % Time.get_ticks_usec()
	var primary := "%s/slot_1.json" % directory
	var repository: RefCounted = Repository.new(primary)
	var first := Schema.create_empty(&"save.slot_1", 100)
	first["inventory"] = {"item.wood": 2}
	var second := first.duplicate(true)
	second["saved_at_unix"] = 200
	second["inventory"]["item.wood"] = 7

	_expect(repository.load_snapshot().status == RepositoryResult.Status.NOT_FOUND, "missing primary and backup must return NOT_FOUND")
	_expect(repository.save(first).status == RepositoryResult.Status.SAVED, "first atomic save must succeed")
	var primary_load: RefCounted = repository.load_snapshot()
	_expect(primary_load.status == RepositoryResult.Status.LOADED_PRIMARY and _has_wood(primary_load.snapshot, 2), "primary load must return a valid semantic snapshot")
	primary_load.snapshot["inventory"]["item.wood"] = 999
	_expect(repository.load_snapshot().snapshot["inventory"]["item.wood"] == 2, "mutating read result must not mutate persisted data")

	var invalid := first.duplicate(true)
	invalid["schema_version"] = 99
	_expect(repository.save(invalid).status == RepositoryResult.Status.INVALID_DATA, "invalid DTO must be rejected before file mutation")
	_expect(_has_wood(repository.load_snapshot().snapshot, 2), "invalid write must preserve primary")
	_expect(repository.save(second).status == RepositoryResult.Status.SAVED, "replacement save must succeed")
	_expect(FileAccess.file_exists("%s.bak" % primary), "replacement must retain the previous valid primary as backup")

	var corrupt := FileAccess.open(primary, FileAccess.WRITE)
	if corrupt == null:
		_failures.append("unable to create corrupt-primary fixture")
	else:
		corrupt.store_string("{broken json")
		corrupt.close()
	var recovered: RefCounted = repository.load_snapshot()
	_expect(recovered.status == RepositoryResult.Status.RECOVERED_BACKUP and _has_wood(recovered.snapshot, 2), "corrupt primary must recover the last valid backup without rewriting files")
	_expect(repository.save(second).status == RepositoryResult.Status.SAVED, "save after recovery must replace corrupt primary")
	_expect(_has_wood(repository.load_snapshot().snapshot, 7), "new primary after recovery must be readable")
	_expect(_read_raw("%s.bak" % primary) == JSON.stringify(first) + "\n", "save after recovery must preserve the valid backup")
	_cleanup(directory, primary)

	if _failures.is_empty():
		print("Save repository validation passed: atomic replacement and backup recovery are valid.")
		quit(0)
	else:
		for failure in _failures:
			printerr("SAVE REPOSITORY VALIDATION FAILURE: %s" % failure)
		quit(1)


func _read_raw(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var value := file.get_as_text()
	file.close()
	return value


func _has_wood(snapshot: Dictionary, expected: int) -> bool:
	return Schema.validate(snapshot).is_valid() and int(snapshot.get("inventory", {}).get("item.wood", -1)) == expected


func _cleanup(directory: String, primary: String) -> void:
	for path in [primary, "%s.bak" % primary, "%s.tmp" % primary]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
