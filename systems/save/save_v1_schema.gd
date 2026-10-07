class_name SaveV1Schema
extends RefCounted

const ValidationResult = preload("res://systems/save/save_validation_result.gd")
const PetMetadata = preload("res://systems/pet/pet_metadata_catalog.gd")
const PetCommandPolicy = preload("res://systems/pet/pet_command_policy.gd")
const BaseProgressStateModel = preload("res://systems/progression/base_progress_state.gd")
const BuildingPlacementRecordModel = preload("res://systems/building/building_placement_record.gd")
const ResourceDepletionRecordModel = preload("res://systems/world/resource_depletion_record.gd")
const SCHEMA_VERSION := 1


static func create_empty(save_id: StringName, saved_at_unix: int) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"save_id": String(save_id),
		"saved_at_unix": saved_at_unix,
		"player": {
			"position": {"x": 0.0, "y": 0.0},
			"level": 1,
			"exp": 0,
			"hp": 100,
			"max_hp": 100,
			"stamina": 100.0,
			"hunger": 100.0,
			"thirst": 100.0,
			"temperature": 50.0,
			"active_pet_instance_id": "",
		},
		"inventory": {},
		"pets": [],
		"base": {"base_level": 1, "active_quest_id": "quest.base.survival", "claimed_quest_ids": []},
		"world": {"clock_seconds": 0.0, "cycle_state": {"raid_triggered_this_cycle": false}, "world_boss_state": WorldBossState.new().to_dto(), "entity_deltas": [], "resource_deltas": []},
	}


static func validate(data: Variant) -> RefCounted:
	var errors := PackedStringArray()
	if not _is_json_safe(data):
		errors.append("root must contain only JSON-safe values with String keys")
		return ValidationResult.new(ValidationResult.Status.INVALID, errors)
	if typeof(data) != TYPE_DICTIONARY:
		errors.append("root must be a Dictionary")
		return ValidationResult.new(ValidationResult.Status.INVALID, errors)
	var root: Dictionary = data
	if root.get("schema_version") != SCHEMA_VERSION:
		errors.append("schema_version must equal 1")
	if ContentId.domain_of(StringName(root.get("save_id", ""))) != &"save":
		errors.append("save_id must use save.* identity")
	if not _is_non_negative_integer(root.get("saved_at_unix")):
		errors.append("saved_at_unix must be a non-negative integer")
	_validate_player(root.get("player"), errors)
	_validate_inventory(root.get("inventory"), errors)
	_validate_pets(root.get("pets"), root.get("player"), errors)
	_validate_base(root.get("base"), errors)
	_validate_world(root.get("world"), errors)
	return ValidationResult.new(ValidationResult.Status.VALID if errors.is_empty() else ValidationResult.Status.INVALID, errors)


static func _validate_player(value: Variant, errors: PackedStringArray) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("player must be a Dictionary")
		return
	var player: Dictionary = value
	var position: Variant = player.get("position")
	if typeof(position) != TYPE_DICTIONARY or not _is_finite_number(position.get("x") if typeof(position) == TYPE_DICTIONARY else null) or not _is_finite_number(position.get("y") if typeof(position) == TYPE_DICTIONARY else null):
		errors.append("player.position must contain finite x/y numbers")
	for field in ["level", "max_hp"]:
		if not _is_positive_integer(player.get(field)):
			errors.append("player.%s must be a positive integer" % field)
	for field in ["exp", "hp"]:
		if not _is_non_negative_integer(player.get(field)):
			errors.append("player.%s must be a non-negative integer" % field)
	if _is_non_negative_integer(player.get("hp")) and _is_positive_integer(player.get("max_hp")) and float(player["hp"]) > float(player["max_hp"]):
		errors.append("player.hp must not exceed max_hp")
	for field in ["stamina", "hunger", "thirst", "temperature"]:
		if not _is_finite_number(player.get(field)):
			errors.append("player.%s must be finite" % field)
	var active_id := StringName(player.get("active_pet_instance_id", ""))
	if not active_id.is_empty() and ContentId.domain_of(active_id) != &"pet":
		errors.append("player.active_pet_instance_id must be empty or pet.*")


static func _validate_inventory(value: Variant, errors: PackedStringArray) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("inventory must be a Dictionary")
		return
	for item_id: Variant in value:
		if ContentId.domain_of(StringName(item_id)) != &"item":
			errors.append("inventory keys must use item.* IDs")
		if not _is_non_negative_integer(value[item_id]):
			errors.append("inventory counts must be non-negative integers")


static func _validate_pets(value: Variant, player_value: Variant, errors: PackedStringArray) -> void:
	if typeof(value) != TYPE_ARRAY:
		errors.append("pets must be an Array")
		return
	var seen := {}
	for entry_value: Variant in value:
		if typeof(entry_value) != TYPE_DICTIONARY:
			errors.append("each pet must be a Dictionary")
			continue
		var entry: Dictionary = entry_value
		var instance_id := StringName(entry.get("instance_id", ""))
		if ContentId.domain_of(instance_id) != &"pet":
			errors.append("pet instance_id must use pet.*")
		elif seen.has(instance_id):
			errors.append("pet instance_id must be unique")
		else:
			seen[instance_id] = true
		if ContentId.domain_of(StringName(entry.get("species_id", ""))) != &"creature":
			errors.append("pet species_id must use creature.*")
		if not _is_positive_integer(entry.get("level")):
			errors.append("pet level must be a positive integer")
		if not _is_non_negative_integer(entry.get("exp")):
			errors.append("pet exp must be a non-negative integer")
		if not PetMetadata.is_valid_rarity(StringName(entry.get("rarity_id", ""))):
			errors.append("pet rarity_id must be supported")
		if not PetMetadata.is_valid_trait(StringName(entry.get("trait_id", ""))):
			errors.append("pet trait_id must be supported")
		if not PetCommandPolicy.VALID_STANCES.has(StringName(entry.get("stance_id", ""))):
			errors.append("pet stance_id must be supported")
	if typeof(player_value) == TYPE_DICTIONARY:
		var active_id := StringName((player_value as Dictionary).get("active_pet_instance_id", ""))
		if not active_id.is_empty() and not seen.has(active_id):
			errors.append("active pet must reference a roster instance")


static func _validate_world(value: Variant, errors: PackedStringArray) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("world must be a Dictionary")
		return
	var world: Dictionary = value
	if not _is_finite_number(world.get("clock_seconds")) or float(world.get("clock_seconds", -1.0)) < 0.0:
		errors.append("world.clock_seconds must be finite and non-negative")
	else:
		var cycle_state := WorldCycleState.from_dto(world.get("cycle_state", {"raid_triggered_this_cycle": false}), float(world["clock_seconds"]))
		if cycle_state == null:
			errors.append("world.cycle_state must be coherent with clock phase")
		else:
			var boss_state := _parse_world_boss_state(world.get("world_boss_state"), cycle_state.boss_spawned)
			if boss_state == null or (boss_state.lifecycle_id == WorldBossState.PENDING) == cycle_state.boss_spawned:
				errors.append("world.world_boss_state must be valid and coherent with cycle state")
	if typeof(world.get("entity_deltas")) != TYPE_ARRAY:
		errors.append("world.entity_deltas must be an Array")
		return
	var seen := {}
	for delta_value: Variant in world["entity_deltas"]:
		var record := BuildingPlacementRecordModel.from_dto(delta_value)
		if record == null:
			errors.append("world.entity_deltas must contain valid building placement records")
			continue
		if seen.has(record.instance_id): errors.append("building instance_id must be unique")
		seen[record.instance_id] = true
	var resource_deltas: Variant = world.get("resource_deltas", [])
	if typeof(resource_deltas) != TYPE_ARRAY:
		errors.append("world.resource_deltas must be an Array")
		return
	seen.clear()
	for delta_value: Variant in resource_deltas:
		var record := ResourceDepletionRecordModel.from_dto(delta_value)
		if record == null:
			errors.append("world.resource_deltas must contain valid resource depletion records")
			continue
		if seen.has(record.instance_id): errors.append("resource instance_id must be unique")
		seen[record.instance_id] = true


static func _parse_world_boss_state(value: Variant, boss_spawned: bool) -> WorldBossState:
	if value == null:
		return WorldBossState.new(WorldBossState.DEFEATED, WorldBossState.INSTANCE_ID, 0, Vector2.ZERO) if boss_spawned else WorldBossState.new()
	return WorldBossState.from_dto(value)


static func _validate_base(value: Variant, errors: PackedStringArray) -> void:
	if BaseProgressStateModel.from_dto(value) == null:
		errors.append("base must contain a coherent stable quest progression state")


static func _is_finite_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))


static func _is_non_negative_integer(value: Variant) -> bool:
	return _is_finite_number(value) and float(value) >= 0.0 and is_equal_approx(float(value), floor(float(value)))


static func _is_positive_integer(value: Variant) -> bool:
	return _is_non_negative_integer(value) and float(value) > 0.0


static func _is_json_safe(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY:
			for child: Variant in value:
				if not _is_json_safe(child):
					return false
			return true
		TYPE_DICTIONARY:
			for key: Variant in value:
				if typeof(key) != TYPE_STRING or not _is_json_safe(value[key]):
					return false
			return true
	return false
