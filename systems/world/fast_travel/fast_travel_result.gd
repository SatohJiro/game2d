class_name FastTravelResult
extends RefCounted

enum Status {
	OK,
	INVALID,
	UNKNOWN_DESTINATION,
	STALE_DISCOVERY,
	UNDISCOVERED,
	SAME_DESTINATION,
	ENCOUNTER_GUARD,
	COOLDOWN_ACTIVE,
	INSUFFICIENT_COST,
	COMMIT_FAILED,
}

var status: Status
var destination_id: StringName
var chunk_key: StringName
var landing_position: Vector2
var cost_item_id: StringName
var cost_amount: int
var discovery_revision: int


func _init(
	p_status: Status,
	p_destination_id: StringName = &"",
	p_chunk_key: StringName = &"",
	p_landing_position: Vector2 = Vector2.ZERO,
	p_cost_item_id: StringName = &"",
	p_cost_amount: int = 0,
	p_discovery_revision: int = 0
) -> void:
	status = p_status
	destination_id = p_destination_id
	chunk_key = p_chunk_key
	landing_position = p_landing_position
	cost_item_id = p_cost_item_id
	cost_amount = p_cost_amount
	discovery_revision = p_discovery_revision


func is_success() -> bool:
	return status == Status.OK
