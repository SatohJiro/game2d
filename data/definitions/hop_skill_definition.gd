@tool
class_name HopSkillDefinition
extends SkillDefinition

@export_range(0.01, 10000.0, 0.01) var hop_speed: float = 1.0
@export_range(0.0, 1000.0, 0.1) var hop_height: float = 0.0
@export_range(0.0, 10.0, 0.01) var compress_seconds: float = 0.0
@export_range(0.0, 10.0, 0.01) var launch_seconds: float = 0.0
@export_range(0.0, 10.0, 0.01) var land_seconds: float = 0.0
@export_range(0.0, 10.0, 0.01) var settle_seconds: float = 0.0


func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if delivery != Delivery.CHARGE:
		errors.append("HopSkillDefinition delivery must be CHARGE for %s" % content_id)
	if hop_speed <= 0.0 or not is_finite(hop_speed):
		errors.append("hop_speed must be positive and finite for %s" % content_id)
	if hop_height < 0.0 or not is_finite(hop_height):
		errors.append("hop_height must be non-negative and finite for %s" % content_id)
	for duration in [compress_seconds, launch_seconds, land_seconds, settle_seconds]:
		if duration < 0.0 or not is_finite(duration):
			errors.append("hop animation durations must be non-negative and finite for %s" % content_id)
			break
	return errors
