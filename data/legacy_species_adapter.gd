class_name LegacySpeciesAdapter
extends RefCounted

const FLAM_ID: StringName = &"creature.flam"
const SLIME_ID: StringName = &"creature.slime"
const MUSHROOM_ID: StringName = &"creature.mushroom"
const BEAST_ID: StringName = &"creature.beast"
const DRAGON_ID: StringName = &"creature.dragon"

const INDEX_TO_CONTENT_ID: Array[StringName] = [
	FLAM_ID,
	SLIME_ID,
	MUSHROOM_ID,
	BEAST_ID,
	DRAGON_ID,
]

const CONTENT_ID_TO_INDEX: Dictionary = {
	FLAM_ID: 0,
	SLIME_ID: 1,
	MUSHROOM_ID: 2,
	BEAST_ID: 3,
	DRAGON_ID: 4,
}


static func to_content_id(species_index: int) -> StringName:
	if species_index < 0 or species_index >= INDEX_TO_CONTENT_ID.size():
		return &""
	return INDEX_TO_CONTENT_ID[species_index]


static func to_legacy_index(species_id: StringName) -> int:
	return int(CONTENT_ID_TO_INDEX.get(species_id, -1))


static func is_supported(species_id: StringName) -> bool:
	return CONTENT_ID_TO_INDEX.has(species_id)


static func create_stable_snapshot(species_index: int, legacy_data: Dictionary) -> Dictionary:
	var species_id := to_content_id(species_index)
	if species_id.is_empty() or legacy_data.is_empty():
		return {}
	var snapshot := legacy_data.duplicate(true)
	snapshot["id"] = species_id
	return snapshot
