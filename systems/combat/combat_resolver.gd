class_name CombatResolver
extends RefCounted


static func resolve(request: DamageRequest) -> DamageResult:
	if request == null:
		return DamageResult.new(DamageResult.Status.INVALID_REQUEST, 0, 0)
	var clamped_hp := clampi(request.current_hp, 0, maxi(0, request.max_hp))
	if request.max_hp <= 0 or request.base_damage <= 0 or request.damage_multiplier < 0.0:
		return DamageResult.new(DamageResult.Status.INVALID_REQUEST, 0, clamped_hp)
	if clamped_hp <= 0:
		return DamageResult.new(DamageResult.Status.ALREADY_DEFEATED, 0, 0, true)
	if request.immune:
		return DamageResult.new(DamageResult.Status.IMMUNE, 0, clamped_hp)
	if not request.allow_friendly_fire and not request.source_faction.is_empty() and request.source_faction == request.target_faction:
		return DamageResult.new(DamageResult.Status.FRIENDLY_FIRE_BLOCKED, 0, clamped_hp)

	var scaled_damage := floori(float(request.base_damage) * request.damage_multiplier)
	var applied_damage := maxi(0, scaled_damage - maxi(0, request.defense))
	var remaining_hp := maxi(0, clamped_hp - applied_damage)
	var knockback := Vector2.ZERO
	if applied_damage > 0 and request.knockback_strength > 0.0:
		knockback = (request.target_position - request.hit_origin).normalized() * request.knockback_strength
	return DamageResult.new(DamageResult.Status.OK, applied_damage, remaining_hp, remaining_hp == 0, knockback, request.tags)
