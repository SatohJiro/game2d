extends CanvasLayer

signal recipe_crafted(recipe_id: String)
signal stat_upgrade_requested(stat_name: String)

@onready var player_level_label: Label = $TopLeft/PlayerCard/Margin/HBox/VBox/LevelLabel
@onready var hp_bar: ProgressBar = $TopLeft/PlayerCard/Margin/HBox/VBox/HpBar
@onready var stamina_bar: ProgressBar = $TopLeft/PlayerCard/Margin/HBox/VBox/StaminaBar
@onready var hunger_bar: ProgressBar = $TopLeft/PlayerCard/Margin/HBox/VBox/HungerBar
@onready var thirst_bar: ProgressBar = $TopLeft/PlayerCard/Margin/HBox/VBox/ThirstBar
@onready var exp_bar: ProgressBar = $TopLeft/PlayerCard/Margin/HBox/VBox/ExpBar
@onready var temp_label: Label = $TopLeft/PlayerCard/Margin/HBox/VBox/StatusHBox/TempLabel
@onready var buff_label: Label = $TopLeft/PlayerCard/Margin/HBox/VBox/StatusHBox/BuffLabel

@onready var pet_card: Control = $TopRight/PetCard
@onready var pet_name_label: Label = $TopRight/PetCard/Margin/VBox/PetNameLabel
@onready var pet_hp_bar: ProgressBar = $TopRight/PetCard/Margin/VBox/PetHpBar
@onready var pet_stance_label: Label = $TopRight/PetCard/Margin/VBox/PetStanceLabel

# Base Mission Panel
@onready var quest_panel: PanelContainer = $TopCenter/QuestPanel
@onready var quest_title_label: Label = $TopCenter/QuestPanel/Margin/VBox/QuestTitle
@onready var quest_desc_label: Label = $TopCenter/QuestPanel/Margin/VBox/QuestDesc
@onready var quest_progress_label: Label = $TopCenter/QuestPanel/Margin/VBox/QuestProgress

# Bottom Bar Items
@onready var spheres_label: Label = $BottomBar/HBox/SphereItem/Margin/HBox/VBox/CountLabel
@onready var wood_label: Label = $BottomBar/HBox/WoodItem/Margin/HBox/VBox/CountLabel
@onready var stone_label: Label = $BottomBar/HBox/StoneItem/Margin/HBox/VBox/CountLabel
@onready var ore_label: Label = $BottomBar/HBox/OreItem/Margin/HBox/VBox/CountLabel
@onready var iron_label: Label = $BottomBar/HBox/IronItem/Margin/HBox/VBox/CountLabel
@onready var berry_label: Label = $BottomBar/HBox/BerryItem/Margin/HBox/VBox/CountLabel

# Crafting Modal
@onready var crafting_modal: PanelContainer = $CraftingModal
@onready var recipe_grid: GridContainer = $CraftingModal/Margin/VBox/Scroll/RecipeGrid
@onready var close_craft_btn: Button = $CraftingModal/Margin/VBox/Header/CloseBtn

# Cooking Modal
@onready var cooking_modal: PanelContainer = $CookingModal
@onready var cooking_grid: GridContainer = $CookingModal/Margin/VBox/Scroll/RecipeGrid
@onready var close_cooking_btn: Button = $CookingModal/Margin/VBox/Header/CloseBtn

# Stat Modal (Character Sheet)
@onready var stat_modal: PanelContainer = $StatModal
@onready var stat_points_label: Label = $StatModal/Margin/VBox/StatPointsLabel
@onready var str_val_label: Label = $StatModal/Margin/VBox/Grid/StrVal
@onready var vit_val_label: Label = $StatModal/Margin/VBox/Grid/VitVal
@onready var sta_val_label: Label = $StatModal/Margin/VBox/Grid/StaVal
@onready var agi_val_label: Label = $StatModal/Margin/VBox/Grid/AgiVal
@onready var str_add_btn: Button = $StatModal/Margin/VBox/Grid/StrBtn
@onready var vit_add_btn: Button = $StatModal/Margin/VBox/Grid/VitBtn
@onready var sta_add_btn: Button = $StatModal/Margin/VBox/Grid/StaBtn
@onready var agi_add_btn: Button = $StatModal/Margin/VBox/Grid/AgiBtn
@onready var close_stat_btn: Button = $StatModal/Margin/VBox/Header/CloseBtn
@onready var weapon_info_label: Label = $StatModal/Margin/VBox/GearInfo

# Banner
@onready var banner: PanelContainer = $Banner
@onready var banner_label: Label = $Banner/MarginContainer/BannerLabel

var banner_tween: Tween = null
var current_recipes: Array = []
var cached_inventory: Dictionary = {}
var cached_base_level: int = 1

# Active cooking references
var active_cooking_pot: Node2D = null
var active_player_ref: CharacterBody2D = null
var cached_cooking_recipes: Array = []


## U3.1: single render entry point. The HUD renders this ViewModel and emits
## intents; it never reads player nodes itself. Granular update_* methods stay
## as the render layer for gameplay event push sites.
func render_view_model(vm: HUDViewModel) -> void:
	if vm == null:
		return
	update_player_stats(vm.hp, vm.max_hp, vm.stamina, vm.max_stamina, vm.hunger, vm.max_hunger, vm.thirst, vm.max_thirst, vm.body_temperature, vm.level, vm.exp_val, vm.max_exp, vm.buff_text)
	update_character_sheet(vm.stat_points, vm.stats, vm.weapon_text)
	update_inventory(vm.inventory)
	if vm.pet_visible:
		update_pet_stats(vm.pet_name, vm.pet_level, vm.pet_hp, vm.pet_max_hp, vm.pet_stance_text)

func _ready() -> void:
	banner.modulate.a = 0.0
	if crafting_modal:
		crafting_modal.visible = false
	if close_craft_btn:
		close_craft_btn.pressed.connect(func(): toggle_crafting(false))
	
	if cooking_modal:
		cooking_modal.visible = false
	if close_cooking_btn:
		close_cooking_btn.pressed.connect(func(): close_cooking_modal())
	
	if stat_modal:
		stat_modal.visible = false
	if close_stat_btn:
		close_stat_btn.pressed.connect(func(): toggle_stat_modal(false))
	
	if str_add_btn: str_add_btn.pressed.connect(func(): emit_signal("stat_upgrade_requested", "str"))
	if vit_add_btn: vit_add_btn.pressed.connect(func(): emit_signal("stat_upgrade_requested", "vit"))
	if sta_add_btn: sta_add_btn.pressed.connect(func(): emit_signal("stat_upgrade_requested", "sta"))
	if agi_add_btn: agi_add_btn.pressed.connect(func(): emit_signal("stat_upgrade_requested", "agi"))

func update_player_stats(hp: int, max_hp: int, stamina: float, max_stamina: float, hunger: float, max_hunger: float, thirst: float, max_thirst: float, body_temp: float, level: int, exp_val: int, max_exp: int, buff_str: String = "Khỏe mạnh") -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = stamina
	if hunger_bar:
		hunger_bar.max_value = max_hunger
		hunger_bar.value = hunger
	if thirst_bar:
		thirst_bar.max_value = max_thirst
		thirst_bar.value = thirst
	if exp_bar:
		exp_bar.max_value = max_exp
		exp_bar.value = exp_val
	if player_level_label:
		player_level_label.text = "Nhà Thám Hiểm  ★ Cấp %d (HP: %d/%d)" % [level, hp, max_hp]
	if temp_label:
		temp_label.text = "🌡️ %.1f°C" % body_temp
		if body_temp < 25.0:
			temp_label.modulate = Color(0.4, 0.8, 1.0)
		elif body_temp > 38.5:
			temp_label.modulate = Color(1.0, 0.4, 0.2)
		else:
			temp_label.modulate = Color(1.0, 0.85, 0.4)
	if buff_label:
		buff_label.text = "✨ %s" % buff_str

func update_character_sheet(stat_pts: int, stats: Dictionary, weapon_str: String) -> void:
	if stat_points_label:
		stat_points_label.text = "✨ Điểm Tiềm Năng Chưa Dùng: %d điểm" % stat_pts
	if str_val_label: str_val_label.text = "%d (+%d Sát thương)" % [stats.get("str", 0), stats.get("str", 0) * 3]
	if vit_val_label: vit_val_label.text = "%d (+%d Máu tối đa)" % [stats.get("vit", 0), stats.get("vit", 0) * 25]
	if sta_val_label: sta_val_label.text = "%d (+%d Thể lực)" % [stats.get("sta", 0), stats.get("sta", 0) * 15]
	if agi_val_label: agi_val_label.text = "%d (+%d Tốc độ)" % [stats.get("agi", 0), stats.get("agi", 0) * 8]
	
	var can_add = stat_pts > 0
	if str_add_btn: str_add_btn.disabled = not can_add
	if vit_add_btn: vit_add_btn.disabled = not can_add
	if sta_add_btn: sta_add_btn.disabled = not can_add
	if agi_add_btn: agi_add_btn.disabled = not can_add
	
	if weapon_info_label:
		weapon_info_label.text = "Trang bị: %s" % weapon_str

func toggle_stat_modal(show: bool) -> void:
	if not stat_modal: return
	stat_modal.visible = show

func is_stat_modal_visible() -> bool:
	return stat_modal != null and stat_modal.visible

func update_pet_stats(pet_name: String, level: int, hp: int, max_hp: int, stance_text: String) -> void:
	if not pet_card.visible:
		pet_card.visible = true
	if pet_name_label:
		pet_name_label.text = "🐾 %s (Lv.%d)" % [pet_name, level]
	if pet_hp_bar:
		pet_hp_bar.max_value = max_hp
		pet_hp_bar.value = hp
	if pet_stance_label:
		pet_stance_label.text = "[R] Lệnh: %s | [G] Skill" % stance_text

func update_inventory(inventory: Dictionary) -> void:
	cached_inventory = inventory
	if spheres_label: spheres_label.text = "x%d" % (inventory.get("Cầu Thu Phục", 0) + inventory.get("Mega Sphere", 0) * 10 + inventory.get("Giga Sphere", 0) * 100)
	if wood_label: wood_label.text = "x%d" % inventory.get("Gỗ", 0)
	if stone_label: stone_label.text = "x%d" % inventory.get("Đá", 0)
	if ore_label: ore_label.text = "x%d" % inventory.get("Quặng Pal", 0)
	if iron_label: iron_label.text = "x%d" % inventory.get("Thỏi Sắt", 0)
	if berry_label: berry_label.text = "x%d" % inventory.get("Quả Mọng Hồi Máu", 0)
	
	if crafting_modal and crafting_modal.visible:
		refresh_crafting_buttons()
	if cooking_modal and cooking_modal.visible:
		build_cooking_cards()

func update_quest_info(title: String, desc: String, progress: String, base_level: int) -> void:
	cached_base_level = base_level
	if quest_title_label: quest_title_label.text = "CĂN CỨ CẤP %d: %s" % [base_level, title]
	if quest_desc_label: quest_desc_label.text = desc
	if quest_progress_label: quest_progress_label.text = "Tiến độ: %s" % progress

func show_banner(text: String, duration: float = 3.5) -> void:
	if not banner: return
	banner_label.text = text
	
	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()
	
	banner_tween = create_tween()
	banner.scale = Vector2(0.8, 0.8)
	banner.modulate.a = 0.0
	banner_tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	banner_tween.parallel().tween_property(banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner_tween.tween_interval(duration)
	banner_tween.tween_property(banner, "modulate:a", 0.0, 0.3)
	banner_tween.parallel().tween_property(banner, "scale", Vector2(0.8, 0.8), 0.3)

# Crafting Modal Handling
func set_recipes(rec_list: Array) -> void:
	current_recipes = rec_list
	build_recipe_cards()

func toggle_crafting(show: bool) -> void:
	if not crafting_modal: return
	crafting_modal.visible = show
	if show:
		build_recipe_cards()

func is_crafting_visible() -> bool:
	return crafting_modal != null and crafting_modal.visible

func build_recipe_cards() -> void:
	if not recipe_grid: return
	for child in recipe_grid.get_children():
		child.queue_free()
	
	for rec in current_recipes:
		var card = create_recipe_card(rec)
		recipe_grid.add_child(card)

func create_recipe_card(rec: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", PaloriaTheme.card_stylebox())
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", PaloriaTheme.MARGIN_NORMAL)
	margin.add_theme_constant_override("margin_top", PaloriaTheme.MARGIN_TIGHT)
	margin.add_theme_constant_override("margin_right", PaloriaTheme.MARGIN_NORMAL)
	margin.add_theme_constant_override("margin_bottom", PaloriaTheme.MARGIN_TIGHT)
	card.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_WIDE)
	margin.add_child(hbox)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if rec.has("icon") and ResourceLoader.exists(rec["icon"]):
		icon.texture = load(rec["icon"])
	hbox.add_child(icon)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_TIGHT)
	hbox.add_child(vbox)
	
	var title = Label.new()
	title.text = rec.get("name", "Vật phẩm")
	title.add_theme_font_size_override("font_size", PaloriaTheme.FONT_NORMAL)
	title.add_theme_color_override("font_color", PaloriaTheme.ACCENT_GOLD)
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = rec.get("desc", "")
	desc.add_theme_font_size_override("font_size", PaloriaTheme.FONT_SMALL)
	desc.add_theme_color_override("font_color", PaloriaTheme.TEXT_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	var cost_parts: Array[String] = []
	var can_afford = true
	var reqs = rec.get("req", {})
	for mat in reqs.keys():
		var need = reqs[mat]
		var have = cached_inventory.get(mat, 0)
		cost_parts.append("%s: %d/%d" % [mat, have, need])
		if have < need:
			can_afford = false
	
	var lvl_req = rec.get("base_lvl", 1)
	if cached_base_level < lvl_req:
		can_afford = false
		cost_parts.append("[Cần Căn Cứ Lv.%d]" % lvl_req)
	
	var cost_lbl = Label.new()
	cost_lbl.text = " • ".join(cost_parts)
	cost_lbl.add_theme_font_size_override("font_size", PaloriaTheme.FONT_SMALL)
	cost_lbl.add_theme_color_override("font_color", PaloriaTheme.AFFORDABLE if can_afford else PaloriaTheme.UNAFFORDABLE)
	vbox.add_child(cost_lbl)
	
	var btn = Button.new()
	btn.text = "Chế Tạo"
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.disabled = not can_afford
	btn.pressed.connect(func():
		emit_signal("recipe_crafted", rec["id"])
	)
	hbox.add_child(btn)
	return card

func refresh_crafting_buttons() -> void:
	build_recipe_cards()

# Cooking Modal Handling
func open_cooking_modal(pot_ref: Node2D, player_ref: CharacterBody2D, recipes_list: Array) -> void:
	active_cooking_pot = pot_ref
	active_player_ref = player_ref
	cached_cooking_recipes = recipes_list
	if cooking_modal:
		cooking_modal.visible = true
		build_cooking_cards()

func close_cooking_modal() -> void:
	if cooking_modal:
		cooking_modal.visible = false
	active_cooking_pot = null

func is_cooking_modal_visible() -> bool:
	return cooking_modal != null and cooking_modal.visible

func build_cooking_cards() -> void:
	if not cooking_grid: return
	for child in cooking_grid.get_children():
		child.queue_free()
	
	for rec in cached_cooking_recipes:
		var card = create_cooking_recipe_card(rec)
		cooking_grid.add_child(card)

func create_cooking_recipe_card(rec: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", PaloriaTheme.cooking_card_stylebox())
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", PaloriaTheme.MARGIN_WIDE)
	margin.add_theme_constant_override("margin_top", PaloriaTheme.MARGIN_NORMAL)
	margin.add_theme_constant_override("margin_right", PaloriaTheme.MARGIN_WIDE)
	margin.add_theme_constant_override("margin_bottom", PaloriaTheme.MARGIN_NORMAL)
	card.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_XWIDE)
	margin.add_child(hbox)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if rec.has("icon"):
		icon.texture = rec["icon"]
	hbox.add_child(icon)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_TIGHT)
	hbox.add_child(vbox)
	
	var title = Label.new()
	title.text = rec.get("name", "")
	title.add_theme_font_size_override("font_size", PaloriaTheme.FONT_NORMAL)
	title.add_theme_color_override("font_color", PaloriaTheme.TEXT_WARM)
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = rec.get("desc", "")
	desc.add_theme_font_size_override("font_size", PaloriaTheme.FONT_SMALL)
	desc.add_theme_color_override("font_color", PaloriaTheme.TEXT_FRESH)
	vbox.add_child(desc)
	
	var cost = rec.get("cost", {})
	var cost_parts: Array[String] = []
	var can_afford = true
	for mat in cost.keys():
		var need = cost[mat]
		var have = cached_inventory.get(mat, 0)
		cost_parts.append("%s: %d/%d" % [mat, have, need])
		if have < need:
			can_afford = false
	
	var cost_lbl = Label.new()
	cost_lbl.text = "Nguyên liệu: " + " • ".join(cost_parts)
	cost_lbl.add_theme_font_size_override("font_size", PaloriaTheme.FONT_SMALL)
	cost_lbl.add_theme_color_override("font_color", PaloriaTheme.SUCCESS_GREEN if can_afford else PaloriaTheme.UNAFFORDABLE)
	vbox.add_child(cost_lbl)
	
	var btn = Button.new()
	btn.text = "Nấu Món"
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.disabled = not can_afford
	btn.pressed.connect(func():
		if is_instance_valid(active_cooking_pot) and active_cooking_pot.has_method("start_cooking"):
			var success = active_cooking_pot.start_cooking(rec, active_player_ref)
			if success:
				close_cooking_modal()
	)
	hbox.add_child(btn)
	return card
