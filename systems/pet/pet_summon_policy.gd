class_name PetSummonPolicy
extends RefCounted

const SummonResult = preload("res://systems/pet/pet_summon_result.gd")


static func resolve(request: RefCounted) -> RefCounted:
	if request == null or not request.selected_exists or ContentId.domain_of(request.selected_instance_id) != &"pet":
		return SummonResult.new(SummonResult.Status.INVALID_REQUEST)
	if request.active_node_valid and request.active_instance_id == request.selected_instance_id:
		return SummonResult.new(SummonResult.Status.NO_CHANGE, request.selected_instance_id)
	if request.active_node_valid or not request.active_instance_id.is_empty():
		return SummonResult.new(SummonResult.Status.REPLACE, request.selected_instance_id)
	return SummonResult.new(SummonResult.Status.SUMMON, request.selected_instance_id)
