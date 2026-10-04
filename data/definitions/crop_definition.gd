@tool
class_name CropDefinition
extends ContentDefinition

@export var seed_item_id: StringName = &""
@export var harvest_item_id: StringName = &""
@export_range(0.01, 864000.0, 0.01) var growth_time_seconds: float = 10.0
@export_range(1, 9999, 1) var harvest_yield_min: int = 1
@export_range(1, 9999, 1) var harvest_yield_max: int = 1


func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if get_content_kind() != &"crop":
		errors.append("CropDefinition ID must use the crop domain: %s" % content_id)
	if not ContentId.is_valid(seed_item_id) or ContentId.domain_of(seed_item_id) != &"item":
		errors.append("seed_item_id must use the item domain for %s: %s" % [content_id, seed_item_id])
	if not ContentId.is_valid(harvest_item_id) or ContentId.domain_of(harvest_item_id) != &"item":
		errors.append("harvest_item_id must use the item domain for %s: %s" % [content_id, harvest_item_id])
	if growth_time_seconds <= 0.0:
		errors.append("growth_time_seconds must be positive for %s" % content_id)
	if harvest_yield_min <= 0:
		errors.append("harvest_yield_min must be positive for %s" % content_id)
	if harvest_yield_max < harvest_yield_min:
		errors.append("harvest_yield_max must be >= harvest_yield_min for %s" % content_id)
	return errors


func get_referenced_content_ids() -> Array[StringName]:
	var references: Array[StringName] = []
	if ContentId.is_valid(seed_item_id):
		references.append(seed_item_id)
	if ContentId.is_valid(harvest_item_id):
		references.append(harvest_item_id)
	return references
