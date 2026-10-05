class_name CreatureEcologySelectionPolicy
extends RefCounted

const HUNT_DISTANCE := 210.0
const HUNT_DURATION := 6.0


static func resolve(request: CreatureEcologySelectionRequest) -> CreatureEcologySelectionResult:
	if request == null or ContentId.domain_of(request.predator_species_id) != &"creature":
		return CreatureEcologySelectionResult.new(CreatureEcologySelectionResult.Status.INVALID_REQUEST)
	if request.is_blocked:
		return CreatureEcologySelectionResult.new(CreatureEcologySelectionResult.Status.PROTECTED)
	if not request.is_predator:
		return CreatureEcologySelectionResult.new(CreatureEcologySelectionResult.Status.NONE_AVAILABLE)

	var best_by_key: Dictionary = {}
	for candidate in request.candidates:
		if candidate == null or candidate.candidate_key.is_empty() or ContentId.domain_of(candidate.species_id) != &"creature":
			continue
		if not candidate.is_prey or candidate.capture_active or candidate.distance < 0.0 or not is_finite(candidate.distance) or candidate.distance >= HUNT_DISTANCE:
			continue
		var existing := best_by_key.get(candidate.candidate_key) as CreatureEcologyCandidate
		if existing == null or candidate.distance < existing.distance:
			best_by_key[candidate.candidate_key] = candidate

	var selected: CreatureEcologyCandidate = null
	for candidate_value in best_by_key.values():
		var candidate := candidate_value as CreatureEcologyCandidate
		if selected == null or candidate.distance < selected.distance or (is_equal_approx(candidate.distance, selected.distance) and String(candidate.candidate_key) < String(selected.candidate_key)):
			selected = candidate
	if selected == null:
		return CreatureEcologySelectionResult.new(CreatureEcologySelectionResult.Status.NONE_AVAILABLE)
	return CreatureEcologySelectionResult.new(
		CreatureEcologySelectionResult.Status.SELECTED,
		selected.candidate_key,
		selected.species_id,
		selected.distance,
		CreatureTransitionPolicy.EVENT_ECOLOGY_PREY_ACQUIRED,
		HUNT_DURATION
	)
