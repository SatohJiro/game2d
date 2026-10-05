@tool
class_name CreatureBehaviorProfile
extends Resource

@export var is_predator: bool = false
@export var is_prey: bool = false


func get_validation_errors(context: String = "behavior_profile") -> PackedStringArray:
	var errors := PackedStringArray()
	if is_predator and is_prey:
		errors.append("%s cannot be both predator and prey" % context)
	return errors
