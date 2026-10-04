@tool
class_name ContentDefinition
extends Resource

@export var content_id: StringName = &""
@export var display_name_key: StringName = &""
@export_multiline var developer_notes: String = ""


func get_content_kind() -> StringName:
	return ContentId.domain_of(content_id)


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not ContentId.is_valid(content_id):
		errors.append("content_id must match %s: %s" % [ContentId.VALID_PATTERN, content_id])
	if display_name_key.is_empty():
		errors.append("display_name_key is required for %s" % content_id)
	return errors
