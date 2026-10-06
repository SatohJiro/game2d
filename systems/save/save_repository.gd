class_name SaveRepository
extends RefCounted

const Schema = preload("res://systems/save/save_v1_schema.gd")
const RepositoryResult = preload("res://systems/save/save_repository_result.gd")

var primary_path: String
var backup_path: String
var temp_path: String


func _init(p_primary_path: String) -> void:
	primary_path = p_primary_path
	backup_path = "%s.bak" % p_primary_path
	temp_path = "%s.tmp" % p_primary_path


func save(snapshot: Variant) -> RefCounted:
	var validation: RefCounted = Schema.validate(snapshot)
	if not validation.is_valid():
		return RepositoryResult.new(RepositoryResult.Status.INVALID_DATA, {}, validation.errors)
	var directory_error := _ensure_parent_directory()
	if directory_error != OK:
		return RepositoryResult.new(RepositoryResult.Status.IO_ERROR, {}, PackedStringArray(["unable to create save directory: %s" % error_string(directory_error)]))
	_cleanup_temp()
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return RepositoryResult.new(RepositoryResult.Status.IO_ERROR, {}, PackedStringArray(["unable to open temporary save file"]))
	file.store_string(JSON.stringify(snapshot) + "\n")
	file.flush()
	file.close()
	var temp_read: RefCounted = _read_file(temp_path, RepositoryResult.Status.LOADED_PRIMARY)
	if not temp_read.is_success():
		_cleanup_temp()
		return RepositoryResult.new(RepositoryResult.Status.IO_ERROR, {}, PackedStringArray(["temporary save verification failed"]))

	var primary_absolute := _absolute(primary_path)
	var backup_absolute := _absolute(backup_path)
	var temp_absolute := _absolute(temp_path)
	if FileAccess.file_exists(primary_path):
		var current_primary: RefCounted = _read_file(primary_path, RepositoryResult.Status.LOADED_PRIMARY)
		if current_primary.is_success():
			if FileAccess.file_exists(backup_path) and DirAccess.remove_absolute(backup_absolute) != OK:
				_cleanup_temp()
				return RepositoryResult.new(RepositoryResult.Status.IO_ERROR, {}, PackedStringArray(["unable to replace backup save"]))
			if DirAccess.rename_absolute(primary_absolute, backup_absolute) != OK:
				_cleanup_temp()
				return RepositoryResult.new(RepositoryResult.Status.IO_ERROR, {}, PackedStringArray(["unable to rotate primary save to backup"]))
		else:
			if DirAccess.remove_absolute(primary_absolute) != OK:
				_cleanup_temp()
				return RepositoryResult.new(RepositoryResult.Status.IO_ERROR, {}, PackedStringArray(["unable to remove corrupt primary save"]))
	if DirAccess.rename_absolute(temp_absolute, primary_absolute) != OK:
		if not FileAccess.file_exists(primary_path) and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_absolute, primary_absolute)
		_cleanup_temp()
		return RepositoryResult.new(RepositoryResult.Status.IO_ERROR, {}, PackedStringArray(["unable to promote temporary save"]))
	return RepositoryResult.new(RepositoryResult.Status.SAVED)


func load_snapshot() -> RefCounted:
	if FileAccess.file_exists(primary_path):
		var primary := _read_file(primary_path, RepositoryResult.Status.LOADED_PRIMARY)
		if primary.is_success():
			return primary
	if FileAccess.file_exists(backup_path):
		var backup := _read_file(backup_path, RepositoryResult.Status.RECOVERED_BACKUP)
		if backup.is_success():
			return backup
		return backup
	if FileAccess.file_exists(primary_path):
		return _read_file(primary_path, RepositoryResult.Status.LOADED_PRIMARY)
	return RepositoryResult.new(RepositoryResult.Status.NOT_FOUND)


func _read_file(path: String, success_status: int) -> RefCounted:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return RepositoryResult.new(RepositoryResult.Status.IO_ERROR, {}, PackedStringArray(["unable to read save file"]))
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return RepositoryResult.new(RepositoryResult.Status.INVALID_DATA, {}, PackedStringArray(["invalid JSON at line %d" % parser.get_error_line()]))
	var decoded: Variant = parser.data
	var validation: RefCounted = Schema.validate(decoded)
	if not validation.is_valid():
		return RepositoryResult.new(RepositoryResult.Status.INVALID_DATA, {}, validation.errors)
	return RepositoryResult.new(success_status, decoded)


func _ensure_parent_directory() -> Error:
	var parent := primary_path.get_base_dir()
	if parent.is_empty():
		return OK
	return DirAccess.make_dir_recursive_absolute(_absolute(parent))


func _cleanup_temp() -> void:
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(_absolute(temp_path))


func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path)
