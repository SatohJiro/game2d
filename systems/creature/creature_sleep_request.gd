class_name CreatureSleepRequest
extends RefCounted

var species_id: StringName
var is_night_raider: bool
var is_enraged: bool
var roll: float
var is_protected: bool


func _init(
	p_species_id: StringName,
	p_is_night_raider: bool,
	p_is_enraged: bool,
	p_roll: float,
	p_is_protected: bool
) -> void:
	species_id = p_species_id
	is_night_raider = p_is_night_raider
	is_enraged = p_is_enraged
	roll = p_roll
	is_protected = p_is_protected
