@tool
class_name ItemAmount
extends Resource

@export var item_id: StringName = &""
@export_range(1, 999999, 1) var quantity: int = 1


func get_validation_errors(context: String) -> PackedStringArray:
	var errors := PackedStringArray()
	if not ContentId.is_valid(item_id) or ContentId.domain_of(item_id) != &"item":
		errors.append("%s item_id must use the item domain: %s" % [context, item_id])
	if quantity <= 0:
		errors.append("%s quantity must be positive for %s" % [context, item_id])
	return errors
