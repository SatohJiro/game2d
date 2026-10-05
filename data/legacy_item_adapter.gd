class_name LegacyItemAdapter
extends RefCounted

const LEGACY_TO_CONTENT_ID: Dictionary = {
	"Gỗ": &"item.wood",
	"Quặng Pal": &"item.pal_ore",
	"Quả Mọng Hồi Máu": &"item.berry",
	"Cầu Thu Phục": &"item.pal_sphere.basic",
	"Hạt Giống Cây": &"item.berry_seed",
	"Thịt Tươi": &"item.fresh_meat",
	"Thỏi Pal": &"item.pal_ingot",
	"Mega Sphere": &"item.pal_sphere.mega",
	"Giga Sphere": &"item.pal_sphere.giga",
}

const CONTENT_ID_TO_LEGACY: Dictionary = {
	&"item.wood": "Gỗ",
	&"item.pal_ore": "Quặng Pal",
	&"item.berry": "Quả Mọng Hồi Máu",
	&"item.pal_sphere.basic": "Cầu Thu Phục",
	&"item.berry_seed": "Hạt Giống Cây",
	&"item.fresh_meat": "Thịt Tươi",
	&"item.pal_ingot": "Thỏi Pal",
	&"item.pal_sphere.mega": "Mega Sphere",
	&"item.pal_sphere.giga": "Giga Sphere",
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
