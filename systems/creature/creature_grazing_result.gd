class_name CreatureGrazingResult
extends RefCounted

enum Status { GRAZE, NO_CHANGE, INVALID_REQUEST, PROTECTED }

var status: Status
var species_id: StringName
var transition_event_id: StringName


func _init(p_status: Status, p_species_id: StringName = &"", p_transition_event_id: StringName = &"") -> void:
	status = p_status
	species_id = p_species_id
	transition_event_id = p_transition_event_id


func should_graze() -> bool:
	return status == Status.GRAZE
