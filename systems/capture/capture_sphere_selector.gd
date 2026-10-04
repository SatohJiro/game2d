class_name CaptureSphereSelector
extends RefCounted

const BASIC_ID: StringName = &"item.pal_sphere.basic"
const MEGA_ID: StringName = &"item.pal_sphere.mega"
const GIGA_ID: StringName = &"item.pal_sphere.giga"

const PRIORITY: Array[StringName] = [GIGA_ID, MEGA_ID, BASIC_ID]
const MULTIPLIERS: Dictionary = {
	GIGA_ID: 4.0,
	MEGA_ID: 2.0,
	BASIC_ID: 1.0,
}


static func select(available_counts: Dictionary) -> CaptureSphereSelectionResult:
	for item_id in PRIORITY:
		if int(available_counts.get(item_id, 0)) > 0:
			return CaptureSphereSelectionResult.new(
				CaptureSphereSelectionResult.Status.OK,
				item_id,
				float(MULTIPLIERS[item_id])
			)
	return CaptureSphereSelectionResult.new(CaptureSphereSelectionResult.Status.NONE_AVAILABLE)


static func is_supported(item_id: StringName) -> bool:
	return MULTIPLIERS.has(item_id)


static func get_multiplier(item_id: StringName) -> float:
	return float(MULTIPLIERS.get(item_id, 0.0))
