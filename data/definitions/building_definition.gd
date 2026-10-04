@tool
class_name BuildingDefinition
extends ContentDefinition

@export var scene: PackedScene
@export_range(1, 999999, 1) var max_health: int = 100
@export var build_cost: Array[ItemAmount] = []
@export var supported_recipe_ids: Array[StringName] = []
@export var tags: PackedStringArray = PackedStringArray()


func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if get_content_kind() != &"building":
		errors.append("BuildingDefinition ID must use the building domain: %s" % content_id)
	if scene == null:
		errors.append("scene is required for %s" % content_id)
	if max_health <= 0:
		errors.append("max_health must be positive for %s" % content_id)
	var seen_cost_items: Dictionary = {}
	for index in range(build_cost.size()):
		var cost := build_cost[index]
		if cost == null:
			errors.append("build_cost[%d] is required for %s" % [index, content_id])
			continue
		for message in cost.get_validation_errors("build_cost[%d]" % index):
			errors.append(message)
		if seen_cost_items.has(cost.item_id):
			errors.append("duplicate build cost item %s for %s" % [cost.item_id, content_id])
		seen_cost_items[cost.item_id] = true
	var seen_recipes: Dictionary = {}
	for recipe_id in supported_recipe_ids:
		if not ContentId.is_valid(recipe_id) or ContentId.domain_of(recipe_id) != &"recipe":
			errors.append("supported recipe must use the recipe domain for %s: %s" % [content_id, recipe_id])
		if seen_recipes.has(recipe_id):
			errors.append("duplicate supported recipe %s for %s" % [recipe_id, content_id])
		seen_recipes[recipe_id] = true
	return errors


func get_referenced_content_ids() -> Array[StringName]:
	var references: Array[StringName] = []
	for cost in build_cost:
		if cost != null and ContentId.is_valid(cost.item_id):
			references.append(cost.item_id)
	for recipe_id in supported_recipe_ids:
		if ContentId.is_valid(recipe_id):
			references.append(recipe_id)
	return references
