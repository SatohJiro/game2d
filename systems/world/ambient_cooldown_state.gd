class_name AmbientCooldownState
extends RefCounted

## Typed defeat/capture cooldown registry for ambient spawn slots (U2.7).
##
## Slots are stable ambient instance IDs (ambient.<chunk>_s<slot>); expiry is
## measured in world-clock seconds. Expired entries are pruned lazily on
## query, explicitly before persistence snapshots, and on save import.
## DTO: {"cooldowns": [{"slot_id": String, "expires_at_seconds": float}]}.
## from_dto(null) returns an empty state so legacy saves stay valid;
## malformed DTOs return null so the schema can fail closed.

const COOLDOWN_SECONDS := 120.0

var _expires_at: Dictionary = {}


func is_empty() -> bool:
	return _expires_at.is_empty()


func entry_count() -> int:
	return _expires_at.size()


static func is_valid_slot_id(slot_id: StringName) -> bool:
	return ContentId.is_valid(slot_id) and ContentId.domain_of(slot_id) == &"ambient"


func register(slot_id: StringName, expires_at_seconds: float) -> bool:
	if not is_valid_slot_id(slot_id):
		return false
	if not is_finite(expires_at_seconds) or expires_at_seconds < 0.0:
		return false
	var previous := float(_expires_at.get(slot_id, -1.0))
	_expires_at[slot_id] = maxf(previous, expires_at_seconds)
	return true


func is_cooling_down(slot_id: StringName, clock_seconds: float) -> bool:
	prune_expired(clock_seconds)
	return _expires_at.has(slot_id)


func active_ids(clock_seconds: float) -> Array[StringName]:
	prune_expired(clock_seconds)
	var ids: Array[StringName] = []
	for slot_id in _expires_at:
		ids.append(slot_id)
	ids.sort()
	return ids


func expires_at(slot_id: StringName) -> float:
	return float(_expires_at.get(slot_id, -1.0))


func prune_expired(clock_seconds: float) -> int:
	var removed := 0
	for slot_id in _expires_at.keys():
		if float(_expires_at[slot_id]) <= clock_seconds:
			_expires_at.erase(slot_id)
			removed += 1
	return removed


func to_dto() -> Dictionary:
	var entries: Array[Dictionary] = []
	var ids: Array[StringName] = []
	for slot_id in _expires_at:
		ids.append(slot_id)
	ids.sort()
	for slot_id in ids:
		entries.append({"slot_id": String(slot_id), "expires_at_seconds": float(_expires_at[slot_id])})
	return {"cooldowns": entries}


static func from_dto(value: Variant) -> AmbientCooldownState:
	var state := AmbientCooldownState.new()
	if value == null:
		return state
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var raw_entries: Variant = (value as Dictionary).get("cooldowns", [])
	if typeof(raw_entries) != TYPE_ARRAY:
		return null
	for raw_entry in raw_entries:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			return null
		var entry: Dictionary = raw_entry
		var slot_id := StringName(entry.get("slot_id", ""))
		var expires_at_value: Variant = entry.get("expires_at_seconds")
		if not is_valid_slot_id(slot_id):
			return null
		if typeof(expires_at_value) != TYPE_INT and typeof(expires_at_value) != TYPE_FLOAT:
			return null
		if not is_finite(float(expires_at_value)) or float(expires_at_value) < 0.0:
			return null
		if not state.register(slot_id, float(expires_at_value)):
			return null
	return state
