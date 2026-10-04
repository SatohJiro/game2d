class_name CreaturePerceptionCandidate
extends RefCounted

var candidate_id: int
var distance: float
var movement_speed: float
var is_valid: bool


func _init(
	input_candidate_id: int,
	input_distance: float,
	input_movement_speed: float,
	input_is_valid: bool = true
) -> void:
	candidate_id = input_candidate_id
	distance = input_distance
	movement_speed = input_movement_speed
	is_valid = input_is_valid
