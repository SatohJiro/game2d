class_name ChestPlacementState
extends RefCounted

const MANAGED_ITEM_IDS: Array[StringName] = [&"item.wood", &"item.pal_ore", &"item.berry"]
const MAX_SLOTS := 12
const MAX_STACK_BY_ITEM := {&"item.wood": 999, &"item.pal_ore": 999, &"item.berry": 99}
const MAX_HEALTH := 250

var inventory: Dictionary
var health: int


func _init(p_inventory: Dictionary = {}, p_health: int = MAX_HEALTH) -> void:
	inventory = p_inventory.duplicate(true)
	health = p_health


func is_valid() -> bool:
	if health < 1 or health > MAX_HEALTH:
		return false
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
	return {"inventory": projected, "health": health}


static func from_dto(value: Variant) -> ChestPlacementState:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = value
	if (data.size() != 1 and data.size() != 2) or typeof(data.get("inventory")) != TYPE_DICTIONARY or (data.size() == 2 and not data.has("health")):
		return null
	var health_value: Variant = data.get("health", MAX_HEALTH)
	if typeof(health_value) != TYPE_INT:
		return null
	var state := ChestPlacementState.new(data["inventory"], int(health_value))
	return state if state.is_valid() else null
