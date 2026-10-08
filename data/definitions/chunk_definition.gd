@tool
class_name ChunkDefinition
extends ContentDefinition

@export var coordinate := Vector2i.ZERO
@export var biome_id: StringName = &""


func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if get_content_kind() != &"chunk":
		errors.append("ChunkDefinition ID must use the chunk domain: %s" % content_id)
	if ContentId.domain_of(biome_id) != &"biome":
		errors.append("biome_id must use the biome domain for %s" % content_id)
	return errors


func get_referenced_content_ids() -> Array[StringName]:
	var references: Array[StringName] = []
	if ContentId.is_valid(biome_id):
		references.append(biome_id)
	return references
