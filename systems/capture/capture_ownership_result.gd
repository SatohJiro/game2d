class_name CaptureOwnershipResult
extends RefCounted

enum Status { ACCEPTED, INVALID_REQUEST, UNKNOWN_SPECIES, DUPLICATE }

var status: Status
var capture_token: StringName
var species_id: StringName
var party_entry: Dictionary
var rarity_id: StringName
var trait_id: StringName
var rarity_badge: String
var trait_name: String
var stat_multiplier: float
var reward_exp: int


func _init(
	result_status: Status,
	result_capture_token: StringName = &"",
	result_species_id: StringName = &"",
	result_party_entry: Dictionary = {},
	result_rarity_id: StringName = &"",
	result_trait_id: StringName = &"",
	result_rarity_badge: String = "",
	result_trait_name: String = "",
	result_stat_multiplier: float = 0.0,
	result_reward_exp: int = 0
) -> void:
	status = result_status
	capture_token = result_capture_token
	species_id = result_species_id
	party_entry = result_party_entry.duplicate(true)
	rarity_id = result_rarity_id
	trait_id = result_trait_id
	rarity_badge = result_rarity_badge
	trait_name = result_trait_name
	stat_multiplier = result_stat_multiplier
	reward_exp = result_reward_exp


func is_accepted() -> bool:
	return status == Status.ACCEPTED
