extends CharacterBody2D
class_name CompanionPet

const PetCommandRequestModel = preload("res://systems/pet/pet_command_request.gd")
const PetCommandResultModel = preload("res://systems/pet/pet_command_result.gd")
const PetCommandPolicyModel = preload("res://systems/pet/pet_command_policy.gd")

var pet_instance_id: StringName = &""
var species_data: Dictionary = {
	"name": "Foxfire",
	"element": "Lửa",
	"color": Color(1.0, 0.42, 0.18),
	"accent": Color(1.0, 0.85, 0.3),
	"max_hp": 100,
	"speed": 145.0,
	"power": 18
}
var level: int = 1
var max_hp: int = 100
var hp: int = 100
var attack_power: int = 18
var move_speed: float = 145.0

var player_target: Node2D = null
var current_enemy: CharacterBody2D = null
var attack_timer: float = 0.0

enum Stance { AUTO_WORK, COMBAT_ASSIST, FOLLOW_PROTECT }
var stance: Stance = Stance.AUTO_WORK

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var name_label: Label = $Overhead/NameLabel
@onready var hp_bar: ProgressBar = $Overhead/HpBar

var anim_timer: float = 0.0
var facing_row: int = 0

var work_target: Node2D = null
var work_timer: float = 0.0
var partner_cooldown: float = 0.0
var co_op_gather_timer: float = 0.0

const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")

func _ready() -> void:
	add_to_group("pets")
	add_to_group("companion_pets")
	setup_pet()

func setup_pet() -> void:
	if species_data.is_empty():
		return
	
	max_hp = species_data.get("max_hp", 100) + (level - 1) * 20
	hp = max_hp
	attack_power = species_data.get("power", 18) + (level - 1) * 3
	move_speed = species_data.get("speed", 135.0) * 1.2
	
	if sprite and species_data.has("texture"):
		sprite.texture = species_data["texture"]
		sprite.frame = 0
	
	update_overhead()

func update_overhead() -> void:
	if name_label:
		name_label.text = "★ Lv.%d %s" % [level, species_data.get("name", "Pet")]
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp

func _physics_process(delta: float) -> void:
	if attack_timer > 0: attack_timer -= delta
	if work_timer > 0: work_timer -= delta
	if partner_cooldown > 0: partner_cooldown -= delta
	if co_op_gather_timer > 0: co_op_gather_timer -= delta
	
	if not is_instance_valid(player_target):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_target = players[0]
	
	if not is_instance_valid(player_target):
		return
	
	# Priority 1: Combat if in COMBAT_ASSIST stance or defending master
	if stance == Stance.COMBAT_ASSIST or stance == Stance.AUTO_WORK:
		update_combat_target()
	
	if is_instance_valid(current_enemy) and stance != Stance.FOLLOW_PROTECT:
		work_target = null
		# Chase enemy and attack
		var dir = (current_enemy.global_position - global_position).normalized()
		velocity = dir * (move_speed * 1.1)
		visual.scale.x = -1.0 if dir.x < 0 else 1.0
		visual.position.y = sin(Time.get_ticks_msec() * 0.015) * 4.0
		
		var dist = global_position.distance_to(current_enemy.global_position)
		if dist <= 45.0 and attack_timer <= 0:
			perform_pet_attack()
	else:
		# Priority 2: Work automation if in AUTO_WORK
		if stance == Stance.AUTO_WORK:
			check_smart_work(delta)
		else:
			work_target = null
		
		if is_instance_valid(work_target):
			process_work_movement(delta)
		else:
			# Priority 3: Smart follow without colliding with master
			process_follow_movement(delta)
	
	# Determine animation frame
	if abs(velocity.x) > abs(velocity.y):
		facing_row = 3 if velocity.x > 0 else 2
	elif velocity.y != 0:
		facing_row = 0 if velocity.y > 0 else 1
	
	if sprite:
		if velocity.length() > 8.0:
			anim_timer += delta * 9.0
			sprite.frame = facing_row * 4 + (int(anim_timer) % 4)
		else:
			anim_timer = 0.0
			sprite.frame = facing_row * 4
	
	move_and_slide()

func process_follow_movement(delta: float) -> void:
	var dist_to_player = global_position.distance_to(player_target.global_position)
	
	# Catch-up dash / teleport if player went too far
	if dist_to_player > 500.0:
		global_position = player_target.global_position + Vector2(-30, 20)
		spawn_floating_text("✨ Lướt tới cạnh chủ nhân!", Color(0.4, 1.0, 0.8))
		return
	
	# Dynamic follow offset behind player's movement direction
	var p_vel = player_target.velocity
	var follow_offset = Vector2(-38, 14)
	if p_vel.length() > 25.0:
		follow_offset = -p_vel.normalized() * 52.0
	
	var follow_pos = player_target.global_position + follow_offset
	var dist_to_follow = global_position.distance_to(follow_pos)
	
	# Anti-stuck avoidance force if player is bumping directly into pet
	var avoid_force = Vector2.ZERO
	if dist_to_player < 36.0:
		var away = (global_position - player_target.global_position).normalized()
		if away == Vector2.ZERO: away = Vector2.RIGHT
		avoid_force = Vector2(-away.y, away.x) * 160.0
	
	if dist_to_follow > 42.0:
		var dir = (follow_pos - global_position).normalized()
		var speed_scale = clamp(dist_to_follow / 75.0, 0.95, 2.2)
		velocity = dir * (move_speed * speed_scale) + avoid_force
		visual.scale.x = -1.0 if dir.x < 0 else 1.0
		visual.position.y = sin(Time.get_ticks_msec() * 0.012) * 3.0
	else:
		velocity = velocity.move_toward(avoid_force, 450 * delta)
		visual.position.y = sin(Time.get_ticks_msec() * 0.005) * 2.0

func check_smart_work(delta: float) -> void:
	# Check 1: Co-op gathering if player is chopping tree or mining stone
	if co_op_gather_timer <= 0 and player_target.get("is_attacking") == true:
		var nodes = get_tree().get_nodes_in_group("resource_nodes")
		for r in nodes:
			if is_instance_valid(r) and player_target.global_position.distance_to(r.global_position) < 65.0:
				if r.get("node_type") != 2: # Not farm plot
					work_target = r
					return
	
	# Check 2: Auto-Loot dropped items in radius 280px
	var items = get_tree().get_nodes_in_group("dropped_items")
	for item in items:
		if is_instance_valid(item) and global_position.distance_to(item.global_position) < 280.0:
			work_target = item
			return
	
	# Check 3: Base farm plots & furnace automation
	var elem = species_data.get("element", "")
	if elem == "Lửa" and is_instance_valid(player_target):
		# Warm aura around player
		if global_position.distance_to(player_target.global_position) < 95.0 and work_timer <= 0:
			work_timer = 3.5
			if player_target.hp < player_target.max_hp:
				player_target.hp = min(player_target.max_hp, player_target.hp + 8)
				player_target.update_hud()
				spawn_floating_text("🔥 Hơi Ấm Hồi Máu +8", Color(1.0, 0.65, 0.2))
		return
	
	if is_instance_valid(work_target):
		if work_target.get("crop_stage") == 0:
			work_target = null
		return
	
	var farm_plots = get_tree().get_nodes_in_group("resource_nodes")
	for plot in farm_plots:
		if is_instance_valid(plot) and plot.get("node_type") == 2:
			var stage = plot.get("crop_stage")
			if elem == "Nước" and (stage == 1 or stage == 2) and not plot.get("is_watered"):
				work_target = plot
				return
			elif elem == "Cỏ" and stage == 3:
				work_target = plot
				return

func process_work_movement(delta: float) -> void:
	if not is_instance_valid(work_target):
		work_target = null
		return
	
	var dir = (work_target.global_position - global_position).normalized()
	velocity = dir * (move_speed * 1.1)
	visual.scale.x = -1.0 if dir.x < 0 else 1.0
	visual.position.y = sin(Time.get_ticks_msec() * 0.015) * 3.5
	
	var dist = global_position.distance_to(work_target.global_position)
	
	# Handling Dropped Item Auto-Loot
	if work_target.is_in_group("dropped_items"):
		if dist <= 28.0:
			var item_name = work_target.get("item_name")
			var count = work_target.get("count")
			if player_target.has_method("add_item"):
				player_target.add_item(item_name, count)
			spawn_floating_text("📦 Pet nhặt: +%d %s" % [count, item_name], Color(0.4, 1.0, 0.6))
			if AudioManager:
				AudioManager.play_sound("pickup")
			work_target.queue_free()
			work_target = null
		return
	
	# Handling Co-op Gathering (Tree/Rock)
	if work_target.is_in_group("resource_nodes") and work_target.get("node_type") != 2:
		if dist <= 42.0 and co_op_gather_timer <= 0:
			co_op_gather_timer = 0.8
			if work_target.has_method("hit_by_tool"):
				work_target.hit_by_tool(attack_power, player_target)
			spawn_floating_text("⛏️ Khai thác giúp!", Color(1.0, 0.85, 0.3))
			work_target = null
		return
	
	# Handling Farm Plot
	if dist <= 34.0:
		do_farm_work(delta)

func do_farm_work(delta: float) -> void:
	if not is_instance_valid(work_target): return
	var elem = species_data.get("element", "")
	
	if elem == "Nước":
		work_target.grow_timer += delta * 2.0
		if work_target.has_method("water_crop") and not work_target.is_watered:
			work_target.water_crop()
		if work_timer <= 0:
			work_timer = 2.5
			spawn_floating_text("💧 Pet Slime tưới đẫm đất!", Color(0.3, 0.8, 1.0))
			if AudioManager: AudioManager.play_sound("pickup")
		if work_target.crop_stage == 3:
			work_target = null
	
	elif elem == "Cỏ":
		if work_target.crop_stage == 3 and work_timer <= 0:
			work_timer = 1.0
			work_target.interact(player_target)
			spawn_floating_text("🌿 Pet Thu Hoạch Giúp!", Color(0.4, 1.0, 0.4))
			work_target = null

func update_combat_target() -> void:
	if is_instance_valid(current_enemy):
		var enemy_capturing = current_enemy.has_method("is_capturing") and current_enemy.is_capturing()
		if current_enemy.hp <= 0 or enemy_capturing:
			current_enemy = null
		elif global_position.distance_to(player_target.global_position) > 420.0:
			current_enemy = null
		return
	
	# Scan for wild creatures targeting master or near master
	var creatures = get_tree().get_nodes_in_group("wild_creatures")
	var nearest: CharacterBody2D = null
	var min_dist: float = 260.0
	
	for c in creatures:
		var c_capturing = c.has_method("is_capturing") and c.is_capturing()
		if is_instance_valid(c) and c.hp > 0 and not c_capturing:
			# High priority: creature attacking player
			if c.get("target") == player_target:
				current_enemy = c
				return
			
			var dist = player_target.global_position.distance_to(c.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = c
	
	current_enemy = nearest

func perform_pet_attack() -> void:
	if not is_instance_valid(current_enemy): return
	attack_timer = 0.90
	
	var dir = (current_enemy.global_position - global_position).normalized()
	velocity = dir * 210.0
	
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(1.35, 0.7), 0.1)
	tween.tween_property(visual, "scale", Vector2.ONE, 0.12)
	
	await get_tree().create_timer(0.18).timeout
	if is_instance_valid(current_enemy):
		var dist = global_position.distance_to(current_enemy.global_position)
		if dist <= 55.0 and current_enemy.has_method("take_damage"):
			current_enemy.take_damage(attack_power, global_position, player_target)
			spawn_floating_text("Pet Tấn Công!", Color(0.3, 0.9, 1.0))

func take_damage(amount: int, hit_origin: Vector2) -> void:
	hp -= amount
	hp = max(0, hp)
	update_overhead()
	
	spawn_floating_text(str(amount), Color(1.0, 0.4, 0.4))
	var kb = (global_position - hit_origin).normalized()
	velocity = kb * 120.0
	
	var tween = create_tween()
	visual.modulate = Color(2.5, 0.5, 0.5)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.2)
	
	if hp <= 0:
		spawn_floating_text("Pet Choáng Váng!", Color(1.0, 0.8, 0.2))
		hp = max_hp / 2
		update_overhead()
		global_position = player_target.global_position + Vector2(25, 25)

func gain_exp(amount: int) -> void:
	level += 1
	setup_pet()
	spawn_floating_text("PET LÊN CẤP! Lv.%d" % level, Color(1.0, 0.9, 0.1))

func get_stance_id() -> StringName:
	match stance:
		Stance.AUTO_WORK: return PetCommandPolicyModel.STANCE_AUTO_WORK
		Stance.COMBAT_ASSIST: return PetCommandPolicyModel.STANCE_COMBAT_ASSIST
		Stance.FOLLOW_PROTECT: return PetCommandPolicyModel.STANCE_FOLLOW_PROTECT
	return &""


func apply_pet_command(command_id: StringName) -> RefCounted:
	var result := PetCommandPolicyModel.resolve(PetCommandRequestModel.new(command_id, pet_instance_id, get_stance_id()))
	if result.status == PetCommandResultModel.Status.NO_CHANGE:
		return result
	if not result.is_applied():
		return result
	match result.next_stance_id:
		PetCommandPolicyModel.STANCE_AUTO_WORK:
			stance = Stance.AUTO_WORK
			spawn_floating_text("Pet: Tự Do Lao Động (Nhặt đồ, tưới cây)!", Color(0.4, 1.0, 0.5))
		PetCommandPolicyModel.STANCE_COMBAT_ASSIST:
			stance = Stance.COMBAT_ASSIST
			current_enemy = null
			spawn_floating_text("Pet: Ưu Tiên Chiến Đấu!", Color(1.0, 0.4, 0.2))
		PetCommandPolicyModel.STANCE_FOLLOW_PROTECT:
			stance = Stance.FOLLOW_PROTECT
			current_enemy = null
			spawn_floating_text("Pet: Bảo Vệ Sát Cánh!", Color(0.4, 0.85, 1.0))
		_:
			return PetCommandResultModel.new(PetCommandResultModel.Status.INVALID_REQUEST)
	return result


func toggle_stance() -> RefCounted:
	return apply_pet_command(PetCommandPolicyModel.COMMAND_CYCLE_STANCE)

func activate_partner_skill(player_ref: CharacterBody2D) -> void:
	if partner_cooldown > 0:
		spawn_floating_text("Kỹ năng hồi: %.1fs" % partner_cooldown, Color(1.0, 0.5, 0.5))
		return
	
	partner_cooldown = 14.0
	var elem = species_data.get("element", "Thường")
	
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(1.6, 1.6), 0.15).set_trans(Tween.TRANS_BACK)
	tween.tween_property(visual, "scale", Vector2.ONE, 0.2)
	
	if AudioManager:
		AudioManager.play_sound("powerup")
	
	match elem:
		"Lửa":
			spawn_floating_text("🔥 PARTNER SKILL: BÃO LỬA DIỆT ĐỊCH!", Color(1.0, 0.45, 0.1))
			var enemies = get_tree().get_nodes_in_group("wild_creatures")
			for e in enemies:
				if is_instance_valid(e) and global_position.distance_to(e.global_position) < 180.0:
					if e.has_method("take_damage"):
						e.take_damage(attack_power * 2 + 25, global_position, player_ref)
						if e.has_method("apply_burn"):
							e.apply_burn(4.0)
		"Nước":
			spawn_floating_text("💧 PARTNER SKILL: KHIÊN THỦY TINH & HỒI MÁU!", Color(0.3, 0.85, 1.0))
			if player_ref:
				player_ref.hp = min(player_ref.max_hp, player_ref.hp + 50)
				player_ref.stamina = player_ref.max_stamina
				player_ref.update_hud()
			var enemies = get_tree().get_nodes_in_group("wild_creatures")
			for e in enemies:
				if is_instance_valid(e) and global_position.distance_to(e.global_position) < 150.0:
					if e.has_method("apply_slow"):
						e.apply_slow(3.5)
		"Cỏ":
			spawn_floating_text("🌿 PARTNER SKILL: BÀO TỬ TRẺ HÓA & TRỊ LIỆU!", Color(0.35, 1.0, 0.45))
			if player_ref:
				player_ref.hp = player_ref.max_hp
				player_ref.stamina = player_ref.max_stamina
				player_ref.update_hud()
		_:
			spawn_floating_text("⚡ PARTNER SKILL: TIẾNG GẦM CUỒNG CHIẾN!", Color(1.0, 0.9, 0.2))
			var enemies = get_tree().get_nodes_in_group("wild_creatures")
			for e in enemies:
				if is_instance_valid(e) and global_position.distance_to(e.global_position) < 160.0:
					if e.has_method("take_damage"):
						e.take_damage(attack_power + 30, global_position, player_ref)
					if e.has_method("apply_stun"):
						e.apply_stun(2.0)

func spawn_floating_text(txt: String, color: Color) -> void:
	var float_node = FLOATING_TEXT_SCENE.instantiate()
	float_node.global_position = global_position + Vector2(randf_range(-10, 10), -24)
	float_node.text = txt
	float_node.color = color
	get_parent().add_child(float_node)
