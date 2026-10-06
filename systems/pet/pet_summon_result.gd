class_name PetSummonResult
extends RefCounted

enum Status { SUMMON, REPLACE, NO_CHANGE, INVALID_REQUEST }

var status: Status
var instance_id: StringName


func _init(p_status: Status, p_instance_id: StringName = &"") -> void:
	status = p_status
	instance_id = p_instance_id


func should_spawn() -> bool:
	return status == Status.SUMMON or status == Status.REPLACE
