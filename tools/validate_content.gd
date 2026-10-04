extends SceneTree

const CONTENT_ROOT := "res://data/definitions"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_content_ids()
	_test_registry_contract()
	_test_definition_validation()
	_test_missing_reference_validation()
	_validate_project_content()

	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame

	if _failures.is_empty():
		print("Content validation passed: U1.3 item/recipe/building/crop catalog and registry references are valid.")
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


func _test_definition_validation() -> void:
	var invalid_amount := ItemAmount.new()
	invalid_amount.item_id = &"building.not_an_item"
	invalid_amount.quantity = 0
	var amount_errors := invalid_amount.get_validation_errors("test")
	_expect(amount_errors.size() == 2, "ItemAmount must reject wrong domain and non-positive quantity")

	var invalid_recipe := RecipeDefinition.new()
	invalid_recipe.content_id = &"item.not_a_recipe"
	invalid_recipe.display_name_key = &"item.not_a_recipe.name"
	invalid_recipe.station_id = &"item.not_a_station"
	invalid_recipe.craft_time_seconds = 0.0
	var recipe_errors := invalid_recipe.get_validation_errors()
	_expect(_contains_message(recipe_errors, "recipe domain"), "RecipeDefinition must reject the wrong domain")
	_expect(_contains_message(recipe_errors, "inputs are required"), "RecipeDefinition must require inputs")
	_expect(_contains_message(recipe_errors, "output is required"), "RecipeDefinition must require output")
	_expect(_contains_message(recipe_errors, "building domain"), "RecipeDefinition must reject a non-building station")
	_expect(_contains_message(recipe_errors, "craft_time_seconds"), "RecipeDefinition must require positive craft time")

	var invalid_building := BuildingDefinition.new()
	invalid_building.content_id = &"item.not_a_building"
	invalid_building.display_name_key = &"item.not_a_building.name"
	invalid_building.max_health = 0
	var building_errors := invalid_building.get_validation_errors()
	_expect(_contains_message(building_errors, "building domain"), "BuildingDefinition must reject the wrong domain")
	_expect(_contains_message(building_errors, "scene is required"), "BuildingDefinition must require a scene")
	_expect(_contains_message(building_errors, "max_health"), "BuildingDefinition must require positive health")

	var invalid_crop := CropDefinition.new()
	invalid_crop.content_id = &"item.not_a_crop"
	invalid_crop.display_name_key = &"item.not_a_crop.name"
	invalid_crop.seed_item_id = &"crop.not_a_seed"
	invalid_crop.harvest_item_id = &"building.not_a_harvest"
	invalid_crop.growth_time_seconds = 0.0
	invalid_crop.harvest_yield_min = 2
	invalid_crop.harvest_yield_max = 1
	var crop_errors := invalid_crop.get_validation_errors()
	_expect(_contains_message(crop_errors, "crop domain"), "CropDefinition must reject the wrong domain")
	_expect(_contains_message(crop_errors, "seed_item_id"), "CropDefinition must require an item seed")
	_expect(_contains_message(crop_errors, "harvest_item_id"), "CropDefinition must require an item harvest")
	_expect(_contains_message(crop_errors, "growth_time_seconds"), "CropDefinition must require positive growth time")
	_expect(_contains_message(crop_errors, "harvest_yield_max"), "CropDefinition must reject an inverted yield range")


func _test_missing_reference_validation() -> void:
	var input := ItemAmount.new()
	input.item_id = &"item.missing_input"
	input.quantity = 1
	var output := ItemAmount.new()
	output.item_id = &"item.missing_output"
	output.quantity = 1
	var recipe := RecipeDefinition.new()
	recipe.content_id = &"recipe.reference_test"
	recipe.display_name_key = &"recipe.reference_test.name"
	recipe.inputs = [input]
	recipe.output = output
	recipe.station_id = &"building.missing_station"
	recipe.craft_time_seconds = 1.0

	var registry := ContentRegistry.new()
	_expect(registry.try_register(recipe), "locally valid recipe should register before reference validation")
	_expect(not registry.validate_references(), "registry must reject missing cross-references")
	var errors := registry.get_errors()
	_expect(_contains_message(errors, "building.missing_station"), "missing station reference should be reported")
	_expect(_contains_message(errors, "item.missing_input"), "missing input reference should be reported")
	_expect(_contains_message(errors, "item.missing_output"), "missing output reference should be reported")


func _validate_project_content() -> void:
	var registry := ContentRegistry.new()
	if not registry.load_directory(CONTENT_ROOT):
		for message in registry.get_errors():
			_failures.append(message)
		return

	_expect(registry.size() == 8, "registry must contain the eight U1.3 canary definitions")
	_expect(registry.has(&"item.wood"), "registry is missing item.wood")
	_expect(registry.has(&"item.pal_ore"), "registry is missing item.pal_ore")
	_expect(registry.has(&"item.pal_sphere.basic"), "registry is missing item.pal_sphere.basic")
	_expect(registry.has(&"item.berry_seed"), "registry is missing item.berry_seed")
	_expect(registry.has(&"item.berry"), "registry is missing item.berry")
	_expect(registry.has(&"recipe.pal_sphere.basic"), "registry is missing recipe.pal_sphere.basic")
	_expect(registry.has(&"building.workbench"), "registry is missing building.workbench")
	_expect(registry.has(&"crop.berry"), "registry is missing crop.berry")
	var wood := registry.get_definition(&"item.wood") as ItemDefinition
	_expect(wood != null, "item.wood must load as ItemDefinition")
	if wood != null:
		_expect(wood.max_stack == 999, "item.wood max_stack mismatch")
		_expect(wood.icon != null, "item.wood icon should resolve")
	var recipe := registry.get_definition(&"recipe.pal_sphere.basic") as RecipeDefinition
	_expect(recipe != null, "recipe.pal_sphere.basic must load as RecipeDefinition")
	if recipe != null:
		_expect(recipe.inputs.size() == 2, "basic sphere recipe input count mismatch")
		_expect(recipe.output != null and recipe.output.item_id == &"item.pal_sphere.basic", "basic sphere output mismatch")
		_expect(recipe.station_id == &"building.workbench", "basic sphere station mismatch")
	var building := registry.get_definition(&"building.workbench") as BuildingDefinition
	_expect(building != null, "building.workbench must load as BuildingDefinition")
	if building != null:
		_expect(building.scene != null, "workbench scene should resolve")
		_expect(building.supported_recipe_ids.has(&"recipe.pal_sphere.basic"), "workbench recipe link mismatch")
	var crop := registry.get_definition(&"crop.berry") as CropDefinition
	_expect(crop != null, "crop.berry must load as CropDefinition")
	if crop != null:
		_expect(crop.seed_item_id == &"item.berry_seed", "berry crop seed mismatch")
		_expect(crop.harvest_item_id == &"item.berry", "berry crop harvest mismatch")
		_expect(crop.harvest_yield_min == 3 and crop.harvest_yield_max == 5, "berry crop yield mismatch")


func _contains_message(messages: PackedStringArray, fragment: String) -> bool:
	for message in messages:
		if fragment in message:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(exit_code: int) -> void:
	quit(exit_code)
