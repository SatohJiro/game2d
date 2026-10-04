class_name CaptureResolver
extends RefCounted

const BASE_CHANCE_AT_ZERO_HP := 0.95
const BASE_CHANCE_AT_FULL_HP := 0.25
const MIN_BASE_CHANCE := 0.15
const MAX_BASE_CHANCE := 0.95
const MIN_FINAL_CHANCE := 0.10
const MAX_FINAL_CHANCE := 0.98
const BACK_STRIKE_BONUS := 0.35
const SLEEP_BONUS := 0.40


static func resolve(request: CaptureRequest) -> CaptureResult:
	if request == null:
		return CaptureResult.new(CaptureResult.Status.INVALID_REQUEST)
	if not request.target_valid:
		return CaptureResult.new(CaptureResult.Status.INVALID_TARGET, request.species_id)
	if request.already_capturing:
		return CaptureResult.new(CaptureResult.Status.ALREADY_CAPTURING, request.species_id)
	if request.already_defeated:
		return CaptureResult.new(CaptureResult.Status.ALREADY_DEFEATED, request.species_id)
	if not _has_valid_numbers(request):
		return CaptureResult.new(CaptureResult.Status.INVALID_REQUEST, request.species_id)

	var base_chance := calculate_base_chance(request.current_hp, request.max_hp)
	var applied_multiplier := request.sphere_multiplier
	var tags := PackedStringArray()
	if request.is_back_strike:
		applied_multiplier += BACK_STRIKE_BONUS
		tags.append("back_strike")
	if request.is_asleep:
		applied_multiplier += SLEEP_BONUS
		tags.append("sleep")
	var final_chance := clampf(base_chance * applied_multiplier, MIN_FINAL_CHANCE, MAX_FINAL_CHANCE)
	return CaptureResult.new(
		CaptureResult.Status.OK,
		request.species_id,
		base_chance,
		final_chance,
		request.roll,
		request.roll <= final_chance,
		applied_multiplier,
		tags
	)


static func calculate_base_chance(current_hp: int, max_hp: int) -> float:
	if max_hp <= 0:
		return 0.0
	var hp_ratio := clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	return clampf(lerpf(BASE_CHANCE_AT_ZERO_HP, BASE_CHANCE_AT_FULL_HP, hp_ratio), MIN_BASE_CHANCE, MAX_BASE_CHANCE)


static func _has_valid_numbers(request: CaptureRequest) -> bool:
	return (
		request.max_hp > 0
		and request.current_hp >= 0
		and request.current_hp <= request.max_hp
		and request.sphere_multiplier > 0.0
		and not is_nan(request.sphere_multiplier)
		and not is_inf(request.sphere_multiplier)
		and request.roll >= 0.0
		and request.roll <= 1.0
		and not is_nan(request.roll)
		and not is_inf(request.roll)
	)
