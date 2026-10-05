class_name CreatureSleepPolicy
extends RefCounted

const SLEEP_CHANCE := 0.18
const DURATION_MIN := 6.0
const DURATION_MAX := 11.0


static func resolve(request: CreatureSleepRequest) -> CreatureSleepResult:
	if request == null or ContentId.domain_of(request.species_id) != &"creature" or request.roll < 0.0 or request.roll > 1.0 or not is_finite(request.roll):
		return CreatureSleepResult.new(CreatureSleepResult.Status.INVALID_REQUEST)
	if request.is_protected:
		return CreatureSleepResult.new(CreatureSleepResult.Status.PROTECTED, request.species_id)
	if request.is_night_raider or request.is_enraged or request.roll >= SLEEP_CHANCE:
		return CreatureSleepResult.new(CreatureSleepResult.Status.NO_CHANGE, request.species_id)
	return CreatureSleepResult.new(CreatureSleepResult.Status.SLEEP, request.species_id, CreatureTransitionPolicy.EVENT_ECOLOGY_SLEEP_ENTRY)
