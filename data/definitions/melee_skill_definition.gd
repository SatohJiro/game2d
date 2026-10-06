@tool
class_name MeleeSkillDefinition
extends SkillDefinition

@export_range(0.01, 1000.0, 0.1) var activation_range: float = 1.0
@export_range(0.01, 10000.0, 0.1) var lunge_speed: float = 1.0
@export_range(0.01, 1000.0, 0.1) var contact_range: float = 1.0
@export_range(0.0, 10.0, 0.01) var squash_seconds: float = 0.0
@export_range(0.0, 10.0, 0.01) var restore_seconds: float = 0.0

func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if delivery != Delivery.MELEE: errors.append("MeleeSkillDefinition delivery must be MELEE for %s" % content_id)
	if activation_range <= 0.0 or not is_finite(activation_range): errors.append("activation_range must be positive and finite for %s" % content_id)
	if lunge_speed <= 0.0 or not is_finite(lunge_speed): errors.append("lunge_speed must be positive and finite for %s" % content_id)
	if contact_range <= 0.0 or not is_finite(contact_range): errors.append("contact_range must be positive and finite for %s" % content_id)
	if squash_seconds < 0.0 or restore_seconds < 0.0 or not is_finite(squash_seconds) or not is_finite(restore_seconds): errors.append("melee tween durations must be non-negative and finite for %s" % content_id)
	return errors
