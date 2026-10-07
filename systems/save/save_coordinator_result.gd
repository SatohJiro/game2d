class_name SaveCoordinatorResult
extends RefCounted

enum Status { SAVED, LOADED_PRIMARY, LOADED_BACKUP, SNAPSHOT_FAILED, REPOSITORY_FAILED, MIGRATION_FAILED, APPLY_FAILED }

var status: Status
var world_clock_seconds: float
var upstream_status: int
var errors: PackedStringArray
var raid_triggered_this_cycle: bool
var boss_spawned: bool
var boss_timer: float


func _init(
	p_status: Status,
	p_world_clock_seconds: float = 0.0,
	p_upstream_status: int = -1,
	p_errors: PackedStringArray = PackedStringArray(),
	p_raid_triggered_this_cycle: bool = false,
	p_boss_spawned: bool = false,
	p_boss_timer: float = WorldCycleState.BOSS_SPAWN_SECONDS
) -> void:
	status = p_status
	world_clock_seconds = p_world_clock_seconds
	upstream_status = p_upstream_status
	errors = p_errors.duplicate()
	raid_triggered_this_cycle = p_raid_triggered_this_cycle
	boss_spawned = p_boss_spawned
	boss_timer = p_boss_timer


func is_success() -> bool:
	return status == Status.SAVED or status == Status.LOADED_PRIMARY or status == Status.LOADED_BACKUP

func is_loaded() -> bool:
	return status == Status.LOADED_PRIMARY or status == Status.LOADED_BACKUP
