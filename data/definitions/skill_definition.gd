@tool
class_name SkillDefinition
extends ContentDefinition

enum Delivery {
	PROJECTILE,
	MELEE,
	CHARGE,
}

@export var delivery: Delivery = Delivery.PROJECTILE
@export_range(0.0, 60.0, 0.01) var cooldown_seconds: float = 0.0
@export_range(0.0, 10.0, 0.01) var anticipation_seconds: float = 0.0
@export_range(0.0, 10.0, 0.01) var recovery_seconds: float = 0.0
@export_range(0.01, 100.0, 0.01) var damage_multiplier: float = 1.0
@export_range(0.0, 10000.0, 0.1) var travel_distance: float = 0.0
@export_range(0.0, 60.0, 0.01) var travel_seconds: float = 0.0
@export_range(0.0, 1000.0, 0.1) var hit_radius: float = 0.0


func get_validation_errors() -> PackedStringArray:
	var errors := super.get_validation_errors()
	if get_content_kind() != &"skill":
		errors.append("SkillDefinition ID must use the skill domain: %s" % content_id)
	if cooldown_seconds <= 0.0 or not is_finite(cooldown_seconds):
		errors.append("cooldown_seconds must be positive and finite for %s" % content_id)
	if anticipation_seconds < 0.0 or not is_finite(anticipation_seconds):
		errors.append("anticipation_seconds must be non-negative and finite for %s" % content_id)
	if recovery_seconds < 0.0 or not is_finite(recovery_seconds):
		errors.append("recovery_seconds must be non-negative and finite for %s" % content_id)
	if damage_multiplier <= 0.0 or not is_finite(damage_multiplier):
		errors.append("damage_multiplier must be positive and finite for %s" % content_id)
	if delivery == Delivery.PROJECTILE:
		if travel_distance <= 0.0 or not is_finite(travel_distance):
			errors.append("projectile travel_distance must be positive and finite for %s" % content_id)
		if travel_seconds <= 0.0 or not is_finite(travel_seconds):
			errors.append("projectile travel_seconds must be positive and finite for %s" % content_id)
		if hit_radius <= 0.0 or not is_finite(hit_radius):
			errors.append("projectile hit_radius must be positive and finite for %s" % content_id)
	return errors
