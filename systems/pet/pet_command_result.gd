class_name PetCommandResult
extends RefCounted

enum Status { APPLIED, NO_CHANGE, INVALID_REQUEST, UNSUPPORTED_COMMAND }

var status: Status
var command_id: StringName
var pet_instance_id: StringName
var previous_stance_id: StringName
var next_stance_id: StringName


func _init(p_status: Status, p_command_id: StringName = &"", p_pet_instance_id: StringName = &"", p_previous_stance_id: StringName = &"", p_next_stance_id: StringName = &"") -> void:
	status = p_status
	command_id = p_command_id
	pet_instance_id = p_pet_instance_id
	previous_stance_id = p_previous_stance_id
	next_stance_id = p_next_stance_id


func is_applied() -> bool:
	return status == Status.APPLIED


func is_resolved() -> bool:
	return status == Status.APPLIED or status == Status.NO_CHANGE
