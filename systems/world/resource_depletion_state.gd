class_name ResourceDepletionState
extends RefCounted

const TREE_MAX_HEALTH := 60
const ROCK_MAX_HEALTH := 80
const RESPAWN_SECONDS := 18.0
var health: int
var respawn_remaining: float
var max_health: int

func _init(p_health: int = TREE_MAX_HEALTH, p_respawn_remaining: float = 0.0, p_max_health: int = TREE_MAX_HEALTH) -> void:
	health = p_health
	respawn_remaining = p_respawn_remaining
	max_health = p_max_health

func is_valid() -> bool:
	if not is_finite(respawn_remaining) or respawn_remaining < 0.0 or respawn_remaining > RESPAWN_SECONDS:
		return false
	if max_health != TREE_MAX_HEALTH and max_health != ROCK_MAX_HEALTH:
		return false
	return (health >= 1 and health <= max_health and is_zero_approx(respawn_remaining)) or (health == 0 and respawn_remaining > 0.0)

func to_dto() -> Dictionary:
	return {"health": health, "respawn_remaining": respawn_remaining}

static func from_dto(value: Variant, p_max_health: int = TREE_MAX_HEALTH) -> ResourceDepletionState:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	if data.size() != 2 or typeof(data.get("health")) != TYPE_INT: return null
	var timer: Variant = data.get("respawn_remaining")
	if typeof(timer) != TYPE_INT and typeof(timer) != TYPE_FLOAT: return null
	var state := ResourceDepletionState.new(int(data["health"]), float(timer), p_max_health)
	return state if state.is_valid() else null
