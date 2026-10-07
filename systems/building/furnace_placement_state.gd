class_name FurnacePlacementState
extends RefCounted

const SMELT_DURATION := 5.0
const MAX_HEALTH := 300

var ore_count: int
var wood_count: int
var iron_ingots_ready: int
var pal_ingots_ready: int
var smelt_timer: float
var health: int


func _init(p_ore_count: int = 0, p_wood_count: int = 0, p_iron_ingots_ready: int = 0, p_pal_ingots_ready: int = 0, p_smelt_timer: float = 0.0, p_health: int = MAX_HEALTH) -> void:
	ore_count = p_ore_count
	wood_count = p_wood_count
	iron_ingots_ready = p_iron_ingots_ready
	pal_ingots_ready = p_pal_ingots_ready
	smelt_timer = p_smelt_timer
	health = p_health


func is_valid() -> bool:
	if health < 1 or health > MAX_HEALTH:
		return false
	if ore_count < 0 or wood_count < 0 or iron_ingots_ready < 0 or pal_ingots_ready < 0:
		return false
	if not is_finite(smelt_timer) or smelt_timer < 0.0 or smelt_timer >= SMELT_DURATION:
		return false
	var can_smelt := ore_count >= 2 and wood_count >= 1
	return can_smelt or is_zero_approx(smelt_timer)


func to_dto() -> Dictionary:
	return {
		"ore_count": ore_count,
		"wood_count": wood_count,
		"iron_ingots_ready": iron_ingots_ready,
		"pal_ingots_ready": pal_ingots_ready,
		"smelt_timer": smelt_timer,
		"health": health,
	}


static func from_dto(value: Variant) -> FurnacePlacementState:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = value
	if (data.size() != 5 and data.size() != 6) or (data.size() == 6 and not data.has("health")):
		return null
	for key: String in ["ore_count", "wood_count", "iron_ingots_ready", "pal_ingots_ready"]:
		if typeof(data.get(key)) != TYPE_INT:
			return null
	var timer: Variant = data.get("smelt_timer")
	if typeof(timer) != TYPE_INT and typeof(timer) != TYPE_FLOAT:
		return null
	var health_value: Variant = data.get("health", MAX_HEALTH)
	if typeof(health_value) != TYPE_INT:
		return null
	var state := FurnacePlacementState.new(
		int(data["ore_count"]), int(data["wood_count"]),
		int(data["iron_ingots_ready"]), int(data["pal_ingots_ready"]), float(timer), int(health_value)
	)
	return state if state.is_valid() else null
