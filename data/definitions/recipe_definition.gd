@tool
class_name RecipeDefinition
extends ContentDefinition

@export var inputs: Array[ItemAmount] = []
@export var output: ItemAmount
@export var station_id: StringName = &""
@export_range(0.01, 86400.0, 0.01) var craft_time_seconds: float = 1.0
@export_range(0, 999, 1) var unlock_level: int = 0


func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if get_content_kind() != &"recipe":
		errors.append("RecipeDefinition ID must use the recipe domain: %s" % content_id)
	if inputs.is_empty():
		errors.append("inputs are required for %s" % content_id)
	var seen_items: Dictionary = {}
	for index in range(inputs.size()):
		var input := inputs[index]
		if input == null:
			errors.append("input[%d] is required for %s" % [index, content_id])
			continue
		for message in input.get_validation_errors("input[%d]" % index):
			errors.append(message)
		if seen_items.has(input.item_id):
			errors.append("duplicate input item %s for %s" % [input.item_id, content_id])
		seen_items[input.item_id] = true
	if output == null:
		errors.append("output is required for %s" % content_id)
	else:
		for message in output.get_validation_errors("output"):
			errors.append(message)
	if not ContentId.is_valid(station_id) or ContentId.domain_of(station_id) != &"building":
		errors.append("station_id must use the building domain for %s: %s" % [content_id, station_id])
	if craft_time_seconds <= 0.0:
		errors.append("craft_time_seconds must be positive for %s" % content_id)
	if unlock_level < 0:
		errors.append("unlock_level cannot be negative for %s" % content_id)
	return errors


func get_referenced_content_ids() -> Array[StringName]:
	var references: Array[StringName] = []
	if ContentId.is_valid(station_id):
		references.append(station_id)
	for input in inputs:
		if input != null and ContentId.is_valid(input.item_id):
			references.append(input.item_id)
	if output != null and ContentId.is_valid(output.item_id):
		references.append(output.item_id)
	return references
