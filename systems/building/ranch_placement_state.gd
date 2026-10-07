class_name RanchPlacementState
extends RefCounted

const STARTER_RESIDENT_ID := &"ranch.resident_starter"
const MAX_ASSIGNMENTS := 2
const PRODUCTION_DURATION := 10.0

var food_count: int
var assignments: Array[Dictionary]
var production_timer: float


func _init(p_food_count: int = 8, p_assignments: Array[Dictionary] = [], p_production_timer: float = 0.0) -> void:
	food_count = p_food_count
	assignments = p_assignments.duplicate(true)
	production_timer = p_production_timer


func is_valid() -> bool:
	if food_count < 0 or assignments.size() > MAX_ASSIGNMENTS:
		return false
	if not is_finite(production_timer) or production_timer < 0.0 or production_timer >= PRODUCTION_DURATION:
		return false
	if assignments.is_empty() and not is_zero_approx(production_timer):
		return false
	var seen := {}
	for assignment: Dictionary in assignments:
		if assignment.size() != 2:
			return false
		var assignment_id := StringName(assignment.get("assignment_id", ""))
		var species_id := StringName(assignment.get("species_id", ""))
		if (assignment_id != STARTER_RESIDENT_ID and ContentId.domain_of(assignment_id) != &"pet") or seen.has(assignment_id) or not LegacySpeciesAdapter.is_supported(species_id):
			return false
		seen[assignment_id] = true
	return true


func to_dto() -> Dictionary:
	var projected: Array[Dictionary] = []
	for assignment: Dictionary in assignments:
		projected.append({"assignment_id": String(assignment["assignment_id"]), "species_id": String(assignment["species_id"])})
	return {"food_count": food_count, "assignments": projected, "production_timer": production_timer}


static func from_dto(value: Variant) -> RanchPlacementState:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = value
	if data.size() != 3 or typeof(data.get("food_count")) != TYPE_INT or typeof(data.get("assignments")) != TYPE_ARRAY:
		return null
	var timer: Variant = data.get("production_timer")
	if typeof(timer) != TYPE_INT and typeof(timer) != TYPE_FLOAT:
		return null
	var typed_assignments: Array[Dictionary] = []
	for assignment: Variant in data["assignments"]:
		if typeof(assignment) != TYPE_DICTIONARY:
			return null
		typed_assignments.append(assignment)
	var state := RanchPlacementState.new(int(data["food_count"]), typed_assignments, float(timer))
	return state if state.is_valid() else null
