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
var spawn_timer: float
var world_boss_state: WorldBossState
var night_raid_state: NightRaidState
var chunk_discovery_state: ChunkDiscoveryState
var ambient_cooldown_state: AmbientCooldownState


func _init(
	p_status: Status,
	p_world_clock_seconds: float = 0.0,
	p_upstream_status: int = -1,
	p_errors: PackedStringArray = PackedStringArray(),
	p_raid_triggered_this_cycle: bool = false,
	p_boss_spawned: bool = false,
	p_boss_timer: float = WorldCycleState.BOSS_SPAWN_SECONDS,
	p_spawn_timer: float = WorldCycleState.INITIAL_AMBIENT_SPAWN_SECONDS,
	p_world_boss_state: WorldBossState = null,
	p_night_raid_state: NightRaidState = null,
	p_chunk_discovery_state: ChunkDiscoveryState = null,
	p_ambient_cooldown_state: AmbientCooldownState = null
) -> void:
	status = p_status
	world_clock_seconds = p_world_clock_seconds
	upstream_status = p_upstream_status
	errors = p_errors.duplicate()
	raid_triggered_this_cycle = p_raid_triggered_this_cycle
	boss_spawned = p_boss_spawned
	boss_timer = p_boss_timer
	spawn_timer = p_spawn_timer
	world_boss_state = WorldBossState.new(p_world_boss_state.lifecycle_id, p_world_boss_state.instance_id, p_world_boss_state.hp, p_world_boss_state.position) if p_world_boss_state != null else WorldBossState.new()
	night_raid_state = NightRaidState.from_dto(p_night_raid_state.to_dto()) if p_night_raid_state != null else NightRaidState.new()
	chunk_discovery_state = ChunkDiscoveryState.from_dto(p_chunk_discovery_state.to_dto()) if p_chunk_discovery_state != null else ChunkDiscoveryState.new()
	ambient_cooldown_state = AmbientCooldownState.from_dto(p_ambient_cooldown_state.to_dto()) if p_ambient_cooldown_state != null else AmbientCooldownState.new()


func is_success() -> bool:
	return status == Status.SAVED or status == Status.LOADED_PRIMARY or status == Status.LOADED_BACKUP

func is_loaded() -> bool:
	return status == Status.LOADED_PRIMARY or status == Status.LOADED_BACKUP
