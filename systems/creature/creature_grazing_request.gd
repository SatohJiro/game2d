class_name CreatureGrazingRequest
extends RefCounted

var species_id: StringName
var is_prey: bool
var roll: float
var is_protected: bool


func _init(p_species_id: StringName, p_is_prey: bool, p_roll: float, p_is_protected: bool) -> void:
	species_id = p_species_id
	is_prey = p_is_prey
	roll = p_roll
	is_protected = p_is_protected
