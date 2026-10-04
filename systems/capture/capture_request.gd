class_name CaptureRequest
extends RefCounted

var species_id: StringName
var current_hp: int
var max_hp: int
var sphere_multiplier: float
var roll: float
var target_valid: bool = true
var already_capturing: bool = false
var already_defeated: bool = false
var is_asleep: bool = false
var is_back_strike: bool = false


func _init(
	request_species_id: StringName,
	request_current_hp: int,
	request_max_hp: int,
	request_sphere_multiplier: float,
	request_roll: float
) -> void:
	species_id = request_species_id
	current_hp = request_current_hp
	max_hp = request_max_hp
	sphere_multiplier = request_sphere_multiplier
	roll = request_roll
