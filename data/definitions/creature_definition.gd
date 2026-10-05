@tool
class_name CreatureDefinition
extends ContentDefinition

@export_range(1, 100000, 1) var base_max_hp: int = 1
@export_range(0.01, 10000.0, 0.01) var move_speed: float = 1.0
@export_range(1, 100000, 1) var base_attack_power: int = 1
@export var behavior_profile: CreatureBehaviorProfile
@export var drop_item_id: StringName = &""


func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if get_content_kind() != &"creature":
		errors.append("CreatureDefinition ID must use the creature domain: %s" % content_id)
	if base_max_hp <= 0:
		errors.append("base_max_hp must be positive for %s" % content_id)
	if move_speed <= 0.0 or not is_finite(move_speed):
		errors.append("move_speed must be positive and finite for %s" % content_id)
	if base_attack_power <= 0:
		errors.append("base_attack_power must be positive for %s" % content_id)
	if behavior_profile == null:
		errors.append("behavior_profile is required for %s" % content_id)
	else:
		for message in behavior_profile.get_validation_errors(String(content_id)):
			errors.append(message)
	if ContentId.domain_of(drop_item_id) != &"item":
		errors.append("drop_item_id must use the item domain for %s" % content_id)
	return errors


func get_referenced_content_ids() -> Array[StringName]:
	var references: Array[StringName] = []
	if ContentId.is_valid(drop_item_id):
		references.append(drop_item_id)
	return references
