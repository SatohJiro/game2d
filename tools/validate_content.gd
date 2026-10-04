extends SceneTree

const CONTENT_ROOT := "res://data/definitions"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_content_ids()
	_test_registry_contract()
	_validate_project_content()

	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame

	if _failures.is_empty():
		print("Content validation passed: item.wood canary and registry contract are valid.")
		_finish.call_deferred(0)
	else:
		for failure in _failures:
			printerr("CONTENT VALIDATION FAILURE: %s" % failure)
		_finish.call_deferred(1)


func _test_content_ids() -> void:
	_expect(ContentId.is_valid(&"item.wood"), "item.wood should be a valid content ID")
	_expect(ContentId.is_valid(&"creature.foxfire.elite"), "multi-segment IDs should be valid")
	_expect(not ContentId.is_valid(&"Gỗ"), "display text must not be a content ID")
	_expect(not ContentId.is_valid(&"item"), "content IDs require a domain and local name")
	_expect(not ContentId.is_valid(&"Item.Wood"), "content IDs must be lowercase ASCII")
	_expect(ContentId.make("item", "wood") == &"item.wood", "ContentId.make should create valid IDs")
	_expect(ContentId.domain_of(&"item.wood") == &"item", "domain extraction failed")
	_expect(ContentId.local_name_of(&"item.wood") == &"wood", "local-name extraction failed")


func _test_registry_contract() -> void:
	var registry := ContentRegistry.new()
	var first := ContentDefinition.new()
	first.content_id = &"test.duplicate"
	first.display_name_key = &"test.duplicate.name"
	var duplicate := ContentDefinition.new()
	duplicate.content_id = &"test.duplicate"
	duplicate.display_name_key = &"test.duplicate.copy_name"
	_expect(registry.try_register(first), "first definition should register")
	_expect(not registry.try_register(duplicate), "duplicate definition should be rejected")
	_expect(registry.size() == 1, "duplicate registration must not replace the original")


func _validate_project_content() -> void:
	var registry := ContentRegistry.new()
	if not registry.load_directory(CONTENT_ROOT):
		for message in registry.get_errors():
			_failures.append(message)
		return

	_expect(registry.size() >= 1, "registry must contain at least the U1.1 canary definition")
	_expect(registry.has(&"item.wood"), "registry is missing item.wood")
	var wood := registry.get_definition(&"item.wood") as ItemDefinition
	_expect(wood != null, "item.wood must load as ItemDefinition")
	if wood != null:
		_expect(wood.max_stack == 999, "item.wood max_stack mismatch")
		_expect(wood.icon != null, "item.wood icon should resolve")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(exit_code: int) -> void:
	quit(exit_code)
