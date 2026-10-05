class_name CreatureEcologyResult
extends RefCounted

enum Status { PANIC_FLEE, NO_CHANGE, INVALID_REQUEST, PROTECTED }

var status: Status
var species_id: StringName
var transition_event_id: StringName
var state_duration: float


func _init(p_status: Status, p_species_id: StringName = &"", p_transition_event_id: StringName = &"", p_state_duration: float = 0.0) -> void:
	status = p_status
	species_id = p_species_id
	transition_event_id = p_transition_event_id
	state_duration = p_state_duration


func should_panic_flee() -> bool:
	return status == Status.PANIC_FLEE
