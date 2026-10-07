class_name NightRaidState
extends RefCounted

const PENDING := &"raid.lifecycle.pending"
const ACTIVE := &"raid.lifecycle.active"
const CLEARED := &"raid.lifecycle.cleared"
const ENCOUNTER_ID := &"raid.night_current"
const DAY_DURATION := 180.0

var lifecycle_id: StringName
var encounter_id: StringName
var cycle_index: int
var actors: Array[NightRaidActorState]

func _init(p_lifecycle_id: StringName = PENDING, p_encounter_id: StringName = &"", p_cycle_index: int = -1, p_actors: Array[NightRaidActorState] = []) -> void:
	lifecycle_id = p_lifecycle_id
	encounter_id = p_encounter_id
	cycle_index = p_cycle_index
	actors = p_actors.duplicate()

func is_valid() -> bool:
	if lifecycle_id == PENDING: return encounter_id == &"" and cycle_index == -1 and actors.is_empty()
	if encounter_id != ENCOUNTER_ID or cycle_index < 0: return false
	if lifecycle_id == CLEARED: return actors.is_empty()
	if lifecycle_id != ACTIVE or actors.is_empty() or actors.size() > 3: return false
	var seen := {}
	for actor in actors:
		if actor == null or not actor.is_valid() or seen.has(actor.instance_id): return false
		seen[actor.instance_id] = true
	return true

func is_coherent(raid_triggered_this_cycle: bool, clock_seconds: float) -> bool:
	if not is_valid() or not is_finite(clock_seconds) or clock_seconds < 0.0: return false
	if lifecycle_id == PENDING: return not raid_triggered_this_cycle
	return raid_triggered_this_cycle and cycle_index == int(floor(clock_seconds / DAY_DURATION))

func to_dto() -> Dictionary:
	var actor_dtos: Array = []
	for actor in actors: actor_dtos.append(actor.to_dto())
	return {"lifecycle_id": String(lifecycle_id), "encounter_id": String(encounter_id), "cycle_index": cycle_index, "actors": actor_dtos}

static func from_dto(value: Variant) -> NightRaidState:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	if data.size() != 4 or typeof(data.get("lifecycle_id")) != TYPE_STRING or typeof(data.get("encounter_id")) != TYPE_STRING or typeof(data.get("actors")) != TYPE_ARRAY: return null
	var cycle_value: Variant = data.get("cycle_index")
	if (typeof(cycle_value) != TYPE_INT and typeof(cycle_value) != TYPE_FLOAT) or not is_equal_approx(float(cycle_value), roundf(float(cycle_value))): return null
	var parsed_actors: Array[NightRaidActorState] = []
	for actor_value: Variant in data["actors"]:
		var actor := NightRaidActorState.from_dto(actor_value)
		if actor == null: return null
		parsed_actors.append(actor)
	var state := NightRaidState.new(StringName(data["lifecycle_id"]), StringName(data["encounter_id"]), int(cycle_value), parsed_actors)
	return state if state.is_valid() else null
