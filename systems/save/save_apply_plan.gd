class_name SaveApplyPlan
extends RefCounted

var player_state: Dictionary
var legacy_inventory: Dictionary
var pet_party: Array[Dictionary]
var active_pet_instance_id: StringName
var active_pet_index: int
var active_stance_command_id: StringName
var base_progress_state: BaseProgressState
var building_placements: Array[BuildingPlacementRecord]
var resource_depletions: Array[ResourceDepletionRecord]
var world_clock_seconds: float
var raid_triggered_this_cycle: bool
var boss_spawned: bool
var boss_timer: float


func _init(
	p_player_state: Dictionary,
	p_legacy_inventory: Dictionary,
	p_pet_party: Array[Dictionary],
	p_active_pet_instance_id: StringName,
	p_active_pet_index: int,
	p_active_stance_command_id: StringName,
	p_base_progress_state: BaseProgressState,
	p_building_placements: Array[BuildingPlacementRecord],
	p_resource_depletions: Array[ResourceDepletionRecord],
	p_world_clock_seconds: float,
	p_raid_triggered_this_cycle: bool,
	p_boss_spawned: bool,
	p_boss_timer: float
) -> void:
	player_state = p_player_state.duplicate(true)
	legacy_inventory = p_legacy_inventory.duplicate(true)
	pet_party = p_pet_party.duplicate(true)
	active_pet_instance_id = p_active_pet_instance_id
	active_pet_index = p_active_pet_index
	active_stance_command_id = p_active_stance_command_id
	base_progress_state = BaseProgressState.new(p_base_progress_state.base_level, p_base_progress_state.active_quest_id, p_base_progress_state.claimed_quest_ids)
	building_placements = p_building_placements.duplicate()
	resource_depletions = p_resource_depletions.duplicate()
	world_clock_seconds = p_world_clock_seconds
	raid_triggered_this_cycle = p_raid_triggered_this_cycle
	boss_spawned = p_boss_spawned
	boss_timer = p_boss_timer
