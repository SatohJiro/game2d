class_name CreatureSleepResult
extends RefCounted

enum Status { SLEEP, NO_CHANGE, INVALID_REQUEST, PROTECTED }

var status: Status
var species_id: StringName
var transition_event_id: StringName


func _init(p_status: Status, p_species_id: StringName = &"", p_transition_event_id: StringName = &"") -> void:
	status = p_status
	species_id = p_species_id
	transition_event_id = p_transition_event_id


func should_sleep() -> bool:
	return status == Status.SLEEP
