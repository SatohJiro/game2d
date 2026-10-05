class_name LegacySpeciesAdapter
extends RefCounted

const FLAM_DEFINITION: CreatureDefinition = preload("res://data/definitions/creatures/flam.tres")
const SLIME_DEFINITION: CreatureDefinition = preload("res://data/definitions/creatures/slime.tres")
const MUSHROOM_DEFINITION: CreatureDefinition = preload("res://data/definitions/creatures/mushroom.tres")
const BEAST_DEFINITION: CreatureDefinition = preload("res://data/definitions/creatures/beast.tres")
const DRAGON_DEFINITION: CreatureDefinition = preload("res://data/definitions/creatures/dragon.tres")
const FLAM_FIREBALL_DEFINITION: SkillDefinition = preload("res://data/definitions/skills/flam_fireball.tres")

const FLAM_ID: StringName = &"creature.flam"
const FLAM_FIREBALL_ID: StringName = &"skill.flam.fireball"
const SLIME_ID: StringName = &"creature.slime"
const MUSHROOM_ID: StringName = &"creature.mushroom"
const BEAST_ID: StringName = &"creature.beast"
const DRAGON_ID: StringName = &"creature.dragon"

const INDEX_TO_CONTENT_ID: Array[StringName] = [
	FLAM_ID,
	SLIME_ID,
	MUSHROOM_ID,
	BEAST_ID,
	DRAGON_ID,
]

const CONTENT_ID_TO_INDEX: Dictionary = {
	FLAM_ID: 0,
	SLIME_ID: 1,
	MUSHROOM_ID: 2,
	BEAST_ID: 3,
	DRAGON_ID: 4,
}


static func to_content_id(species_index: int) -> StringName:
	if species_index < 0 or species_index >= INDEX_TO_CONTENT_ID.size():
		return &""
	return INDEX_TO_CONTENT_ID[species_index]


static func to_legacy_index(species_id: StringName) -> int:
	return int(CONTENT_ID_TO_INDEX.get(species_id, -1))


static func is_supported(species_id: StringName) -> bool:
	return CONTENT_ID_TO_INDEX.has(species_id)


static func get_primary_skill_definition(species_id: StringName) -> SkillDefinition:
	if species_id != FLAM_ID:
		return null
	if FLAM_DEFINITION.skill_ids.is_empty() or FLAM_DEFINITION.skill_ids[0] != FLAM_FIREBALL_ID:
		return null
	if FLAM_FIREBALL_DEFINITION == null or not FLAM_FIREBALL_DEFINITION.get_validation_errors().is_empty():
		return null
	return FLAM_FIREBALL_DEFINITION


static func get_drop_item_id(species_id: StringName, legacy_drop_name: String = "") -> StringName:
	var definition := get_creature_definition(species_id)
	if definition != null and definition.get_validation_errors().is_empty():
		return definition.drop_item_id
	return LegacyItemAdapter.to_content_id(legacy_drop_name)


static func create_stable_snapshot(species_index: int, legacy_data: Dictionary) -> Dictionary:
	var species_id := to_content_id(species_index)
	if species_id.is_empty() or legacy_data.is_empty():
		return {}
	var snapshot := legacy_data.duplicate(true)
	snapshot["id"] = species_id
	return snapshot


static func create_runtime_snapshot(species_index: int, legacy_data: Dictionary) -> Dictionary:
	var snapshot := create_stable_snapshot(species_index, legacy_data)
	if snapshot.is_empty():
		return {}
	var definition := get_creature_definition(snapshot["id"] as StringName)
	if definition != null:
		if not definition.get_validation_errors().is_empty():
			return {}
		snapshot["max_hp"] = definition.base_max_hp
		snapshot["speed"] = definition.move_speed
		snapshot["power"] = definition.base_attack_power
		snapshot["is_predator"] = definition.behavior_profile.is_predator
		snapshot["is_prey"] = definition.behavior_profile.is_prey
		var legacy_drop := LegacyItemAdapter.to_legacy_key(definition.drop_item_id)
		if legacy_drop.is_empty():
			return {}
		snapshot["drop_item"] = legacy_drop
	return snapshot


static func get_creature_definition(species_id: StringName) -> CreatureDefinition:
	match species_id:
		FLAM_ID:
			return FLAM_DEFINITION
		SLIME_ID:
			return SLIME_DEFINITION
		MUSHROOM_ID:
			return MUSHROOM_DEFINITION
		BEAST_ID:
			return BEAST_DEFINITION
		DRAGON_ID:
			return DRAGON_DEFINITION
		_:
			return null
