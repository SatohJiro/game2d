class_name NightRaidActorState
extends RefCounted

const VALID_INSTANCE_IDS: Array[StringName] = [
	&"raid.night_actor_1",
	&"raid.night_actor_2",
	&"raid.night_actor_3",
]
const VALID_SPECIES_IDS: Array[StringName] = [
	&"creature.flam",
	&"creature.slime",
	&"creature.mushroom",
	&"creature.beast",
]

var instance_id: StringName
var species_id: StringName
var level: int
var hp: int
var position: Vector2

func _init(p_instance_id: StringName, p_species_id: StringName, p_level: int, p_hp: int, p_position: Vector2) -> void:
	instance_id = p_instance_id
	species_id = p_species_id
	level = p_level
	hp = p_hp
	position = p_position

func is_valid() -> bool:
	if not VALID_INSTANCE_IDS.has(instance_id) or not VALID_SPECIES_IDS.has(species_id): return false
	if level < 2 or level > 5 or hp < 1: return false
	if not is_finite(position.x) or not is_finite(position.y): return false
	var definition := LegacySpeciesAdapter.get_creature_definition(species_id)
	if definition == null: return false
	var raid_max_hp := int((definition.base_max_hp + (level - 1) * 15) * 2.4)
	return hp <= raid_max_hp

func to_dto() -> Dictionary:
	return {"instance_id": String(instance_id), "species_id": String(species_id), "level": level, "hp": hp, "position_x": position.x, "position_y": position.y}

static func from_dto(value: Variant) -> NightRaidActorState:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	if data.size() != 6 or typeof(data.get("instance_id")) != TYPE_STRING or typeof(data.get("species_id")) != TYPE_STRING: return null
	var level_value: Variant = data.get("level")
	var hp_value: Variant = data.get("hp")
	var x: Variant = data.get("position_x")
	var y: Variant = data.get("position_y")
	if not _is_json_integer(level_value) or not _is_json_integer(hp_value): return null
	if not _is_number(x) or not _is_number(y): return null
	var state := NightRaidActorState.new(StringName(data["instance_id"]), StringName(data["species_id"]), int(level_value), int(hp_value), Vector2(float(x), float(y)))
	return state if state.is_valid() else null

static func _is_json_integer(value: Variant) -> bool:
	return _is_number(value) and is_equal_approx(float(value), roundf(float(value)))

static func _is_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))
