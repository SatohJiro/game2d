class_name CreatureDrinkingPolicy
extends RefCounted

const WATER_RANGE := 320.0
const DRINKING_CHANCE := 0.25
const DURATION_MIN := 3.0
const DURATION_MAX := 5.0


static func resolve(request: CreatureDrinkingRequest) -> CreatureDrinkingResult:
	if request == null or ContentId.domain_of(request.species_id) != &"creature" or request.roll < 0.0 or request.roll > 1.0 or not is_finite(request.roll):
		return CreatureDrinkingResult.new(CreatureDrinkingResult.Status.INVALID_REQUEST)
	if request.has_water_source and (request.water_distance < 0.0 or not is_finite(request.water_distance)):
		return CreatureDrinkingResult.new(CreatureDrinkingResult.Status.INVALID_REQUEST)
	if request.is_protected:
		return CreatureDrinkingResult.new(CreatureDrinkingResult.Status.PROTECTED, request.species_id)
	if not request.has_water_source or request.water_distance >= WATER_RANGE or request.roll >= DRINKING_CHANCE:
		return CreatureDrinkingResult.new(CreatureDrinkingResult.Status.NO_CHANGE, request.species_id)
	return CreatureDrinkingResult.new(CreatureDrinkingResult.Status.DRINK, request.species_id, CreatureTransitionPolicy.EVENT_ECOLOGY_DRINKING_ENTRY)
