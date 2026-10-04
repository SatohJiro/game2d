class_name CreaturePerceptionRequest
extends RefCounted

var is_blocked: bool
var is_sleeping: bool
var is_suspicious: bool
var aggro_distance: float
var suspicion_distance: float
var candidates: Array[CreaturePerceptionCandidate]


func _init(
	input_is_blocked: bool,
	input_is_sleeping: bool,
	input_is_suspicious: bool,
	input_aggro_distance: float,
	input_suspicion_distance: float,
	input_candidates: Array[CreaturePerceptionCandidate]
) -> void:
	is_blocked = input_is_blocked
	is_sleeping = input_is_sleeping
	is_suspicious = input_is_suspicious
	aggro_distance = input_aggro_distance
	suspicion_distance = input_suspicion_distance
	candidates = input_candidates.duplicate()
