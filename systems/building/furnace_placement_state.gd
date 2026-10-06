class_name FurnacePlacementState
extends RefCounted

const SMELT_DURATION := 5.0

var ore_count: int
var wood_count: int
var iron_ingots_ready: int
var pal_ingots_ready: int
var smelt_timer: float


func _init(p_ore_count: int = 0, p_wood_count: int = 0, p_iron_ingots_ready: int = 0, p_pal_ingots_ready: int = 0, p_smelt_timer: float = 0.0) -> void:
	ore_count = p_ore_count
	wood_count = p_wood_count
	iron_ingots_ready = p_iron_ingots_ready
	pal_ingots_ready = p_pal_ingots_ready
	smelt_timer = p_smelt_timer


func is_valid() -> bool:
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
	}


static func from_dto(value: Variant) -> FurnacePlacementState:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = value
	if data.size() != 5:
		return null
	for key: String in ["ore_count", "wood_count", "iron_ingots_ready", "pal_ingots_ready"]:
		if typeof(data.get(key)) != TYPE_INT:
			return null
	var timer: Variant = data.get("smelt_timer")
	if typeof(timer) != TYPE_INT and typeof(timer) != TYPE_FLOAT:
		return null
	var state := FurnacePlacementState.new(
		int(data["ore_count"]), int(data["wood_count"]),
		int(data["iron_ingots_ready"]), int(data["pal_ingots_ready"]), float(timer)
	)
	return state if state.is_valid() else null
