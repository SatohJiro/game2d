@tool
class_name BiomeDefinition
extends ContentDefinition

@export var biome_tags: Array[StringName] = []


func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if get_content_kind() != &"biome":
		errors.append("BiomeDefinition ID must use the biome domain: %s" % content_id)
	var seen: Dictionary = {}
	for tag in biome_tags:
		if tag.is_empty() or seen.has(tag):
			errors.append("biome_tags must be non-empty and unique for %s" % content_id)
		seen[tag] = true
	return errors
