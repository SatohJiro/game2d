class_name BuildingPlacementRecord
extends RefCounted

var instance_id: StringName
var building_id: StringName
var transform: Transform2D

func _init(p_instance_id: StringName, p_building_id: StringName, p_transform: Transform2D) -> void:
	instance_id = p_instance_id
	building_id = p_building_id
	transform = p_transform

func is_valid() -> bool:
	return ContentId.domain_of(instance_id) == &"building" and BuildingPlacementCatalog.is_supported(building_id) and transform.is_finite()

func to_dto() -> Dictionary:
	return {"instance_id": String(instance_id), "building_id": String(building_id), "position": {"x": transform.origin.x, "y": transform.origin.y}, "rotation": transform.get_rotation(), "scale": {"x": transform.get_scale().x, "y": transform.get_scale().y}}

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
	var record := BuildingPlacementRecord.new(StringName(data.get("instance_id", "")), StringName(data.get("building_id", "")), built_transform)
	return record if record.is_valid() else null
