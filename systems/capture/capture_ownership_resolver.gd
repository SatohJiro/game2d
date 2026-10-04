class_name CaptureOwnershipResolver
extends RefCounted

const CAPTURE_REWARD_EXP := 75
const LEGENDARY_THRESHOLD := 0.05
const EPIC_THRESHOLD := 0.20
const RARE_THRESHOLD := 0.45

const LEGENDARY_BADGE := "★★★★ Thần Thoại"
const EPIC_BADGE := "★★★ Sử Thi"
const RARE_BADGE := "★★ Hiếm"
const COMMON_BADGE := "★ Thường"

const LEGENDARY_TRAIT := "Thần Long Hộ Mệnh"
const EPIC_TRAITS: Array[String] = ["Chiến Tướng", "Thần Tốc", "Hộ Vệ"]
const RARE_TRAITS: Array[String] = ["Dũng Cảm", "Nhanh Nhẹn"]
const COMMON_TRAIT := "Bình Thường"


static func resolve(request: CaptureOwnershipRequest) -> CaptureOwnershipResult:
	if request == null:
		return CaptureOwnershipResult.new(CaptureOwnershipResult.Status.INVALID_REQUEST)
	if request.capture_token.is_empty():
		return CaptureOwnershipResult.new(
			CaptureOwnershipResult.Status.INVALID_REQUEST,
			request.capture_token,
			request.species_id
		)
	if request.already_committed:
		return CaptureOwnershipResult.new(
			CaptureOwnershipResult.Status.DUPLICATE,
			request.capture_token,
			request.species_id
		)
	if not LegacySpeciesAdapter.is_supported(request.species_id):
		return CaptureOwnershipResult.new(
			CaptureOwnershipResult.Status.UNKNOWN_SPECIES,
			request.capture_token,
			request.species_id
		)
	if not _has_valid_payload(request):
		return CaptureOwnershipResult.new(
			CaptureOwnershipResult.Status.INVALID_REQUEST,
			request.capture_token,
			request.species_id
		)

	var rarity := _resolve_rarity(request.rarity_roll, request.trait_roll)
	var boosted_snapshot := request.species_snapshot.duplicate(true)
	boosted_snapshot["id"] = request.species_id
	boosted_snapshot["power"] = int(float(boosted_snapshot["power"]) * float(rarity["stat_multiplier"]))
	boosted_snapshot["max_hp"] = int(float(boosted_snapshot["max_hp"]) * float(rarity["stat_multiplier"]))
	var party_entry := {
		"species_id": request.species_id,
		"species_data": boosted_snapshot,
		"level": request.level,
		"rarity_badge": rarity["rarity_badge"],
		"trait": rarity["trait_name"],
	}
	return CaptureOwnershipResult.new(
		CaptureOwnershipResult.Status.ACCEPTED,
		request.capture_token,
		request.species_id,
		party_entry,
		rarity["rarity_badge"],
		rarity["trait_name"],
		rarity["stat_multiplier"],
		CAPTURE_REWARD_EXP
	)


static func _has_valid_payload(request: CaptureOwnershipRequest) -> bool:
	if request.level <= 0 or request.species_snapshot.is_empty():
		return false
	if request.species_snapshot.has("id") and StringName(request.species_snapshot["id"]) != request.species_id:
		return false
	if String(request.species_snapshot.get("name", "")).is_empty():
		return false
	if not request.species_snapshot.has("power") or float(request.species_snapshot["power"]) <= 0.0:
		return false
	if not request.species_snapshot.has("max_hp") or float(request.species_snapshot["max_hp"]) <= 0.0:
		return false
	return _is_unit_roll(request.rarity_roll) and _is_unit_roll(request.trait_roll)


static func _is_unit_roll(value: float) -> bool:
	return value >= 0.0 and value <= 1.0 and not is_nan(value) and not is_inf(value)


static func _resolve_rarity(rarity_roll: float, trait_roll: float) -> Dictionary:
	if rarity_roll < LEGENDARY_THRESHOLD:
		return {
			"rarity_badge": LEGENDARY_BADGE,
			"trait_name": LEGENDARY_TRAIT,
			"stat_multiplier": 1.5,
		}
	if rarity_roll < EPIC_THRESHOLD:
		return {
			"rarity_badge": EPIC_BADGE,
			"trait_name": EPIC_TRAITS[_roll_index(trait_roll, EPIC_TRAITS.size())],
			"stat_multiplier": 1.3,
		}
	if rarity_roll < RARE_THRESHOLD:
		return {
			"rarity_badge": RARE_BADGE,
			"trait_name": RARE_TRAITS[_roll_index(trait_roll, RARE_TRAITS.size())],
			"stat_multiplier": 1.15,
		}
	return {
		"rarity_badge": COMMON_BADGE,
		"trait_name": COMMON_TRAIT,
		"stat_multiplier": 1.0,
	}


static func _roll_index(roll: float, option_count: int) -> int:
	return mini(int(floor(roll * option_count)), option_count - 1)
