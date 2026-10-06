class_name SaveApplyPlan
extends RefCounted

var player_state: Dictionary
var legacy_inventory: Dictionary
var pet_party: Array[Dictionary]
var active_pet_instance_id: StringName
var active_pet_index: int
var active_stance_command_id: StringName
var base_progress_state: BaseProgressState
var world_clock_seconds: float


func _init(
	p_player_state: Dictionary,
	p_legacy_inventory: Dictionary,
	p_pet_party: Array[Dictionary],
	p_active_pet_instance_id: StringName,
	p_active_pet_index: int,
	p_active_stance_command_id: StringName,
	p_base_progress_state: BaseProgressState,
	p_world_clock_seconds: float
) -> void:
	player_state = p_player_state.duplicate(true)
	legacy_inventory = p_legacy_inventory.duplicate(true)
	pet_party = p_pet_party.duplicate(true)
	active_pet_instance_id = p_active_pet_instance_id
	active_pet_index = p_active_pet_index
	active_stance_command_id = p_active_stance_command_id
	base_progress_state = BaseProgressState.new(p_base_progress_state.base_level, p_base_progress_state.active_quest_id, p_base_progress_state.claimed_quest_ids)
	world_clock_seconds = p_world_clock_seconds
