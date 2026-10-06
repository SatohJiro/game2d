class_name SaveMigrationStep
extends RefCounted

var from_version: int
var to_version: int
var transform: Callable


func _init(p_from_version: int, p_to_version: int, p_transform: Callable) -> void:
	from_version = p_from_version
	to_version = p_to_version
	transform = p_transform


func is_valid() -> bool:
	return from_version >= 0 and to_version >= 0 and transform.is_valid()


func apply(source: Dictionary) -> Variant:
	return transform.call(source.duplicate(true))
