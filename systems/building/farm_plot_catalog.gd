class_name FarmPlotCatalog
extends RefCounted

const EMPTY_STAGE := &"farm.stage.empty"
const SEEDED_STAGE := &"farm.stage.seeded"
const GROWING_STAGE := &"farm.stage.growing"
const READY_STAGE := &"farm.stage.ready"
const VALID_STAGES: Array[StringName] = [EMPTY_STAGE, SEEDED_STAGE, GROWING_STAGE, READY_STAGE]
const CROP_IDS: Array[StringName] = [&"crop.berry", &"crop.golden_wheat", &"crop.pal_herb"]
const CROP_ID_BY_LEGACY_TYPE := {0: &"crop.berry", 1: &"crop.golden_wheat", 2: &"crop.pal_herb"}
const LEGACY_TYPE_BY_CROP_ID := {&"crop.berry": 0, &"crop.golden_wheat": 1, &"crop.pal_herb": 2}

static func crop_id_from_legacy(crop_type: int) -> StringName: return CROP_ID_BY_LEGACY_TYPE.get(crop_type, &"")
static func legacy_type_from_id(crop_id: StringName) -> int: return int(LEGACY_TYPE_BY_CROP_ID.get(crop_id, -1))
static func is_supported_crop(crop_id: StringName) -> bool: return CROP_IDS.has(crop_id)
