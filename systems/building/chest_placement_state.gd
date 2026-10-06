class_name ChestPlacementState
extends RefCounted

const MANAGED_ITEM_IDS: Array[StringName] = [&"item.wood", &"item.pal_ore", &"item.berry"]
const MAX_SLOTS := 12
const MAX_STACK_BY_ITEM := {&"item.wood": 999, &"item.pal_ore": 999, &"item.berry": 99}

var inventory: Dictionary


func _init(p_inventory: Dictionary = {}) -> void:
	inventory = p_inventory.duplicate(true)


func is_valid() -> bool:
	var used_slots := 0
	for raw_item_id: Variant in inventory:
		var item_id := StringName(raw_item_id)
		var count: Variant = inventory[raw_item_id]
		if not MANAGED_ITEM_IDS.has(item_id) or typeof(count) != TYPE_INT or int(count) < 0:
			return false
		if int(count) > 0:
			used_slots += ceili(float(count) / float(MAX_STACK_BY_ITEM[item_id]))
	return used_slots <= MAX_SLOTS


func to_dto() -> Dictionary:
	var projected: Dictionary = {}
	var item_ids: Array = inventory.keys()
	item_ids.sort()
	for raw_item_id: Variant in item_ids:
		var count := int(inventory[raw_item_id])
		if count > 0:
			projected[String(raw_item_id)] = count
	return {"inventory": projected}


static func from_dto(value: Variant) -> ChestPlacementState:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = value
	if data.size() != 1 or typeof(data.get("inventory")) != TYPE_DICTIONARY:
		return null
	var state := ChestPlacementState.new(data["inventory"])
	return state if state.is_valid() else null
