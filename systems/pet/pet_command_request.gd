class_name PetCommandRequest
extends RefCounted

var command_id: StringName
var pet_instance_id: StringName
var current_stance_id: StringName


func _init(p_command_id: StringName, p_pet_instance_id: StringName, p_current_stance_id: StringName) -> void:
	command_id = p_command_id
	pet_instance_id = p_pet_instance_id
	current_stance_id = p_current_stance_id
