@tool
class_name ChargeSkillDefinition
extends SkillDefinition

@export_range(0.0, 10000.0, 0.1) var minimum_range: float = 0.0
@export_range(0.01, 10000.0, 0.1) var maximum_range: float = 1.0
@export_range(0.01, 10000.0, 0.1) var charge_speed: float = 1.0
@export_range(0.01, 60.0, 0.01) var charge_seconds: float = 0.01
@export_range(0.01, 60.0, 0.01) var stun_seconds: float = 0.01


func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if delivery != Delivery.CHARGE:
		errors.append("ChargeSkillDefinition delivery must be CHARGE for %s" % content_id)
	if minimum_range < 0.0 or not is_finite(minimum_range):
		errors.append("minimum_range must be non-negative and finite for %s" % content_id)
	if maximum_range <= minimum_range or not is_finite(maximum_range):
		errors.append("maximum_range must exceed minimum_range for %s" % content_id)
	if charge_speed <= 0.0 or not is_finite(charge_speed):
		errors.append("charge_speed must be positive and finite for %s" % content_id)
	if charge_seconds <= 0.0 or not is_finite(charge_seconds):
		errors.append("charge_seconds must be positive and finite for %s" % content_id)
	if stun_seconds <= 0.0 or not is_finite(stun_seconds):
		errors.append("stun_seconds must be positive and finite for %s" % content_id)
	return errors
