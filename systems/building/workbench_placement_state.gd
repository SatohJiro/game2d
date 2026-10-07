class_name WorkbenchPlacementState
extends RefCounted

const MAX_HEALTH := 200
var health: int

func _init(p_health: int = MAX_HEALTH) -> void:
	health = p_health

func is_valid() -> bool:
	return health >= 1 and health <= MAX_HEALTH

func to_dto() -> Dictionary:
	return {"health": health}

static func from_dto(value: Variant) -> WorkbenchPlacementState:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	if data.size() != 1 or not data.has("health") or typeof(data["health"]) != TYPE_INT: return null
	var state := WorkbenchPlacementState.new(int(data["health"]))
	return state if state.is_valid() else null
