class_name CreatureDropRequest
extends RefCounted

var species_id: StringName
var primary_item_id: StringName
var defeated: bool
var capture_active: bool
var already_committed: bool
var is_elite: bool
var is_alpha: bool
var primary_count_roll: int
var bonus_count_roll: int

func _init(p_species_id: StringName, p_primary_item_id: StringName, p_defeated: bool, p_capture_active: bool, p_already_committed: bool, p_is_elite: bool, p_is_alpha: bool, p_primary_count_roll: int, p_bonus_count_roll: int) -> void:
	species_id = p_species_id
	primary_item_id = p_primary_item_id
	defeated = p_defeated
	capture_active = p_capture_active
	already_committed = p_already_committed
	is_elite = p_is_elite
	is_alpha = p_is_alpha
	primary_count_roll = p_primary_count_roll
	bonus_count_roll = p_bonus_count_roll
