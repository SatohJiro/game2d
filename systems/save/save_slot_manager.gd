class_name SaveSlotManager
extends RefCounted

## Multi-slot save management (U3.3).
##
## Owns the save directory and maps stable slot IDs to SaveCoordinator
## instances, each keeping the repository's primary/backup atomicity.
## Slots: slot_1..slot_3 for manual saves, autosave for automatic saves.
## UI only lists/deletes/requests; all snapshot/apply work stays in the
## SaveCoordinator pipeline.

const SLOT_IDS: Array[StringName] = [&"slot_1", &"slot_2", &"slot_3"]
const AUTOSAVE_SLOT := &"autosave"
const DEFAULT_BASE_DIRECTORY := "user://saves"

var base_directory: String


func _init(p_base_directory: String = DEFAULT_BASE_DIRECTORY) -> void:
	base_directory = p_base_directory


static func is_valid_slot_id(slot_id: StringName) -> bool:
	return SLOT_IDS.has(slot_id) or slot_id == AUTOSAVE_SLOT


static func save_id_for_slot(slot_id: StringName) -> StringName:
	return StringName("save.%s" % String(slot_id))


func primary_path_for(slot_id: StringName) -> String:
	return "%s/%s.json" % [base_directory, String(slot_id)]


func coordinator_for(slot_id: StringName) -> SaveCoordinator:
	return SaveCoordinator.new(primary_path_for(slot_id))


func list_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for slot_id in SLOT_IDS + [AUTOSAVE_SLOT] as Array[StringName]:
		slots.append(describe_slot(slot_id))
	return slots


func describe_slot(slot_id: StringName) -> Dictionary:
	var info := {"slot_id": String(slot_id), "save_id": String(save_id_for_slot(slot_id)), "exists": false}
	if not is_valid_slot_id(slot_id):
		return info
	var repository := SaveRepository.new(primary_path_for(slot_id))
	var loaded: RefCounted = repository.load_snapshot()
	if loaded == null or not loaded.is_success():
		return info
	var snapshot: Dictionary = loaded.snapshot
	info["exists"] = true
	info["saved_at_unix"] = int(snapshot.get("saved_at_unix", 0))
	info["clock_seconds"] = float((snapshot.get("world", {}) as Dictionary).get("clock_seconds", 0.0))
	info["player_level"] = int((snapshot.get("player", {}) as Dictionary).get("level", 1))
	info["base_level"] = int((snapshot.get("base", {}) as Dictionary).get("base_level", 1))
	return info


func delete_slot(slot_id: StringName) -> bool:
	if not is_valid_slot_id(slot_id):
		return false
	var removed := false
	var primary := primary_path_for(slot_id)
	for path in [primary, "%s.bak" % primary, "%s.tmp" % primary]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			removed = true
	return removed
