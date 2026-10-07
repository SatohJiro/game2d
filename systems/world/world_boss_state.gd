class_name WorldBossState
extends RefCounted

const PENDING := &"world_boss.lifecycle.pending"
const ACTIVE := &"world_boss.lifecycle.active"
const DEFEATED := &"world_boss.lifecycle.defeated"
const INSTANCE_ID := &"boss.world_dragon_1"
const MAX_HP := 380

var lifecycle_id: StringName
var instance_id: StringName
var hp: int
var position: Vector2

func _init(p_lifecycle_id: StringName = PENDING, p_instance_id: StringName = &"", p_hp: int = 0, p_position: Vector2 = Vector2.ZERO) -> void:
	lifecycle_id = p_lifecycle_id
	instance_id = p_instance_id
	hp = p_hp
	position = p_position

func is_valid() -> bool:
	if not is_finite(position.x) or not is_finite(position.y): return false
	if lifecycle_id == PENDING:
		return instance_id == &"" and hp == 0 and position == Vector2.ZERO
	if lifecycle_id == ACTIVE:
		return instance_id == INSTANCE_ID and hp > 0 and hp <= MAX_HP
	if lifecycle_id == DEFEATED:
		return instance_id == INSTANCE_ID and hp == 0 and position == Vector2.ZERO
	return false

func to_dto() -> Dictionary:
	return {
		"lifecycle_id": String(lifecycle_id),
		"instance_id": String(instance_id),
		"hp": hp,
		"position_x": position.x,
		"position_y": position.y,
	}

static func from_dto(value: Variant) -> WorldBossState:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	if data.size() != 5: return null
	if typeof(data.get("lifecycle_id")) != TYPE_STRING or typeof(data.get("instance_id")) != TYPE_STRING: return null
	var hp_value: Variant = data.get("hp")
	if typeof(hp_value) != TYPE_INT and (typeof(hp_value) != TYPE_FLOAT or not is_equal_approx(float(hp_value), roundf(float(hp_value)))): return null
	var x: Variant = data.get("position_x")
	var y: Variant = data.get("position_y")
	if (typeof(x) != TYPE_INT and typeof(x) != TYPE_FLOAT) or (typeof(y) != TYPE_INT and typeof(y) != TYPE_FLOAT): return null
	var state := WorldBossState.new(StringName(data["lifecycle_id"]), StringName(data["instance_id"]), int(hp_value), Vector2(float(x), float(y)))
	return state if state.is_valid() else null
