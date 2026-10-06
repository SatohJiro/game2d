class_name BaseProgressState
extends RefCounted

var base_level: int
var active_quest_id: StringName
var claimed_quest_ids: Array[StringName]


func _init(p_base_level: int, p_active_quest_id: StringName, p_claimed_quest_ids: Array[StringName]) -> void:
	base_level = p_base_level
	active_quest_id = p_active_quest_id
	claimed_quest_ids = p_claimed_quest_ids.duplicate()


func is_valid() -> bool:
	if claimed_quest_ids.size() > BaseQuestCatalog.QUEST_IDS.size():
		return false
	for index in claimed_quest_ids.size():
		if claimed_quest_ids[index] != BaseQuestCatalog.QUEST_IDS[index]:
			return false
	var expected_active := BaseQuestCatalog.quest_id_at(claimed_quest_ids.size())
	return (
		active_quest_id == expected_active
		and base_level == BaseQuestCatalog.expected_level_for_claim_count(claimed_quest_ids.size())
	)


func to_dto() -> Dictionary:
	var claimed: Array[String] = []
	for quest_id in claimed_quest_ids:
		claimed.append(String(quest_id))
	return {
		"base_level": base_level,
		"active_quest_id": String(active_quest_id),
		"claimed_quest_ids": claimed,
	}


static func from_dto(value: Variant) -> BaseProgressState:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = value
	var level_value: Variant = data.get("base_level")
	if (typeof(level_value) != TYPE_INT and typeof(level_value) != TYPE_FLOAT) or not is_finite(float(level_value)) or not is_equal_approx(float(level_value), floor(float(level_value))) or typeof(data.get("active_quest_id")) != TYPE_STRING or typeof(data.get("claimed_quest_ids")) != TYPE_ARRAY:
		return null
	var claimed: Array[StringName] = []
	for quest_id: Variant in data["claimed_quest_ids"]:
		if typeof(quest_id) != TYPE_STRING:
			return null
		claimed.append(StringName(quest_id))
	var state := BaseProgressState.new(int(data["base_level"]), StringName(data["active_quest_id"]), claimed)
	return state if state.is_valid() else null
