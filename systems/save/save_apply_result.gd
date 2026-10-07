class_name SaveApplyResult
extends RefCounted

enum Status { APPLIED, INVALID_TARGET, INVALID_SNAPSHOT, UNSUPPORTED_REFERENCE, COMMIT_FAILED }

var status: Status
var world_clock_seconds: float
var errors: PackedStringArray
var raid_triggered_this_cycle: bool
var boss_spawned: bool
var boss_timer: float
var spawn_timer: float


func _init(p_status: Status, p_world_clock_seconds: float = 0.0, p_errors: PackedStringArray = PackedStringArray(), p_raid_triggered_this_cycle: bool = false, p_boss_spawned: bool = false, p_boss_timer: float = WorldCycleState.BOSS_SPAWN_SECONDS, p_spawn_timer: float = WorldCycleState.INITIAL_AMBIENT_SPAWN_SECONDS) -> void:
	status = p_status
	world_clock_seconds = p_world_clock_seconds
	errors = p_errors.duplicate()
	raid_triggered_this_cycle = p_raid_triggered_this_cycle
	boss_spawned = p_boss_spawned
	boss_timer = p_boss_timer
	spawn_timer = p_spawn_timer


func is_applied() -> bool:
	return status == Status.APPLIED
