class_name CreatureEcologyRequest
extends RefCounted

var species_id: StringName
var is_prey: bool
var current_hp: int
var max_hp: int
var defeated: bool
var is_enraged: bool
var capture_active: bool


func _init(p_species_id: StringName, p_is_prey: bool, p_current_hp: int, p_max_hp: int, p_defeated: bool, p_is_enraged: bool, p_capture_active: bool) -> void:
	species_id = p_species_id
	is_prey = p_is_prey
	current_hp = p_current_hp
	max_hp = p_max_hp
	defeated = p_defeated
	is_enraged = p_is_enraged
	capture_active = p_capture_active
