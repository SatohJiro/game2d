@tool
class_name ItemDefinition
extends ContentDefinition

@export_range(1, 9999, 1) var max_stack: int = 99
@export var icon: Texture2D
@export var tags: PackedStringArray = PackedStringArray()


func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if get_content_kind() != &"item":
		errors.append("ItemDefinition ID must use the item domain: %s" % content_id)
	if max_stack <= 0:
		errors.append("max_stack must be positive for %s" % content_id)
	if icon == null:
		errors.append("icon is required for %s" % content_id)
	return errors
