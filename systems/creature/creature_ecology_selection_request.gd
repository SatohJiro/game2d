class_name CreatureEcologySelectionRequest
extends RefCounted

var predator_species_id: StringName
var is_predator: bool
var is_blocked: bool
var candidates: Array[CreatureEcologyCandidate]


func _init(p_predator_species_id: StringName, p_is_predator: bool, p_is_blocked: bool, p_candidates: Array[CreatureEcologyCandidate]) -> void:
	predator_species_id = p_predator_species_id
	is_predator = p_is_predator
	is_blocked = p_is_blocked
	candidates = p_candidates
