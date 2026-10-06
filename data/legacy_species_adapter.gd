class_name LegacySpeciesAdapter
extends RefCounted

const FLAM_DEFINITION: CreatureDefinition = preload("res://data/definitions/creatures/flam.tres")
const SLIME_DEFINITION: CreatureDefinition = preload("res://data/definitions/creatures/slime.tres")
const MUSHROOM_DEFINITION: CreatureDefinition = preload("res://data/definitions/creatures/mushroom.tres")
const BEAST_DEFINITION: CreatureDefinition = preload("res://data/definitions/creatures/beast.tres")
const DRAGON_DEFINITION: CreatureDefinition = preload("res://data/definitions/creatures/dragon.tres")
const FLAM_FIREBALL_DEFINITION: SkillDefinition = preload("res://data/definitions/skills/flam_fireball.tres")
const DRAGON_FIREBALL_DEFINITION: SkillDefinition = preload("res://data/definitions/skills/dragon_fireball.tres")
const MUSHROOM_SPORE_DEFINITION: SkillDefinition = preload("res://data/definitions/skills/mushroom_spore.tres")
const SLIME_HOP_DEFINITION: HopSkillDefinition = preload("res://data/definitions/skills/slime_hop.tres")
const BEAST_CHARGE_DEFINITION: ChargeSkillDefinition = preload("res://data/definitions/skills/beast_charge.tres")
const BEAST_MELEE_DEFINITION: MeleeSkillDefinition = preload("res://data/definitions/skills/beast_melee.tres")
const DRAGON_MELEE_DEFINITION: MeleeSkillDefinition = preload("res://data/definitions/skills/dragon_melee.tres")

const FLAM_ID: StringName = &"creature.flam"
const FLAM_FIREBALL_ID: StringName = &"skill.flam.fireball"
const DRAGON_FIREBALL_ID: StringName = &"skill.dragon.fireball"
const MUSHROOM_SPORE_ID: StringName = &"skill.mushroom.spore"
const SLIME_HOP_ID: StringName = &"skill.slime.hop"
const BEAST_CHARGE_ID: StringName = &"skill.beast.charge"
const BEAST_MELEE_ID: StringName = &"skill.beast.melee"
const DRAGON_MELEE_ID: StringName = &"skill.dragon.melee"
const SLIME_ID: StringName = &"creature.slime"
const MUSHROOM_ID: StringName = &"creature.mushroom"
const BEAST_ID: StringName = &"creature.beast"
const DRAGON_ID: StringName = &"creature.dragon"

const LEGACY_PRESENTATION: Dictionary = {
	FLAM_ID: {"name": "Flam", "element": "Lửa", "texture": preload("res://assets/monsters/flam_sheet.png")},
	SLIME_ID: {"name": "Slime", "element": "Nước", "texture": preload("res://assets/monsters/slime_sheet.png")},
	MUSHROOM_ID: {"name": "Mushroom", "element": "Thảo Mộc", "texture": preload("res://assets/monsters/mushroom_sheet.png")},
	BEAST_ID: {"name": "Beast", "element": "Đất", "texture": preload("res://assets/monsters/beast_sheet.png")},
	DRAGON_ID: {"name": "Dragon", "element": "Hỏa Long", "texture": preload("res://assets/monsters/dragon_sheet.png")},
}

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
	var expected_skill_id: StringName
	var skill_definition: SkillDefinition
	match species_id:
		FLAM_ID:
			expected_skill_id = FLAM_FIREBALL_ID
			skill_definition = FLAM_FIREBALL_DEFINITION
		DRAGON_ID:
			expected_skill_id = DRAGON_FIREBALL_ID
			skill_definition = DRAGON_FIREBALL_DEFINITION
		MUSHROOM_ID:
			expected_skill_id = MUSHROOM_SPORE_ID
			skill_definition = MUSHROOM_SPORE_DEFINITION
		SLIME_ID:
			expected_skill_id = SLIME_HOP_ID
			skill_definition = SLIME_HOP_DEFINITION
		BEAST_ID:
			expected_skill_id = BEAST_CHARGE_ID
			skill_definition = BEAST_CHARGE_DEFINITION
		_:
			return null
	var creature_definition := get_creature_definition(species_id)
	if creature_definition == null or not creature_definition.skill_ids.has(expected_skill_id):
		return null
	if skill_definition == null or not skill_definition.get_validation_errors().is_empty():
		return null
	return skill_definition

static func get_melee_skill_definition(species_id: StringName) -> MeleeSkillDefinition:
	var expected_id: StringName
	var skill: MeleeSkillDefinition
	match species_id:
		BEAST_ID: expected_id = BEAST_MELEE_ID; skill = BEAST_MELEE_DEFINITION
		DRAGON_ID: expected_id = DRAGON_MELEE_ID; skill = DRAGON_MELEE_DEFINITION
		_: return null
	var creature := get_creature_definition(species_id)
	if creature == null or not creature.skill_ids.has(expected_id) or skill == null or not skill.get_validation_errors().is_empty(): return null
	return skill


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


static func create_runtime_snapshot_for_id(species_id: StringName) -> Dictionary:
	var species_index := to_legacy_index(species_id)
	var presentation: Dictionary = LEGACY_PRESENTATION.get(species_id, {})
	if species_index < 0 or presentation.is_empty():
		return {}
	return create_runtime_snapshot(species_index, presentation)


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
