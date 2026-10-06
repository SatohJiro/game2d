class_name CompostBinPlacementState
extends RefCounted

const MAX_MATERIALS := 10
const BATCH_DURATION := 8.0

var organic_materials: int
var ready_fertilizer_count: int
var composting_timer: float


func _init(p_organic_materials: int = 0, p_ready_fertilizer_count: int = 0, p_composting_timer: float = 0.0) -> void:
	organic_materials = p_organic_materials
	ready_fertilizer_count = p_ready_fertilizer_count
	composting_timer = p_composting_timer


func is_valid() -> bool:
	if organic_materials < 0 or organic_materials > MAX_MATERIALS or ready_fertilizer_count < 0:
		return false
	if not is_finite(composting_timer) or composting_timer < 0.0 or composting_timer >= BATCH_DURATION:
		return false
	return organic_materials > 0 or is_zero_approx(composting_timer)


func to_dto() -> Dictionary:
	return {
		"organic_materials": organic_materials,
		"ready_fertilizer_count": ready_fertilizer_count,
		"composting_timer": composting_timer,
	}


static func from_dto(value: Variant) -> CompostBinPlacementState:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = value
	if data.size() != 3 or typeof(data.get("organic_materials")) != TYPE_INT or typeof(data.get("ready_fertilizer_count")) != TYPE_INT:
		return null
	var timer: Variant = data.get("composting_timer")
	if typeof(timer) != TYPE_INT and typeof(timer) != TYPE_FLOAT:
		return null
	var state := CompostBinPlacementState.new(int(data["organic_materials"]), int(data["ready_fertilizer_count"]), float(timer))
	return state if state.is_valid() else null
