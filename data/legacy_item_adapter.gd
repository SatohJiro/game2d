class_name LegacyItemAdapter
extends RefCounted

const LEGACY_TO_CONTENT_ID: Dictionary = {
	"Gỗ": &"item.wood",
}

const CONTENT_ID_TO_LEGACY: Dictionary = {
	&"item.wood": "Gỗ",
}


static func to_content_id(value: String) -> StringName:
	if LEGACY_TO_CONTENT_ID.has(value):
		return LEGACY_TO_CONTENT_ID[value] as StringName
	var candidate := StringName(value)
	return candidate if ContentId.is_valid(candidate) else &""


static func to_legacy_key(content_id: StringName) -> String:
	return String(CONTENT_ID_TO_LEGACY.get(content_id, ""))


static func is_mapped(content_id: StringName) -> bool:
	return CONTENT_ID_TO_LEGACY.has(content_id)


static func get_count(legacy_inventory: Dictionary, content_id: StringName) -> int:
	var legacy_key := to_legacy_key(content_id)
	if legacy_key.is_empty():
		return 0
	return maxi(0, int(legacy_inventory.get(legacy_key, 0)))


static func add(legacy_inventory: Dictionary, content_id: StringName, amount: int) -> bool:
	if amount <= 0:
		return false
	var legacy_key := to_legacy_key(content_id)
	if legacy_key.is_empty():
		return false
	legacy_inventory[legacy_key] = get_count(legacy_inventory, content_id) + amount
	return true


static func set_count(legacy_inventory: Dictionary, content_id: StringName, amount: int) -> bool:
	if amount < 0:
		return false
	var legacy_key := to_legacy_key(content_id)
	if legacy_key.is_empty():
		return false
	legacy_inventory[legacy_key] = amount
	return true
