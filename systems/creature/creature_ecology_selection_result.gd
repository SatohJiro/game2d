class_name CreatureEcologySelectionResult
extends RefCounted

enum Status { SELECTED, NONE_AVAILABLE, INVALID_REQUEST, PROTECTED }

var status: Status
var candidate_key: StringName
var candidate_species_id: StringName
var distance: float
var transition_event_id: StringName
var hunt_duration: float


func _init(p_status: Status, p_candidate_key: StringName = &"", p_candidate_species_id: StringName = &"", p_distance: float = -1.0, p_transition_event_id: StringName = &"", p_hunt_duration: float = 0.0) -> void:
	status = p_status
	candidate_key = p_candidate_key
	candidate_species_id = p_candidate_species_id
	distance = p_distance
	transition_event_id = p_transition_event_id
	hunt_duration = p_hunt_duration


func is_selected() -> bool:
	return status == Status.SELECTED
