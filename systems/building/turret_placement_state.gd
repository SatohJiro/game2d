class_name TurretPlacementState
extends RefCounted

const FIRE_INTERVAL := 1.25
var cooldown_remaining: float

func _init(p_cooldown_remaining: float = 0.0) -> void:
	cooldown_remaining = p_cooldown_remaining

func is_valid() -> bool:
	return is_finite(cooldown_remaining) and cooldown_remaining >= 0.0 and cooldown_remaining <= FIRE_INTERVAL

func to_dto() -> Dictionary:
	return {"cooldown_remaining": cooldown_remaining}

static func from_dto(value: Variant) -> TurretPlacementState:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	if data.size() != 1: return null
	var cooldown: Variant = data.get("cooldown_remaining")
	if typeof(cooldown) != TYPE_INT and typeof(cooldown) != TYPE_FLOAT: return null
	var state := TurretPlacementState.new(float(cooldown))
	return state if state.is_valid() else null
