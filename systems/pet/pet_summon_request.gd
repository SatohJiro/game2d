class_name PetSummonRequest
extends RefCounted

var selected_instance_id: StringName
var active_instance_id: StringName
var selected_exists: bool
var active_node_valid: bool


func _init(p_selected_instance_id: StringName, p_active_instance_id: StringName, p_selected_exists: bool, p_active_node_valid: bool) -> void:
	selected_instance_id = p_selected_instance_id
	active_instance_id = p_active_instance_id
	selected_exists = p_selected_exists
	active_node_valid = p_active_node_valid
