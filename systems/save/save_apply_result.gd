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
var world_boss_state: WorldBossState
var night_raid_state: NightRaidState


func _init(p_status: Status, p_world_clock_seconds: float = 0.0, p_errors: PackedStringArray = PackedStringArray(), p_raid_triggered_this_cycle: bool = false, p_boss_spawned: bool = false, p_boss_timer: float = WorldCycleState.BOSS_SPAWN_SECONDS, p_spawn_timer: float = WorldCycleState.INITIAL_AMBIENT_SPAWN_SECONDS, p_world_boss_state: WorldBossState = null, p_night_raid_state: NightRaidState = null) -> void:
	status = p_status
	world_clock_seconds = p_world_clock_seconds
	errors = p_errors.duplicate()
	raid_triggered_this_cycle = p_raid_triggered_this_cycle
	boss_spawned = p_boss_spawned
	boss_timer = p_boss_timer
	spawn_timer = p_spawn_timer
	world_boss_state = WorldBossState.new(p_world_boss_state.lifecycle_id, p_world_boss_state.instance_id, p_world_boss_state.hp, p_world_boss_state.position) if p_world_boss_state != null else WorldBossState.new()
	night_raid_state = NightRaidState.from_dto(p_night_raid_state.to_dto()) if p_night_raid_state != null else NightRaidState.new()


func is_applied() -> bool:
	return status == Status.APPLIED
