extends CharacterBody2D
class_name Player

@export var move_speed: float = 175.0
@export var sprint_speed: float = 245.0

var max_hp: int = 100
var hp: int = 100
var locomotion_state := PlayerLocomotionState.new()
var max_stamina: float:
	get: return locomotion_state.max_stamina
	set(value): locomotion_state.set_max_stamina(value)
var stamina: float:
	get: return locomotion_state.stamina
	set(value): locomotion_state.set_stamina(value)

var needs_state := PlayerNeedsState.new()
var max_hunger: float:
	get: return needs_state.max_hunger
	set(value): needs_state.set_max_hunger(value)
var hunger: float:
	get: return needs_state.hunger
	set(value): needs_state.set_hunger(value)
var max_thirst: float:
	get: return needs_state.max_thirst
	set(value): needs_state.set_max_thirst(value)
var thirst: float:
	get: return needs_state.thirst
	set(value): needs_state.set_thirst(value)
var body_temperature: float:
	get: return needs_state.body_temperature
	set(value): needs_state.set_temperature(value)
var food_buff_name: String:
	get: return needs_state.get_buff_display_name()
	set(value): needs_state.set_legacy_buff_name(value)
var food_buff_timer: float:
	get: return needs_state.buff_time_remaining
	set(value): needs_state.set_buff_duration(value)

var level: int = 1
var exp_val: int = 0
var max_exp: int = 100

# Stat Allocation System (RPG Depth)
var stat_points: int = 2
var stats: Dictionary = {
	"str": 0,
	"vit": 0,
	"sta": 0,
	"agi": 0
}

var inventory: Dictionary = {
	"Cầu Thu Phục": 12,
	"Mega Sphere": 0,
	"Giga Sphere": 0,
	"Gỗ": 10,
	"Đá": 8,
	"Quặng Pal": 4,
	"Thỏi Sắt": 0,
	"Thỏi Pal": 0,
	"Hạt Giống Cây": 3,
	"Quả Mọng Hồi Máu": 4
}

var attack_cooldown: float = 0.0
var sphere_cooldown: float = 0.0
var is_sprinting: bool:
	get: return locomotion_state.is_sprinting
var shake_amount: float = 0.0
var anim_time: float = 0.0
var footstep_timer: float = 0.0

# Equipment
var weapon_name: String = "Kiếm Gỗ Sơ Cấp"
var weapon_damage: int = 22
var has_armor: bool = false

# Pet Party (Slots 1, 2, 3)
var pet_party: Array[Dictionary] = []
var active_pet_node: Node2D = null

# Combat Roll / Dash (Juice & Skill-based action)
var is_rolling: bool:
	get: return locomotion_state.is_rolling
var is_invulnerable: bool:
	get: return locomotion_state.is_invulnerable
var roll_timer: float:
	get: return locomotion_state.roll_timer
var roll_direction: Vector2:
	get: return locomotion_state.roll_direction
var roll_speed: float:
	get: return locomotion_state.roll_speed
	set(value): locomotion_state.roll_speed = maxf(0.0, value)
var ghost_trail_timer: float = 0.0

# Attack Animation
var is_attacking: bool = false
var attack_anim_timer: float = 0.0

# Build Mode
var is_building: bool = false
var pending_build_id: String = ""
var ghost_preview: Node2D = null

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var weapon_pivot: Node2D = $Visual/WeaponPivot
@onready var camera: Camera2D = $Camera2D
@onready var interact_detector: Area2D = $InteractDetector

const SLASH_SCENE = preload("res://scenes/slash_effect.tscn")
const SPHERE_SCENE = preload("res://scenes/sphere.tscn")
const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")
const RESOURCE_SCENE = preload("res://scenes/resource_node.tscn")
const PET_SCENE = preload("res://scenes/pet.tscn")

# Building preloads
const WB_SCENE = preload("res://scenes/building_workbench.tscn")
const FN_SCENE = preload("res://scenes/building_furnace.tscn")
const CH_SCENE = preload("res://scenes/building_chest.tscn")
const TR_SCENE = preload("res://scenes/building_turret.tscn")
const AL_SCENE = preload("res://scenes/building_altar.tscn")
const RANCH_SCENE = preload("res://scenes/building_ranch.tscn")
const COOKING_POT_SCENE = preload("res://scenes/building_cooking_pot.tscn")
const COMPOST_BIN_SCENE = preload("res://scenes/building_compost_bin.tscn")

var hud_ref: CanvasLayer = null
var base_manager_ref: BaseManager = null

# Recipe database
var recipes: Array[Dictionary] = [
	{
		"id": "building_cooking_pot",
		"name": "Bếp Nấu Ăn Dã Ngoại",
		"type": "building",
		"icon": "res://assets/buildings/cooking_pot.png",
		"req": {"Đá": 4, "Gỗ": 4},
		"base_lvl": 1,
		"desc": "Nấu các món ăn sinh tồn: Thịt nướng, Súp hầm, Nước tinh khiết, Bánh mì."
	},
	{
		"id": "building_compost_bin",
		"name": "Thùng Ủ Phân Hữu Cơ",
		"type": "building",
		"icon": "res://assets/buildings/compost_bin.png",
		"req": {"Gỗ": 6, "Đá": 2},
		"base_lvl": 1,
		"desc": "Ủ rơm rác, cỏ dại và chất thải thành Phân Bón Hữu Cơ x2 sản lượng mùa màng."
	},
	{
		"id": "building_ranch",
		"name": "Chuồng Thú Cưng (Ranch)",
		"type": "building",
		"icon": "res://assets/buildings/ranch_fence.png",
		"req": {"Gỗ": 8, "Đá": 4},
		"base_lvl": 1,
		"desc": "Nuôi Pet thả rông, tiêu thụ thức ăn và định kỳ sản sinh tài nguyên hiếm!"
	},
	{
		"id": "fertilizer",
		"name": "Phân Bón Hữu Cơ Pal",
		"type": "item",
		"icon": "res://assets/items/fertilizer.png",
		"req": {"Gỗ": 2, "Quả Mọng Hồi Máu": 2},
		"base_lvl": 1,
		"desc": "Bón vào luống đất tăng gấp đôi (x2) sản lượng cây trồng khi thu hoạch."
	},
	{
		"id": "pal_elixir",
		"name": "Bình Thuốc Tăng Thể Lực (Elixir)",
		"type": "item",
		"icon": "res://assets/items/pal_elixir.png",
		"req": {"Thảo Dược Pal": 2, "Tinh Chất Thạch Lam": 1},
		"base_lvl": 2,
		"desc": "Tăng tối đa Thể Lực và hồi 40 HP ngay lập tức!"
	},
	{
		"id": "regular_sphere",
		"name": "Cầu Pal Thường (x2)",
		"type": "item",
		"icon": "res://assets/fx/energy_ball.png",
		"req": {"Quặng Pal": 1, "Gỗ": 1},
		"base_lvl": 1,
		"desc": "Cầu thu phục cơ bản, dùng để bắt quái dã ngoại."
	},
	{
		"id": "mega_sphere",
		"name": "Cầu Siêu Cấp (Mega)",
		"type": "item",
		"icon": "res://assets/items/mega_sphere.png",
		"req": {"Quặng Pal": 2, "Thỏi Sắt": 1},
		"base_lvl": 2,
		"desc": "Tỉ lệ bắt gấp đôi (x2), dễ bắt quái cấp trung."
	},
	{
		"id": "giga_sphere",
		"name": "Cầu Huyền Thoại (Giga)",
		"type": "item",
		"icon": "res://assets/items/giga_sphere.png",
		"req": {"Thỏi Pal": 3, "Thỏi Sắt": 2},
		"base_lvl": 4,
		"desc": "Cầu tối thượng (x4), bắt được cả quái cấp cao và Boss!"
	},
	{
		"id": "sword_iron",
		"name": "Kiếm Sắt Rèn Kỹ",
		"type": "equipment",
		"icon": "res://assets/items/sword.png",
		"req": {"Thỏi Sắt": 4, "Gỗ": 3},
		"base_lvl": 2,
		"desc": "Vũ khí sắc bén, tăng sát thương vung chém lên 48!"
	},
	{
		"id": "sword_pal",
		"name": "Đao Thần Long Pal",
		"type": "equipment",
		"icon": "res://assets/items/sword.png",
		"req": {"Thỏi Pal": 6, "Thỏi Sắt": 4},
		"base_lvl": 4,
		"desc": "Đao truyền thuyết, tăng sát thương lên 85 và tầm chém xa!"
	},
	{
		"id": "armor_warrior",
		"name": "Giáp Chiến Binh Pal",
		"type": "equipment",
		"icon": "res://assets/hunter/hunter_faceset.png",
		"req": {"Thỏi Sắt": 5, "Gỗ": 6},
		"base_lvl": 3,
		"desc": "Tăng +60 Máu tối đa và giảm 25% sát thương nhận vào."
	},
	{
		"id": "building_furnace",
		"name": "Lò Luyện Kim",
		"type": "building",
		"icon": "res://assets/buildings/furnace_stove.png",
		"req": {"Đá": 6, "Gỗ": 4},
		"base_lvl": 1,
		"desc": "Đúc Quặng thành Thỏi Sắt (Pet Flam tăng 2.8x tốc độ nung)."
	},
	{
		"id": "building_chest",
		"name": "Rương Kho Chứa Đồ",
		"type": "building",
		"icon": "res://assets/buildings/chest_wood.png",
		"req": {"Gỗ": 6, "Thỏi Sắt": 1},
		"base_lvl": 2,
		"desc": "Kho chứa đồ rộng, Pet tự động cất nông sản & đá vào đây."
	},
	{
		"id": "building_turret",
		"name": "Tháp Canh Phòng Thủ",
		"type": "building",
		"icon": "res://assets/buildings/anvil.png",
		"req": {"Đá": 8, "Thỏi Sắt": 4},
		"base_lvl": 3,
		"desc": "Tự động phát hiện và bắn đạn bảo vệ căn cứ trong đêm xâm lăng!"
	},
	{
		"id": "building_altar",
		"name": "Bệ Triệu Hồi Boss",
		"type": "building",
		"icon": "res://assets/buildings/altar_stone.png",
		"req": {"Đá": 10, "Thỏi Pal": 2},
		"base_lvl": 4,
		"desc": "Tế lễ để khiêu chiến Boss cổ đại nhận trang bị thần thoại."
	},
	{
		"id": "farm_plot",
		"name": "Luống Đất Cày Xới",
		"type": "building",
		"icon": "res://assets/items/seed.png",
		"req": {"Gỗ": 3, "Đá": 2},
		"base_lvl": 1,
		"desc": "Gieo hạt trồng quả mọng (Pet Slime tưới, Mushroom gặt)."
	},
	{
		"id": "wood_fence",
		"name": "Hàng Rào Gỗ",
		"type": "building",
		"icon": "res://assets/items/wood.png",
		"req": {"Gỗ": 2},
		"base_lvl": 1,
		"desc": "Rào chắn kiên cố ngăn chặn quái vật áp sát."
	}
]

func _ready() -> void:
	add_to_group("player")
	
	# Connect to HUD
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.size() > 0:
		hud_ref = huds[0]
		hud_ref.set_recipes(recipes)
		hud_ref.recipe_crafted.connect(craft_recipe)
		hud_ref.stat_upgrade_requested.connect(upgrade_stat)
	
	# Setup Ghost Preview for Building
	ghost_preview = Node2D.new()
	ghost_preview.visible = false
	var ghost_sprite = Sprite2D.new()
	ghost_sprite.name = "Sprite"
	ghost_sprite.modulate = Color(0.4, 0.9, 1.0, 0.6)
	ghost_preview.add_child(ghost_sprite)
	get_parent().call_deferred("add_child", ghost_preview)
	
	# Setup Base Manager
	base_manager_ref = BaseManager.new()
	base_manager_ref.name = "BaseManager"
	add_child(base_manager_ref)
	base_manager_ref.quest_updated.connect(func(title, desc, prog):
		if hud_ref:
			hud_ref.update_quest_info(title, desc, prog, base_manager_ref.base_level)
	)
	
	recalculate_stats()
	update_hud()
	base_manager_ref.check_quest_progress(self)

func recalculate_stats() -> void:
	max_hp = 100 + (level - 1) * 18 + stats["vit"] * 25 + (60 if has_armor else 0)
	max_stamina = 100.0 + stats["sta"] * 15.0
	move_speed = 175.0 + stats["agi"] * 8.0
	sprint_speed = move_speed * 1.4

func upgrade_stat(stat_name: String) -> void:
	if stat_points <= 0 or not stats.has(stat_name):
		return
	stat_points -= 1
	stats[stat_name] += 1
	recalculate_stats()
	hp = min(max_hp, hp + 25)
	
	spawn_floating_text("+1 %s!" % stat_name.to_upper(), Color(0.3, 1.0, 0.5))
	if AudioManager:
		AudioManager.play_sound("powerup")
	update_hud()

func _input(event: InputEvent) -> void:
	# Build mode placement
	if is_building:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			place_current_building()
			return
		elif (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed) or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			cancel_build_mode()
			return
	
	# Right mouse or Q: Throw sphere
	if event.is_action_pressed("ui_focus_next") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		throw_pal_sphere()
	
	# Key C: Toggle Crafting Menu
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		if hud_ref:
			hud_ref.toggle_crafting(not hud_ref.is_crafting_visible())
	
	# Key P: Toggle Character Sheet (Stat Points)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		if hud_ref:
			hud_ref.toggle_stat_modal(not hud_ref.is_stat_modal_visible())
	
	# Key E: Interact
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		try_interact()
	
	# Key R: Command pet
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		command_pets()
	
	# Key G: Partner Active Skill
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G:
		activate_partner_skill()
	
	# Key H: Use Pal Elixir
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
		use_pal_elixir()
	
	# Key F: Eat berry to heal
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		eat_berry()
	
	# Key B: Quick build fence
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		start_build_mode("wood_fence")
	
	# Spacebar: Combat Roll (Dodge & Invulnerability Frames)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		var modal_open = (hud_ref != null) and (hud_ref.is_crafting_visible() or hud_ref.is_stat_modal_visible())
		if not is_building and not modal_open:
			try_combat_roll()
			return

	# Keys 1, 2, 3: Swap active pet from party
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			swap_active_pet(0)
		elif event.keycode == KEY_2:
			swap_active_pet(1)
		elif event.keycode == KEY_3:
			swap_active_pet(2)

func try_combat_roll() -> void:
	# Determine roll direction from move input or mouse direction
	var movement_input := read_movement_input()
	var direction := movement_input.move_direction
	if direction == Vector2.ZERO:
		direction = (get_global_mouse_position() - global_position).normalized()
	if not locomotion_state.try_start_roll(direction):
		return
	
	# Audio & Juice: Squash & Stretch Tween
	if AudioManager:
		AudioManager.play_sound("jump")
	
	spawn_ghost_trail()
	spawn_footstep_dust()
	
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(1.35, 0.75), 0.12)
	tween.tween_property(visual, "scale", Vector2(1.0, 1.0), 0.18)


func read_movement_input() -> PlayerMovementInput:
	var move_direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): move_direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): move_direction.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move_direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move_direction.x += 1.0
	return PlayerMovementInput.new(move_direction, Input.is_key_pressed(KEY_SHIFT))

func spawn_ghost_trail() -> void:
	if not is_inside_tree() or not sprite: return
	var ghost = Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	ghost.scale = sprite.scale * 1.6
	ghost.global_position = sprite.global_position
	ghost.modulate = Color(0.4, 0.8, 1.0, 0.55)
	get_parent().add_child(ghost)
	
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.24)
	tween.chain().tween_callback(ghost.queue_free)

func _physics_process(delta: float) -> void:
	if attack_cooldown > 0: attack_cooldown -= delta
	if sphere_cooldown > 0: sphere_cooldown -= delta
	
	# Temperature logic (Warmth from heat sources, Campfire, Furnace, Cooking Pot, or Fire Pet)
	var near_heat := false
	var heat_nodes = get_tree().get_nodes_in_group("heat_sources")
	for h in heat_nodes:
		if is_instance_valid(h) and global_position.distance_to(h.global_position) < 110.0:
			near_heat = true
			break
	if not near_heat and is_instance_valid(active_pet_node) and active_pet_node.get("species_data") != null and active_pet_node.species_data.get("element") == "Lửa":
		if global_position.distance_to(active_pet_node.global_position) < 80.0:
			near_heat = true
	
	needs_state.tick(delta, is_sprinting, near_heat)
	var movement_input := read_movement_input()
	var locomotion_result := locomotion_state.tick(
		delta,
		movement_input,
		velocity,
		move_speed,
		sprint_speed,
		needs_state.get_movement_multiplier(),
		needs_state.get_stamina_regen_multiplier()
	)
	velocity = locomotion_result.velocity
	
	# Handle active Combat Roll
	if locomotion_result.roll_frame:
		ghost_trail_timer += delta
		if ghost_trail_timer >= 0.08:
			ghost_trail_timer = 0.0
			spawn_ghost_trail()
		
		move_and_slide()
		update_hud()
		return
	
	# Update ghost preview in build mode
	if is_building and ghost_preview:
		ghost_preview.global_position = get_global_mouse_position()
	
	# Handle camera screen shake
	if shake_amount > 0:
		camera.offset = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		shake_amount = max(0.0, shake_amount - delta * 16.0)
	else:
		camera.offset = Vector2.ZERO
	
	# Aim weapon towards mouse
	var mouse_pos = get_global_mouse_position()
	var aim_dir = (mouse_pos - global_position).normalized()
	weapon_pivot.rotation = aim_dir.angle()
	
	var move_input := locomotion_result.move_direction
	if is_sprinting:
		# Footstep dust particle
		footstep_timer += delta
		if footstep_timer >= 0.16:
			footstep_timer = 0.0
			spawn_footstep_dust()
	# Update attack animation timer
	if attack_anim_timer > 0:
		attack_anim_timer -= delta
		is_attacking = attack_anim_timer > 0
	
	# Determine facing column (0=Down, 1=Up, 2=Left, 3=Right)
	var facing_col = 0
	if abs(aim_dir.x) > abs(aim_dir.y):
		facing_col = 3 if aim_dir.x > 0 else 2
	else:
		facing_col = 0 if aim_dir.y > 0 else 1
	
	if is_rolling:
		# Row 6: Roll / acrobat frame in facing direction
		if sprite:
			sprite.frame = 6 * 4 + facing_col
	elif is_attacking:
		# Row 4 (windup) and Row 5 (strike thrust)
		var atk_row = 4 if attack_anim_timer > 0.11 else 5
		if sprite:
			sprite.frame = atk_row * 4 + facing_col
	elif move_input != Vector2.ZERO:
		anim_time += delta * (10.0 if is_sprinting else 7.0)
		var walk_frames = [0, 1, 2, 3]
		var step = int(anim_time) % 4
		var walk_row = walk_frames[step]
		if sprite:
			sprite.frame = walk_row * 4 + facing_col
		# Gentle bobbing while walking
		visual.position.y = sin(anim_time * 2.0) * 1.5
	else:
		anim_time = 0.0
		var idle_row = 0 if int(Time.get_ticks_msec() / 600.0) % 2 == 0 else 2
		if sprite:
			sprite.frame = idle_row * 4 + facing_col
		# Subtle idle breathing
		visual.position.y = sin(Time.get_ticks_msec() * 0.004) * 0.8
	
	move_and_slide()
	
	# Primary attack: Left mouse click (only when not in build mode and modal menus closed)
	var modal_open = (hud_ref != null) and (hud_ref.is_crafting_visible() or hud_ref.is_stat_modal_visible())
	var can_attack = not is_building and not modal_open and not is_rolling
	if can_attack and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and attack_cooldown <= 0:
		perform_attack(aim_dir)
	
	update_hud()

func spawn_footstep_dust() -> void:
	if not is_inside_tree(): return
	var dust = Sprite2D.new()
	dust.texture = preload("res://assets/fx/dust.png")
	dust.global_position = global_position + Vector2(randf_range(-4, 4), 10)
	get_parent().add_child(dust)
	
	var tween = create_tween()
	tween.tween_property(dust, "scale", Vector2(1.4, 1.4), 0.3)
	tween.parallel().tween_property(dust, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(dust.queue_free)

func perform_attack(aim_dir: Vector2) -> void:
	attack_cooldown = 0.28
	is_attacking = true
	attack_anim_timer = 0.22
	
	if AudioManager:
		AudioManager.play_sound("slash")
	
	# Spawn sword slash arc
	var slash = SLASH_SCENE.instantiate()
	slash.global_position = global_position + aim_dir * 28.0
	slash.rotation = aim_dir.angle()
	slash.player_ref = self
	var total_dmg = weapon_damage + (level - 1) * 3 + stats["str"] * 3
	slash.damage = total_dmg
	get_parent().add_child(slash)
	
	# Dynamic sword thrust animation
	var weapon_spr = weapon_pivot.get_node_or_null("SwordSprite")
	if weapon_spr:
		weapon_spr.visible = true
		weapon_spr.position.x = 14.0
		var stween = create_tween()
		stween.tween_property(weapon_spr, "position:x", 28.0, 0.08)
		stween.tween_property(weapon_spr, "position:x", 14.0, 0.12)
		stween.tween_callback(func(): weapon_spr.visible = false)
	
	velocity += aim_dir * 70.0

func shake_camera(amount: float) -> void:
	shake_amount = max(shake_amount, amount)

func throw_pal_sphere() -> void:
	if sphere_cooldown > 0 or is_building:
		return
	
	# Select best available sphere
	var sphere_type = ""
	var multiplier = 1.0
	
	if inventory.get("Giga Sphere", 0) > 0:
		sphere_type = "Giga Sphere"
		multiplier = 4.0
	elif inventory.get("Mega Sphere", 0) > 0:
		sphere_type = "Mega Sphere"
		multiplier = 2.0
	elif inventory.get("Cầu Thu Phục", 0) > 0:
		sphere_type = "Cầu Thu Phục"
		multiplier = 1.0
	else:
		spawn_floating_text("Hết Cầu Thu Phục! (Bấm [C] chế tạo)", Color(1.0, 0.4, 0.4))
		return
	
	sphere_cooldown = 0.50
	inventory[sphere_type] -= 1
	update_hud()
	
	var mouse_pos = get_global_mouse_position()
	
	var sphere = SPHERE_SCENE.instantiate()
	sphere.sphere_name = sphere_type
	sphere.player_ref = self
	sphere.catch_multiplier = multiplier
	get_parent().add_child(sphere)
	sphere.launch(global_position + Vector2(0, -6), mouse_pos)
	
	# Throw recoil animation
	var throw_dir = (mouse_pos - global_position).normalized()
	velocity -= throw_dir * 45.0
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(0.85, 1.2), 0.08)
	tween.tween_property(visual, "scale", Vector2.ONE, 0.12)
	
	spawn_floating_text("Ném %s (x%.1f tỉ lệ)!" % [sphere_type, multiplier], Color(0.3, 0.9, 1.0))
	if AudioManager:
		AudioManager.play_sound("sphere_throw")

func craft_recipe(recipe_id: String) -> void:
	var rec: Dictionary = {}
	for r in recipes:
		if r["id"] == recipe_id:
			rec = r
			break
	if rec.is_empty(): return
	
	# Check materials
	var reqs = rec.get("req", {})
	for mat in reqs.keys():
		if inventory.get(mat, 0) < reqs[mat]:
			spawn_floating_text("Không đủ nguyên liệu: %s!" % mat, Color(1.0, 0.4, 0.4))
			return
	
	# Deduct
	for mat in reqs.keys():
		inventory[mat] -= reqs[mat]
	
	# Handle result
	if rec["type"] == "item":
		if recipe_id == "regular_sphere":
			inventory["Cầu Thu Phục"] = inventory.get("Cầu Thu Phục", 0) + 2
		elif recipe_id == "mega_sphere":
			inventory["Mega Sphere"] = inventory.get("Mega Sphere", 0) + 1
		elif recipe_id == "giga_sphere":
			inventory["Giga Sphere"] = inventory.get("Giga Sphere", 0) + 1
		elif recipe_id == "fertilizer":
			inventory["Phân Bón Hữu Cơ Pal"] = inventory.get("Phân Bón Hữu Cơ Pal", 0) + 2
		elif recipe_id == "pal_elixir":
			inventory["Bình Thuốc Tăng Thể Lực"] = inventory.get("Bình Thuốc Tăng Thể Lực", 0) + 1
		spawn_floating_text("Chế tạo thành công: %s!" % rec["name"], Color(0.2, 1.0, 0.5))
		if AudioManager:
			AudioManager.play_sound("pickup")
	
	elif rec["type"] == "equipment":
		if recipe_id == "sword_iron":
			weapon_name = "Kiếm Sắt Rèn Kỹ"
			weapon_damage = 48
			spawn_floating_text("Trang bị Kiếm Sắt (Sát thương 48)!", Color(1.0, 0.85, 0.2))
		elif recipe_id == "sword_pal":
			weapon_name = "Đao Thần Long Pal"
			weapon_damage = 85
			spawn_floating_text("Trang bị Đao Thần Long Pal (Sát thương 85)!", Color(0.3, 0.9, 1.0))
		elif recipe_id == "armor_warrior":
			has_armor = true
			recalculate_stats()
			hp = max_hp
			spawn_floating_text("Trang bị Giáp Chiến Binh (+60 Máu, -25% Dmg)!", Color(0.4, 1.0, 0.5))
		if AudioManager:
			AudioManager.play_sound("powerup")
	
	elif rec["type"] == "building":
		if hud_ref:
			hud_ref.toggle_crafting(false)
		start_build_mode(recipe_id)
		return
	
	update_hud()
	if base_manager_ref:
		base_manager_ref.check_quest_progress(self)

func start_build_mode(building_id: String) -> void:
	is_building = true
	pending_build_id = building_id
	if ghost_preview:
		ghost_preview.visible = true
		var spr = ghost_preview.get_node_or_null("Sprite") as Sprite2D
		if spr:
			match building_id:
				"building_furnace": spr.texture = preload("res://assets/buildings/furnace_stove.png")
				"building_chest": spr.texture = preload("res://assets/buildings/chest_wood.png")
				"building_turret": spr.texture = preload("res://assets/buildings/anvil.png")
				"building_altar": spr.texture = preload("res://assets/buildings/altar_stone.png")
				"building_ranch": spr.texture = preload("res://assets/buildings/ranch_fence.png")
				"farm_plot": spr.texture = preload("res://assets/tilesets/tileset_field.png")
				"wood_fence": spr.texture = preload("res://assets/items/wood.png")
				_: spr.texture = preload("res://assets/buildings/table_workbench.png")
	
	spawn_floating_text("CHẾ ĐỘ XÂY DỰNG: Click chuột trái để đặt công trình!", Color(0.3, 0.9, 1.0))

func place_current_building() -> void:
	var place_pos = get_global_mouse_position()
	var b_node: Node2D = null
	
	match pending_build_id:
		"building_furnace": b_node = FN_SCENE.instantiate()
		"building_chest": b_node = CH_SCENE.instantiate()
		"building_turret": b_node = TR_SCENE.instantiate()
		"building_altar": b_node = AL_SCENE.instantiate()
		"building_ranch": b_node = RANCH_SCENE.instantiate()
		"building_cooking_pot": b_node = COOKING_POT_SCENE.instantiate()
		"building_compost_bin": b_node = COMPOST_BIN_SCENE.instantiate()
		"farm_plot":
			var plot = RESOURCE_SCENE.instantiate()
			plot.node_type = ResourceNode.NodeType.FARM_PLOT
			b_node = plot
		"wood_fence":
			var body = StaticBody2D.new()
			body.name = "Fence"
			body.collision_layer = 1
			body.collision_mask = 7
			var col = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = Vector2(24, 24)
			col.shape = shape
			body.add_child(col)
			var spr = Sprite2D.new()
			spr.texture = preload("res://assets/tilesets/tileset_house.png")
			spr.region_enabled = true
			spr.region_rect = Rect2(304, 304, 32, 32)
			body.add_child(spr)
			b_node = body
		_:
			b_node = WB_SCENE.instantiate()
	
	if b_node:
		b_node.global_position = place_pos
		get_parent().add_child(b_node)
		spawn_floating_text("Đã xây dựng thành công!", Color(0.4, 1.0, 0.5))
		if AudioManager:
			AudioManager.play_sound("pickup")
	
	cancel_build_mode()
	if base_manager_ref:
		base_manager_ref.check_quest_progress(self)

func cancel_build_mode() -> void:
	is_building = false
	pending_build_id = ""
	if ghost_preview:
		ghost_preview.visible = false

func swap_active_pet(idx: int) -> void:
	if idx >= pet_party.size():
		spawn_floating_text("Ô Pet số %d đang trống!" % (idx + 1), Color(0.8, 0.8, 0.8))
		return
	
	var data = pet_party[idx]
	var pets = get_tree().get_nodes_in_group("companion_pets")
	for p in pets:
		p.queue_free()
	
	var pet_inst = PET_SCENE.instantiate()
	pet_inst.species_data = data["species_data"]
	pet_inst.level = data["level"]
	pet_inst.player_target = self
	pet_inst.global_position = global_position + Vector2(25, 25)
	get_parent().add_child(pet_inst)
	active_pet_node = pet_inst
	
	var badge = data.get("rarity_badge", "★")
	var trait_str = data.get("trait", "")
	spawn_floating_text("[%s] Triệu hồi %s (Lv.%d)!" % [badge, data["species_data"]["name"], data["level"]], Color(0.4, 0.9, 1.0))
	if AudioManager:
		AudioManager.play_sound("powerup")
	if hud_ref:
		var display_name = "[%s] %s (%s)" % [badge, data["species_data"]["name"], trait_str]
		hud_ref.update_pet_stats(display_name, data["level"], pet_inst.hp, pet_inst.max_hp, "Tự do Tấn công")

func on_pet_captured(pet_data: Dictionary, pet_level: int) -> void:
	gain_exp(75)
	shake_camera(4.5)
	
	# Determine Pet Rarity & Traits
	var roll = randf()
	var rarity_badge = "★"
	var trait_name = "Chăm Chỉ"
	var stat_multiplier = 1.0
	
	if roll < 0.05:
		rarity_badge = "★★★★ Thần Thoại"
		trait_name = "Thần Long Hộ Mệnh"
		stat_multiplier = 1.5
	elif roll < 0.20:
		rarity_badge = "★★★ Sử Thi"
		trait_name = ["Chiến Tướng", "Thần Tốc", "Hộ Vệ"][randi() % 3]
		stat_multiplier = 1.3
	elif roll < 0.45:
		rarity_badge = "★★ Hiếm"
		trait_name = ["Dũng Cảm", "Nhanh Nhẹn"][randi() % 2]
		stat_multiplier = 1.15
	else:
		rarity_badge = "★ Thường"
		trait_name = "Bình Thường"
		stat_multiplier = 1.0
	
	var boosted_data = pet_data.duplicate()
	boosted_data["power"] = int(boosted_data.get("power", 16) * stat_multiplier)
	boosted_data["max_hp"] = int(boosted_data.get("max_hp", 100) * stat_multiplier)
	
	var party_entry = {
		"species_data": boosted_data,
		"level": pet_level,
		"rarity_badge": rarity_badge,
		"trait": trait_name
	}
	pet_party.append(party_entry)
	
	if hud_ref:
		hud_ref.show_banner("THU PHỤC THÀNH CÔNG!\n[%s] %s (Nội Tại: %s)!" % [rarity_badge, pet_data["name"], trait_name], 4.5)
		hud_ref.update_pet_stats("[%s] %s" % [rarity_badge, pet_data["name"]], pet_level, boosted_data["max_hp"], boosted_data["max_hp"], "Tự do Tấn công")
	
	if base_manager_ref:
		base_manager_ref.check_quest_progress(self)

func try_interact() -> void:
	var overlapping = interact_detector.get_overlapping_bodies()
	for body in overlapping:
		if body.has_method("interact"):
			body.interact(self)
			return
		elif body.has_method("hit_by_tool"):
			body.hit_by_tool(35, self)
			return
	
	var overlapping_areas = interact_detector.get_overlapping_areas()
	for area in overlapping_areas:
		var parent_node = area.get_parent()
		if parent_node and parent_node.has_method("interact"):
			parent_node.interact(self)
			return
	
	# Check if standing near Water Pond to drink natural water
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_node("Environment/WaterPond"):
		var pond = main_scene.get_node("Environment/WaterPond")
		if global_position.distance_to(pond.global_position) < 85.0:
			needs_state.restore_thirst(45.0)
			spawn_floating_text("💧 Vốc nước hồ uống giải khát! (+45 Khát)", Color(0.3, 0.9, 1.0))
			if AudioManager:
				AudioManager.play_sound("pickup")
			update_hud()
			return

func command_pets() -> void:
	var pets = get_tree().get_nodes_in_group("companion_pets")
	if pets.size() == 0:
		spawn_floating_text("Bạn chưa có Pet nào xuất chiến! [Phím 1,2,3]", Color(1.0, 0.7, 0.2))
		return
	
	for pet in pets:
		if pet.has_method("toggle_stance"):
			pet.toggle_stance()
			var stance_str = "Tự do Tấn công" if pet.stance == pet.Stance.AGGRESSIVE else "Theo sát & Phòng thủ"
			if hud_ref:
				hud_ref.update_pet_stats(pet.species_data.get("name", "Pet"), pet.level, pet.hp, pet.max_hp, stance_str)

func activate_partner_skill() -> void:
	if is_instance_valid(active_pet_node) and active_pet_node.has_method("activate_partner_skill"):
		active_pet_node.activate_partner_skill(self)
	else:
		spawn_floating_text("Chưa xuất chiến Pet nào! [Bấm phím 1, 2, 3]", Color(1.0, 0.7, 0.2))

func use_pal_elixir() -> void:
	if inventory.get("Bình Thuốc Tăng Thể Lực", 0) > 0:
		inventory["Bình Thuốc Tăng Thể Lực"] -= 1
		hp = min(max_hp, hp + 45)
		stamina = max_stamina
		spawn_floating_text("✨ Uống Elixir: Hồi 45 HP & 100% Thể Lực!", Color(0.2, 1.0, 0.8))
		if AudioManager:
			AudioManager.play_sound("powerup")
		update_hud()
	else:
		spawn_floating_text("Không có Bình Thuốc Thể Lực! [Bấm C chế tạo]", Color(1.0, 0.4, 0.4))

func eat_berry() -> void:
	consume_food()

func consume_food() -> void:
	# Priority 1: High tier cooked food
	if inventory.get("Súp Hầm Sơn Hào", 0) > 0:
		inventory["Súp Hầm Sơn Hào"] -= 1
		hp = min(max_hp, hp + 60)
		needs_state.restore_hunger(70.0)
		needs_state.restore_thirst(45.0)
		needs_state.set_buff(PlayerNeedsState.BUFF_STAMINA_REGEN, 180.0)
		spawn_floating_text("🍲 Thưởng thức Súp Hầm Sơn Hào (+60 HP, +70 No, +45 Khát)!", Color(1.0, 0.85, 0.3))
		if AudioManager: AudioManager.play_sound("pickup")
		update_hud()
		return
	
	if inventory.get("Thịt Nướng Xông Khói", 0) > 0:
		inventory["Thịt Nướng Xông Khói"] -= 1
		hp = min(max_hp, hp + 35)
		needs_state.restore_hunger(50.0)
		needs_state.set_temperature(37.5)
		needs_state.set_buff(PlayerNeedsState.BUFF_WARMTH, 180.0)
		spawn_floating_text("🍖 Ăn Thịt Nướng Xông Khói (+35 HP, +50 No, Giữ Ấm)!", Color(1.0, 0.7, 0.2))
		if AudioManager: AudioManager.play_sound("pickup")
		update_hud()
		return
	
	if inventory.get("Nước Tinh Khiết Đun Sôi", 0) > 0:
		inventory["Nước Tinh Khiết Đun Sôi"] -= 1
		needs_state.restore_thirst(65.0)
		needs_state.set_temperature(37.0)
		spawn_floating_text("💧 Uống Nước Đun Sôi Tinh Khiết (+65 Khát, Thanh Lọc)!", Color(0.3, 0.9, 1.0))
		if AudioManager: AudioManager.play_sound("pickup")
		update_hud()
		return
	
	if inventory.get("Mứt Dâu Rừng Dẻo", 0) > 0:
		inventory["Mứt Dâu Rừng Dẻo"] -= 1
		needs_state.restore_hunger(40.0)
		stamina = max_stamina
		needs_state.set_buff(PlayerNeedsState.BUFF_SPEED, 120.0)
		spawn_floating_text("🍓 Ăn Mứt Dâu Rừng (+40 No, +100% Thể Lực, +Tốc Độ)!", Color(1.0, 0.4, 0.6))
		if AudioManager: AudioManager.play_sound("pickup")
		update_hud()
		return
	
	if inventory.get("Bánh Mì Lúa Mì Nướng", 0) > 0:
		inventory["Bánh Mì Lúa Mì Nướng"] -= 1
		needs_state.restore_hunger(55.0)
		needs_state.set_buff(PlayerNeedsState.BUFF_SLOW_HUNGER, 240.0)
		spawn_floating_text("🍞 Ăn Bánh Mì Lúa Mì (+55 No, No Lâu Dài)!", Color(1.0, 0.85, 0.4))
		if AudioManager: AudioManager.play_sound("pickup")
		update_hud()
		return
	
	if inventory.get("Quả Mọng Hồi Máu", 0) > 0:
		inventory["Quả Mọng Hồi Máu"] -= 1
		hp = min(max_hp, hp + 35)
		needs_state.restore_hunger(25.0)
		needs_state.restore_thirst(15.0)
		spawn_floating_text("🫐 Ăn Quả Mọng (+35 Máu, +25 No, +15 Khát)!", Color(0.3, 1.0, 0.4))
		if AudioManager:
			AudioManager.play_sound("pickup")
		update_hud()
		return
	
	spawn_floating_text("Không có thức ăn! [Bấm E Bếp nấu ăn hoặc thu hoạch quả]", Color(1.0, 0.4, 0.4))

func take_damage(amount: int, hit_origin: Vector2) -> void:
	if is_invulnerable or is_rolling:
		spawn_floating_text("NÉ ĐÒN! (DODGE)", Color(0.3, 1.0, 1.0))
		shake_camera(2.0)
		return

	var request := DamageRequest.new(&"hostile", &"player", hp, max_hp, amount, hit_origin, global_position)
	request.damage_multiplier = 0.75 if has_armor else 1.0
	request.knockback_strength = 200.0
	var result := apply_damage_request(request)
	if not result.is_applied():
		return
	update_hud()
	
	spawn_floating_text(str(result.applied_damage), Color(1.0, 0.2, 0.2))
	shake_camera(6.0)
	if AudioManager:
		AudioManager.play_sound("hit")
	
	velocity = result.knockback
	
	var tween = create_tween()
	visual.modulate = Color(2.5, 0.4, 0.4)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.2)
	
	if result.defeated:
		spawn_floating_text("BẠN ĐÃ NGẤT! HỒI SINH TẠI TRẠI...", Color(1.0, 0.2, 0.2))
		hp = max_hp
		needs_state.set_hunger(80.0)
		global_position = Vector2.ZERO
		update_hud()


func apply_damage_request(request: DamageRequest) -> DamageResult:
	var result := CombatResolver.resolve(request)
	if result.is_applied():
		hp = result.remaining_hp
	return result

func gain_exp(amount: int) -> void:
	exp_val += amount
	spawn_floating_text("+%d EXP" % amount, Color(0.3, 0.9, 1.0))
	
	while exp_val >= max_exp:
		exp_val -= max_exp
		level += 1
		max_exp = int(max_exp * 1.4)
		stat_points += 2
		recalculate_stats()
		hp = max_hp
		spawn_floating_text("★ LÊN CẤP %d! +2 ĐIỂM TIỀM NĂNG [P]!" % level, Color(1.0, 0.9, 0.1))
		shake_camera(5.5)
		if AudioManager:
			AudioManager.play_sound("level_up")
		if hud_ref:
			hud_ref.show_banner("CHÚC MỪNG! ĐẠT CẤP %d (+2 ĐIỂM TIỀM NĂNG [Phím P])!" % level)
	
	update_hud()

func add_item(item_name: String, count: int) -> bool:
	var content_id := LegacyItemAdapter.to_content_id(item_name)
	if LegacyItemAdapter.is_mapped(content_id):
		return add_item_by_id(content_id, count)
	if item_name.is_empty() or count <= 0:
		return false
	inventory[item_name] = maxi(0, int(inventory.get(item_name, 0))) + count
	_on_inventory_changed()
	return true


func add_item_by_id(item_id: StringName, count: int) -> bool:
	var result := InventoryTransaction.new(inventory).add(item_id, count)
	if not result.is_success():
		return false
	_on_inventory_changed()
	return true


func get_item_count_by_id(item_id: StringName) -> int:
	return InventoryTransaction.new(inventory).get_count(item_id)


func remove_item_by_id(item_id: StringName, count: int) -> bool:
	var result := InventoryTransaction.new(inventory).remove(item_id, count)
	if not result.is_success():
		return false
	_on_inventory_changed()
	return true


func _on_inventory_changed() -> void:
	if is_inside_tree() and AudioManager:
		AudioManager.play_sound("pickup")
	update_hud()
	if base_manager_ref:
		base_manager_ref.check_quest_progress(self)

func update_hud() -> void:
	if not is_inside_tree():
		return
	if not hud_ref:
		var huds = get_tree().get_nodes_in_group("hud")
		if huds.size() > 0:
			hud_ref = huds[0]
	
	if hud_ref:
		var needs_snapshot := needs_state.create_snapshot()
		var buff_text := needs_snapshot.buff_display_name if not needs_snapshot.buff_display_name.is_empty() else "Khỏe mạnh"
		hud_ref.update_player_stats(hp, max_hp, stamina, max_stamina, needs_snapshot.hunger, needs_snapshot.max_hunger, needs_snapshot.thirst, needs_snapshot.max_thirst, needs_snapshot.body_temperature, level, exp_val, max_exp, buff_text)
		hud_ref.update_character_sheet(stat_points, stats, "%s (Sát thương %d)" % [weapon_name, weapon_damage + stats["str"] * 3])
		hud_ref.update_inventory(inventory)

func spawn_floating_text(txt: String, color: Color) -> void:
	var float_node = FLOATING_TEXT_SCENE.instantiate()
	float_node.global_position = global_position + Vector2(randf_range(-12, 12), -32)
	float_node.text = txt
	float_node.color = color
	get_parent().add_child(float_node)
