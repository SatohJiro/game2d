class_name CreaturePerceptionCadence
extends RefCounted

const DEFAULT_INTERVAL := 0.20

var interval: float
var remaining: float
var query_count: int = 0


func _init(input_interval: float = DEFAULT_INTERVAL) -> void:
	interval = input_interval if input_interval > 0.0 and is_finite(input_interval) else DEFAULT_INTERVAL
	remaining = interval


func advance(delta: float) -> bool:
	if delta <= 0.0 or not is_finite(delta):
		return false
	remaining -= delta
	if remaining > 0.000001:
		return false
	while remaining <= 0.000001:
		remaining += interval
	query_count += 1
	return true


func reset() -> void:
	remaining = interval
	query_count = 0
