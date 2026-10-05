class_name CreatureEcologyPolicy
extends RefCounted

const DAMAGE_PANIC_HP_RATIO := 0.35
const DAMAGE_PANIC_DURATION := 3.5


static func resolve_damage_panic(request: CreatureEcologyRequest) -> CreatureEcologyResult:
	if request == null or ContentId.domain_of(request.species_id) != &"creature" or request.max_hp <= 0 or request.current_hp < 0 or request.current_hp > request.max_hp:
		return CreatureEcologyResult.new(CreatureEcologyResult.Status.INVALID_REQUEST)
	if request.capture_active:
		return CreatureEcologyResult.new(CreatureEcologyResult.Status.PROTECTED, request.species_id)
	if request.defeated or not request.is_prey or request.is_enraged:
		return CreatureEcologyResult.new(CreatureEcologyResult.Status.NO_CHANGE, request.species_id)
	if float(request.current_hp) / float(request.max_hp) >= DAMAGE_PANIC_HP_RATIO:
		return CreatureEcologyResult.new(CreatureEcologyResult.Status.NO_CHANGE, request.species_id)
	return CreatureEcologyResult.new(
		CreatureEcologyResult.Status.PANIC_FLEE,
		request.species_id,
		CreatureTransitionPolicy.EVENT_ECOLOGY_DAMAGE_PANIC,
		DAMAGE_PANIC_DURATION
	)
