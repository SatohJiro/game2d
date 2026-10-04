class_name CaptureResult
extends RefCounted

enum Status { OK, INVALID_REQUEST, INVALID_TARGET, ALREADY_CAPTURING, ALREADY_DEFEATED }

var status: Status
var species_id: StringName
var base_chance: float
var final_chance: float
var roll: float
var succeeded: bool
var applied_multiplier: float
var tags: PackedStringArray


func _init(
	result_status: Status,
	result_species_id: StringName = &"",
	result_base_chance: float = 0.0,
	result_final_chance: float = 0.0,
	result_roll: float = 0.0,
	result_succeeded: bool = false,
	result_applied_multiplier: float = 0.0,
	result_tags: PackedStringArray = PackedStringArray()
) -> void:
	status = result_status
	species_id = result_species_id
	base_chance = result_base_chance
	final_chance = result_final_chance
	roll = result_roll
	succeeded = result_succeeded
	applied_multiplier = result_applied_multiplier
	tags = result_tags.duplicate()


func is_resolved() -> bool:
	return status == Status.OK
