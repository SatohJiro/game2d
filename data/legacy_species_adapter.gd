class_name LegacySpeciesAdapter
extends RefCounted

const FLAM_DEFINITION: CreatureDefinition = preload("res://data/definitions/creatures/flam.tres")
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
	if snapshot["id"] == FLAM_ID:
		if FLAM_DEFINITION == null or not FLAM_DEFINITION.get_validation_errors().is_empty():
			return {}
		snapshot["max_hp"] = FLAM_DEFINITION.base_max_hp
		snapshot["speed"] = FLAM_DEFINITION.move_speed
		snapshot["power"] = FLAM_DEFINITION.base_attack_power
		snapshot["is_predator"] = FLAM_DEFINITION.behavior_profile.is_predator
		snapshot["is_prey"] = FLAM_DEFINITION.behavior_profile.is_prey
		var legacy_drop := LegacyItemAdapter.to_legacy_key(FLAM_DEFINITION.drop_item_id)
		if legacy_drop.is_empty():
			return {}
		snapshot["drop_item"] = legacy_drop
	return snapshot
