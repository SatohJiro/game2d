class_name CreatureDropResult
extends RefCounted

enum Status { ACCEPTED, INVALID_REQUEST, NOT_DEFEATED, CAPTURE_BLOCKED, DUPLICATE }

var status: Status
var species_id: StringName
var primary_item_id: StringName
var primary_count: int
var bonus_item_id: StringName
var bonus_count: int

func _init(p_status: Status, p_species_id: StringName = &"", p_primary_item_id: StringName = &"", p_primary_count: int = 0, p_bonus_item_id: StringName = &"", p_bonus_count: int = 0) -> void:
	status = p_status
	species_id = p_species_id
	primary_item_id = p_primary_item_id
	primary_count = p_primary_count
	bonus_item_id = p_bonus_item_id
	bonus_count = p_bonus_count

func is_accepted() -> bool:
	return status == Status.ACCEPTED
