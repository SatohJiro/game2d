class_name WorldCycleState
extends RefCounted

const DAY_DURATION := 180.0
const RAID_START := 0.72
var raid_triggered_this_cycle: bool

func _init(p_raid_triggered: bool = false) -> void:
	raid_triggered_this_cycle = p_raid_triggered

func is_valid(clock_seconds: float) -> bool:
	if not is_finite(clock_seconds) or clock_seconds < 0.0: return false
	return not raid_triggered_this_cycle or fmod(clock_seconds / DAY_DURATION, 1.0) >= RAID_START

func to_dto() -> Dictionary:
	return {"raid_triggered_this_cycle": raid_triggered_this_cycle}

static func from_dto(value: Variant, clock_seconds: float) -> WorldCycleState:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	if data.size() != 1 or typeof(data.get("raid_triggered_this_cycle")) != TYPE_BOOL: return null
	var state := WorldCycleState.new(bool(data["raid_triggered_this_cycle"]))
	return state if state.is_valid(clock_seconds) else null
