class_name CreaturePerceptionPolicy
extends RefCounted

const SLEEP_WAKE_MOVEMENT_SPEED := 190.0
const SLEEP_WAKE_MOVEMENT_DISTANCE := 90.0
const SLEEP_WAKE_PROXIMITY_DISTANCE := 40.0
const SUSPICIOUS_MOVEMENT_SPEED := 100.0


static func resolve(request: CreaturePerceptionRequest) -> CreaturePerceptionResult:
	if request == null or request.is_blocked:
		return CreaturePerceptionResult.new(CreaturePerceptionResult.Decision.NONE)
	if not _has_valid_ranges(request):
		return CreaturePerceptionResult.new(CreaturePerceptionResult.Decision.NONE)

	var candidates := _valid_candidates(request.candidates)
	if candidates.is_empty():
		return CreaturePerceptionResult.new(CreaturePerceptionResult.Decision.NONE)
	candidates.sort_custom(_candidate_precedes)
	var candidate: CreaturePerceptionCandidate = candidates[0]

	if request.is_sleeping:
		var wakes_from_movement := (
			candidate.movement_speed > SLEEP_WAKE_MOVEMENT_SPEED
			and candidate.distance < SLEEP_WAKE_MOVEMENT_DISTANCE
		)
		if wakes_from_movement or candidate.distance < SLEEP_WAKE_PROXIMITY_DISTANCE:
			return CreaturePerceptionResult.new(
				CreaturePerceptionResult.Decision.ALERT,
				candidate.candidate_id
			)
		return CreaturePerceptionResult.new(CreaturePerceptionResult.Decision.NONE)

	if candidate.distance < request.aggro_distance:
		return CreaturePerceptionResult.new(
			CreaturePerceptionResult.Decision.ALERT,
			candidate.candidate_id
		)
	if (
		candidate.distance < request.suspicion_distance
		and not request.is_suspicious
		and candidate.movement_speed > SUSPICIOUS_MOVEMENT_SPEED
	):
		return CreaturePerceptionResult.new(
			CreaturePerceptionResult.Decision.SUSPICIOUS,
			candidate.candidate_id
		)
	return CreaturePerceptionResult.new(CreaturePerceptionResult.Decision.NONE)


static func _has_valid_ranges(request: CreaturePerceptionRequest) -> bool:
	return (
		request.aggro_distance > 0.0
		and request.suspicion_distance >= request.aggro_distance
		and is_finite(request.aggro_distance)
		and is_finite(request.suspicion_distance)
	)


static func _valid_candidates(
	source: Array[CreaturePerceptionCandidate]
) -> Array[CreaturePerceptionCandidate]:
	var valid: Array[CreaturePerceptionCandidate] = []
	for candidate in source:
		if candidate == null or not candidate.is_valid or candidate.candidate_id <= 0:
			continue
		if candidate.distance < 0.0 or not is_finite(candidate.distance):
			continue
		if candidate.movement_speed < 0.0 or not is_finite(candidate.movement_speed):
			continue
		valid.append(candidate)
	return valid


static func _candidate_precedes(
	left: CreaturePerceptionCandidate,
	right: CreaturePerceptionCandidate
) -> bool:
	if not is_equal_approx(left.distance, right.distance):
		return left.distance < right.distance
	return left.candidate_id < right.candidate_id
