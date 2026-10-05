class_name CreatureGrazingPolicy
extends RefCounted

const GRAZING_CHANCE := 0.22
const DURATION_MIN := 2.5
const DURATION_MAX := 4.0


static func resolve(request: CreatureGrazingRequest) -> CreatureGrazingResult:
	if request == null or ContentId.domain_of(request.species_id) != &"creature" or request.roll < 0.0 or request.roll > 1.0 or not is_finite(request.roll):
		return CreatureGrazingResult.new(CreatureGrazingResult.Status.INVALID_REQUEST)
	if request.is_protected:
		return CreatureGrazingResult.new(CreatureGrazingResult.Status.PROTECTED, request.species_id)
	if not request.is_prey or request.roll >= GRAZING_CHANCE:
		return CreatureGrazingResult.new(CreatureGrazingResult.Status.NO_CHANGE, request.species_id)
	return CreatureGrazingResult.new(CreatureGrazingResult.Status.GRAZE, request.species_id, CreatureTransitionPolicy.EVENT_ECOLOGY_GRAZING_ENTRY)
