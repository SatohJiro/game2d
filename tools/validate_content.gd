extends SceneTree

const CONTENT_ROOT := "res://data/definitions"
const RuntimeInventoryManifest = preload("res://data/runtime_inventory_manifest.gd")

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
		print("Content validation passed: catalog plus all five typed creature definitions and registry references are valid.")
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
	_expect(LegacyItemAdapter.to_content_id("Hạt Giống Cây") == &"item.berry_seed", "berry seed legacy key must map to stable ID")
	_expect(LegacyItemAdapter.to_legacy_key(&"item.berry_seed") == "Hạt Giống Cây", "berry seed stable ID must preserve legacy key")
	_expect(LegacyItemAdapter.to_content_id("Đá") == &"item.stone", "stone legacy key must map to stable ID")
	_expect(LegacyItemAdapter.to_content_id("Thỏi Sắt") == &"item.iron_ingot", "iron ingot legacy key must map to stable ID")


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

	var invalid_behavior := CreatureBehaviorProfile.new()
	invalid_behavior.is_predator = true
	invalid_behavior.is_prey = true
	var invalid_creature := CreatureDefinition.new()
	invalid_creature.content_id = &"item.not_a_creature"
	invalid_creature.display_name_key = &"creature.invalid.name"
	invalid_creature.base_max_hp = 0
	invalid_creature.move_speed = NAN
	invalid_creature.base_attack_power = 0
	invalid_creature.behavior_profile = invalid_behavior
	invalid_creature.drop_item_id = &"creature.not_an_item"
	var creature_errors := invalid_creature.get_validation_errors()
	_expect(_contains_message(creature_errors, "creature domain"), "CreatureDefinition must reject the wrong domain")
	_expect(_contains_message(creature_errors, "base_max_hp"), "CreatureDefinition must require positive health")
	_expect(_contains_message(creature_errors, "move_speed"), "CreatureDefinition must require finite positive speed")
	_expect(_contains_message(creature_errors, "base_attack_power"), "CreatureDefinition must require positive attack power")
	_expect(_contains_message(creature_errors, "both predator and prey"), "Creature behavior profile must reject conflicting ecology roles")
	_expect(_contains_message(creature_errors, "drop_item_id"), "CreatureDefinition must require an item drop reference")

	var invalid_skill := SkillDefinition.new()
	invalid_skill.content_id = &"creature.not_a_skill"
	invalid_skill.display_name_key = &"skill.invalid.name"
	invalid_skill.cooldown_seconds = 0.0
	invalid_skill.damage_multiplier = NAN
	invalid_skill.travel_distance = 0.0
	invalid_skill.travel_seconds = 0.0
	invalid_skill.hit_radius = 0.0
	var skill_errors := invalid_skill.get_validation_errors()
	_expect(_contains_message(skill_errors, "skill domain"), "SkillDefinition must reject the wrong domain")
	_expect(_contains_message(skill_errors, "cooldown_seconds"), "SkillDefinition must require positive cooldown")
	_expect(_contains_message(skill_errors, "damage_multiplier"), "SkillDefinition must require finite positive damage scaling")
	_expect(_contains_message(skill_errors, "travel_distance"), "Projectile skill must require travel distance")
	_expect(_contains_message(skill_errors, "travel_seconds"), "Projectile skill must require travel time")
	_expect(_contains_message(skill_errors, "hit_radius"), "Projectile skill must require a hit radius")


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
	var behavior := CreatureBehaviorProfile.new()
	var creature := CreatureDefinition.new()
	creature.content_id = &"creature.reference_test"
	creature.display_name_key = &"creature.reference_test.name"
	creature.base_max_hp = 10
	creature.move_speed = 10.0
	creature.base_attack_power = 1
	creature.behavior_profile = behavior
	creature.drop_item_id = &"item.missing_creature_drop"
	creature.skill_ids = [&"skill.missing_creature_skill"]
	_expect(registry.try_register(creature), "locally valid creature should register before reference validation")
	_expect(not registry.validate_references(), "registry must reject missing cross-references")
	var errors := registry.get_errors()
	_expect(_contains_message(errors, "building.missing_station"), "missing station reference should be reported")
	_expect(_contains_message(errors, "item.missing_input"), "missing input reference should be reported")
	_expect(_contains_message(errors, "item.missing_output"), "missing output reference should be reported")
	_expect(_contains_message(errors, "item.missing_creature_drop"), "missing creature drop reference should be reported")
	_expect(_contains_message(errors, "skill.missing_creature_skill"), "missing creature skill reference should be reported")


func _validate_project_content() -> void:
	var registry := ContentRegistry.new()
	if not registry.load_directory(CONTENT_ROOT):
		for message in registry.get_errors():
			_failures.append(message)
		return

	_expect(registry.size() == 44, "registry must contain forty-four definitions through U2.1")
	_validate_runtime_inventory_manifest(registry)
	_expect(registry.has(&"item.wood"), "registry is missing item.wood")
	_expect(registry.has(&"item.pal_ore"), "registry is missing item.pal_ore")
	_expect(registry.has(&"item.pal_sphere.basic"), "registry is missing item.pal_sphere.basic")
	_expect(registry.has(&"item.pal_sphere.mega"), "registry is missing item.pal_sphere.mega")
	_expect(registry.has(&"item.pal_sphere.giga"), "registry is missing item.pal_sphere.giga")
	_expect(registry.has(&"item.berry_seed"), "registry is missing item.berry_seed")
	_expect(registry.has(&"item.berry"), "registry is missing item.berry")
	_expect(registry.has(&"item.fresh_meat"), "registry is missing item.fresh_meat")
	_expect(registry.has(&"item.pal_ingot"), "registry is missing item.pal_ingot")
	_expect(registry.has(&"item.stone"), "registry is missing item.stone")
	_expect(registry.has(&"item.iron_ingot"), "registry is missing item.iron_ingot")
	_expect(registry.has(&"recipe.pal_sphere.basic"), "registry is missing recipe.pal_sphere.basic")
	_expect(registry.has(&"building.workbench"), "registry is missing building.workbench")
	_expect(registry.has(&"crop.berry"), "registry is missing crop.berry")
	_expect(registry.has(&"crop.golden_wheat") and registry.has(&"crop.pal_herb"), "registry is missing U1.12k crop definitions")
	_expect(registry.has(&"creature.flam"), "registry is missing creature.flam")
	_expect(registry.has(&"creature.slime"), "registry is missing creature.slime")
	_expect(registry.has(&"creature.mushroom"), "registry is missing creature.mushroom")
	_expect(registry.has(&"creature.beast"), "registry is missing creature.beast")
	_expect(registry.has(&"creature.dragon"), "registry is missing creature.dragon")
	_expect(registry.has(&"skill.flam.fireball"), "registry is missing skill.flam.fireball")
	_expect(registry.has(&"skill.dragon.fireball"), "registry is missing skill.dragon.fireball")
	_expect(registry.has(&"skill.mushroom.spore"), "registry is missing skill.mushroom.spore")
	_expect(registry.has(&"biome.paloria_meadow"), "registry is missing biome.paloria_meadow")
	_expect(registry.has(&"chunk.paloria_origin"), "registry is missing chunk.paloria_origin")
	var origin_chunk := registry.get_definition(&"chunk.paloria_origin") as ChunkDefinition
	_expect(origin_chunk != null and origin_chunk.coordinate == Vector2i.ZERO, "origin chunk definition mismatch")
	_expect(origin_chunk != null and origin_chunk.biome_id == &"biome.paloria_meadow", "origin chunk biome reference mismatch")
	var wood := registry.get_definition(&"item.wood") as ItemDefinition
	_expect(wood != null, "item.wood must load as ItemDefinition")
	if wood != null:
		_expect(wood.max_stack == 999, "item.wood max_stack mismatch")
		_expect(wood.icon != null, "item.wood icon should resolve")
	var mega_sphere := registry.get_definition(&"item.pal_sphere.mega") as ItemDefinition
	var giga_sphere := registry.get_definition(&"item.pal_sphere.giga") as ItemDefinition
	_expect(mega_sphere != null and mega_sphere.icon != null and mega_sphere.tags.has("mega"), "mega sphere definition mismatch")
	_expect(giga_sphere != null and giga_sphere.icon != null and giga_sphere.tags.has("giga"), "giga sphere definition mismatch")
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
	var flam := registry.get_definition(&"creature.flam") as CreatureDefinition
	_expect(flam != null, "creature.flam must load as CreatureDefinition")
	if flam != null:
		_expect(flam.base_max_hp == 80, "Flam base_max_hp mismatch")
		_expect(is_equal_approx(flam.move_speed, 105.0), "Flam move_speed mismatch")
		_expect(flam.base_attack_power == 14, "Flam base_attack_power mismatch")
		_expect(flam.behavior_profile != null and not flam.behavior_profile.is_predator and not flam.behavior_profile.is_prey, "Flam behavior profile mismatch")
		_expect(flam.drop_item_id == &"item.pal_ore", "Flam drop reference mismatch")
		_expect(flam.skill_ids == [&"skill.flam.fireball"], "Flam skill reference mismatch")
	var slime := registry.get_definition(&"creature.slime") as CreatureDefinition
	_expect(slime != null, "creature.slime must load as CreatureDefinition")
	if slime != null:
		_expect(slime.base_max_hp == 110, "Slime base_max_hp mismatch")
		_expect(is_equal_approx(slime.move_speed, 85.0), "Slime move_speed mismatch")
		_expect(slime.base_attack_power == 9, "Slime base_attack_power mismatch")
		_expect(slime.behavior_profile != null and not slime.behavior_profile.is_predator and slime.behavior_profile.is_prey, "Slime behavior profile mismatch")
		_expect(slime.drop_item_id == &"item.berry", "Slime drop reference mismatch")
		_expect(slime.skill_ids == [&"skill.slime.hop"], "Slime hop reference mismatch")
	var mushroom := registry.get_definition(&"creature.mushroom") as CreatureDefinition
	_expect(mushroom != null, "creature.mushroom must load as CreatureDefinition")
	if mushroom != null:
		_expect(mushroom.base_max_hp == 90, "Mushroom base_max_hp mismatch")
		_expect(is_equal_approx(mushroom.move_speed, 95.0), "Mushroom move_speed mismatch")
		_expect(mushroom.base_attack_power == 11, "Mushroom base_attack_power mismatch")
		_expect(mushroom.behavior_profile != null and not mushroom.behavior_profile.is_predator and mushroom.behavior_profile.is_prey, "Mushroom behavior profile mismatch")
		_expect(mushroom.drop_item_id == &"item.berry_seed", "Mushroom drop reference mismatch")
		_expect(mushroom.skill_ids == [&"skill.mushroom.spore"], "Mushroom spore reference mismatch")
	var fresh_meat := registry.get_definition(&"item.fresh_meat") as ItemDefinition
	_expect(fresh_meat != null and fresh_meat.icon != null and fresh_meat.tags.has("meat"), "fresh meat definition mismatch")
	_expect(LegacyItemAdapter.to_content_id("Thịt Tươi") == &"item.fresh_meat", "fresh meat legacy key must map to stable ID")
	_expect(LegacyItemAdapter.to_legacy_key(&"item.fresh_meat") == "Thịt Tươi", "fresh meat stable ID must preserve legacy storage key")
	var beast := registry.get_definition(&"creature.beast") as CreatureDefinition
	_expect(beast != null, "creature.beast must load as CreatureDefinition")
	if beast != null:
		_expect(beast.base_max_hp == 130, "Beast base_max_hp mismatch")
		_expect(is_equal_approx(beast.move_speed, 115.0), "Beast move_speed mismatch")
		_expect(beast.base_attack_power == 16, "Beast base_attack_power mismatch")
		_expect(beast.behavior_profile != null and beast.behavior_profile.is_predator and not beast.behavior_profile.is_prey, "Beast behavior profile mismatch")
		_expect(beast.drop_item_id == &"item.fresh_meat", "Beast drop reference mismatch")
		_expect(beast.skill_ids == [&"skill.beast.charge", &"skill.beast.melee"], "Beast skill references mismatch")
	var pal_ingot := registry.get_definition(&"item.pal_ingot") as ItemDefinition
	_expect(pal_ingot != null and pal_ingot.icon != null and pal_ingot.tags.has("ingot"), "Pal ingot definition mismatch")
	_expect(LegacyItemAdapter.to_content_id("Thỏi Pal") == &"item.pal_ingot", "Pal ingot legacy key must map to stable ID")
	_expect(LegacyItemAdapter.to_legacy_key(&"item.pal_ingot") == "Thỏi Pal", "Pal ingot stable ID must preserve legacy storage key")
	var dragon := registry.get_definition(&"creature.dragon") as CreatureDefinition
	_expect(dragon != null, "creature.dragon must load as CreatureDefinition")
	if dragon != null:
		_expect(dragon.base_max_hp == 340, "Dragon base_max_hp mismatch")
		_expect(is_equal_approx(dragon.move_speed, 95.0), "Dragon move_speed mismatch")
		_expect(dragon.base_attack_power == 26, "Dragon base_attack_power mismatch")
		_expect(dragon.behavior_profile != null and dragon.behavior_profile.is_predator and not dragon.behavior_profile.is_prey, "Dragon behavior profile mismatch")
		_expect(dragon.drop_item_id == &"item.pal_ingot", "Dragon drop reference mismatch")
		_expect(dragon.skill_ids == [&"skill.dragon.fireball", &"skill.dragon.melee"], "Dragon skill references mismatch")
	var fireball := registry.get_definition(&"skill.flam.fireball") as SkillDefinition
	_expect(fireball != null, "skill.flam.fireball must load as SkillDefinition")
	if fireball != null:
		_expect(fireball.delivery == SkillDefinition.Delivery.PROJECTILE, "Flam fireball delivery mismatch")
		_expect(is_equal_approx(fireball.cooldown_seconds, 2.2), "Flam fireball cooldown mismatch")
		_expect(is_equal_approx(fireball.recovery_seconds, 0.3), "Flam fireball recovery mismatch")
		_expect(is_equal_approx(fireball.damage_multiplier, 1.0), "Flam fireball damage scaling mismatch")
		_expect(is_equal_approx(fireball.travel_distance, 240.0), "Flam fireball distance mismatch")
		_expect(is_equal_approx(fireball.travel_seconds, 0.55), "Flam fireball travel time mismatch")
		_expect(is_equal_approx(fireball.hit_radius, 45.0), "Flam fireball hit radius mismatch")
	var dragon_fireball := registry.get_definition(&"skill.dragon.fireball") as SkillDefinition
	_expect(dragon_fireball != null, "skill.dragon.fireball must load as SkillDefinition")
	if dragon_fireball != null:
		_expect(dragon_fireball.delivery == SkillDefinition.Delivery.PROJECTILE, "Dragon fireball delivery mismatch")
		_expect(is_equal_approx(dragon_fireball.cooldown_seconds, 2.2), "Dragon fireball cooldown mismatch")
		_expect(is_equal_approx(dragon_fireball.recovery_seconds, 0.3), "Dragon fireball recovery mismatch")
		_expect(is_equal_approx(dragon_fireball.damage_multiplier, 1.0), "Dragon fireball damage scaling mismatch")
		_expect(is_equal_approx(dragon_fireball.travel_distance, 240.0), "Dragon fireball distance mismatch")
		_expect(is_equal_approx(dragon_fireball.travel_seconds, 0.55), "Dragon fireball travel time mismatch")
		_expect(is_equal_approx(dragon_fireball.hit_radius, 45.0), "Dragon fireball hit radius mismatch")
	var mushroom_spore := registry.get_definition(&"skill.mushroom.spore") as SkillDefinition
	_expect(mushroom_spore != null, "skill.mushroom.spore must load as SkillDefinition")
	if mushroom_spore != null:
		_expect(is_equal_approx(mushroom_spore.cooldown_seconds, 2.0), "Mushroom spore cooldown mismatch")
		_expect(is_equal_approx(mushroom_spore.recovery_seconds, 0.25), "Mushroom spore recovery mismatch")
		_expect(is_equal_approx(mushroom_spore.damage_multiplier, 1.0), "Mushroom spore damage mismatch")
		_expect(is_equal_approx(mushroom_spore.travel_distance, 200.0) and is_equal_approx(mushroom_spore.travel_seconds, 0.5), "Mushroom spore travel mismatch")
		_expect(is_equal_approx(mushroom_spore.hit_radius, 45.0), "Mushroom spore hit radius mismatch")
	var slime_hop := registry.get_definition(&"skill.slime.hop") as HopSkillDefinition
	_expect(slime_hop != null, "skill.slime.hop must load as HopSkillDefinition")
	if slime_hop != null:
		_expect(is_equal_approx(slime_hop.cooldown_seconds, 1.15), "Slime hop cooldown mismatch")
		_expect(is_equal_approx(slime_hop.hop_speed, 260.0) and is_equal_approx(slime_hop.hop_height, 12.0), "Slime hop movement mismatch")
		_expect(is_equal_approx(slime_hop.compress_seconds, 0.15) and is_equal_approx(slime_hop.launch_seconds, 0.12), "Slime hop launch timing mismatch")
		_expect(is_equal_approx(slime_hop.land_seconds, 0.15) and is_equal_approx(slime_hop.settle_seconds, 0.1), "Slime hop landing timing mismatch")
	var beast_charge := registry.get_definition(&"skill.beast.charge") as ChargeSkillDefinition
	_expect(beast_charge != null, "skill.beast.charge must load as ChargeSkillDefinition")
	if beast_charge != null:
		_expect(is_equal_approx(beast_charge.minimum_range, 70.0) and is_equal_approx(beast_charge.maximum_range, 220.0), "Beast charge range mismatch")
		_expect(is_equal_approx(beast_charge.anticipation_seconds, 0.45) and is_equal_approx(beast_charge.cooldown_seconds, 3.5), "Beast charge entry timing mismatch")
		_expect(is_equal_approx(beast_charge.charge_speed, 330.0) and is_equal_approx(beast_charge.charge_seconds, 0.95), "Beast charge movement mismatch")
		_expect(is_equal_approx(beast_charge.stun_seconds, 1.4), "Beast charge stun mismatch")
	var beast_melee := registry.get_definition(&"skill.beast.melee") as MeleeSkillDefinition
	var dragon_melee := registry.get_definition(&"skill.dragon.melee") as MeleeSkillDefinition
	_expect(beast_melee != null and dragon_melee != null, "species melee definitions must load")
	if beast_melee != null and dragon_melee != null:
		_expect(beast_melee.content_id != dragon_melee.content_id, "Beast and Dragon melee require separate identities")
		_expect(is_equal_approx(beast_melee.activation_range, 38.0) and is_equal_approx(dragon_melee.activation_range, 48.0), "melee activation range mismatch")
		_expect(is_equal_approx(beast_melee.cooldown_seconds, 1.2) and is_equal_approx(beast_melee.lunge_speed, 180.0), "melee timing/movement mismatch")
		_expect(is_equal_approx(beast_melee.contact_range, 55.0) and is_equal_approx(beast_melee.anticipation_seconds, 0.2), "melee contact mismatch")


func _validate_runtime_inventory_manifest(registry: ContentRegistry) -> void:
	for group_name: Variant in RuntimeInventoryManifest.GROUPS:
		var group_keys: Variant = RuntimeInventoryManifest.GROUPS[group_name]
		_expect(group_keys is Array and not group_keys.is_empty(), "runtime inventory group %s must not be empty" % group_name)
		if not group_keys is Array:
			continue
		for legacy_key: Variant in group_keys:
			var key := String(legacy_key)
			var content_id := LegacyItemAdapter.to_content_id(key)
			_expect(ContentId.domain_of(content_id) == &"item", "%s runtime key '%s' must map to an item ID" % [group_name, key])
			_expect(LegacyItemAdapter.is_mapped(content_id), "%s runtime item '%s' must have a reverse mapping" % [group_name, content_id])
			_expect(LegacyItemAdapter.to_legacy_key(content_id) == key, "%s runtime item '%s' must round-trip its legacy key" % [group_name, content_id])
			var definition := registry.get_definition(content_id) as ItemDefinition
			_expect(definition != null, "%s runtime item '%s' must have a typed ItemDefinition" % [group_name, content_id])


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
