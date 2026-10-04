class_name CreatureTransitionResult
extends RefCounted

enum Status { CHANGED, NO_CHANGE, INVALID_REQUEST, PROTECTED }
enum TargetAction { KEEP, CLEAR }

var status: Status
var from_state_id: StringName
var to_state_id: StringName
var reason_id: StringName
var next_timer: float
var target_action: TargetAction


func _init(
	input_status: Status,
	input_from_state_id: StringName = &"",
	input_to_state_id: StringName = &"",
	input_reason_id: StringName = &"",
	input_next_timer: float = 0.0,
	input_target_action: TargetAction = TargetAction.KEEP
) -> void:
	status = input_status
	from_state_id = input_from_state_id
	to_state_id = input_to_state_id
	reason_id = input_reason_id
	next_timer = input_next_timer
	target_action = input_target_action


func is_changed() -> bool:
	return status == Status.CHANGED
