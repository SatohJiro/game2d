class_name ContentRegistry
extends RefCounted

var _definitions: Dictionary = {}
var _errors := PackedStringArray()


func clear() -> void:
	_definitions.clear()
	_errors.clear()


func try_register(definition: ContentDefinition) -> bool:
	if definition == null:
		_errors.append("Cannot register a null ContentDefinition.")
		return false

	var validation_errors := definition.get_validation_errors()
	if not validation_errors.is_empty():
		for message in validation_errors:
			_errors.append("%s: %s" % [definition.resource_path, message])
		return false

	if _definitions.has(definition.content_id):
		var existing := _definitions[definition.content_id] as ContentDefinition
		_errors.append(
			"Duplicate content_id %s: %s and %s" % [
				definition.content_id,
				existing.resource_path,
				definition.resource_path,
			]
		)
		return false

	_definitions[definition.content_id] = definition
	return true


func load_directory(root_path: String) -> bool:
	clear()
	var resource_paths: Array[String] = []
	_collect_resource_paths(root_path, resource_paths)
	resource_paths.sort()

	for resource_path in resource_paths:
		var loaded := ResourceLoader.load(resource_path)
		var definition := loaded as ContentDefinition
		if definition == null:
			_errors.append("Resource is not a ContentDefinition: %s" % resource_path)
			continue
		try_register(definition)

	validate_references()

	return _errors.is_empty()


func validate_references() -> bool:
	var definition_ids := get_all_ids()
	for definition_id in definition_ids:
		var definition := _definitions[definition_id] as ContentDefinition
		var referenced_ids := definition.get_referenced_content_ids()
		referenced_ids.sort()
		for referenced_id in referenced_ids:
			if ContentId.is_valid(referenced_id) and not _definitions.has(referenced_id):
				_errors.append(
					"Missing content reference %s from %s (%s)" % [
						referenced_id,
						definition.content_id,
						definition.resource_path,
					]
				)
	return _errors.is_empty()


func has(content_id: StringName) -> bool:
	return _definitions.has(content_id)


func get_definition(content_id: StringName) -> ContentDefinition:
	return _definitions.get(content_id) as ContentDefinition


func get_definitions_for_domain(domain: StringName) -> Array[ContentDefinition]:
	var matches: Array[ContentDefinition] = []
	for definition in _definitions.values():
		var typed_definition := definition as ContentDefinition
		if typed_definition.get_content_kind() == domain:
			matches.append(typed_definition)
	return matches


func get_all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for content_id in _definitions.keys():
		ids.append(content_id as StringName)
	ids.sort()
	return ids


func get_errors() -> PackedStringArray:
	return _errors.duplicate()


func size() -> int:
	return _definitions.size()


func _collect_resource_paths(directory_path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		_errors.append("Unable to open content directory: %s" % directory_path)
		return

	for child_directory in directory.get_directories():
		_collect_resource_paths(directory_path.path_join(child_directory), output)
	for file_name in directory.get_files():
		var extension := file_name.get_extension().to_lower()
		if extension == "tres" or extension == "res":
			output.append(directory_path.path_join(file_name))
