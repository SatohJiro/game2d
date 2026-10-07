class_name WorldCycleState
extends RefCounted

const DAY_DURATION := 180.0
const RAID_START := 0.72
const BOSS_SPAWN_SECONDS := 50.0
const AMBIENT_SPAWN_INTERVAL := 4.0
const INITIAL_AMBIENT_SPAWN_SECONDS := 3.0
var raid_triggered_this_cycle: bool
var boss_spawned: bool
var boss_timer: float
var spawn_timer: float

func _init(p_raid_triggered: bool = false, p_boss_spawned: bool = false, p_boss_timer: float = BOSS_SPAWN_SECONDS, p_spawn_timer: float = INITIAL_AMBIENT_SPAWN_SECONDS) -> void:
	raid_triggered_this_cycle = p_raid_triggered
	boss_spawned = p_boss_spawned
	boss_timer = p_boss_timer
	spawn_timer = p_spawn_timer

func is_valid(clock_seconds: float) -> bool:
	if not is_finite(clock_seconds) or clock_seconds < 0.0: return false
	if raid_triggered_this_cycle and fmod(clock_seconds / DAY_DURATION, 1.0) < RAID_START: return false
	if not is_finite(boss_timer) or boss_timer < 0.0 or boss_timer > BOSS_SPAWN_SECONDS: return false
	if not is_finite(spawn_timer) or spawn_timer <= 0.0 or spawn_timer > AMBIENT_SPAWN_INTERVAL: return false
	return (boss_spawned and is_zero_approx(boss_timer)) or (not boss_spawned and boss_timer > 0.0)

func to_dto() -> Dictionary:
	return {"raid_triggered_this_cycle": raid_triggered_this_cycle, "boss_spawned": boss_spawned, "boss_timer": boss_timer, "spawn_timer": spawn_timer}

static func from_dto(value: Variant, clock_seconds: float) -> WorldCycleState:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	if (data.size() != 1 and data.size() != 3 and data.size() != 4) or typeof(data.get("raid_triggered_this_cycle")) != TYPE_BOOL: return null
	if data.size() == 3 and typeof(data.get("boss_spawned")) != TYPE_BOOL: return null
	var timer: Variant = data.get("boss_timer", BOSS_SPAWN_SECONDS)
	if typeof(timer) != TYPE_INT and typeof(timer) != TYPE_FLOAT: return null
	var ambient_timer: Variant = data.get("spawn_timer", INITIAL_AMBIENT_SPAWN_SECONDS)
	if typeof(ambient_timer) != TYPE_INT and typeof(ambient_timer) != TYPE_FLOAT: return null
	var state := WorldCycleState.new(bool(data["raid_triggered_this_cycle"]), bool(data.get("boss_spawned", false)), float(timer), float(ambient_timer))
	return state if state.is_valid(clock_seconds) else null
