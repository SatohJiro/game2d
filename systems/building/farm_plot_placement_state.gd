class_name FarmPlotPlacementState
extends RefCounted

var stage_id: StringName
var crop_id: StringName
var grow_timer: float
var moisture: float
var is_watered: bool
var is_fertilized: bool

func _init(p_stage_id: StringName = FarmPlotCatalog.EMPTY_STAGE, p_crop_id: StringName = &"", p_grow_timer: float = 0.0, p_moisture: float = 0.0, p_is_watered: bool = false, p_is_fertilized: bool = false) -> void:
	stage_id = p_stage_id; crop_id = p_crop_id; grow_timer = p_grow_timer; moisture = p_moisture; is_watered = p_is_watered; is_fertilized = p_is_fertilized

func is_valid() -> bool:
	if not FarmPlotCatalog.VALID_STAGES.has(stage_id) or not is_finite(grow_timer) or not is_finite(moisture) or grow_timer < 0.0 or moisture < 0.0 or moisture > 100.0:
		return false
	if is_watered != (moisture > 0.0): return false
	if stage_id == FarmPlotCatalog.EMPTY_STAGE: return crop_id == &"" and is_zero_approx(grow_timer)
	if not FarmPlotCatalog.is_supported_crop(crop_id): return false
	if stage_id == FarmPlotCatalog.SEEDED_STAGE: return grow_timer < 4.5
	if stage_id == FarmPlotCatalog.GROWING_STAGE: return grow_timer >= 4.5 and grow_timer < 10.0
	return grow_timer >= 10.0

func to_dto() -> Dictionary:
	return {"stage_id": String(stage_id), "crop_id": String(crop_id), "grow_timer": grow_timer, "moisture": moisture, "is_watered": is_watered, "is_fertilized": is_fertilized}

static func from_dto(value: Variant) -> FarmPlotPlacementState:
	if typeof(value) != TYPE_DICTIONARY: return null
	var data: Dictionary = value
	if data.size() != 6 or typeof(data.get("stage_id")) != TYPE_STRING or typeof(data.get("crop_id")) != TYPE_STRING or typeof(data.get("is_watered")) != TYPE_BOOL or typeof(data.get("is_fertilized")) != TYPE_BOOL: return null
	var timer: Variant = data.get("grow_timer"); var moisture_value: Variant = data.get("moisture")
	if (typeof(timer) != TYPE_INT and typeof(timer) != TYPE_FLOAT) or (typeof(moisture_value) != TYPE_INT and typeof(moisture_value) != TYPE_FLOAT): return null
	var state := FarmPlotPlacementState.new(StringName(data["stage_id"]), StringName(data["crop_id"]), float(timer), float(moisture_value), bool(data["is_watered"]), bool(data["is_fertilized"]))
	return state if state.is_valid() else null
