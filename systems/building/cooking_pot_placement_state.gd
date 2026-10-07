class_name CookingPotPlacementState
extends RefCounted

const MAX_HEALTH := 200

var recipe_id: StringName
var remaining_seconds: float
var health: int


func _init(p_recipe_id: StringName = &"", p_remaining_seconds: float = 0.0, p_health: int = MAX_HEALTH) -> void:
	recipe_id = p_recipe_id
	remaining_seconds = p_remaining_seconds
	health = p_health


func is_valid() -> bool:
	if health < 1 or health > MAX_HEALTH:
		return false
	if not is_finite(remaining_seconds) or remaining_seconds < 0.0:
		return false
	if recipe_id == &"":
		return is_zero_approx(remaining_seconds)
	return CookingRecipeCatalog.is_supported(recipe_id) and remaining_seconds > 0.0 and remaining_seconds <= CookingRecipeCatalog.get_duration(recipe_id)


func to_dto() -> Dictionary:
	return {"recipe_id": String(recipe_id), "remaining_seconds": remaining_seconds, "health": health}


static func from_dto(value: Variant) -> CookingPotPlacementState:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = value
	if (data.size() != 2 and data.size() != 3) or typeof(data.get("recipe_id")) != TYPE_STRING or (data.size() == 3 and not data.has("health")):
		return null
	var remaining: Variant = data.get("remaining_seconds")
	if typeof(remaining) != TYPE_INT and typeof(remaining) != TYPE_FLOAT:
		return null
	var health_value: Variant = data.get("health", MAX_HEALTH)
	if typeof(health_value) != TYPE_INT:
		return null
	var state := CookingPotPlacementState.new(StringName(data["recipe_id"]), float(remaining), int(health_value))
	return state if state.is_valid() else null
