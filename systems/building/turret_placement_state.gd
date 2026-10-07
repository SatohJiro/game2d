class_name TurretPlacementState
extends RefCounted

const FIRE_INTERVAL := 1.25
const MAX_HEALTH := 350
var cooldown_remaining: float
var health: int

func _init(p_cooldown_remaining: float = 0.0, p_health: int = MAX_HEALTH) -> void:
	cooldown_remaining = p_cooldown_remaining
	health = p_health

func is_valid() -> bool:
	return is_finite(cooldown_remaining) and cooldown_remaining >= 0.0 and cooldown_remaining <= FIRE_INTERVAL and health >= 1 and health <= MAX_HEALTH

func to_dto() -> Dictionary:
	return {"cooldown_remaining": cooldown_remaining, "health": health}

static func from_dto(value: Variant) -> TurretPlacementState:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	if (data.size() != 1 and data.size() != 2) or (data.size() == 2 and not data.has("health")): return null
	var cooldown: Variant = data.get("cooldown_remaining")
	if typeof(cooldown) != TYPE_INT and typeof(cooldown) != TYPE_FLOAT: return null
	var health_value: Variant = data.get("health", MAX_HEALTH)
	if typeof(health_value) != TYPE_INT: return null
	var state := TurretPlacementState.new(float(cooldown), int(health_value))
	return state if state.is_valid() else null
