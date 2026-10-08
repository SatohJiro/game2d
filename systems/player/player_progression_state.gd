class_name PlayerProgressionState
extends RefCounted

const STAT_IDS := [&"str", &"vit", &"sta", &"agi"]
const BASE_MAX_EXP := 100
const POINTS_PER_LEVEL := 2
const BASE_MAX_HP := 100
const HP_PER_LEVEL := 18
const HP_PER_VITALITY := 25
const BASE_MAX_STAMINA := 100.0
const STAMINA_PER_STAT := 15.0
const DEFAULT_MAX_NEED := 100.0
const MAX_BUFF_DURATION := 240.0

var level: int
var exp: int
var max_exp: int
var stat_points: int
var stats: Dictionary
var weapon_id: StringName
var armor_id: StringName
var max_hp: int
var max_stamina: float
var max_hunger: float
var max_thirst: float
var buff_id: StringName
var buff_time_remaining: float


func _init(
	p_level: int,
	p_exp: int,
	p_max_exp: int,
	p_stat_points: int,
	p_stats: Dictionary,
	p_weapon_id: StringName,
	p_armor_id: StringName,
	p_max_hp: int,
	p_max_stamina: float,
	p_max_hunger: float,
	p_max_thirst: float,
	p_buff_id: StringName,
	p_buff_time_remaining: float
) -> void:
	level = p_level
	exp = p_exp
	max_exp = p_max_exp
	stat_points = p_stat_points
	stats = p_stats.duplicate(true)
	weapon_id = p_weapon_id
	armor_id = p_armor_id
	max_hp = p_max_hp
	max_stamina = p_max_stamina
	max_hunger = p_max_hunger
	max_thirst = p_max_thirst
	buff_id = p_buff_id
	buff_time_remaining = p_buff_time_remaining


func is_valid() -> bool:
	if level < 1 or exp < 0 or max_exp != expected_max_exp(level) or exp >= max_exp or stat_points < 0:
		return false
	if stats.size() != STAT_IDS.size():
		return false
	var allocated := 0
	for stat_id: StringName in STAT_IDS:
		var value: Variant = stats.get(String(stat_id))
		if typeof(value) != TYPE_INT or int(value) < 0:
			return false
		allocated += int(value)
	if allocated + stat_points != level * POINTS_PER_LEVEL:
		return false
	if not PlayerEquipmentCatalog.is_valid_weapon(weapon_id) or not PlayerEquipmentCatalog.is_valid_armor(armor_id):
		return false
	if max_hp != expected_max_hp(level, int(stats["vit"]), armor_id):
		return false
	if not _finite_positive(max_stamina) or not is_equal_approx(max_stamina, expected_max_stamina(int(stats["sta"]))):
		return false
	if not _finite_positive(max_hunger) or not _finite_positive(max_thirst):
		return false
	if not _valid_buff_id(buff_id) or not is_finite(buff_time_remaining) or buff_time_remaining < 0.0 or buff_time_remaining > MAX_BUFF_DURATION:
		return false
	return (buff_id == PlayerNeedsState.BUFF_NONE) == is_zero_approx(buff_time_remaining)


func to_dto() -> Dictionary:
	return {
		"level": level,
		"exp": exp,
		"max_exp": max_exp,
		"stat_points": stat_points,
		"stats": stats.duplicate(true),
		"weapon_id": String(weapon_id),
		"armor_id": String(armor_id),
		"max_hp": max_hp,
		"max_stamina": max_stamina,
		"max_hunger": max_hunger,
		"max_thirst": max_thirst,
		"buff_id": String(buff_id),
		"buff_time_remaining": buff_time_remaining,
	}


static func from_dto(value: Variant) -> PlayerProgressionState:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = value
	if data.size() != 13 or typeof(data.get("stats")) != TYPE_DICTIONARY or typeof(data.get("weapon_id")) != TYPE_STRING or typeof(data.get("armor_id")) != TYPE_STRING or typeof(data.get("buff_id")) != TYPE_STRING:
		return null
	for field in ["level", "exp", "max_exp", "stat_points", "max_hp"]:
		if not _json_integer(data.get(field)):
			return null
	for field in ["max_stamina", "max_hunger", "max_thirst", "buff_time_remaining"]:
		if not _json_number(data.get(field)):
			return null
	var normalized_stats := {}
	var raw_stats: Dictionary = data["stats"]
	if raw_stats.size() != STAT_IDS.size():
		return null
	for stat_id: StringName in STAT_IDS:
		var key := String(stat_id)
		if not _json_integer(raw_stats.get(key)):
			return null
		normalized_stats[key] = int(raw_stats[key])
	var state := PlayerProgressionState.new(
		int(data["level"]), int(data["exp"]), int(data["max_exp"]), int(data["stat_points"]), normalized_stats,
		StringName(data["weapon_id"]), StringName(data["armor_id"]), int(data["max_hp"]), float(data["max_stamina"]),
		float(data["max_hunger"]), float(data["max_thirst"]), StringName(data["buff_id"]), float(data["buff_time_remaining"])
	)
	return state if state.is_valid() else null


static func create_legacy_default(p_level: int, p_exp: int) -> PlayerProgressionState:
	var safe_level := maxi(1, p_level)
	var threshold := expected_max_exp(safe_level)
	var safe_exp := clampi(p_exp, 0, threshold - 1)
	return PlayerProgressionState.new(
		safe_level, safe_exp, threshold, safe_level * POINTS_PER_LEVEL,
		{"str": 0, "vit": 0, "sta": 0, "agi": 0},
		PlayerEquipmentCatalog.WOOD_SWORD, PlayerEquipmentCatalog.NO_ARMOR,
		expected_max_hp(safe_level, 0, PlayerEquipmentCatalog.NO_ARMOR), BASE_MAX_STAMINA,
		DEFAULT_MAX_NEED, DEFAULT_MAX_NEED, PlayerNeedsState.BUFF_NONE, 0.0
	)


static func expected_max_exp(p_level: int) -> int:
	var threshold := BASE_MAX_EXP
	for _step in range(1, maxi(1, p_level)):
		threshold = int(threshold * 1.4)
	return threshold


static func expected_max_hp(p_level: int, vitality: int, p_armor_id: StringName) -> int:
	return BASE_MAX_HP + (p_level - 1) * HP_PER_LEVEL + vitality * HP_PER_VITALITY + PlayerEquipmentCatalog.armor_max_hp_bonus(p_armor_id)


static func expected_max_stamina(stamina_stat: int) -> float:
	return BASE_MAX_STAMINA + stamina_stat * STAMINA_PER_STAT


static func _valid_buff_id(p_buff_id: StringName) -> bool:
	return [PlayerNeedsState.BUFF_NONE, PlayerNeedsState.BUFF_STAMINA_REGEN, PlayerNeedsState.BUFF_WARMTH, PlayerNeedsState.BUFF_SPEED, PlayerNeedsState.BUFF_SLOW_HUNGER].has(p_buff_id)


static func _finite_positive(value: float) -> bool:
	return is_finite(value) and value > 0.0


static func _json_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))


static func _json_integer(value: Variant) -> bool:
	return _json_number(value) and is_equal_approx(float(value), roundf(float(value)))
