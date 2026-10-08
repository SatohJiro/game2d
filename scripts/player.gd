extends CharacterBody2D
class_name Player

const PetSummonRequestModel = preload("res://systems/pet/pet_summon_request.gd")
const PetSummonResultModel = preload("res://systems/pet/pet_summon_result.gd")
const PetSummonPolicyModel = preload("res://systems/pet/pet_summon_policy.gd")
const PetCommandPolicyModel = preload("res://systems/pet/pet_command_policy.gd")

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
var committed_capture_tokens: Dictionary = {}
var active_pet_node: Node2D = null
var active_pet_instance_id: StringName = &""

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
## Art-bible attack phases: windup (telegraph) -> strike (contact).
const ATTACK_WINDUP := 0.15
const ATTACK_STRIKE := 0.13
var _slash_armed: bool = false
var _pending_slash_dir: Vector2 = Vector2.ZERO

# Build Mode
var is_building: bool = false
var pending_build_id: String = ""
var placed_buildings: Array[Dictionary] = []
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
var recipes: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("player")
	recipes = PlayerCraftCatalog.presentation_recipes()
	
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
	var intent := PlayerActionInputMapper.map_event(event, is_building)
	if intent.is_valid():
		dispatch_action_intent(intent)


func dispatch_action_intent(intent: PlayerActionIntent) -> bool:
	var modal_open: bool = (hud_ref != null) and (hud_ref.is_crafting_visible() or hud_ref.is_stat_modal_visible())
	if not PlayerActionPolicy.is_allowed(intent, is_building, modal_open, is_rolling):
		return false
	match intent.action_id:
		PlayerActionIntent.ACTION_ATTACK:
			perform_attack(intent.aim_direction)
		PlayerActionIntent.ACTION_ROLL:
			try_combat_roll()
		PlayerActionIntent.ACTION_INTERACT:
			try_interact()
		PlayerActionIntent.ACTION_CAPTURE_THROW:
			throw_pal_sphere()
		PlayerActionIntent.ACTION_TOGGLE_CRAFTING:
			if hud_ref: hud_ref.toggle_crafting(not hud_ref.is_crafting_visible())
		PlayerActionIntent.ACTION_TOGGLE_CHARACTER:
			if hud_ref: hud_ref.toggle_stat_modal(not hud_ref.is_stat_modal_visible())
		PlayerActionIntent.ACTION_BUILD_START:
			start_build_mode(String(intent.target_id))
		PlayerActionIntent.ACTION_BUILD_PLACE:
			place_current_building()
		PlayerActionIntent.ACTION_BUILD_CANCEL:
			cancel_build_mode()
		PlayerActionIntent.ACTION_PET_SELECT:
			swap_active_pet(intent.slot_index)
		PlayerActionIntent.ACTION_PET_COMMAND:
			command_pets()
		PlayerActionIntent.ACTION_PET_SKILL:
			activate_partner_skill()
		PlayerActionIntent.ACTION_USE_FOOD:
			eat_berry()
		PlayerActionIntent.ACTION_USE_ELIXIR:
			use_pal_elixir()
		_:
			return false
	return true

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
		# Windup ends -> contact: spawn the slash exactly at strike start.
		if _slash_armed and attack_anim_timer <= ATTACK_STRIKE:
			_slash_armed = false
			_spawn_slash(_pending_slash_dir)
	
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
		var atk_row = 4 if attack_anim_timer > ATTACK_STRIKE else 5
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
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and attack_cooldown <= 0:
		dispatch_action_intent(PlayerActionIntent.new(PlayerActionIntent.ACTION_ATTACK, -1, &"", aim_dir))
	
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
	attack_cooldown = ATTACK_WINDUP + ATTACK_STRIKE
	is_attacking = true
	attack_anim_timer = ATTACK_WINDUP + ATTACK_STRIKE
	# Arm the slash: it spawns exactly when the windup ends (contact).
	_slash_armed = true
	_pending_slash_dir = aim_dir

	# Dynamic sword thrust animation (windup telegraph)
	var weapon_spr = weapon_pivot.get_node_or_null("SwordSprite")
	if weapon_spr:
		weapon_spr.visible = true
		weapon_spr.position.x = 14.0
		var stween = create_tween()
		stween.tween_property(weapon_spr, "position:x", 28.0, ATTACK_WINDUP)
		stween.tween_property(weapon_spr, "position:x", 14.0, ATTACK_STRIKE)
		stween.tween_callback(func(): weapon_spr.visible = false)

	velocity += aim_dir * 70.0


## Contact marker: slash VFX + SFX + damage area spawn at strike start.
func _spawn_slash(aim_dir: Vector2) -> void:
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

func shake_camera(amount: float) -> void:
	if GameSettings.reduce_motion:
		amount = 0.0
	shake_amount = max(shake_amount, amount)

func throw_pal_sphere() -> bool:
	if sphere_cooldown > 0 or is_building:
		return false

	var selection := select_capture_sphere()
	if not selection.is_selected():
		spawn_floating_text("Hết Cầu Thu Phục! (Bấm [C] chế tạo)", Color(1.0, 0.4, 0.4))
		return false
	if not is_inside_tree() or get_parent() == null:
		return false
	var sphere = SPHERE_SCENE.instantiate()
	if sphere == null or not sphere.has_method("configure_capture_sphere"):
		if sphere != null:
			sphere.free()
		return false
	if not bool(sphere.call("configure_capture_sphere", selection.item_id, selection.catch_multiplier)):
		sphere.free()
		return false
	if not spend_capture_sphere(selection):
		sphere.free()
		return false

	var mouse_pos := get_global_mouse_position()
	sphere.player_ref = self
	get_parent().add_child(sphere)
	sphere.launch(global_position + Vector2(0, -6), mouse_pos)
	sphere_cooldown = 0.50

	# Throw recoil animation
	var throw_dir := (mouse_pos - global_position).normalized()
	velocity -= throw_dir * 45.0
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(0.85, 1.2), 0.08)
	tween.tween_property(visual, "scale", Vector2.ONE, 0.12)

	var sphere_name := LegacyItemAdapter.to_legacy_key(selection.item_id)
	spawn_floating_text("Ném %s (x%.1f tỉ lệ)!" % [sphere_name, selection.catch_multiplier], Color(0.3, 0.9, 1.0))
	if AudioManager:
		AudioManager.play_sound("sphere_throw")
	return true


func select_capture_sphere() -> CaptureSphereSelectionResult:
	var transaction := InventoryTransaction.new(inventory)
	var available_counts := {}
	for item_id in CaptureSphereSelector.PRIORITY:
		available_counts[item_id] = transaction.get_count(item_id)
	return CaptureSphereSelector.select(available_counts)


func spend_capture_sphere(selection: CaptureSphereSelectionResult) -> bool:
	if selection == null or not selection.is_selected() or not CaptureSphereSelector.is_supported(selection.item_id):
		return false
	var result := InventoryTransaction.new(inventory).remove(selection.item_id, 1)
	if not result.is_success():
		return false
	update_hud()
	return true

func craft_recipe(recipe_id: String) -> void:
	var result := PlayerCraftResolver.resolve(StringName(recipe_id), level, PlayerCraftResolver.snapshot_inventory(inventory))
	if result.status == PlayerCraftResult.Status.INSUFFICIENT_ITEMS:
		spawn_floating_text("Không đủ nguyên liệu: %s!" % LegacyItemAdapter.to_legacy_key(result.missing_item_id), Color(1.0, 0.4, 0.4))
		return
	if not result.is_accepted() or not PlayerCraftTransaction.commit(inventory, result): return
	var definition := result.definition
	if definition.result_kind == PlayerCraftDefinition.RESULT_ITEM:
		spawn_floating_text("Chế tạo thành công: %s!" % definition.display_name, Color(0.2, 1.0, 0.5))
		if AudioManager:
			AudioManager.play_sound("pickup")
	elif definition.result_kind == PlayerCraftDefinition.RESULT_EQUIPMENT:
		var equipment_color := Color(0.4, 1.0, 0.5)
		if PlayerEquipmentCatalog.is_valid_weapon(definition.result_id):
			weapon_name = PlayerEquipmentCatalog.weapon_display_name(definition.result_id)
			weapon_damage = PlayerEquipmentCatalog.weapon_damage(definition.result_id)
			equipment_color = Color(1.0, 0.85, 0.2) if definition.result_id == PlayerEquipmentCatalog.IRON_SWORD else Color(0.3, 0.9, 1.0)
		elif definition.result_id == PlayerEquipmentCatalog.PAL_WARRIOR_ARMOR:
			has_armor = true
			recalculate_stats()
			hp = max_hp
		spawn_floating_text(definition.success_text, equipment_color)
		if AudioManager:
			AudioManager.play_sound("powerup")
	elif definition.result_kind == PlayerCraftDefinition.RESULT_BUILDING:
		if hud_ref:
			hud_ref.toggle_crafting(false)
		start_build_mode(String(definition.result_id))
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
	var building_id := BuildingPlacementCatalog.from_legacy(pending_build_id)
	var b_node := BuildingPlacementCatalog.instantiate(building_id)
	
	if b_node:
		b_node.global_position = place_pos
		var instance_id := StringName("building.instance_%d" % ResourceUID.create_id())
		b_node.set_meta("building_instance_id", instance_id)
		b_node.set_meta("building_id", building_id)
		b_node.add_to_group("persistent_player_buildings")
		get_parent().add_child(b_node)
		var state: Dictionary = {}
		if (building_id == &"building.chest" or building_id == &"building.furnace" or building_id == &"building.cooking_pot" or building_id == &"building.compost_bin" or building_id == &"building.ranch" or building_id == &"building.farm_plot" or building_id == &"building.altar" or building_id == &"building.turret" or building_id == &"building.workbench") and b_node.has_method("create_persistence_state"):
			state = b_node.call("create_persistence_state").to_dto()
		placed_buildings.append(BuildingPlacementRecord.new(instance_id, building_id, b_node.transform, state).to_dto())
		spawn_floating_text("Đã xây dựng thành công!", Color(0.4, 1.0, 0.5))
		if AudioManager:
			AudioManager.play_sound("pickup")
	
	cancel_build_mode()
	if base_manager_ref:
		base_manager_ref.check_quest_progress(self)

func replace_persistent_buildings(records: Array[BuildingPlacementRecord]) -> bool:
	var staged: Array[Node2D] = []
	for record in records:
		if record == null or not record.is_valid():
			for node in staged: node.free()
			return false
		var node := BuildingPlacementCatalog.instantiate(record.building_id)
		if node == null:
			for staged_node in staged: staged_node.free()
			return false
		if record.building_id == &"building.chest" and (not node.has_method("apply_persistence_state") or not bool(node.call("apply_persistence_state", ChestPlacementState.from_dto(record.state)))):
			for staged_node in staged: staged_node.free()
			node.free()
			return false
		if record.building_id == &"building.furnace" and (not node.has_method("apply_persistence_state") or not bool(node.call("apply_persistence_state", FurnacePlacementState.from_dto(record.state)))):
			for staged_node in staged: staged_node.free()
			node.free()
			return false
		if record.building_id == &"building.cooking_pot" and (not node.has_method("apply_persistence_state") or not bool(node.call("apply_persistence_state", CookingPotPlacementState.from_dto(record.state)))):
			for staged_node in staged: staged_node.free()
			node.free()
			return false
		if record.building_id == &"building.compost_bin" and (not node.has_method("apply_persistence_state") or not bool(node.call("apply_persistence_state", CompostBinPlacementState.from_dto(record.state)))):
			for staged_node in staged: staged_node.free()
			node.free()
			return false
		if record.building_id == &"building.ranch" and (not node.has_method("apply_persistence_state") or not bool(node.call("apply_persistence_state", RanchPlacementState.from_dto(record.state)))):
			for staged_node in staged: staged_node.free()
			node.free()
			return false
		if record.building_id == &"building.farm_plot" and (not node.has_method("apply_persistence_state") or not bool(node.call("apply_persistence_state", FarmPlotPlacementState.from_dto(record.state)))):
			for staged_node in staged: staged_node.free()
			node.free()
			return false
		if record.building_id == &"building.altar" and (not node.has_method("apply_persistence_state") or not bool(node.call("apply_persistence_state", AltarPlacementState.from_dto(record.state)))):
			for staged_node in staged: staged_node.free()
			node.free()
			return false
		if record.building_id == &"building.turret" and (not node.has_method("apply_persistence_state") or not bool(node.call("apply_persistence_state", TurretPlacementState.from_dto(record.state)))):
			for staged_node in staged: staged_node.free()
			node.free()
			return false
		if record.building_id == &"building.workbench" and (not node.has_method("apply_persistence_state") or not bool(node.call("apply_persistence_state", WorkbenchPlacementState.from_dto(record.state)))):
			for staged_node in staged: staged_node.free()
			node.free()
			return false
		node.transform = record.transform; node.set_meta("building_instance_id", record.instance_id); node.set_meta("building_id", record.building_id); node.add_to_group("persistent_player_buildings")
		staged.append(node)
	for boss in get_tree().get_nodes_in_group("persistent_altar_bosses"):
		boss.set_meta("suppress_altar_lifecycle", true)
		if boss.get_parent() != null: boss.get_parent().remove_child(boss)
		boss.queue_free()
	for existing in get_tree().get_nodes_in_group("persistent_player_buildings"):
		if existing.get_parent() != null: existing.get_parent().remove_child(existing)
		existing.queue_free()
	placed_buildings.clear()
	for index in staged.size():
		get_parent().add_child(staged[index]); placed_buildings.append(records[index].to_dto())
	return true

func create_building_placement_snapshot() -> Array[Dictionary]:
	var live_by_id: Dictionary = {}
	for node in get_tree().get_nodes_in_group("persistent_player_buildings"):
		if is_instance_valid(node): live_by_id[node.get_meta("building_instance_id", &"")] = node
	var snapshot: Array[Dictionary] = []
	for value: Variant in placed_buildings:
		var record := BuildingPlacementRecord.from_dto(value)
		if record == null: return []
		var node: Variant = live_by_id.get(record.instance_id)
		if is_instance_valid(node):
			record.transform = node.transform
			if record.building_id == &"building.chest" and node.has_method("create_persistence_state"):
				record.state = node.call("create_persistence_state").to_dto()
			elif record.building_id == &"building.furnace" and node.has_method("create_persistence_state"):
				record.state = node.call("create_persistence_state").to_dto()
			elif record.building_id == &"building.cooking_pot" and node.has_method("create_persistence_state"):
				record.state = node.call("create_persistence_state").to_dto()
			elif record.building_id == &"building.compost_bin" and node.has_method("create_persistence_state"):
				record.state = node.call("create_persistence_state").to_dto()
			elif record.building_id == &"building.ranch" and node.has_method("create_persistence_state"):
				record.state = node.call("create_persistence_state").to_dto()
			elif record.building_id == &"building.farm_plot" and node.has_method("create_persistence_state"):
				record.state = node.call("create_persistence_state").to_dto()
			elif record.building_id == &"building.altar" and node.has_method("create_persistence_state"):
				record.state = node.call("create_persistence_state").to_dto()
			elif record.building_id == &"building.turret" and node.has_method("create_persistence_state"):
				record.state = node.call("create_persistence_state").to_dto()
			elif record.building_id == &"building.workbench" and node.has_method("create_persistence_state"):
				record.state = node.call("create_persistence_state").to_dto()
		snapshot.append(record.to_dto())
	return snapshot

func create_resource_depletion_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	var seen := {}
	for node in get_tree().get_nodes_in_group("resource_nodes"):
		if not is_instance_valid(node) or not node.has_method("create_resource_depletion_record"): continue
		var record: Variant = node.call("create_resource_depletion_record")
		if record == null: continue
		if not record.is_valid() or seen.has(record.instance_id): return []
		seen[record.instance_id] = true
		snapshot.append(record.to_dto())
	snapshot.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["instance_id"]) < String(b["instance_id"]))
	return snapshot

func create_chunk_resource_projection() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("resource_nodes"):
		if not is_instance_valid(node) or not node.has_method("create_resource_depletion_record"): continue
		var record: Variant = node.call("create_resource_depletion_record")
		if record != null and record.is_valid():
			output.append({"position": {"x": node.global_position.x, "y": node.global_position.y}, "payload": record.to_dto()})
	return output

func apply_resource_depletion_snapshot(records: Array[ResourceDepletionRecord]) -> bool:
	if not can_apply_resource_depletion_snapshot(records): return false
	var nodes_by_id := {}
	for node in get_tree().get_nodes_in_group("resource_nodes"):
		if is_instance_valid(node):
			var instance_id := StringName(node.get("resource_instance_id"))
			if not instance_id.is_empty(): nodes_by_id[instance_id] = node
	for record in records:
		nodes_by_id[record.instance_id].call("apply_resource_depletion_state", record.state)
	return true

func can_apply_resource_depletion_snapshot(records: Array[ResourceDepletionRecord]) -> bool:
	var available := {}
	for node in get_tree().get_nodes_in_group("resource_nodes"):
		if is_instance_valid(node):
			var instance_id := StringName(node.get("resource_instance_id"))
			if not instance_id.is_empty() and node.has_method("apply_resource_depletion_state"):
				available[instance_id] = true
	for record in records:
		if record == null or not record.is_valid() or not available.has(record.instance_id): return false
	return true

func cancel_build_mode() -> void:
	is_building = false
	pending_build_id = ""
	if ghost_preview:
		ghost_preview.visible = false

func swap_active_pet(idx: int) -> RefCounted:
	if idx < 0 or idx >= pet_party.size():
		spawn_floating_text("Ô Pet số %d đang trống!" % (idx + 1), Color(0.8, 0.8, 0.8))
		return PetSummonResultModel.new(PetSummonResultModel.Status.INVALID_REQUEST)
	
	var data: Dictionary = pet_party[idx]
	var selected_instance_id := StringName(data.get("instance_id", &""))
	var summon_result := PetSummonPolicyModel.resolve(PetSummonRequestModel.new(
		selected_instance_id,
		active_pet_instance_id,
		true,
		is_instance_valid(active_pet_node) and active_pet_node.is_inside_tree()
	))
	if not summon_result.should_spawn():
		return summon_result

	_persist_active_pet_stance()
	var pets = get_tree().get_nodes_in_group("companion_pets")
	for p in pets:
		if p.is_inside_tree() and p.get_parent() != null:
			p.get_parent().remove_child(p)
		p.queue_free()
	active_pet_node = null
	
	var pet_inst = PET_SCENE.instantiate()
	pet_inst.pet_instance_id = summon_result.instance_id
	pet_inst.species_data = data["species_data"]
	pet_inst.level = data["level"]
	pet_inst.player_target = self
	pet_inst.global_position = global_position + Vector2(25, 25)
	get_parent().add_child(pet_inst)
	var saved_stance_id := StringName(data.get("stance_id", PetCommandPolicyModel.STANCE_AUTO_WORK))
	var saved_stance_command := _command_for_pet_stance(saved_stance_id)
	if not saved_stance_command.is_empty():
		pet_inst.apply_pet_command(saved_stance_command)
	active_pet_node = pet_inst
	active_pet_instance_id = summon_result.instance_id
	
	var badge = data.get("rarity_badge", "★")
	var trait_str = data.get("trait", "")
	spawn_floating_text("[%s] Triệu hồi %s (Lv.%d)!" % [badge, data["species_data"]["name"], data["level"]], Color(0.4, 0.9, 1.0))
	if AudioManager:
		AudioManager.play_sound("powerup")
	if hud_ref:
		var display_name = "[%s] %s (%s)" % [badge, data["species_data"]["name"], trait_str]
		hud_ref.update_pet_stats(display_name, data["level"], pet_inst.hp, pet_inst.max_hp, "Tự do Tấn công")
	return summon_result


func _persist_active_pet_stance() -> void:
	if not is_instance_valid(active_pet_node) or not active_pet_node.has_method("get_stance_id"):
		return
	var stance_id: StringName = active_pet_node.get_stance_id()
	for entry: Dictionary in pet_party:
		if StringName(entry.get("instance_id", &"")) == active_pet_instance_id:
			entry["stance_id"] = stance_id
			return


func _command_for_pet_stance(stance_id: StringName) -> StringName:
	match stance_id:
		PetCommandPolicyModel.STANCE_AUTO_WORK: return PetCommandPolicyModel.COMMAND_AUTO_WORK
		PetCommandPolicyModel.STANCE_COMBAT_ASSIST: return PetCommandPolicyModel.COMMAND_COMBAT_ASSIST
		PetCommandPolicyModel.STANCE_FOLLOW_PROTECT: return PetCommandPolicyModel.COMMAND_FOLLOW_PROTECT
	return &""

func on_pet_captured(
	pet_data: Dictionary,
	pet_level: int,
	capture_token: StringName = &"",
	rarity_roll: float = -1.0,
	trait_roll: float = -1.0
) -> CaptureOwnershipResult:
	var request := CaptureOwnershipRequest.new(
		capture_token,
		create_pet_instance_id(),
		StringName(pet_data.get("id", "")),
		pet_data,
		pet_level,
		rarity_roll,
		trait_roll
	)
	return commit_capture_ownership(request)


func create_pet_instance_id() -> StringName:
	var candidate := StringName("pet.instance_%d" % ResourceUID.create_id())
	while pet_party.any(func(entry: Dictionary) -> bool: return StringName(entry.get("instance_id", &"")) == candidate):
		candidate = StringName("pet.instance_%d" % ResourceUID.create_id())
	return candidate


func commit_capture_ownership(request: CaptureOwnershipRequest) -> CaptureOwnershipResult:
	if request != null:
		request.already_committed = committed_capture_tokens.has(request.capture_token)
	var result := CaptureOwnershipResolver.resolve(request)
	if not result.is_accepted():
		return result

	var party_entry := result.party_entry.duplicate(true)
	pet_party.append(party_entry)
	committed_capture_tokens[result.capture_token] = true
	gain_exp(result.reward_exp)
	shake_camera(4.5)

	var pet_data: Dictionary = party_entry["species_data"]
	var pet_level := int(party_entry["level"])
	if hud_ref:
		hud_ref.show_banner(
			"THU PHỤC THÀNH CÔNG!\n[%s] %s (Nội Tại: %s)!" % [
				result.rarity_badge,
				pet_data["name"],
				result.trait_name,
			],
			4.5
		)
		hud_ref.update_pet_stats(
			"[%s] %s" % [result.rarity_badge, pet_data["name"]],
			pet_level,
			int(pet_data["max_hp"]),
			int(pet_data["max_hp"]),
			"Tự do Tấn công"
		)

	if base_manager_ref:
		base_manager_ref.check_quest_progress(self)
	return result


## Nearest interactable in range, for the context prompt (U3.4). Mirrors the
## target priority of try_interact without triggering any effect.
func get_interaction_target() -> Node:
	var best: Node = null
	var best_distance := INF
	var overlapping = interact_detector.get_overlapping_bodies()
	for body in overlapping:
		if body.has_method("interact") or body.has_method("hit_by_tool"):
			var distance := global_position.distance_to((body as Node2D).global_position)
			if distance < best_distance:
				best_distance = distance
				best = body
	var overlapping_areas = interact_detector.get_overlapping_areas()
	for area in overlapping_areas:
		var parent_node = area.get_parent()
		if parent_node and parent_node.has_method("interact"):
			var distance := global_position.distance_to((parent_node as Node2D).global_position)
			if distance < best_distance:
				best_distance = distance
				best = parent_node
	return best

func try_interact() -> void:
	var target := get_interaction_target()
	if target != null:
		if target.has_method("interact"):
			target.interact(self)
			return
		elif target.has_method("hit_by_tool"):
			target.hit_by_tool(35, self)
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
		if pet.has_method("apply_pet_command"):
			var command_result: RefCounted = pet.apply_pet_command(PetCommandPolicyModel.COMMAND_CYCLE_STANCE)
			if not command_result.is_applied():
				continue
			_persist_active_pet_stance()
			var stance_str = "Tự do Tấn công" if command_result.next_stance_id == PetCommandPolicyModel.STANCE_COMBAT_ASSIST else "Theo sát & Phòng thủ"
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
		hud_ref.render_view_model(HUDViewModel.from_player(self))

func spawn_floating_text(txt: String, color: Color) -> void:
	var float_node = FLOATING_TEXT_SCENE.instantiate()
	float_node.global_position = global_position + Vector2(randf_range(-12, 12), -32)
	float_node.text = txt
	float_node.color = color
	get_parent().add_child(float_node)
