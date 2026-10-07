extends SceneTree

const Schema = preload("res://systems/save/save_v1_schema.gd")
const ValidationResult = preload("res://systems/save/save_validation_result.gd")
const SnapshotAdapter = preload("res://systems/save/save_snapshot_adapter.gd")
const SnapshotResult = preload("res://systems/save/save_snapshot_result.gd")
const ApplyAdapter = preload("res://systems/save/save_apply_adapter.gd")
const ApplyResult = preload("res://systems/save/save_apply_result.gd")
const RuntimeInventoryManifest = preload("res://data/runtime_inventory_manifest.gd")
const PetMetadata = preload("res://systems/pet/pet_metadata_catalog.gd")
const BaseProgressStateModel = preload("res://systems/progression/base_progress_state.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_valid_envelope_and_round_trip()
	_test_identity_and_shape_guards()
	_test_non_serializable_guards()
	await _test_runtime_snapshot_adapter()
	await _test_runtime_apply_adapter()
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
		"rarity_id": "pet.rarity.epic",
		"trait_id": "pet.trait.guardian",
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
		{"instance_id": "pet.same", "species_id": "creature.flam", "level": 1, "exp": 0, "rarity_id": "pet.rarity.common", "trait_id": "pet.trait.normal", "stance_id": "pet.stance.auto_work"},
		{"instance_id": "pet.same", "species_id": "creature.slime", "level": 1, "exp": 0, "rarity_id": "pet.rarity.common", "trait_id": "pet.trait.normal", "stance_id": "pet.stance.auto_work"},
	]
	_expect(not Schema.validate(duplicate).is_valid(), "duplicate pet instance ID must fail")
	var stale_active := Schema.create_empty(&"save.slot_1", 1)
	stale_active["player"]["active_pet_instance_id"] = "pet.missing"
	_expect(not Schema.validate(stale_active).is_valid(), "active pet must reference roster")
	var negative_count := Schema.create_empty(&"save.slot_1", 1)
	negative_count["inventory"] = {"item.wood": -1}
	_expect(not Schema.validate(negative_count).is_valid(), "negative inventory count must fail")
	var localized_metadata := Schema.create_empty(&"save.slot_1", 1)
	localized_metadata["pets"] = [{"instance_id": "pet.one", "species_id": "creature.flam", "level": 1, "exp": 0, "rarity_id": "★★★★ Thần Thoại", "trait_id": "Hộ Vệ", "stance_id": "pet.stance.auto_work"}]
	_expect(not Schema.validate(localized_metadata).is_valid(), "localized rarity/trait text must not become save identity")
	var localized_quest := Schema.create_empty(&"save.slot_1", 1)
	localized_quest["base"]["active_quest_id"] = "Giai Đoạn 1: Sinh Tồn"
	_expect(not Schema.validate(localized_quest).is_valid(), "localized quest title must not become save identity")
	var skipped_claim := Schema.create_empty(&"save.slot_1", 1)
	skipped_claim["base"] = {"base_level": 2, "active_quest_id": "quest.base.organic_farming", "claimed_quest_ids": ["quest.base.organic_farming"]}
	_expect(not Schema.validate(skipped_claim).is_valid(), "non-prefix claimed quest state must fail")
	var invalid_building := Schema.create_empty(&"save.slot_1", 1)
	invalid_building["world"]["entity_deltas"] = [{"instance_id": "res://scenes/building_chest.tscn", "building_id": "building.chest", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}}]
	_expect(not Schema.validate(invalid_building).is_valid(), "scene path must not become building instance identity")
	var invalid_chest_item := Schema.create_empty(&"save.slot_1", 1)
	invalid_chest_item["world"]["entity_deltas"] = [{"instance_id": "building.instance_chest", "building_id": "building.chest", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"inventory": {"item.stone": 1}}}]
	_expect(not Schema.validate(invalid_chest_item).is_valid(), "chest state must reject items outside its admitted inventory contract")
	var over_capacity_chest := Schema.create_empty(&"save.slot_1", 1)
	over_capacity_chest["world"]["entity_deltas"] = [{"instance_id": "building.instance_chest", "building_id": "building.chest", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"inventory": {"item.berry": 1189}}}]
	_expect(not Schema.validate(over_capacity_chest).is_valid(), "over-capacity chest state must fail before runtime mutation")
	var invalid_chest_health := Schema.create_empty(&"save.slot_1", 1)
	invalid_chest_health["world"]["entity_deltas"] = [{"instance_id": "building.instance_chest", "building_id": "building.chest", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"inventory": {"item.wood": 1}, "health": 0}}]
	_expect(not Schema.validate(invalid_chest_health).is_valid(), "destroyed chest health must fail before mutation")
	var state_on_furnace := Schema.create_empty(&"save.slot_1", 1)
	state_on_furnace["world"]["entity_deltas"] = [{"instance_id": "building.instance_furnace", "building_id": "building.furnace", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"inventory": {}}}]
	_expect(not Schema.validate(state_on_furnace).is_valid(), "furnace must reject state from another subtype")
	var invalid_furnace_progress := Schema.create_empty(&"save.slot_1", 1)
	invalid_furnace_progress["world"]["entity_deltas"] = [{"instance_id": "building.instance_furnace", "building_id": "building.furnace", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"ore_count": 0, "wood_count": 0, "iron_ingots_ready": 0, "pal_ingots_ready": 0, "smelt_timer": 2.0}}]
	_expect(not Schema.validate(invalid_furnace_progress).is_valid(), "furnace progress without a committed batch must fail before mutation")
	var invalid_furnace_health := Schema.create_empty(&"save.slot_1", 1)
	invalid_furnace_health["world"]["entity_deltas"] = [{"instance_id": "building.instance_furnace", "building_id": "building.furnace", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"ore_count": 2, "wood_count": 1, "iron_ingots_ready": 0, "pal_ingots_ready": 0, "smelt_timer": 2.0, "health": 301}}]
	_expect(not Schema.validate(invalid_furnace_health).is_valid(), "furnace health above maximum must fail before mutation")
	var invalid_cooking_recipe := Schema.create_empty(&"save.slot_1", 1)
	invalid_cooking_recipe["world"]["entity_deltas"] = [{"instance_id": "building.instance_pot", "building_id": "building.cooking_pot", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"recipe_id": "hearty_stew", "remaining_seconds": 1.5}}]
	_expect(not Schema.validate(invalid_cooking_recipe).is_valid(), "legacy cooking recipe ID must not become persistence identity")
	var invalid_cooking_progress := Schema.create_empty(&"save.slot_1", 1)
	invalid_cooking_progress["world"]["entity_deltas"] = [{"instance_id": "building.instance_pot", "building_id": "building.cooking_pot", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"recipe_id": "recipe.cooking.hearty_stew", "remaining_seconds": 4.0}}]
	_expect(not Schema.validate(invalid_cooking_progress).is_valid(), "cooking progress beyond recipe duration must fail before mutation")
	var invalid_compost_capacity := Schema.create_empty(&"save.slot_1", 1)
	invalid_compost_capacity["world"]["entity_deltas"] = [{"instance_id": "building.instance_compost", "building_id": "building.compost_bin", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"organic_materials": 11, "ready_fertilizer_count": 0, "composting_timer": 0.0}}]
	_expect(not Schema.validate(invalid_compost_capacity).is_valid(), "compost material count above capacity must fail before mutation")
	var invalid_compost_progress := Schema.create_empty(&"save.slot_1", 1)
	invalid_compost_progress["world"]["entity_deltas"] = [{"instance_id": "building.instance_compost", "building_id": "building.compost_bin", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"organic_materials": 0, "ready_fertilizer_count": 2, "composting_timer": 3.0}}]
	_expect(not Schema.validate(invalid_compost_progress).is_valid(), "compost progress without committed material must fail before mutation")
	var invalid_ranch_identity := Schema.create_empty(&"save.slot_1", 1)
	invalid_ranch_identity["world"]["entity_deltas"] = [{"instance_id": "building.instance_ranch", "building_id": "building.ranch", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"food_count": 8, "assignments": [{"assignment_id": "Lovely Slime", "species_id": "creature.slime"}], "production_timer": 2.0}}]
	_expect(not Schema.validate(invalid_ranch_identity).is_valid(), "localized ranch assignment identity must fail before mutation")
	var duplicate_ranch_assignment := Schema.create_empty(&"save.slot_1", 1)
	duplicate_ranch_assignment["world"]["entity_deltas"] = [{"instance_id": "building.instance_ranch", "building_id": "building.ranch", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"food_count": 8, "assignments": [{"assignment_id": "pet.loaded_1", "species_id": "creature.flam"}, {"assignment_id": "pet.loaded_1", "species_id": "creature.flam"}], "production_timer": 2.0}}]
	_expect(not Schema.validate(duplicate_ranch_assignment).is_valid(), "duplicate ranch assignment must fail before mutation")
	var invalid_farm_crop := Schema.create_empty(&"save.slot_1", 1)
	invalid_farm_crop["world"]["entity_deltas"] = [{"instance_id": "building.instance_plot", "building_id": "building.farm_plot", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"stage_id": "farm.stage.growing", "crop_id": "Wheat", "grow_timer": 7.0, "moisture": 50.0, "is_watered": true, "is_fertilized": false}}]
	_expect(not Schema.validate(invalid_farm_crop).is_valid(), "localized farm crop identity must fail before mutation")
	var invalid_farm_stage := Schema.create_empty(&"save.slot_1", 1)
	invalid_farm_stage["world"]["entity_deltas"] = [{"instance_id": "building.instance_plot", "building_id": "building.farm_plot", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"stage_id": "farm.stage.seeded", "crop_id": "crop.berry", "grow_timer": 6.0, "moisture": 0.0, "is_watered": false, "is_fertilized": false}}]
	_expect(not Schema.validate(invalid_farm_stage).is_valid(), "farm progress inconsistent with stage must fail before mutation")
	var invalid_altar_idle := Schema.create_empty(&"save.slot_1", 1)
	invalid_altar_idle["world"]["entity_deltas"] = [{"instance_id": "building.instance_altar", "building_id": "building.altar", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"lifecycle_id": "altar.lifecycle.idle", "boss_instance_id": "boss.instance_stale", "boss_hp": 137}}]
	_expect(not Schema.validate(invalid_altar_idle).is_valid(), "idle altar must reject stale boss identity and HP")
	var invalid_altar_hp := Schema.create_empty(&"save.slot_1", 1)
	invalid_altar_hp["world"]["entity_deltas"] = [{"instance_id": "building.instance_altar", "building_id": "building.altar", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"lifecycle_id": "altar.lifecycle.active", "boss_instance_id": "boss.instance_test", "boss_hp": 281}}]
	_expect(not Schema.validate(invalid_altar_hp).is_valid(), "altar boss HP above encounter maximum must fail before mutation")
	var invalid_turret_cooldown := Schema.create_empty(&"save.slot_1", 1)
	invalid_turret_cooldown["world"]["entity_deltas"] = [{"instance_id": "building.instance_turret", "building_id": "building.turret", "position": {"x": 1, "y": 2}, "rotation": 0, "scale": {"x": 1, "y": 1}, "state": {"cooldown_remaining": 1.26}}]
	_expect(not Schema.validate(invalid_turret_cooldown).is_valid(), "turret cooldown above fire interval must fail before mutation")


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
	var snapshot_base: BaseManager = player.get("base_manager_ref")
	snapshot_base.apply_persistence_state(BaseProgressStateModel.new(3, &"quest.base.automation", [&"quest.base.survival", &"quest.base.organic_farming"]))
	var snapshot_placements: Array[Dictionary] = player.get("placed_buildings")
	snapshot_placements.append({"instance_id": "building.instance_snapshot", "building_id": "building.chest", "position": {"x": 25.5, "y": -4.0}, "rotation": 0.25, "scale": {"x": 1.0, "y": 1.0}})
	player.global_position = Vector2(12.5, -7.25)
	var party: Array[Dictionary] = player.get("pet_party")
	var species := LegacySpeciesAdapter.create_stable_snapshot(0, {"name": "Flam", "element": "Lửa", "power": 20, "max_hp": 100, "speed": 100.0})
	party.append({"instance_id": &"pet.snapshot_1", "species_id": LegacySpeciesAdapter.FLAM_ID, "species_data": species, "level": 3, "exp": 9, "rarity_id": PetMetadata.RARITY_LEGENDARY, "trait_id": PetMetadata.TRAIT_DRAGON_BLESSING, "stance_id": &"pet.stance.auto_work", "rarity_badge": "★★★★ Thần Thoại", "trait": "Thần Long Hộ Mệnh"})
	party.append({"instance_id": &"pet.snapshot_2", "species_id": LegacySpeciesAdapter.SLIME_ID, "species_data": LegacySpeciesAdapter.create_runtime_snapshot_for_id(LegacySpeciesAdapter.SLIME_ID), "level": 2, "exp": 4, "rarity_id": PetMetadata.RARITY_RARE, "trait_id": PetMetadata.TRAIT_AGILE, "stance_id": &"pet.stance.combat_assist", "rarity_badge": "★★ Hiếm", "trait": "Nhanh Nhẹn"})
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
		_expect(snapshot["pets"][0]["rarity_id"] == "pet.rarity.legendary" and snapshot["pets"][0]["trait_id"] == "pet.trait.dragon_blessing", "active pet stable metadata projection mismatch")
		_expect(snapshot["pets"][1]["stance_id"] == "pet.stance.combat_assist" and snapshot["pets"][1]["trait_id"] == "pet.trait.agile", "inactive pet metadata/stance projection mismatch")
		_expect(snapshot["base"] == {"base_level": 3, "active_quest_id": "quest.base.automation", "claimed_quest_ids": ["quest.base.survival", "quest.base.organic_farming"]}, "base/quest stable snapshot mismatch")
		_expect(snapshot["world"]["entity_deltas"][0]["building_id"] == "building.chest", "building placement snapshot mismatch")
		_expect(snapshot["player"]["position"] == {"x": 12.5, "y": -7.25} and snapshot["world"]["clock_seconds"] == 45.5, "position/world clock projection mismatch")
		snapshot["inventory"]["item.wood"] = 9999
		_expect(source_inventory == inventory_before and party == party_before, "mutating snapshot must not mutate runtime source")
	for group_name: Variant in RuntimeInventoryManifest.GROUPS:
		var group_inventory := inventory_before.duplicate(true)
		for legacy_key: Variant in RuntimeInventoryManifest.GROUPS[group_name]:
			group_inventory[String(legacy_key)] = 1
		player.set("inventory", group_inventory)
		var group_result: RefCounted = SnapshotAdapter.create_player_snapshot(player, &"save.slot_1", 1234)
		_expect(group_result.is_accepted(), "%s runtime inventory outputs must project to Save v1" % group_name)
		if group_result.is_accepted():
			for legacy_key: Variant in RuntimeInventoryManifest.GROUPS[group_name]:
				var content_id := LegacyItemAdapter.to_content_id(String(legacy_key))
				_expect(group_result.snapshot["inventory"].get(String(content_id)) == 1, "%s item '%s' must persist under its stable ID" % [group_name, content_id])
	player.set("inventory", source_inventory)
	source_inventory["Chưa Có Mapping"] = 1
	var unmapped: RefCounted = SnapshotAdapter.create_player_snapshot(player, &"save.slot_1", 1234)
	_expect(unmapped.status == SnapshotResult.Status.UNMAPPED_ITEM and unmapped.snapshot.is_empty(), "unmapped inventory key must fail without partial snapshot")
	source_inventory.erase("Chưa Có Mapping")
	root.remove_child(fixture)
	fixture.free()
	await process_frame
	await process_frame


func _test_runtime_apply_adapter() -> void:
	var packed_player := load("res://scenes/player.tscn") as PackedScene
	if packed_player == null:
		_failures.append("unable to load Player scene for save apply")
		return
	var fixture := Node2D.new()
	root.add_child(fixture)
	var player := packed_player.instantiate()
	fixture.add_child(player)
	await process_frame
	player.set("hud_ref", null)
	var apply_base: BaseManager = player.get("base_manager_ref")
	var save := Schema.create_empty(&"save.slot_1", 2000)
	save["player"] = {
		"position": {"x": 91.25, "y": 42.5}, "level": 4, "exp": 33,
		"hp": 77, "max_hp": 140, "stamina": 62.5,
		"hunger": 51.0, "thirst": 49.0, "temperature": 36.5,
		"active_pet_instance_id": "pet.loaded_1",
	}
	save["inventory"] = {"item.wood": 21, "item.stone": 13}
	save["pets"] = [{
		"instance_id": "pet.loaded_1", "species_id": "creature.flam",
		"level": 5, "exp": 17, "rarity_id": "pet.rarity.epic", "trait_id": "pet.trait.guardian", "stance_id": "pet.stance.combat_assist",
	}, {
		"instance_id": "pet.loaded_2", "species_id": "creature.slime",
		"level": 3, "exp": 8, "rarity_id": "pet.rarity.rare", "trait_id": "pet.trait.agile", "stance_id": "pet.stance.follow_protect",
	}]
	save["world"]["clock_seconds"] = 321.5
	save["base"] = {"base_level": 4, "active_quest_id": "quest.base.fortress", "claimed_quest_ids": ["quest.base.survival", "quest.base.organic_farming", "quest.base.automation"]}
	save["world"]["entity_deltas"] = [{"instance_id": "building.instance_loaded", "building_id": "building.chest", "position": {"x": 44.0, "y": 55.0}, "rotation": 0.5, "scale": {"x": 1.0, "y": 1.0}, "state": {"inventory": {"item.wood": 17, "item.berry": 4}, "health": 137}}]
	var applied: RefCounted = ApplyAdapter.apply_player_snapshot(player, save)
	_expect(applied.is_applied() and is_equal_approx(applied.world_clock_seconds, 321.5), "valid Save v1 must apply and return world clock")
	_expect(player.global_position == Vector2(91.25, 42.5) and player.get("level") == 4 and player.get("hp") == 77, "player scalar apply mismatch")
	_expect(player.get("inventory") == {"Gỗ": 21, "Đá": 13}, "stable inventory must map back to the single legacy store")
	var loaded_party: Array = player.get("pet_party")
	var loaded_pet: Node = player.get("active_pet_node")
	_expect(loaded_party.size() == 2 and loaded_party[0]["species_id"] == &"creature.flam" and loaded_party[0]["exp"] == 17, "pet roster apply mismatch")
	_expect(loaded_party[0]["rarity_id"] == PetMetadata.RARITY_EPIC and loaded_party[0]["trait_id"] == PetMetadata.TRAIT_GUARDIAN, "active pet stable metadata apply mismatch")
	_expect(loaded_party[1]["stance_id"] == &"pet.stance.follow_protect" and loaded_party[1]["trait"] == "Nhanh Nhẹn", "inactive pet metadata/stance apply mismatch")
	_expect(is_instance_valid(loaded_pet) and loaded_pet.call("get_stance_id") == &"pet.stance.combat_assist", "active pet and stance apply mismatch")
	_expect(apply_base.create_persistence_state().to_dto() == save["base"], "base/quest stable apply mismatch")
	var loaded_buildings := get_nodes_in_group("persistent_player_buildings")
	_expect(loaded_buildings.size() == 1 and loaded_buildings[0].get_meta("building_instance_id") == &"building.instance_loaded" and loaded_buildings[0].global_position == Vector2(44.0, 55.0), "building placement apply mismatch")
	var loaded_chest: BuildingChest = loaded_buildings[0] as BuildingChest
	_expect(loaded_chest != null and loaded_chest.health == 137 and not loaded_chest.is_queued_for_deletion() and LegacyItemAdapter.get_count(loaded_chest.stored_items, &"item.wood") == 17 and LegacyItemAdapter.get_count(loaded_chest.stored_items, &"item.berry") == 4, "chest inventory/durability apply must not trigger destruction")
	var chest_snapshot: RefCounted = SnapshotAdapter.create_player_snapshot(player, &"save.slot_1", 2001, 321.5)
	_expect(chest_snapshot.is_accepted(), "loaded chest must snapshot with typed state")
	if chest_snapshot.is_accepted():
		var reloaded: RefCounted = ApplyAdapter.apply_player_snapshot(player, chest_snapshot.snapshot)
		var reloaded_buildings := get_nodes_in_group("persistent_player_buildings")
		var reloaded_chest: BuildingChest = reloaded_buildings[0] as BuildingChest if reloaded_buildings.size() == 1 else null
		_expect(reloaded.is_applied() and reloaded_chest != null and reloaded_chest.health == 137 and not reloaded_chest.is_queued_for_deletion() and LegacyItemAdapter.get_count(reloaded_chest.stored_items, &"item.wood") == 17 and LegacyItemAdapter.get_count(reloaded_chest.stored_items, &"item.berry") == 4, "chest save/load must preserve inventory and durability without destruction")
		var invalid_durability: Dictionary = chest_snapshot.snapshot.duplicate(true)
		invalid_durability["world"]["entity_deltas"][0]["state"]["health"] = 0
		var rejected_durability: RefCounted = ApplyAdapter.apply_player_snapshot(player, invalid_durability)
		var preserved_chests := get_nodes_in_group("persistent_player_buildings")
		var preserved_chest: BuildingChest = preserved_chests[0] as BuildingChest if preserved_chests.size() == 1 else null
		_expect(rejected_durability.status == ApplyResult.Status.INVALID_SNAPSHOT and preserved_chest == reloaded_chest and preserved_chest.health == 137 and LegacyItemAdapter.get_count(preserved_chest.stored_items, &"item.wood") == 17, "invalid chest durability must fail before replacing runtime state")
		loaded_pet = player.get("active_pet_node")
	var furnace_save := save.duplicate(true)
	furnace_save["world"]["entity_deltas"] = [{"instance_id": "building.instance_furnace", "building_id": "building.furnace", "position": {"x": 30.0, "y": 40.0}, "rotation": 0.0, "scale": {"x": 1.0, "y": 1.0}, "state": {"ore_count": 4, "wood_count": 2, "iron_ingots_ready": 3, "pal_ingots_ready": 1, "smelt_timer": 2.25, "health": 181}}]
	var furnace_applied: RefCounted = ApplyAdapter.apply_player_snapshot(player, furnace_save)
	var furnace_nodes := get_nodes_in_group("persistent_player_buildings")
	var loaded_furnace: Variant = furnace_nodes[0] if furnace_nodes.size() == 1 else null
	_expect(furnace_applied.is_applied() and is_instance_valid(loaded_furnace) and loaded_furnace.get("health") == 181 and not loaded_furnace.is_queued_for_deletion() and loaded_furnace.get("ore_count") == 4 and loaded_furnace.get("wood_count") == 2 and loaded_furnace.get("iron_ingots_ready") == 3 and loaded_furnace.get("pal_ingots_ready") == 1 and is_equal_approx(loaded_furnace.get("smelt_timer"), 2.25), "furnace committed batch/durability apply must not run smelting or destruction")
	var furnace_snapshot: RefCounted = SnapshotAdapter.create_player_snapshot(player, &"save.slot_1", 2002, 321.5)
	_expect(furnace_snapshot.is_accepted(), "mid-batch furnace must snapshot with typed state")
	if furnace_snapshot.is_accepted():
		var furnace_reloaded: RefCounted = ApplyAdapter.apply_player_snapshot(player, furnace_snapshot.snapshot)
		var reloaded_furnace_nodes := get_nodes_in_group("persistent_player_buildings")
		var reloaded_furnace: Variant = reloaded_furnace_nodes[0] if reloaded_furnace_nodes.size() == 1 else null
		_expect(furnace_reloaded.is_applied() and is_instance_valid(reloaded_furnace) and reloaded_furnace.get("health") == 181 and not reloaded_furnace.is_queued_for_deletion() and reloaded_furnace.get("ore_count") == 4 and reloaded_furnace.get("wood_count") == 2 and reloaded_furnace.get("iron_ingots_ready") == 3 and reloaded_furnace.get("pal_ingots_ready") == 1 and is_equal_approx(reloaded_furnace.get("smelt_timer"), 2.25), "furnace save/load must preserve processing and durability without side effects")
		var invalid_furnace_durability: Dictionary = furnace_snapshot.snapshot.duplicate(true)
		invalid_furnace_durability["world"]["entity_deltas"][0]["state"]["health"] = 301
		var rejected_furnace_durability: RefCounted = ApplyAdapter.apply_player_snapshot(player, invalid_furnace_durability)
		var preserved_furnaces := get_nodes_in_group("persistent_player_buildings")
		var preserved_furnace: Variant = preserved_furnaces[0] if preserved_furnaces.size() == 1 else null
		_expect(rejected_furnace_durability.status == ApplyResult.Status.INVALID_SNAPSHOT and preserved_furnace == reloaded_furnace and preserved_furnace.get("health") == 181 and preserved_furnace.get("iron_ingots_ready") == 3 and is_equal_approx(preserved_furnace.get("smelt_timer"), 2.25), "invalid furnace durability must fail before replacing or advancing runtime state")
		loaded_pet = player.get("active_pet_node")
	var cooking_save := save.duplicate(true)
	cooking_save["world"]["entity_deltas"] = [{"instance_id": "building.instance_pot", "building_id": "building.cooking_pot", "position": {"x": 18.0, "y": 24.0}, "rotation": 0.0, "scale": {"x": 1.0, "y": 1.0}, "state": {"recipe_id": "recipe.cooking.hearty_stew", "remaining_seconds": 1.75}}]
	var cooking_applied: RefCounted = ApplyAdapter.apply_player_snapshot(player, cooking_save)
	var cooking_nodes := get_nodes_in_group("persistent_player_buildings")
	var loaded_pot: Variant = cooking_nodes[0] if cooking_nodes.size() == 1 else null
	_expect(cooking_applied.is_applied() and is_instance_valid(loaded_pot) and loaded_pot.get("is_cooking") and is_equal_approx(loaded_pot.get("cooking_timer"), 1.75) and loaded_pot.get("current_recipe").get("id") == "hearty_stew", "cooking pot committed recipe/progress apply mismatch")
	var cooking_snapshot: RefCounted = SnapshotAdapter.create_player_snapshot(player, &"save.slot_1", 2003, 321.5)
	_expect(cooking_snapshot.is_accepted(), "mid-batch cooking pot must snapshot with stable recipe state")
	if cooking_snapshot.is_accepted():
		var cooking_reloaded: RefCounted = ApplyAdapter.apply_player_snapshot(player, cooking_snapshot.snapshot)
		var reloaded_cooking_nodes := get_nodes_in_group("persistent_player_buildings")
		var reloaded_pot: Variant = reloaded_cooking_nodes[0] if reloaded_cooking_nodes.size() == 1 else null
		_expect(cooking_reloaded.is_applied() and is_instance_valid(reloaded_pot) and reloaded_pot.get("is_cooking") and is_equal_approx(reloaded_pot.get("cooking_timer"), 1.75) and reloaded_pot.get("current_recipe").get("yield_item") == "Súp Hầm Sơn Hào", "cooking save/load must preserve committed recipe and output exactly once")
		loaded_pet = player.get("active_pet_node")
	var compost_save := save.duplicate(true)
	compost_save["world"]["entity_deltas"] = [{"instance_id": "building.instance_compost", "building_id": "building.compost_bin", "position": {"x": 14.0, "y": 20.0}, "rotation": 0.0, "scale": {"x": 1.0, "y": 1.0}, "state": {"organic_materials": 6, "ready_fertilizer_count": 4, "composting_timer": 3.25}}]
	var compost_applied: RefCounted = ApplyAdapter.apply_player_snapshot(player, compost_save)
	var compost_nodes := get_nodes_in_group("persistent_player_buildings")
	var loaded_compost: Variant = compost_nodes[0] if compost_nodes.size() == 1 else null
	_expect(compost_applied.is_applied() and is_instance_valid(loaded_compost) and loaded_compost.get("organic_materials") == 6 and loaded_compost.get("ready_fertilizer_count") == 4 and is_equal_approx(loaded_compost.get("composting_timer"), 3.25), "compost committed material/output/progress apply mismatch")
	var compost_snapshot: RefCounted = SnapshotAdapter.create_player_snapshot(player, &"save.slot_1", 2004, 321.5)
	_expect(compost_snapshot.is_accepted(), "mid-batch compost bin must snapshot with typed state")
	if compost_snapshot.is_accepted():
		var compost_reloaded: RefCounted = ApplyAdapter.apply_player_snapshot(player, compost_snapshot.snapshot)
		var reloaded_compost_nodes := get_nodes_in_group("persistent_player_buildings")
		var reloaded_compost: Variant = reloaded_compost_nodes[0] if reloaded_compost_nodes.size() == 1 else null
		_expect(compost_reloaded.is_applied() and is_instance_valid(reloaded_compost) and reloaded_compost.get("organic_materials") == 6 and reloaded_compost.get("ready_fertilizer_count") == 4 and is_equal_approx(reloaded_compost.get("composting_timer"), 3.25), "compost save/load must preserve input, output and progress exactly once")
		loaded_pet = player.get("active_pet_node")
	var ranch_save := save.duplicate(true)
	ranch_save["world"]["entity_deltas"] = [{"instance_id": "building.instance_ranch", "building_id": "building.ranch", "position": {"x": 9.0, "y": 15.0}, "rotation": 0.0, "scale": {"x": 1.0, "y": 1.0}, "state": {"food_count": 13, "assignments": [{"assignment_id": "ranch.resident_starter", "species_id": "creature.slime"}, {"assignment_id": "pet.loaded_1", "species_id": "creature.flam"}], "production_timer": 4.5}}]
	var ranch_applied: RefCounted = ApplyAdapter.apply_player_snapshot(player, ranch_save)
	var ranch_nodes := get_nodes_in_group("persistent_player_buildings")
	var loaded_ranch: Variant = ranch_nodes[0] if ranch_nodes.size() == 1 else null
	_expect(ranch_applied.is_applied() and is_instance_valid(loaded_ranch) and loaded_ranch.get("food_count") == 13 and loaded_ranch.get("assigned_pets").size() == 2 and loaded_ranch.get("animal_nodes").size() == 2 and is_equal_approx(loaded_ranch.get("production_timer"), 4.5), "ranch stable assignments/production apply mismatch")
	var ranch_snapshot: RefCounted = SnapshotAdapter.create_player_snapshot(player, &"save.slot_1", 2005, 321.5)
	_expect(ranch_snapshot.is_accepted(), "active ranch must snapshot without runtime animal nodes")
	if ranch_snapshot.is_accepted():
		var ranch_reloaded: RefCounted = ApplyAdapter.apply_player_snapshot(player, ranch_snapshot.snapshot)
		var reloaded_ranch_nodes := get_nodes_in_group("persistent_player_buildings")
		var reloaded_ranch: Variant = reloaded_ranch_nodes[0] if reloaded_ranch_nodes.size() == 1 else null
		var ranch_assignments: Array = reloaded_ranch.get("assigned_pets") if is_instance_valid(reloaded_ranch) else []
		_expect(ranch_reloaded.is_applied() and ranch_assignments.size() == 2 and ranch_assignments[0].get("assignment_id") == &"ranch.resident_starter" and ranch_assignments[1].get("assignment_id") == &"pet.loaded_1" and reloaded_ranch.get("animal_nodes").size() == 2 and is_equal_approx(reloaded_ranch.get("production_timer"), 4.5), "ranch save/load must preserve assignments once and rebuild presentation nodes")
		loaded_pet = player.get("active_pet_node")
	var farm_save := save.duplicate(true)
	farm_save["world"]["entity_deltas"] = [{"instance_id": "building.instance_plot", "building_id": "building.farm_plot", "position": {"x": 7.0, "y": 11.0}, "rotation": 0.0, "scale": {"x": 1.0, "y": 1.0}, "state": {"stage_id": "farm.stage.growing", "crop_id": "crop.golden_wheat", "grow_timer": 7.25, "moisture": 64.0, "is_watered": true, "is_fertilized": true}}]
	var farm_applied: RefCounted = ApplyAdapter.apply_player_snapshot(player, farm_save)
	var farm_nodes := get_nodes_in_group("persistent_player_buildings")
	var loaded_plot: Variant = farm_nodes[0] if farm_nodes.size() == 1 else null
	_expect(farm_applied.is_applied() and is_instance_valid(loaded_plot) and loaded_plot.get("crop_stage") == 2 and loaded_plot.get("crop_type") == 1 and is_equal_approx(loaded_plot.get("grow_timer"), 7.25) and is_equal_approx(loaded_plot.get("moisture"), 64.0) and loaded_plot.get("is_watered") and loaded_plot.get("is_fertilized"), "farm plot crop/stage/progress apply mismatch")
	var farm_snapshot: RefCounted = SnapshotAdapter.create_player_snapshot(player, &"save.slot_1", 2006, 321.5)
	_expect(farm_snapshot.is_accepted(), "growing farm plot must snapshot with stable crop/stage state")
	if farm_snapshot.is_accepted():
		var farm_reloaded: RefCounted = ApplyAdapter.apply_player_snapshot(player, farm_snapshot.snapshot)
		var reloaded_farm_nodes := get_nodes_in_group("persistent_player_buildings")
		var reloaded_plot: Variant = reloaded_farm_nodes[0] if reloaded_farm_nodes.size() == 1 else null
		_expect(farm_reloaded.is_applied() and is_instance_valid(reloaded_plot) and reloaded_plot.get("crop_stage") == 2 and reloaded_plot.get("crop_type") == 1 and is_equal_approx(reloaded_plot.get("grow_timer"), 7.25) and is_equal_approx(reloaded_plot.get("moisture"), 64.0) and reloaded_plot.get("is_watered") and reloaded_plot.get("is_fertilized"), "farm save/load must preserve growth and avoid harvest/reset")
		loaded_pet = player.get("active_pet_node")
	var altar_save := save.duplicate(true)
	altar_save["world"]["entity_deltas"] = [{"instance_id": "building.instance_altar", "building_id": "building.altar", "position": {"x": 5.0, "y": 8.0}, "rotation": 0.0, "scale": {"x": 1.0, "y": 1.0}, "state": {"lifecycle_id": "altar.lifecycle.active", "boss_instance_id": "boss.instance_test", "boss_hp": 137}}]
	var altar_applied: RefCounted = ApplyAdapter.apply_player_snapshot(player, altar_save)
	var altar_bosses := get_nodes_in_group("persistent_altar_bosses")
	var loaded_boss: Variant = altar_bosses[0] if altar_bosses.size() == 1 else null
	_expect(altar_applied.is_applied() and altar_bosses.size() == 1 and loaded_boss.get_meta("boss_instance_id") == &"boss.instance_test" and loaded_boss.get("hp") == 137, "active altar must restore exactly one boss with committed HP")
	var altar_snapshot: RefCounted = SnapshotAdapter.create_player_snapshot(player, &"save.slot_1", 2007, 321.5)
	_expect(altar_snapshot.is_accepted(), "active altar must snapshot boss lifecycle without serializing Node")
	if altar_snapshot.is_accepted():
		var altar_reloaded: RefCounted = ApplyAdapter.apply_player_snapshot(player, altar_snapshot.snapshot)
		var reloaded_bosses := get_nodes_in_group("persistent_altar_bosses")
		var reloaded_boss: Variant = reloaded_bosses[0] if reloaded_bosses.size() == 1 else null
		_expect(altar_reloaded.is_applied() and reloaded_bosses.size() == 1 and reloaded_boss.get_meta("boss_instance_id") == &"boss.instance_test" and reloaded_boss.get("hp") == 137, "altar save/load must replace rather than duplicate active boss")
		loaded_pet = player.get("active_pet_node")
	var turret_save := save.duplicate(true)
	turret_save["world"]["entity_deltas"] = [{"instance_id": "building.instance_turret", "building_id": "building.turret", "position": {"x": 3.0, "y": 6.0}, "rotation": 0.0, "scale": {"x": 1.0, "y": 1.0}, "state": {"cooldown_remaining": 0.8}}]
	var turret_applied: RefCounted = ApplyAdapter.apply_player_snapshot(player, turret_save)
	var turret_nodes := get_nodes_in_group("persistent_player_buildings")
	var loaded_turret: Variant = turret_nodes[0] if turret_nodes.size() == 1 else null
	_expect(turret_applied.is_applied() and is_instance_valid(loaded_turret) and is_equal_approx(loaded_turret.get("fire_cooldown"), 0.8), "turret must restore cooldown without firing on load")
	var turret_snapshot: RefCounted = SnapshotAdapter.create_player_snapshot(player, &"save.slot_1", 2008, 321.5)
	_expect(turret_snapshot.is_accepted(), "turret cooldown must snapshot without target or projectile nodes")
	if turret_snapshot.is_accepted():
		var turret_state: Dictionary = turret_snapshot.snapshot["world"]["entity_deltas"][0]["state"]
		_expect(turret_state.size() == 1 and is_equal_approx(float(turret_state.get("cooldown_remaining", -1.0)), 0.8), "turret DTO must contain only remaining cooldown")
		var turret_reloaded: RefCounted = ApplyAdapter.apply_player_snapshot(player, turret_snapshot.snapshot)
		var reloaded_turret_nodes := get_nodes_in_group("persistent_player_buildings")
		var reloaded_turret: Variant = reloaded_turret_nodes[0] if reloaded_turret_nodes.size() == 1 else null
		_expect(turret_reloaded.is_applied() and is_instance_valid(reloaded_turret) and is_equal_approx(reloaded_turret.get("fire_cooldown"), 0.8), "turret save/load must preserve cooldown without stale target state")
		loaded_pet = player.get("active_pet_node")

	var position_before: Vector2 = player.global_position
	var inventory_before: Dictionary = player.get("inventory").duplicate(true)
	var party_before: Array = player.get("pet_party").duplicate(true)
	var base_before: Dictionary = apply_base.create_persistence_state().to_dto()
	var unsupported := save.duplicate(true)
	unsupported["inventory"] = {"item.not_admitted": 1}
	var rejected: RefCounted = ApplyAdapter.apply_player_snapshot(player, unsupported)
	_expect(rejected.status == ApplyResult.Status.UNSUPPORTED_REFERENCE, "valid-shape unsupported content must fail before commit")
	_expect(player.global_position == position_before and player.get("inventory") == inventory_before and player.get("pet_party") == party_before and player.get("active_pet_node") == loaded_pet, "failed apply must preserve all runtime source state")
	_expect(apply_base.create_persistence_state().to_dto() == base_before, "failed apply must preserve base progression")
	var malformed := save.duplicate(true)
	malformed["player"]["hp"] = 999
	var invalid: RefCounted = ApplyAdapter.apply_player_snapshot(player, malformed)
	_expect(invalid.status == ApplyResult.Status.INVALID_SNAPSHOT, "invalid schema must fail before planning")
	_expect(player.global_position == position_before and player.get("inventory") == inventory_before and player.get("pet_party") == party_before and player.get("active_pet_node") == loaded_pet, "invalid schema must preserve all runtime source state")
	root.remove_child(fixture)
	fixture.free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
