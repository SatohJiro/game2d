class_name AltarPlacementState
extends RefCounted

const IDLE := &"altar.lifecycle.idle"
const ACTIVE := &"altar.lifecycle.active"
const BOSS_MAX_HP := 280

var lifecycle_id: StringName
var boss_instance_id: StringName
var boss_hp: int

func _init(p_lifecycle_id: StringName = IDLE, p_boss_instance_id: StringName = &"", p_boss_hp: int = 0) -> void:
	lifecycle_id = p_lifecycle_id; boss_instance_id = p_boss_instance_id; boss_hp = p_boss_hp

func is_valid() -> bool:
	if lifecycle_id == IDLE: return boss_instance_id == &"" and boss_hp == 0
	return lifecycle_id == ACTIVE and ContentId.domain_of(boss_instance_id) == &"boss" and boss_hp > 0 and boss_hp <= BOSS_MAX_HP

func to_dto() -> Dictionary:
	return {"lifecycle_id": String(lifecycle_id), "boss_instance_id": String(boss_instance_id), "boss_hp": boss_hp}

static func from_dto(value: Variant) -> AltarPlacementState:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	if data.size() != 3 or typeof(data.get("lifecycle_id")) != TYPE_STRING or typeof(data.get("boss_instance_id")) != TYPE_STRING or typeof(data.get("boss_hp")) != TYPE_INT: return null
	var state := AltarPlacementState.new(StringName(data["lifecycle_id"]), StringName(data["boss_instance_id"]), int(data["boss_hp"]))
	return state if state.is_valid() else null
