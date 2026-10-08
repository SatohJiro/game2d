class_name PlayerCraftCatalog
extends RefCounted

const LEGACY_TO_ID := {
	"building_cooking_pot": &"recipe.building.cooking_pot", "building_compost_bin": &"recipe.building.compost_bin",
	"building_ranch": &"recipe.building.ranch", "fertilizer": &"recipe.item.organic_fertilizer",
	"pal_elixir": &"recipe.item.stamina_elixir", "regular_sphere": &"recipe.item.pal_sphere_basic",
	"mega_sphere": &"recipe.item.pal_sphere_mega", "giga_sphere": &"recipe.item.pal_sphere_giga",
	"sword_iron": &"recipe.equipment.iron_sword", "sword_pal": &"recipe.equipment.pal_blade",
	"armor_warrior": &"recipe.equipment.pal_warrior_armor", "building_furnace": &"recipe.building.furnace",
	"building_chest": &"recipe.building.chest", "building_turret": &"recipe.building.turret",
	"building_altar": &"recipe.building.altar", "farm_plot": &"recipe.building.farm_plot",
	"wood_fence": &"recipe.building.wood_fence",
}
const ORDER: Array[StringName] = [
	&"recipe.building.cooking_pot", &"recipe.building.compost_bin", &"recipe.building.ranch",
	&"recipe.item.organic_fertilizer", &"recipe.item.stamina_elixir", &"recipe.item.pal_sphere_basic",
	&"recipe.item.pal_sphere_mega", &"recipe.item.pal_sphere_giga", &"recipe.equipment.iron_sword",
	&"recipe.equipment.pal_blade", &"recipe.equipment.pal_warrior_armor", &"recipe.building.furnace",
	&"recipe.building.chest", &"recipe.building.turret", &"recipe.building.altar",
	&"recipe.building.farm_plot", &"recipe.building.wood_fence",
]

static var _definitions: Dictionary = {}


static func get_definition(recipe_id: StringName) -> PlayerCraftDefinition:
	_ensure_initialized()
	var stable_id := LEGACY_TO_ID.get(String(recipe_id), recipe_id) as StringName
	return _definitions.get(stable_id) as PlayerCraftDefinition


static func all_definitions() -> Array[PlayerCraftDefinition]:
	_ensure_initialized()
	var result: Array[PlayerCraftDefinition] = []
	for recipe_id in ORDER: result.append(_definitions[recipe_id])
	return result


static func presentation_recipes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in all_definitions():
		var requirements := {}
		for item_id: StringName in definition.input_amounts(): requirements[LegacyItemAdapter.to_legacy_key(item_id)] = definition.input_amounts()[item_id]
		result.append({"id": String(definition.recipe_id), "name": definition.display_name, "type": _legacy_type(definition.result_kind), "icon": definition.icon_path, "req": requirements, "base_lvl": definition.unlock_level, "desc": definition.description})
	return result


static func _ensure_initialized() -> void:
	if not _definitions.is_empty(): return
	_register(_make(&"recipe.building.cooking_pot", "Bếp Nấu Ăn Dã Ngoại", "res://assets/buildings/cooking_pot.png", 1, {&"item.stone": 4, &"item.wood": 4}, PlayerCraftDefinition.RESULT_BUILDING, &"building.cooking_pot", 1, "Nấu các món ăn sinh tồn: Thịt nướng, Súp hầm, Nước tinh khiết, Bánh mì."))
	_register(_make(&"recipe.building.compost_bin", "Thùng Ủ Phân Hữu Cơ", "res://assets/buildings/compost_bin.png", 1, {&"item.wood": 6, &"item.stone": 2}, PlayerCraftDefinition.RESULT_BUILDING, &"building.compost_bin", 1, "Ủ rơm rác, cỏ dại và chất thải thành Phân Bón Hữu Cơ x2 sản lượng mùa màng."))
	_register(_make(&"recipe.building.ranch", "Chuồng Thú Cưng (Ranch)", "res://assets/buildings/ranch_fence.png", 1, {&"item.wood": 8, &"item.stone": 4}, PlayerCraftDefinition.RESULT_BUILDING, &"building.ranch", 1, "Nuôi Pet thả rông, tiêu thụ thức ăn và định kỳ sản sinh tài nguyên hiếm!"))
	_register(_make(&"recipe.item.organic_fertilizer", "Phân Bón Hữu Cơ Pal", "res://assets/items/fertilizer.png", 1, {&"item.wood": 2, &"item.berry": 2}, PlayerCraftDefinition.RESULT_ITEM, &"item.fertilizer.organic_pal", 2, "Bón vào luống đất tăng gấp đôi (x2) sản lượng cây trồng khi thu hoạch."))
	_register(_make(&"recipe.item.stamina_elixir", "Bình Thuốc Tăng Thể Lực (Elixir)", "res://assets/items/pal_elixir.png", 2, {&"item.pal_herb": 2, &"item.slime_essence": 1}, PlayerCraftDefinition.RESULT_ITEM, &"item.elixir.stamina", 1, "Tăng tối đa Thể Lực và hồi 40 HP ngay lập tức!"))
	_register(_make(&"recipe.item.pal_sphere_basic", "Cầu Pal Thường (x2)", "res://assets/fx/energy_ball.png", 1, {&"item.pal_ore": 1, &"item.wood": 1}, PlayerCraftDefinition.RESULT_ITEM, &"item.pal_sphere.basic", 2, "Cầu thu phục cơ bản, dùng để bắt quái dã ngoại."))
	_register(_make(&"recipe.item.pal_sphere_mega", "Cầu Siêu Cấp (Mega)", "res://assets/items/mega_sphere.png", 2, {&"item.pal_ore": 2, &"item.iron_ingot": 1}, PlayerCraftDefinition.RESULT_ITEM, &"item.pal_sphere.mega", 1, "Tỉ lệ bắt gấp đôi (x2), dễ bắt quái cấp trung."))
	_register(_make(&"recipe.item.pal_sphere_giga", "Cầu Huyền Thoại (Giga)", "res://assets/items/giga_sphere.png", 4, {&"item.pal_ingot": 3, &"item.iron_ingot": 2}, PlayerCraftDefinition.RESULT_ITEM, &"item.pal_sphere.giga", 1, "Cầu tối thượng (x4), bắt được cả quái cấp cao và Boss!"))
	_register(_make(&"recipe.equipment.iron_sword", "Kiếm Sắt Rèn Kỹ", "res://assets/items/sword.png", 2, {&"item.iron_ingot": 4, &"item.wood": 3}, PlayerCraftDefinition.RESULT_EQUIPMENT, PlayerEquipmentCatalog.IRON_SWORD, 1, "Vũ khí sắc bén, tăng sát thương vung chém lên 48!", "Trang bị Kiếm Sắt (Sát thương 48)!"))
	_register(_make(&"recipe.equipment.pal_blade", "Đao Thần Long Pal", "res://assets/items/sword.png", 4, {&"item.pal_ingot": 6, &"item.iron_ingot": 4}, PlayerCraftDefinition.RESULT_EQUIPMENT, PlayerEquipmentCatalog.PAL_BLADE, 1, "Đao truyền thuyết, tăng sát thương lên 85 và tầm chém xa!", "Trang bị Đao Thần Long Pal (Sát thương 85)!"))
	_register(_make(&"recipe.equipment.pal_warrior_armor", "Giáp Chiến Binh Pal", "res://assets/hunter/hunter_faceset.png", 3, {&"item.iron_ingot": 5, &"item.wood": 6}, PlayerCraftDefinition.RESULT_EQUIPMENT, PlayerEquipmentCatalog.PAL_WARRIOR_ARMOR, 1, "Tăng +60 Máu tối đa và giảm 25% sát thương nhận vào.", "Trang bị Giáp Chiến Binh (+60 Máu, -25% Dmg)!"))
	_register(_make(&"recipe.building.furnace", "Lò Luyện Kim", "res://assets/buildings/furnace_stove.png", 1, {&"item.stone": 6, &"item.wood": 4}, PlayerCraftDefinition.RESULT_BUILDING, &"building.furnace", 1, "Đúc Quặng thành Thỏi Sắt (Pet Flam tăng 2.8x tốc độ nung)."))
	_register(_make(&"recipe.building.chest", "Rương Kho Chứa Đồ", "res://assets/buildings/chest_wood.png", 2, {&"item.wood": 6, &"item.iron_ingot": 1}, PlayerCraftDefinition.RESULT_BUILDING, &"building.chest", 1, "Kho chứa đồ rộng, Pet tự động cất nông sản & đá vào đây."))
	_register(_make(&"recipe.building.turret", "Tháp Canh Phòng Thủ", "res://assets/buildings/anvil.png", 3, {&"item.stone": 8, &"item.iron_ingot": 4}, PlayerCraftDefinition.RESULT_BUILDING, &"building.turret", 1, "Tự động phát hiện và bắn đạn bảo vệ căn cứ trong đêm xâm lăng!"))
	_register(_make(&"recipe.building.altar", "Bệ Triệu Hồi Boss", "res://assets/buildings/altar_stone.png", 4, {&"item.stone": 10, &"item.pal_ingot": 2}, PlayerCraftDefinition.RESULT_BUILDING, &"building.altar", 1, "Tế lễ để khiêu chiến Boss cổ đại nhận trang bị thần thoại."))
	_register(_make(&"recipe.building.farm_plot", "Luống Đất Cày Xới", "res://assets/items/seed.png", 1, {&"item.wood": 3, &"item.stone": 2}, PlayerCraftDefinition.RESULT_BUILDING, &"building.farm_plot", 1, "Gieo hạt trồng quả mọng (Pet Slime tưới, Mushroom gặt)."))
	_register(_make(&"recipe.building.wood_fence", "Hàng Rào Gỗ", "res://assets/items/wood.png", 1, {&"item.wood": 2}, PlayerCraftDefinition.RESULT_BUILDING, &"building.wood_fence", 1, "Rào chắn kiên cố ngăn chặn quái vật áp sát."))


static func _register(definition: PlayerCraftDefinition) -> void:
	_definitions[definition.recipe_id] = definition


static func _make(recipe_id: StringName, name: String, icon: String, level: int, input_values: Dictionary, kind: StringName, result_id: StringName, amount: int, description: String, success_text: String = "") -> PlayerCraftDefinition:
	var definition := PlayerCraftDefinition.new()
	definition.recipe_id = recipe_id; definition.display_name = name; definition.icon_path = icon; definition.unlock_level = level
	definition.result_kind = kind; definition.result_id = result_id; definition.result_amount = amount; definition.description = description; definition.success_text = success_text
	var item_ids: Array[StringName] = []
	for raw_id in input_values: item_ids.append(StringName(raw_id))
	item_ids.sort()
	for item_id in item_ids:
		var input := ItemAmount.new(); input.item_id = item_id; input.quantity = int(input_values[item_id]); definition.inputs.append(input)
	return definition


static func _legacy_type(kind: StringName) -> String:
	if kind == PlayerCraftDefinition.RESULT_ITEM: return "item"
	if kind == PlayerCraftDefinition.RESULT_EQUIPMENT: return "equipment"
	return "building"
