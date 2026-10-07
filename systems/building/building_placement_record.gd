class_name BuildingPlacementRecord
extends RefCounted

var instance_id: StringName
var building_id: StringName
var transform: Transform2D
var state: Dictionary

func _init(p_instance_id: StringName, p_building_id: StringName, p_transform: Transform2D, p_state: Dictionary = {}) -> void:
	instance_id = p_instance_id
	building_id = p_building_id
	transform = p_transform
	state = p_state.duplicate(true)
	if building_id == &"building.chest" and state.is_empty():
		state = {"inventory": {}}
	elif building_id == &"building.furnace" and state.is_empty():
		state = FurnacePlacementState.new().to_dto()
	elif building_id == &"building.cooking_pot" and state.is_empty():
		state = CookingPotPlacementState.new().to_dto()
	elif building_id == &"building.compost_bin" and state.is_empty():
		state = CompostBinPlacementState.new().to_dto()
	elif building_id == &"building.ranch" and state.is_empty():
		state = RanchPlacementState.new().to_dto()
	elif building_id == &"building.farm_plot" and state.is_empty():
		state = FarmPlotPlacementState.new().to_dto()

func is_valid() -> bool:
	if ContentId.domain_of(instance_id) != &"building" or not BuildingPlacementCatalog.is_supported(building_id) or not transform.is_finite():
		return false
	if building_id == &"building.chest":
		return ChestPlacementState.from_dto(state) != null
	if building_id == &"building.furnace":
		return FurnacePlacementState.from_dto(state) != null
	if building_id == &"building.cooking_pot":
		return CookingPotPlacementState.from_dto(state) != null
	if building_id == &"building.compost_bin":
		return CompostBinPlacementState.from_dto(state) != null
	if building_id == &"building.ranch":
		return RanchPlacementState.from_dto(state) != null
	if building_id == &"building.farm_plot":
		return FarmPlotPlacementState.from_dto(state) != null
	return state.is_empty()

func to_dto() -> Dictionary:
	return {"instance_id": String(instance_id), "building_id": String(building_id), "position": {"x": transform.origin.x, "y": transform.origin.y}, "rotation": transform.get_rotation(), "scale": {"x": transform.get_scale().x, "y": transform.get_scale().y}, "state": state.duplicate(true)}

static func from_dto(value: Variant) -> BuildingPlacementRecord:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = value
	var position: Variant = data.get("position")
	var scale_value: Variant = data.get("scale")
	if typeof(position) != TYPE_DICTIONARY or typeof(scale_value) != TYPE_DICTIONARY:
		return null
	for number: Variant in [position.get("x"), position.get("y"), data.get("rotation"), scale_value.get("x"), scale_value.get("y")]:
		if (typeof(number) != TYPE_INT and typeof(number) != TYPE_FLOAT) or not is_finite(float(number)):
			return null
	var scale := Vector2(float(scale_value["x"]), float(scale_value["y"]))
	if is_zero_approx(scale.x) or is_zero_approx(scale.y):
		return null
	var built_transform := Transform2D(float(data["rotation"]), scale, 0.0, Vector2(float(position["x"]), float(position["y"])))
	var state_value: Variant = data.get("state", {})
	if typeof(state_value) != TYPE_DICTIONARY:
		return null
	var record := BuildingPlacementRecord.new(StringName(data.get("instance_id", "")), StringName(data.get("building_id", "")), built_transform, state_value)
	return record if record.is_valid() else null
