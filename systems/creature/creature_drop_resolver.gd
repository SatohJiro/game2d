class_name CreatureDropResolver
extends RefCounted

const ELITE_BONUS_ITEM_ID: StringName = &"item.pal_ore"

static func resolve(request: CreatureDropRequest) -> CreatureDropResult:
	if request == null:
		return CreatureDropResult.new(CreatureDropResult.Status.INVALID_REQUEST)
	if ContentId.domain_of(request.species_id) != &"creature" or ContentId.domain_of(request.primary_item_id) != &"item":
		return CreatureDropResult.new(CreatureDropResult.Status.INVALID_REQUEST)
	if request.already_committed:
		return CreatureDropResult.new(CreatureDropResult.Status.DUPLICATE, request.species_id)
	if request.capture_active:
		return CreatureDropResult.new(CreatureDropResult.Status.CAPTURE_BLOCKED, request.species_id)
	if not request.defeated:
		return CreatureDropResult.new(CreatureDropResult.Status.NOT_DEFEATED, request.species_id)

	var has_bonus := request.is_elite or request.is_alpha
	var primary_min := 3 if has_bonus else 1
	var primary_max := 5 if has_bonus else 2
	if request.primary_count_roll < primary_min or request.primary_count_roll > primary_max:
		return CreatureDropResult.new(CreatureDropResult.Status.INVALID_REQUEST, request.species_id)
	if has_bonus:
		if request.bonus_count_roll < 2 or request.bonus_count_roll > 4:
			return CreatureDropResult.new(CreatureDropResult.Status.INVALID_REQUEST, request.species_id)
	elif request.bonus_count_roll != 0:
		return CreatureDropResult.new(CreatureDropResult.Status.INVALID_REQUEST, request.species_id)

	return CreatureDropResult.new(CreatureDropResult.Status.ACCEPTED, request.species_id, request.primary_item_id, request.primary_count_roll, ELITE_BONUS_ITEM_ID if has_bonus else &"", request.bonus_count_roll)
