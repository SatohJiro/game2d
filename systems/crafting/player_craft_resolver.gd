class_name PlayerCraftResolver
extends RefCounted


static func resolve(recipe_id: StringName, player_level: int, stable_inventory: Dictionary) -> PlayerCraftResult:
	var definition := PlayerCraftCatalog.get_definition(recipe_id)
	if definition == null: return PlayerCraftResult.new(PlayerCraftResult.Status.UNKNOWN_RECIPE)
	if not definition.is_valid(): return PlayerCraftResult.new(PlayerCraftResult.Status.INVALID_DEFINITION, definition)
	if player_level < definition.unlock_level: return PlayerCraftResult.new(PlayerCraftResult.Status.LOCKED, definition)
	for item_id: StringName in definition.input_amounts():
		if int(stable_inventory.get(item_id, 0)) < int(definition.input_amounts()[item_id]):
			return PlayerCraftResult.new(PlayerCraftResult.Status.INSUFFICIENT_ITEMS, definition, item_id)
	return PlayerCraftResult.new(PlayerCraftResult.Status.ACCEPTED, definition)


static func snapshot_inventory(legacy_inventory: Dictionary) -> Dictionary:
	var snapshot := {}
	for item_id: StringName in LegacyItemAdapter.CONTENT_ID_TO_LEGACY:
		snapshot[item_id] = LegacyItemAdapter.get_count(legacy_inventory, item_id)
	return snapshot
