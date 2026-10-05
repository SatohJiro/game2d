class_name CreatureEcologyCandidate
extends RefCounted

var candidate_key: StringName
var species_id: StringName
var is_prey: bool
var capture_active: bool
var distance: float


func _init(p_candidate_key: StringName, p_species_id: StringName, p_is_prey: bool, p_capture_active: bool, p_distance: float) -> void:
	candidate_key = p_candidate_key
	species_id = p_species_id
	is_prey = p_is_prey
	capture_active = p_capture_active
	distance = p_distance
