class_name BuildingPlacementCatalog
extends RefCounted

const LEGACY_TO_ID := {
	"building_furnace": &"building.furnace", "building_chest": &"building.chest", "building_turret": &"building.turret",
	"building_altar": &"building.altar", "building_ranch": &"building.ranch", "building_cooking_pot": &"building.cooking_pot",
	"building_compost_bin": &"building.compost_bin", "farm_plot": &"building.farm_plot", "wood_fence": &"building.wood_fence",
	"building_workbench": &"building.workbench",
}
const SCENE_PATHS := {
	&"building.furnace": "res://scenes/building_furnace.tscn", &"building.chest": "res://scenes/building_chest.tscn",
	&"building.turret": "res://scenes/building_turret.tscn", &"building.altar": "res://scenes/building_altar.tscn",
	&"building.ranch": "res://scenes/building_ranch.tscn", &"building.cooking_pot": "res://scenes/building_cooking_pot.tscn",
	&"building.compost_bin": "res://scenes/building_compost_bin.tscn", &"building.farm_plot": "res://scenes/resource_node.tscn",
	&"building.workbench": "res://scenes/building_workbench.tscn",
}

static func from_legacy(legacy_id: String) -> StringName: return LEGACY_TO_ID.get(legacy_id, &"")
static func is_supported(building_id: StringName) -> bool: return LEGACY_TO_ID.values().has(building_id)

static func instantiate(building_id: StringName) -> Node2D:
	var node: Node2D
	if building_id == &"building.wood_fence":
		var body := StaticBody2D.new(); body.collision_layer = 1; body.collision_mask = 7
		var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = Vector2(24, 24); collision.shape = shape; body.add_child(collision)
		node = body
	elif SCENE_PATHS.has(building_id):
		var scene := load(String(SCENE_PATHS[building_id])) as PackedScene
		if scene == null: return null
		node = scene.instantiate()
		if building_id == &"building.farm_plot": node.set("node_type", 2)
	return node
