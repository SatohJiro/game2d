class_name ResourceDepletionRecord
extends RefCounted

const TREE_ID := &"resource.tree"
var instance_id: StringName
var resource_id: StringName
var state: ResourceDepletionState

func _init(p_instance_id: StringName, p_resource_id: StringName, p_state: ResourceDepletionState) -> void:
	instance_id = p_instance_id
	resource_id = p_resource_id
	state = p_state

func is_valid() -> bool:
	return ContentId.domain_of(instance_id) == &"resource" and resource_id == TREE_ID and state != null and state.is_valid()

func to_dto() -> Dictionary:
	return {"instance_id": String(instance_id), "resource_id": String(resource_id), "state": state.to_dto()}

static func from_dto(value: Variant) -> ResourceDepletionRecord:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	if data.size() != 3: return null
	var record := ResourceDepletionRecord.new(StringName(data.get("instance_id", "")), StringName(data.get("resource_id", "")), ResourceDepletionState.from_dto(data.get("state")))
	return record if record.is_valid() else null
