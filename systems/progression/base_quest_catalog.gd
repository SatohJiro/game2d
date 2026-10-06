class_name BaseQuestCatalog
extends RefCounted

const QUEST_IDS: Array[StringName] = [
	&"quest.base.survival",
	&"quest.base.organic_farming",
	&"quest.base.automation",
	&"quest.base.fortress",
	&"quest.base.paloria_lord",
]

const UNLOCK_LEVELS: Dictionary = {
	&"quest.base.survival": 2,
	&"quest.base.organic_farming": 3,
	&"quest.base.automation": 4,
	&"quest.base.fortress": 5,
	&"quest.base.paloria_lord": 5,
}


static func is_supported(quest_id: StringName) -> bool:
	return QUEST_IDS.has(quest_id)


static func index_of(quest_id: StringName) -> int:
	return QUEST_IDS.find(quest_id)


static func quest_id_at(index: int) -> StringName:
	return QUEST_IDS[index] if index >= 0 and index < QUEST_IDS.size() else &""


static func expected_level_for_claim_count(claim_count: int) -> int:
	if claim_count <= 0:
		return 1
	var quest_id := quest_id_at(clampi(claim_count, 1, QUEST_IDS.size()) - 1)
	return int(UNLOCK_LEVELS.get(quest_id, 1))
