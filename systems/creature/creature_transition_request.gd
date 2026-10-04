class_name CreatureTransitionRequest
extends RefCounted

var current_state_id: StringName
var event_id: StringName
var condition_met: bool
var has_target: bool
var target_distance: float
var is_night_raider: bool
var proposed_timer: float
var is_protected: bool


func _init(
	input_current_state_id: StringName,
	input_event_id: StringName,
	input_condition_met: bool,
	input_has_target: bool = false,
	input_target_distance: float = -1.0,
	input_is_night_raider: bool = false,
	input_proposed_timer: float = 0.0,
	input_is_protected: bool = false
) -> void:
	current_state_id = input_current_state_id
	event_id = input_event_id
	condition_met = input_condition_met
	has_target = input_has_target
	target_distance = input_target_distance
	is_night_raider = input_is_night_raider
	proposed_timer = input_proposed_timer
	is_protected = input_is_protected
