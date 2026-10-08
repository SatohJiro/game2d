class_name PlayerCraftDefinition
extends Resource

const RESULT_ITEM := &"craft.result.item"
const RESULT_EQUIPMENT := &"craft.result.equipment"
const RESULT_BUILDING := &"craft.result.building"

@export var recipe_id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export_file("*.png") var icon_path: String = ""
@export_range(1, 999, 1) var unlock_level: int = 1
@export var inputs: Array[ItemAmount] = []
@export var result_kind: StringName = &""
@export var result_id: StringName = &""
@export_range(1, 999999, 1) var result_amount: int = 1
@export var success_text: String = ""


func is_valid() -> bool:
	if not ContentId.is_valid(recipe_id) or ContentId.domain_of(recipe_id) != &"recipe": return false
	if display_name.is_empty() or unlock_level < 1 or inputs.is_empty() or result_amount <= 0: return false
	var seen := {}
	for input in inputs:
		if input == null or not input.get_validation_errors("craft input").is_empty() or seen.has(input.item_id): return false
		seen[input.item_id] = true
	if result_kind == RESULT_ITEM:
		return ContentId.is_valid(result_id) and ContentId.domain_of(result_id) == &"item" and LegacyItemAdapter.is_mapped(result_id)
	if result_kind == RESULT_EQUIPMENT:
		return PlayerEquipmentCatalog.is_valid_weapon(result_id) or PlayerEquipmentCatalog.is_valid_armor(result_id)
	if result_kind == RESULT_BUILDING:
		return BuildingPlacementCatalog.is_supported(result_id)
	return false


func input_amounts() -> Dictionary:
	var amounts := {}
	for input in inputs: amounts[input.item_id] = input.quantity
	return amounts
