class_name CookingPotPlacementState
extends RefCounted

var recipe_id: StringName
var remaining_seconds: float


func _init(p_recipe_id: StringName = &"", p_remaining_seconds: float = 0.0) -> void:
	recipe_id = p_recipe_id
	remaining_seconds = p_remaining_seconds


func is_valid() -> bool:
	if not is_finite(remaining_seconds) or remaining_seconds < 0.0:
		return false
	if recipe_id == &"":
		return is_zero_approx(remaining_seconds)
	return CookingRecipeCatalog.is_supported(recipe_id) and remaining_seconds > 0.0 and remaining_seconds <= CookingRecipeCatalog.get_duration(recipe_id)


func to_dto() -> Dictionary:
	return {"recipe_id": String(recipe_id), "remaining_seconds": remaining_seconds}


static func from_dto(value: Variant) -> CookingPotPlacementState:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = value
	if data.size() != 2 or typeof(data.get("recipe_id")) != TYPE_STRING:
		return null
	var remaining: Variant = data.get("remaining_seconds")
	if typeof(remaining) != TYPE_INT and typeof(remaining) != TYPE_FLOAT:
		return null
	var state := CookingPotPlacementState.new(StringName(data["recipe_id"]), float(remaining))
	return state if state.is_valid() else null
