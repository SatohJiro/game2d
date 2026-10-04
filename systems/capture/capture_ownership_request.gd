class_name CaptureOwnershipRequest
extends RefCounted

var capture_token: StringName
var species_id: StringName
var species_snapshot: Dictionary
var level: int
var rarity_roll: float
var trait_roll: float
var already_committed: bool = false


func _init(
	request_capture_token: StringName,
	request_species_id: StringName,
	request_species_snapshot: Dictionary,
	request_level: int,
	request_rarity_roll: float,
	request_trait_roll: float
) -> void:
	capture_token = request_capture_token
	species_id = request_species_id
	species_snapshot = request_species_snapshot.duplicate(true)
	level = request_level
	rarity_roll = request_rarity_roll
	trait_roll = request_trait_roll
