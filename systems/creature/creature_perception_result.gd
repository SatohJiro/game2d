class_name CreaturePerceptionResult
extends RefCounted

enum Decision { NONE, SUSPICIOUS, ALERT }

var decision: Decision
var candidate_id: int


func _init(input_decision: Decision, input_candidate_id: int = 0) -> void:
	decision = input_decision
	candidate_id = input_candidate_id


func has_target_decision() -> bool:
	return decision != Decision.NONE and candidate_id > 0
