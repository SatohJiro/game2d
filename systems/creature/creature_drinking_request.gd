class_name CreatureDrinkingRequest
extends RefCounted

var species_id: StringName
var has_water_source: bool
var water_distance: float
var roll: float
var is_protected: bool


func _init(
	p_species_id: StringName,
	p_has_water_source: bool,
	p_water_distance: float,
	p_roll: float,
	p_is_protected: bool
) -> void:
	species_id = p_species_id
	has_water_source = p_has_water_source
	water_distance = p_water_distance
	roll = p_roll
	is_protected = p_is_protected
