extends CharacterBody2D
class_name WildCreature

@export var species_index: int = 0
@export var level: int = 1

var species_data: Array[Dictionary] = [
	{
		"name": "Flam",
		"element": "Lửa",
		"texture": preload("res://assets/monsters/flam_sheet.png")
	},
	{
		"name": "Slime",
		"element": "Nước",
		"texture": preload("res://assets/monsters/slime_sheet.png")
	},
	{
		"name": "Mushroom",
		"element": "Thảo Mộc",
		"texture": preload("res://assets/monsters/mushroom_sheet.png")
	},
	{
		"name": "Beast",
		"element": "Đất",
		"texture": preload("res://assets/monsters/beast_sheet.png")
	},
	{
		"name": "Dragon",
		"element": "Hỏa Long",
		"texture": preload("res://assets/monsters/dragon_sheet.png")
	}
]

var cur_data: Dictionary
var max_hp: int = 80
var hp: int = 80
var defeat_committed: bool = false
var defeat_drops_committed: bool = false
var capture_attempt_active: bool = false
var capture_ownership_committed: bool = false
var capture_ownership_token: StringName = &""
var move_speed: float = 90.0
var attack_power: int = 12
var anim_timer: float = 0.0
var facing_row: int = 0

enum State { 
	IDLE, 
	WANDER, 
	CHASE, 
	ATTACK, 
	TELEGRAPH_CHARGE, 
	CHARGING, 
	STUNNED, 
	CAPTURING, 
	SLEEP, 
	ALERT,
	SUSPICIOUS,
	FLEE,
	DRINKING,
	GRAZING,
	HUNTING_PREY
}

var state: State = State.IDLE
var state_timer: float = 2.0
var wander_dir: Vector2 = Vector2.ZERO
var target: Node2D = null
var prey_target: Node2D = null
var home_pos: Vector2 = Vector2.ZERO
var attack_cooldown: float = 0.0
var primary_skill_definition: SkillDefinition
var is_enraged: bool = false
var is_night_raider: bool = false
var is_elite: bool = false

# Pack AI & Herd Intelligence
var is_alpha: bool = false
var pack_leader: WildCreature = null
var pack_members: Array[WildCreature] = []
var flank_angle: float = 0.0
var howl_cooldown: float = 0.0
const PLAYER_PERCEPTION_INTERVAL := 0.20

var pack_scan_timer: float = 1.0
var perception_cadence := CreaturePerceptionCadence.new(PLAYER_PERCEPTION_INTERVAL)
var perception_query_count: int = 0
var transition_apply_count: int = 0
var ecology_query_count: int = 0
var grazing_roll_count: int = 0
var grazing_duration_roll_count: int = 0
var sleep_roll_count: int = 0
var sleep_duration_roll_count: int = 0
var drinking_roll_count: int = 0
var drinking_duration_roll_count: int = 0

# Natural Behaviors (Pond Drinking & Grazing)
var water_source_pos: Vector2 = Vector2.ZERO
var has_water_source: bool = false

# Target Ring & Sleep State
var is_targeted_by_mouse: bool = false
var ring_rot: float = 0.0
var sleep_bubble_timer: float = 0.0
var idle_action_timer: float = 0.0

# Elemental status effects
var burn_timer: float = 0.0
var burn_tick: float = 0.0
var slow_timer: float = 0.0
var stun_timer: float = 0.0

# Beast Charge Variables
var charge_dir: Vector2 = Vector2.ZERO
var charge_timer: float = 0.0

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var hp_bar: ProgressBar = $Overhead/HpBar
@onready var name_label: Label = $Overhead/NameLabel
@onready var catch_label: Label = $Overhead/CatchLabel

const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")
const PET_SCENE = preload("res://scenes/pet.tscn")
const DROPPED_ITEM_SCENE = preload("res://scenes/dropped_item.tscn")

func _ready() -> void:
	add_to_group("wild_creatures")
	home_pos = global_position
	setup_species()
	find_nearby_water_source()

func setup_species() -> void:
	species_index = species_index % species_data.size()
	cur_data = LegacySpeciesAdapter.create_runtime_snapshot(species_index, species_data[species_index])
	primary_skill_definition = LegacySpeciesAdapter.get_primary_skill_definition(cur_data.get("id", &"") as StringName)
	
	# 18% chance to become an Elite monster (or 100% if night raider or dragon)
	if is_night_raider or species_index == 4 or randf() < 0.18:
		is_elite = true
	
	var elite_hp_mult = 2.4 if is_elite else 1.0
	var elite_pwr_mult = 1.45 if is_elite else 1.0
	
	max_hp = int((cur_data["max_hp"] + (level - 1) * 15) * elite_hp_mult)
	hp = max_hp
	move_speed = cur_data["speed"] * (1.15 if is_elite else 1.0)
	attack_power = int((cur_data["power"] + (level - 1) * 2) * elite_pwr_mult)
	
	if sprite:
		sprite.texture = cur_data["texture"]
		sprite.frame = 0
	
	if is_elite and visual:
		visual.scale = Vector2(1.35, 1.35)
	
	update_overhead()

func find_nearby_water_source() -> void:
	# Locate water ponds in the world for natural drinking behavior
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_node("Environment/WaterPond"):
		var pond = main_scene.get_node("Environment/WaterPond")
		water_source_pos = pond.global_position
		has_water_source = true

func update_overhead() -> void:
	if name_label:
		if is_alpha:
			name_label.text = "👑 [ĐẦU ĐÀN] Lv.%d %s" % [level, cur_data["name"]]
			name_label.modulate = Color(1.0, 0.75, 0.15)
		elif is_elite:
			name_label.text = "★ [Tinh Anh] Lv.%d %s" % [level, cur_data["name"]]
			name_label.modulate = Color(1.0, 0.85, 0.2)
		else:
			name_label.text = "Lv.%d %s" % [level, cur_data["name"]]
			name_label.modulate = Color.WHITE
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
	
	update_catch_chance_label()

func is_capturing() -> bool:
	return state == State.CAPTURING

func update_catch_chance_label() -> void:
	if not catch_label:
		return
	var chance = get_catch_chance()
	if hp < max_hp * 0.5:
		catch_label.visible = true
		catch_label.text = "Tỉ lệ bắt: %d%%" % int(chance * 100)
		catch_label.modulate = Color(1.0, 0.9, 0.2) if chance < 0.7 else Color(0.2, 1.0, 0.4)
	else:
		catch_label.visible = false

func get_catch_chance() -> float:
	return CaptureResolver.calculate_base_chance(hp, max_hp)

func _process(delta: float) -> void:
	if state == State.CAPTURING:
		if is_targeted_by_mouse:
			is_targeted_by_mouse = false
			queue_redraw()
		return
	
	# Holographic Target Ring detection
	var mpos = get_global_mouse_position()
	var dist_mouse = global_position.distance_to(mpos)
	var should_target = dist_mouse < 50.0 or (is_instance_valid(target) and hp < max_hp * 0.6)
	
	if should_target:
		is_targeted_by_mouse = true
		ring_rot += delta * 3.5
		queue_redraw()
	elif is_targeted_by_mouse:
		is_targeted_by_mouse = false
		queue_redraw()
	
	# Sleep breathing and bubble effect
	if state == State.SLEEP:
		visual.scale.y = 0.82 + sin(Time.get_ticks_msec() * 0.003) * 0.06
		sleep_bubble_timer += delta
		if sleep_bubble_timer >= 2.2:
			sleep_bubble_timer = 0.0
			spawn_floating_text("💤 zzz...", Color(0.65, 0.85, 1.0))
	elif state == State.DRINKING:
		# Drinking bobbing head motion
		visual.position.y = sin(Time.get_ticks_msec() * 0.008) * 3.0
	elif state == State.GRAZING:
		visual.position.y = sin(Time.get_ticks_msec() * 0.006) * 2.0
	elif state != State.ALERT and state != State.STUNNED and state != State.SUSPICIOUS:
		visual.position.y = 0.0
		if not is_elite and not is_alpha:
			visual.scale = Vector2.ONE

func _draw() -> void:
	if is_targeted_by_mouse and state != State.CAPTURING:
		var chance = get_catch_chance()
		var ring_color = Color(0.25, 1.0, 0.45, 0.85) if chance >= 0.6 else (Color(1.0, 0.85, 0.2, 0.85) if chance >= 0.35 else Color(1.0, 0.3, 0.3, 0.85))
		
		# Draw holographic techno targeting arc brackets
		draw_arc(Vector2(0, 2), 24.0, ring_rot, ring_rot + 1.5, 16, ring_color, 2.0)
		draw_arc(Vector2(0, 2), 24.0, ring_rot + 2.1, ring_rot + 3.6, 16, ring_color, 2.0)
		draw_arc(Vector2(0, 2), 24.0, ring_rot + 4.2, ring_rot + 5.7, 16, ring_color, 2.0)
		# Outer faint ring
		draw_arc(Vector2(0, 2), 27.0, -ring_rot * 0.5, -ring_rot * 0.5 + TAU, 24, Color(ring_color.r, ring_color.g, ring_color.b, 0.25), 1.0)
	
	# If Alpha Leader: draw subtle leadership aura underneath
	if is_alpha and state != State.CAPTURING:
		var pulse = 0.4 + sin(Time.get_ticks_msec() * 0.004) * 0.2
		draw_circle(Vector2(0, 10), 16.0, Color(1.0, 0.8, 0.2, pulse * 0.35))

func _physics_process(delta: float) -> void:
	if state == State.CAPTURING:
		return
	
	# Process burn DoT
	if burn_timer > 0:
		burn_timer -= delta
		burn_tick += delta
		if burn_tick >= 0.8:
			burn_tick = 0.0
			hp = max(0, hp - 8)
			update_overhead()
			spawn_floating_text("🔥 -8", Color(1.0, 0.4, 0.1))
			if visual:
				var tw = create_tween()
				visual.modulate = Color(2.5, 0.5, 0.2)
				tw.tween_property(visual, "modulate", Color.WHITE, 0.2)
			if hp <= 0:
				die(target)
				return

	# Process stun
	if stun_timer > 0:
		stun_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Process slow & howl cooldown
	if slow_timer > 0:
		slow_timer -= delta
	if howl_cooldown > 0:
		howl_cooldown -= delta
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	state_timer -= delta
	
	# Periodic Pack cohesion check
	pack_scan_timer -= delta
	if pack_scan_timer <= 0.0:
		pack_scan_timer = randf_range(2.0, 3.5)
		update_pack_status()
		check_predator_prey_ecosystem()
	
	# Player perception runs at a bounded cadence; pack/ecosystem keep their existing timer.
	update_player_perception(delta)
	
	var cur_speed = move_speed * (0.55 if slow_timer > 0 else 1.0)
	
	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 300 * delta)
			if state_timer <= 0:
				start_wander()
		
		State.WANDER:
			# If following an Alpha leader: wander toward leader
			if is_instance_valid(pack_leader) and pack_leader != self:
				var dist_lead = global_position.distance_to(pack_leader.global_position)
				if dist_lead > 130.0:
					wander_dir = (pack_leader.global_position - global_position).normalized()
			
			velocity = wander_dir * (cur_speed * 0.45)
			if state_timer <= 0 or global_position.distance_to(home_pos) > 300:
				var transition := resolve_creature_transition(
					CreatureTransitionPolicy.EVENT_WANDER_COMPLETE,
					true,
					randf_range(1.5, 3.5)
				)
				apply_creature_transition(transition)
		
		State.SUSPICIOUS:
			# Staring at the player, investigating strange noise
			velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
			if is_instance_valid(target):
				var face_dir = (target.global_position - global_position).normalized()
				update_facing_direction(face_dir)
			if state_timer <= 0:
				var alert_target := target
				var transition := resolve_creature_transition(
					CreatureTransitionPolicy.EVENT_SUSPICION_TIMEOUT,
					true
				)
				if apply_creature_transition(transition):
					if (
						transition.reason_id == CreatureTransitionPolicy.REASON_SUSPICION_CONFIRMED
						and is_instance_valid(alert_target)
					):
						present_alert_feedback(alert_target)
		
		State.CHASE:
			handle_smart_chase(delta)
		
		State.FLEE:
			# Running away in panic!
			if is_instance_valid(target):
				var flee_dir = (global_position - target.global_position).normalized()
				# Add slight zigzag
				var zigzag = Vector2(-flee_dir.y, flee_dir.x) * sin(Time.get_ticks_msec() * 0.01) * 0.4
				velocity = (flee_dir + zigzag).normalized() * (cur_speed * 1.35)
				if state_timer <= 0 or global_position.distance_to(target.global_position) > 360.0:
					var transition := resolve_creature_transition(CreatureTransitionPolicy.EVENT_FLEE_COMPLETE, true)
					if apply_creature_transition(transition):
						spawn_floating_text("Thoát hiểm!", Color(0.4, 1.0, 0.5))
			else:
				apply_creature_transition(resolve_creature_transition(
					CreatureTransitionPolicy.EVENT_FLEE_TARGET_LOST,
					true
				))
		
		State.HUNTING_PREY:
			# Predator hunting wild prey (e.g. Beast chasing Slime)
			handle_prey_hunt(delta)
		
		State.DRINKING:
			# Drinking at water pond
			velocity = Vector2.ZERO
			if state_timer <= 0:
				var transition := resolve_creature_transition(CreatureTransitionPolicy.EVENT_DRINKING_COMPLETE, true)
				if apply_creature_transition(transition):
					spawn_floating_text("Uống no nước!", Color(0.3, 0.8, 1.0))
					hp = min(max_hp, hp + 15)
					update_overhead()
		
		State.GRAZING:
			# Grazing grass/berries
			velocity = Vector2.ZERO
			if state_timer <= 0:
				apply_creature_transition(resolve_creature_transition(
					CreatureTransitionPolicy.EVENT_GRAZING_COMPLETE,
					true
				))
		
		State.TELEGRAPH_CHARGE:
			# Beast winding up charge
			velocity = Vector2.ZERO
			visual.position.x = sin(Time.get_ticks_msec() * 0.05) * 2.0
			if state_timer <= 0:
				state = State.CHARGING
				charge_timer = 0.95
				spawn_floating_text("HÚC CỰC MẠNH!", Color(1.0, 0.3, 0.1))
		
		State.CHARGING:
			charge_timer -= delta
			velocity = charge_dir * 330.0
			if charge_timer <= 0 or is_on_wall():
				state = State.STUNNED
				state_timer = 1.4
				spawn_floating_text("@_@ CHOÁNG VÁNG! (SƠ HỞ)", Color(1.0, 0.9, 0.2))
				visual.rotation = 0.3
		
		State.STUNNED:
			velocity = Vector2.ZERO
			visual.rotation = sin(Time.get_ticks_msec() * 0.02) * 0.2
			if state_timer <= 0:
				visual.rotation = 0.0
				state = State.CHASE
				attack_cooldown = 1.0
		
		State.ATTACK:
			velocity = velocity.move_toward(Vector2.ZERO, 400 * delta)
		
		State.ALERT:
			velocity = Vector2.ZERO
			if state_timer <= 0:
				apply_creature_transition(resolve_creature_transition(
					CreatureTransitionPolicy.EVENT_ALERT_COMPLETE,
					true
				))
		
		State.SLEEP:
			velocity = Vector2.ZERO
			if state_timer <= 0:
				apply_creature_transition(resolve_creature_transition(
					CreatureTransitionPolicy.EVENT_SLEEP_COMPLETE,
					true
				))
	
	# Determine animation frame
	update_animation(delta)
	move_and_slide()

func update_animation(delta: float) -> void:
	if abs(velocity.x) > abs(velocity.y):
		facing_row = 3 if velocity.x > 0 else 2
	elif velocity.y != 0:
		facing_row = 0 if velocity.y > 0 else 1
	
	if sprite and state != State.STUNNED:
		if velocity.length() > 5.0:
			anim_timer += delta * 8.5
			sprite.frame = facing_row * 4 + (int(anim_timer) % 4)
		else:
			anim_timer = 0.0
			sprite.frame = facing_row * 4

func update_facing_direction(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing_row = 3 if dir.x > 0 else 2
	else:
		facing_row = 0 if dir.y > 0 else 1
	if sprite:
		sprite.frame = facing_row * 4

# --- PACK & HERD LOGIC ---
func update_pack_status() -> void:
	if state == State.CAPTURING or not is_inside_tree():
		return
	
	pack_members.clear()
	var nearby_allies = get_tree().get_nodes_in_group("wild_creatures")
	var strongest_candidate: WildCreature = self
	
	for node in nearby_allies:
		if not is_instance_valid(node) or node == self or not (node is WildCreature):
			continue
		var other = node as WildCreature
		if other.species_index == species_index and global_position.distance_to(other.global_position) < 240.0:
			pack_members.append(other)
			# Find highest level or elite to be Alpha
			if other.level > strongest_candidate.level or (other.is_elite and not strongest_candidate.is_elite):
				strongest_candidate = other
	
	# Determine if this creature is the Alpha Leader
	var prev_alpha = is_alpha
	if strongest_candidate == self and (pack_members.size() >= 1 or is_elite):
		is_alpha = true
		pack_leader = self
		if not prev_alpha:
			update_overhead()
	else:
		is_alpha = false
		pack_leader = strongest_candidate
		if prev_alpha:
			update_overhead()
	
	# Assign Flanking Angles to pack members so they don't bunch up
	if is_alpha:
		var angles = [0.0, 0.85, -0.85, 1.45, -1.45]
		for i in range(pack_members.size()):
			var m = pack_members[i]
			if is_instance_valid(m):
				m.flank_angle = angles[(i + 1) % angles.size()]

func pack_howl_alert(threat: Node2D) -> void:
	if howl_cooldown > 0 or not is_instance_valid(threat):
		return
	howl_cooldown = 9.0
	
	var howl_msg = "🐺 HÚ GỌI BẦY SĂN MỒI!" if species_index == 3 else ("🔥 TIẾNG KÊU BÁO ĐỘNG BẦY ĐÀN!" if species_index == 0 else "❗ BẦY ĐÀN HỢP LỰC!")
	spawn_floating_text(howl_msg, Color(1.0, 0.45, 0.1))
	
	# Visual soundwave expansion tween
	var wave = Sprite2D.new()
	wave.texture = preload("res://assets/fx/spark.png")
	wave.modulate = Color(1.0, 0.7, 0.2, 0.8)
	wave.global_position = global_position
	get_parent().add_child(wave)
	var w_tw = create_tween()
	w_tw.tween_property(wave, "scale", Vector2(4.5, 4.5), 0.35)
	w_tw.parallel().tween_property(wave, "modulate:a", 0.0, 0.35)
	w_tw.tween_callback(wave.queue_free)
	
	if AudioManager:
		AudioManager.play_sound("shake")
	
	# Alert all nearby pack members or allies within 300px
	var allies = get_tree().get_nodes_in_group("wild_creatures")
	for node in allies:
		if is_instance_valid(node) and node != self and (node is WildCreature):
			var ally = node as WildCreature
			if ally.species_index == species_index and global_position.distance_to(ally.global_position) < 320.0:
				ally.join_pack_attack(threat)

func join_pack_attack(threat: Node2D) -> void:
	if state == State.CAPTURING or state == State.SLEEP:
		return
	target = threat
	state = State.CHASE
	attack_cooldown = randf_range(0.2, 0.8)
	spawn_floating_text("⚔️ TIẾP ỨNG BẦY ĐÀN!", Color(1.0, 0.8, 0.2))

# --- PREDATOR VS PREY ECOSYSTEM ---
func check_predator_prey_ecosystem() -> void:
	var is_blocked := state == State.CHASE or state == State.ALERT or state == State.CAPTURING
	var species_id := cur_data.get("id", &"") as StringName
	var is_predator := bool(cur_data.get("is_predator", false))
	if not is_predator or is_blocked:
		return

	ecology_query_count += 1
	var creatures = get_tree().get_nodes_in_group("wild_creatures")
	var candidate_nodes: Dictionary = {}
	var candidates: Array[CreatureEcologyCandidate] = []
	for c in creatures:
		if is_instance_valid(c) and c != self and (c is WildCreature):
			var wild := c as WildCreature
			var candidate_key := StringName("runtime.creature.%d" % wild.get_instance_id())
			candidate_nodes[candidate_key] = wild
			candidates.append(CreatureEcologyCandidate.new(
				candidate_key,
				wild.cur_data.get("id", &"") as StringName,
				bool(wild.cur_data.get("is_prey", false)),
				wild.state == State.CAPTURING or wild.capture_attempt_active or wild.capture_ownership_committed,
				global_position.distance_to(wild.global_position)
			))
	var selection := CreatureEcologySelectionPolicy.resolve(CreatureEcologySelectionRequest.new(species_id, is_predator, is_blocked, candidates))
	if not selection.is_selected():
		return
	var selected_prey := candidate_nodes.get(selection.candidate_key) as WildCreature
	if not is_instance_valid(selected_prey):
		return
	var transition := resolve_creature_transition(selection.transition_event_id, true, selection.hunt_duration)
	if not apply_creature_transition(transition):
		return
	prey_target = selected_prey
	spawn_floating_text("🍖 RÌNH RẬP SĂN MỒI...", Color(1.0, 0.6, 0.2))
	selected_prey.panic_from_predator(self)

func panic_from_predator(predator: Node2D) -> bool:
	var transition := resolve_creature_transition(
		CreatureTransitionPolicy.EVENT_ECOLOGY_PREDATOR_THREAT,
		true,
		0.0,
		predator
	)
	if not apply_creature_transition(transition, predator):
		return false
	spawn_floating_text("😱 GẶP THÚ SĂN MỒI!", Color(0.3, 0.9, 1.0))
	if AudioManager:
		AudioManager.play_sound("shake")
	return true

func handle_prey_hunt(delta: float) -> void:
	if not is_instance_valid(prey_target) or state_timer <= 0:
		apply_prey_hunt_exit(resolve_creature_transition(
			CreatureTransitionPolicy.EVENT_ECOLOGY_HUNT_ABORTED,
			true
		))
		return
	
	var dir = (prey_target.global_position - global_position).normalized()
	var dist = global_position.distance_to(prey_target.global_position)
	
	velocity = dir * (move_speed * 1.05)
	
	if dist < 42.0:
		var transition := resolve_creature_transition(
			CreatureTransitionPolicy.EVENT_ECOLOGY_HUNT_CONTACT,
			true
		)
		perform_melee_attack_on_prey(prey_target)
		if apply_prey_hunt_exit(transition):
			spawn_floating_text("Vồ hụt con mồi!", Color(1.0, 0.7, 0.3))


func apply_prey_hunt_exit(result: CreatureTransitionResult) -> bool:
	if not apply_creature_transition(result):
		return false
	prey_target = null
	return true

func perform_melee_attack_on_prey(prey: Node2D) -> void:
	if is_instance_valid(prey) and prey.has_method("take_damage"):
		prey.take_damage(int(attack_power * 0.7), global_position, self)

# --- CHASE & FLANKING AI ---
func handle_smart_chase(delta: float) -> void:
	if not is_instance_valid(target):
		apply_creature_transition(resolve_creature_transition(
			CreatureTransitionPolicy.EVENT_CHASE_TARGET_LOST,
			true
		))
		return
	
	var raw_dir = (target.global_position - global_position).normalized()
	var dist = global_position.distance_to(target.global_position)
	
	if dist > CreatureTransitionPolicy.CHASE_LEASH_DISTANCE and not is_night_raider:
		apply_creature_transition(resolve_creature_transition(
			CreatureTransitionPolicy.EVENT_CHASE_OUT_OF_RANGE,
			true
		))
		return
	
	# Apply Flanking angle maneuver if in pack
	var attack_dir = raw_dir
	if flank_angle != 0.0 and dist > 90.0 and dist < 260.0:
		attack_dir = raw_dir.rotated(flank_angle)
	
	match species_index:
		0: # Flam (Lửa) - Circling Flanker
			if dist > 140.0:
				velocity = attack_dir * move_speed
			else:
				var tangent = Vector2(-raw_dir.y, raw_dir.x)
				velocity = (tangent * 0.8 + raw_dir * 0.2).normalized() * move_speed
				if attack_cooldown <= 0:
					perform_fireball_attack(raw_dir, primary_skill_definition)
		
		1: # Slime (Nước) - Bouncy Hopper
			if hp < max_hp * 0.30:
				# Low HP Slime panics and flees!
				state = State.FLEE
				state_timer = 3.5
				spawn_floating_text("💦 HOẢNG SỢ BỎ CHẠY!", Color(0.3, 0.9, 1.0))
				return
			
			if attack_cooldown <= 0:
				perform_slime_hop(raw_dir)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
		
		2: # Mushroom (Thảo Mộc) - Kiting Sniper
			if hp < max_hp * 0.25:
				state = State.FLEE
				state_timer = 3.0
				spawn_floating_text("🍄 BỎ CHẠY THOÁT THÂN!", Color(0.5, 1.0, 0.4))
				return
			
			if dist < 120.0:
				velocity = -raw_dir * (move_speed * 1.1)
			elif dist > 170.0:
				velocity = attack_dir * move_speed
			else:
				velocity = Vector2.ZERO
			
			if attack_cooldown <= 0:
				perform_spore_attack(raw_dir)
		
		3: # Beast (Đất) - Bull Charging Rush
			if dist >= 70.0 and dist <= 220.0 and attack_cooldown <= 0:
				state = State.TELEGRAPH_CHARGE
				state_timer = 0.45
				charge_dir = raw_dir
				attack_cooldown = 3.5
				spawn_floating_text("! CHUẨN BỊ LAO TỚI", Color(1.0, 0.4, 0.1))
			else:
				velocity = attack_dir * move_speed
				if dist <= 38.0 and attack_cooldown <= 0:
					perform_melee_attack()
		
		_: # Dragon Boss / Default
			velocity = attack_dir * move_speed
			if dist <= 48.0 and attack_cooldown <= 0:
				perform_melee_attack()
			elif dist <= 180.0 and attack_cooldown <= 0:
				perform_fireball_attack(raw_dir)

func perform_slime_hop(dir: Vector2) -> void:
	attack_cooldown = 1.15
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(1.4, 0.6), 0.15)
	tween.tween_callback(func():
		velocity = dir * 260.0
		visual.position.y = -12.0
	)
	tween.tween_property(visual, "scale", Vector2(0.8, 1.3), 0.12)
	tween.tween_property(visual, "position:y", 0.0, 0.15)
	tween.tween_property(visual, "scale", Vector2.ONE, 0.1)

func perform_fireball_attack(dir: Vector2, skill: SkillDefinition = null) -> void:
	var cooldown_seconds := skill.cooldown_seconds if skill != null else 2.2
	var travel_distance := skill.travel_distance if skill != null else 240.0
	var travel_seconds := skill.travel_seconds if skill != null else 0.55
	var hit_radius := skill.hit_radius if skill != null else 45.0
	var recovery_seconds := skill.recovery_seconds if skill != null else 0.3
	var damage_multiplier := skill.damage_multiplier if skill != null else 1.0
	attack_cooldown = cooldown_seconds
	state = State.ATTACK
	velocity = Vector2.ZERO
	
	spawn_floating_text("🔥 Bắn Cầu Lửa!", Color(1.0, 0.4, 0.1))
	if AudioManager:
		AudioManager.play_sound("sphere_throw")
	
	var fb = Sprite2D.new()
	fb.texture = preload("res://assets/fx/fireball.png")
	fb.global_position = global_position + dir * 16.0
	fb.rotation = dir.angle()
	get_parent().add_child(fb)
	
	var tween = create_tween()
	var dest = fb.global_position + dir * travel_distance
	tween.tween_property(fb, "global_position", dest, travel_seconds).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(func():
		if is_instance_valid(target) and fb.global_position.distance_to(target.global_position) < hit_radius:
			if target.has_method("take_damage"):
				target.take_damage(int(attack_power * damage_multiplier), global_position)
		fb.queue_free()
	)
	
	await get_tree().create_timer(recovery_seconds).timeout
	finish_legacy_attack_recovery()

func perform_spore_attack(dir: Vector2) -> void:
	attack_cooldown = 2.0
	state = State.ATTACK
	velocity = Vector2.ZERO
	
	spawn_floating_text("🌿 Bắn Bào Tử Độc!", Color(0.4, 1.0, 0.3))
	var spore = Sprite2D.new()
	spore.texture = preload("res://assets/fx/leaf.png")
	spore.modulate = Color(0.8, 0.2, 1.0)
	spore.scale = Vector2(1.5, 1.5)
	spore.global_position = global_position + dir * 14.0
	get_parent().add_child(spore)
	
	var tween = create_tween()
	var dest = spore.global_position + dir * 200.0
	tween.tween_property(spore, "global_position", dest, 0.5)
	tween.tween_callback(func():
		if is_instance_valid(target) and spore.global_position.distance_to(target.global_position) < 45.0:
			if target.has_method("take_damage"):
				target.take_damage(attack_power, global_position)
		spore.queue_free()
	)
	
	await get_tree().create_timer(0.25).timeout
	finish_legacy_attack_recovery()

func perform_melee_attack() -> void:
	if not is_instance_valid(target): return
	state = State.ATTACK
	attack_cooldown = 1.2
	
	var dir = (target.global_position - global_position).normalized()
	velocity = dir * 180.0
	
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(1.3, 0.7), 0.1)
	tween.tween_property(visual, "scale", Vector2.ONE, 0.15)
	
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(target) and global_position.distance_to(target.global_position) < 55.0:
		if target.has_method("take_damage"):
			target.take_damage(attack_power, global_position)
	
	finish_legacy_attack_recovery()


func finish_legacy_attack_recovery() -> bool:
	if (
		defeat_committed
		or state == State.CAPTURING
		or state == State.STUNNED
		or state != State.ATTACK
	):
		return false
	state = State.CHASE
	return true


func update_player_perception(delta: float) -> void:
	if not perception_cadence.advance(delta):
		return
	if is_player_perception_blocked():
		return
	perception_query_count += 1

	var candidate_nodes: Dictionary = {}
	var candidates: Array[CreaturePerceptionCandidate] = []
	for node in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		var player_node := node as Node2D
		var movement_speed := 0.0
		if player_node is CharacterBody2D:
			movement_speed = (player_node as CharacterBody2D).velocity.length()
		var candidate_id := int(player_node.get_instance_id())
		candidate_nodes[candidate_id] = player_node
		candidates.append(CreaturePerceptionCandidate.new(
			candidate_id,
			global_position.distance_to(player_node.global_position),
			movement_speed
		))

	var aggro_distance := 280.0 if is_night_raider else (150.0 if is_elite else 115.0)
	var request := CreaturePerceptionRequest.new(
		is_player_perception_blocked(),
		state == State.SLEEP,
		state == State.SUSPICIOUS,
		aggro_distance,
		aggro_distance + 65.0,
		candidates
	)
	var result := CreaturePerceptionPolicy.resolve(request)
	if not result.has_target_decision():
		return
	var selected_target := candidate_nodes.get(result.candidate_id) as Node2D
	if not is_instance_valid(selected_target):
		return
	match result.decision:
		CreaturePerceptionResult.Decision.ALERT:
			trigger_alert(selected_target)
		CreaturePerceptionResult.Decision.SUSPICIOUS:
			trigger_suspicion(selected_target)


func is_player_perception_blocked() -> bool:
	return (
		defeat_committed
		or state == State.CHASE
		or state == State.TELEGRAPH_CHARGE
		or state == State.CHARGING
		or state == State.STUNNED
		or state == State.CAPTURING
		or state == State.ALERT
		or state == State.FLEE
	)

func resolve_creature_transition(
	event_id: StringName,
	condition_met: bool,
	proposed_timer: float = 0.0,
	proposed_target: Node2D = null
) -> CreatureTransitionResult:
	var resolved_target := proposed_target if is_instance_valid(proposed_target) else target
	var has_valid_target := is_instance_valid(resolved_target)
	var target_distance := (
		global_position.distance_to(resolved_target.global_position)
		if has_valid_target
		else -1.0
	)
	var request := CreatureTransitionRequest.new(
		get_creature_state_id(),
		event_id,
		condition_met,
		has_valid_target,
		target_distance,
		is_night_raider,
		proposed_timer,
		is_transition_request_protected(event_id)
	)
	return CreatureTransitionPolicy.resolve(request)


func apply_creature_transition(result: CreatureTransitionResult, proposed_target: Node2D = null) -> bool:
	if result == null or not result.is_changed() or is_transition_apply_protected(result):
		return false
	if result.from_state_id != get_creature_state_id():
		return false
	if not is_supported_transition_state(result.to_state_id):
		return false
	if result.target_action == CreatureTransitionResult.TargetAction.SET and not is_instance_valid(proposed_target):
		return false

	state = creature_state_from_id(result.to_state_id)
	state_timer = result.next_timer
	if result.target_action == CreatureTransitionResult.TargetAction.CLEAR:
		target = null
	elif result.target_action == CreatureTransitionResult.TargetAction.SET:
		target = proposed_target
	transition_apply_count += 1
	return true


func is_transition_request_protected(event_id: StringName) -> bool:
	return defeat_committed or state == State.STUNNED or (state == State.CAPTURING and event_id != CreatureTransitionPolicy.EVENT_CAPTURE_REJECTED)


func is_transition_apply_protected(result: CreatureTransitionResult = null) -> bool:
	var capture_rejection := result != null and result.reason_id == CreatureTransitionPolicy.EVENT_CAPTURE_REJECTED
	return defeat_committed or state == State.STUNNED or (state == State.CAPTURING and not capture_rejection)


func get_creature_state_id() -> StringName:
	match state:
		State.IDLE:
			return CreatureTransitionPolicy.STATE_IDLE
		State.WANDER:
			return CreatureTransitionPolicy.STATE_WANDER
		State.SUSPICIOUS:
			return CreatureTransitionPolicy.STATE_SUSPICIOUS
		State.ALERT:
			return CreatureTransitionPolicy.STATE_ALERT
		State.CHASE:
			return CreatureTransitionPolicy.STATE_CHASE
		State.SLEEP:
			return CreatureTransitionPolicy.STATE_SLEEP
		State.DRINKING:
			return CreatureTransitionPolicy.STATE_DRINKING
		State.GRAZING:
			return CreatureTransitionPolicy.STATE_GRAZING
		State.FLEE:
			return CreatureTransitionPolicy.STATE_FLEE
		State.CAPTURING:
			return CreatureTransitionPolicy.STATE_CAPTURING
		State.HUNTING_PREY:
			return CreatureTransitionPolicy.STATE_HUNTING_PREY
		_:
			return &"creature.state.legacy"


func is_supported_transition_state(state_id: StringName) -> bool:
	return (
		state_id == CreatureTransitionPolicy.STATE_IDLE
		or state_id == CreatureTransitionPolicy.STATE_WANDER
		or state_id == CreatureTransitionPolicy.STATE_SUSPICIOUS
		or state_id == CreatureTransitionPolicy.STATE_ALERT
		or state_id == CreatureTransitionPolicy.STATE_CHASE
		or state_id == CreatureTransitionPolicy.STATE_SLEEP
		or state_id == CreatureTransitionPolicy.STATE_DRINKING
		or state_id == CreatureTransitionPolicy.STATE_GRAZING
		or state_id == CreatureTransitionPolicy.STATE_FLEE
		or state_id == CreatureTransitionPolicy.STATE_CAPTURING
		or state_id == CreatureTransitionPolicy.STATE_HUNTING_PREY
	)


func creature_state_from_id(state_id: StringName) -> State:
	match state_id:
		CreatureTransitionPolicy.STATE_WANDER:
			return State.WANDER
		CreatureTransitionPolicy.STATE_SUSPICIOUS:
			return State.SUSPICIOUS
		CreatureTransitionPolicy.STATE_ALERT:
			return State.ALERT
		CreatureTransitionPolicy.STATE_CHASE:
			return State.CHASE
		CreatureTransitionPolicy.STATE_SLEEP:
			return State.SLEEP
		CreatureTransitionPolicy.STATE_DRINKING:
			return State.DRINKING
		CreatureTransitionPolicy.STATE_GRAZING:
			return State.GRAZING
		CreatureTransitionPolicy.STATE_FLEE:
			return State.FLEE
		CreatureTransitionPolicy.STATE_CAPTURING:
			return State.CAPTURING
		CreatureTransitionPolicy.STATE_HUNTING_PREY:
			return State.HUNTING_PREY
		_:
			return State.IDLE


func trigger_suspicion(p: Node2D) -> void:
	var transition := resolve_creature_transition(CreatureTransitionPolicy.EVENT_PERCEPTION_SUSPICIOUS, true, 0.0, p)
	if apply_creature_transition(transition, p):
		spawn_floating_text("❓", Color(1.0, 0.9, 0.2))

func trigger_alert(p: Node2D) -> void:
	var transition := resolve_creature_transition(CreatureTransitionPolicy.EVENT_PERCEPTION_ALERT, true, 0.0, p)
	if apply_creature_transition(transition, p):
		present_alert_feedback(p)


func present_alert_feedback(p: Node2D) -> void:
	velocity = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(0.9, 1.35), 0.1)
	tween.tween_property(visual, "scale", Vector2(1.35 if (is_elite or is_alpha) else 1.0, 1.35 if (is_elite or is_alpha) else 1.0), 0.12)
	spawn_floating_text("❗", Color(1.0, 0.2, 0.2))
	if AudioManager:
		AudioManager.play_sound("shake")
	
	# Trigger pack howl so the entire herd responds
	pack_howl_alert(p)

func start_wander() -> void:
	# Chance to nap if peaceful
	if not is_night_raider and not is_enraged:
		sleep_roll_count += 1
		var sleep_result := resolve_sleep_entry(randf())
		if sleep_result.should_sleep():
			sleep_duration_roll_count += 1
			var sleep_duration := randf_range(CreatureSleepPolicy.DURATION_MIN, CreatureSleepPolicy.DURATION_MAX)
			if apply_sleep_entry(sleep_result, sleep_duration):
				return
	
	# Natural behavior: Drink at pond if nearby
	if has_water_source and global_position.distance_to(water_source_pos) < CreatureDrinkingPolicy.WATER_RANGE:
		drinking_roll_count += 1
		var drinking_result := resolve_drinking_entry(randf())
		if drinking_result.should_drink():
			drinking_duration_roll_count += 1
			var drinking_duration := randf_range(CreatureDrinkingPolicy.DURATION_MIN, CreatureDrinkingPolicy.DURATION_MAX)
			if apply_drinking_entry(drinking_result, drinking_duration):
				spawn_floating_text("💧 Đi uống nước mát...", Color(0.4, 0.8, 1.0))
				return
	
	# Preserve legacy RNG ordering: only prey roll after sleep/drink fail; duration rolls only on acceptance.
	if cur_data.get("is_prey", false):
		grazing_roll_count += 1
		var grazing_result := resolve_grazing_entry(randf())
		if grazing_result.should_graze():
			grazing_duration_roll_count += 1
			var grazing_duration := randf_range(CreatureGrazingPolicy.DURATION_MIN, CreatureGrazingPolicy.DURATION_MAX)
			if apply_grazing_entry(grazing_result, grazing_duration):
				spawn_floating_text("🌾 Gặm cỏ thong dong...", Color(0.5, 0.9, 0.3))
				return
	
	var transition := resolve_creature_transition(
		CreatureTransitionPolicy.EVENT_IDLE_WANDER,
		true,
		randf_range(2.0, 4.0)
	)
	if apply_creature_transition(transition):
		var angle = randf() * TAU
		wander_dir = Vector2(cos(angle), sin(angle))


func resolve_grazing_entry(roll: float) -> CreatureGrazingResult:
	return CreatureGrazingPolicy.resolve(CreatureGrazingRequest.new(
		cur_data.get("id", &"") as StringName,
		bool(cur_data.get("is_prey", false)),
		roll,
		is_transition_request_protected(CreatureTransitionPolicy.EVENT_ECOLOGY_GRAZING_ENTRY)
	))


func resolve_sleep_entry(roll: float) -> CreatureSleepResult:
	return CreatureSleepPolicy.resolve(CreatureSleepRequest.new(
		cur_data.get("id", &"") as StringName,
		is_night_raider,
		is_enraged,
		roll,
		is_transition_request_protected(CreatureTransitionPolicy.EVENT_ECOLOGY_SLEEP_ENTRY)
	))


func apply_sleep_entry(result: CreatureSleepResult, duration: float) -> bool:
	if result == null or not result.should_sleep() or duration < CreatureSleepPolicy.DURATION_MIN or duration > CreatureSleepPolicy.DURATION_MAX or not is_finite(duration):
		return false
	return apply_creature_transition(resolve_creature_transition(result.transition_event_id, true, duration))


func resolve_drinking_entry(roll: float) -> CreatureDrinkingResult:
	var water_distance := global_position.distance_to(water_source_pos) if has_water_source else -1.0
	return CreatureDrinkingPolicy.resolve(CreatureDrinkingRequest.new(
		cur_data.get("id", &"") as StringName,
		has_water_source,
		water_distance,
		roll,
		is_transition_request_protected(CreatureTransitionPolicy.EVENT_ECOLOGY_DRINKING_ENTRY)
	))


func apply_drinking_entry(result: CreatureDrinkingResult, duration: float) -> bool:
	if result == null or not result.should_drink() or duration < CreatureDrinkingPolicy.DURATION_MIN or duration > CreatureDrinkingPolicy.DURATION_MAX or not is_finite(duration):
		return false
	if not has_water_source or not is_finite(water_source_pos.x) or not is_finite(water_source_pos.y):
		return false
	if not apply_creature_transition(resolve_creature_transition(result.transition_event_id, true, duration)):
		return false
	wander_dir = (water_source_pos - global_position).normalized()
	return true


func apply_grazing_entry(result: CreatureGrazingResult, duration: float) -> bool:
	if result == null or not result.should_graze():
		return false
	return apply_creature_transition(resolve_creature_transition(result.transition_event_id, true, duration))

func take_damage(amount: int, hit_origin: Vector2, attacker: Node2D = null) -> void:
	if state == State.CAPTURING or defeat_committed:
		return

	var source_faction := &"player_companion"
	var allow_legacy_wild_damage := false
	if is_instance_valid(attacker) and attacker.is_in_group("wild_creatures"):
		source_faction = &"wild"
		allow_legacy_wild_damage = true
	var request := DamageRequest.new(source_faction, &"wild", hp, max_hp, amount, hit_origin, global_position)
	request.knockback_strength = 160.0
	request.allow_friendly_fire = allow_legacy_wild_damage
	if state == State.SLEEP:
		request.damage_multiplier = 1.75
		spawn_floating_text("💥 CHÍ MẠNG KHI NGỦ (x1.75)!", Color(1.0, 0.85, 0.2))
		if attacker:
			trigger_alert(attacker)

	var result := apply_damage_request(request)
	if not result.is_applied():
		return
	update_overhead()
	
	spawn_floating_text(str(result.applied_damage), Color(1.0, 0.25, 0.25))
	if AudioManager:
		AudioManager.play_sound("hit")
	
	velocity = result.knockback
	
	var tween = create_tween()
	visual.modulate = Color(2.5, 0.3, 0.3)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.18)
	
	if attacker and is_instance_valid(attacker):
		target = attacker
		state = State.CHASE
		# Call pack assistance immediately
		pack_howl_alert(attacker)
	
	var ecology_result := resolve_damage_panic(result.defeated)
	if ecology_result.should_panic_flee():
		var panic_transition := resolve_creature_transition(
			ecology_result.transition_event_id,
			true,
			ecology_result.state_duration
		)
		if apply_creature_transition(panic_transition):
			spawn_floating_text("💦 HOẢNG LOẠN THÁO CHẠY!", Color(0.3, 0.9, 1.0))
			return
	
	if hp > 0 and hp <= max_hp * 0.5 and not is_enraged and level >= 5:
		is_enraged = true
		move_speed *= 1.4
		attack_power = int(attack_power * 1.35)
		spawn_floating_text("⚠️ CUỒNG NỘ! (+TỐC ĐỘ & SÁT THƯƠNG)", Color(1.0, 0.1, 0.1))
		if AudioManager:
			AudioManager.play_sound("sphere_throw")
	
	if result.defeated:
		defeat_committed = true
		die(attacker)


func create_damage_ecology_request(defeated: bool) -> CreatureEcologyRequest:
	return CreatureEcologyRequest.new(
		cur_data.get("id", &"") as StringName,
		bool(cur_data.get("is_prey", false)),
		hp,
		max_hp,
		defeated,
		is_enraged,
		capture_attempt_active or state == State.CAPTURING or capture_ownership_committed
	)


func resolve_damage_panic(defeated: bool) -> CreatureEcologyResult:
	return CreatureEcologyPolicy.resolve_damage_panic(create_damage_ecology_request(defeated))


func apply_damage_request(request: DamageRequest) -> DamageResult:
	if defeat_committed:
		return DamageResult.new(DamageResult.Status.ALREADY_DEFEATED, 0, 0, true)
	var result := CombatResolver.resolve(request)
	if result.is_applied():
		hp = result.remaining_hp
	return result

func apply_burn(dur: float) -> void:
	burn_timer = max(burn_timer, dur)
	spawn_floating_text("🔥 BỊ THIÊU ĐỐT!", Color(1.0, 0.4, 0.1))

func apply_slow(dur: float) -> void:
	slow_timer = max(slow_timer, dur)
	spawn_floating_text("💧 BỊ LÀM CHẬM!", Color(0.3, 0.85, 1.0))

func apply_stun(dur: float) -> void:
	stun_timer = max(stun_timer, dur)
	spawn_floating_text("⚡ CHOÁNG VÁNG!", Color(1.0, 0.9, 0.2))

func die(killer: Node2D) -> void:
	var exp_gained = level * (120 if is_alpha else (80 if is_elite else 25))
	spawn_floating_text("+%d EXP" % exp_gained, Color(0.4, 0.9, 1.0))
	if killer and killer.has_method("gain_exp"):
		killer.gain_exp(exp_gained)
	
	var species_id := cur_data.get("id", &"") as StringName
	if species_id == LegacySpeciesAdapter.FLAM_ID:
		var has_bonus := is_elite or is_alpha
		var drop_request := create_defeat_drop_request(
			randi_range(3, 5) if has_bonus else randi_range(1, 2),
			randi_range(2, 4) if has_bonus else 0
		)
		commit_defeat_drop_result(CreatureDropResolver.resolve(drop_request))
	else:
		spawn_legacy_defeat_drops()

	if is_elite or is_alpha:
		if killer and killer.has_method("shake_camera"):
			killer.shake_camera(6.0)

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)


func create_defeat_drop_request(primary_count_roll: int, bonus_count_roll: int) -> CreatureDropRequest:
	var species_id := cur_data.get("id", &"") as StringName
	return CreatureDropRequest.new(
		species_id,
		LegacySpeciesAdapter.get_drop_item_id(species_id, String(cur_data.get("drop_item", ""))),
		defeat_committed,
		capture_attempt_active or state == State.CAPTURING or capture_ownership_committed,
		defeat_drops_committed,
		is_elite,
		is_alpha,
		primary_count_roll,
		bonus_count_roll
	)


func commit_defeat_drop_result(result: CreatureDropResult) -> bool:
	if result == null or not result.is_accepted() or defeat_drops_committed:
		return false
	var species_id := cur_data.get("id", &"") as StringName
	var expected_item_id := LegacySpeciesAdapter.get_drop_item_id(species_id, String(cur_data.get("drop_item", "")))
	if result.species_id != species_id or result.primary_item_id != expected_item_id:
		return false
	defeat_drops_committed = true
	for _drop_index in range(result.primary_count):
		spawn_stable_drop(result.primary_item_id, 1, Vector2(12.0, 8.0))
	if result.bonus_count > 0:
		spawn_stable_drop(result.bonus_item_id, result.bonus_count, Vector2(16.0, 10.0))
	return true


func spawn_stable_drop(item_id: StringName, count: int, spread: Vector2) -> void:
	var item := DROPPED_ITEM_SCENE.instantiate()
	item.item_id = item_id
	item.item_name = LegacyItemAdapter.to_legacy_key(item_id)
	item.count = count
	item.global_position = global_position + Vector2(randf_range(-spread.x, spread.x), randf_range(-spread.y, spread.y))
	get_parent().call_deferred("add_child", item)


func spawn_legacy_defeat_drops() -> void:
	var drop_count = randi_range(3, 5) if (is_elite or is_alpha) else randi_range(1, 2)
	for _drop_index in range(drop_count):
		var item = DROPPED_ITEM_SCENE.instantiate()
		item.item_name = cur_data["drop_item"]
		item.count = 1
		item.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-8, 8))
		get_parent().call_deferred("add_child", item)
	if is_elite or is_alpha:
		var bonus_item = DROPPED_ITEM_SCENE.instantiate()
		bonus_item.item_name = "Quặng Pal"
		bonus_item.count = randi_range(2, 4)
		bonus_item.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-10, 10))
		get_parent().call_deferred("add_child", bonus_item)

func attempt_capture(player_ref: Node2D, catch_multiplier: float = 1.0, throw_pos: Vector2 = Vector2.ZERO) -> void:
	if state == State.CAPTURING or capture_attempt_active:
		return

	var request := create_capture_request(catch_multiplier, randf(), throw_pos)
	var result := resolve_capture_request(request)
	if not result.is_resolved():
		return

	capture_attempt_active = true
	state = State.CAPTURING
	velocity = Vector2.ZERO
	if result.tags.has("back_strike"):
		spawn_floating_text("🎯 ĐÁNH LÉN SAU LƯNG! (+35% BẮT)", Color(1.0, 0.9, 0.2))
	if result.tags.has("sleep"):
		spawn_floating_text("💤 BẮT KHI ĐANG NGỦ SAY (+40% BẮT)!", Color(0.4, 0.9, 1.0))

	spawn_floating_text("Tỉ lệ bắt: %d%%" % int(result.final_chance * 100), Color(0.2, 0.85, 1.0))
	
	# Spiral shrink into sphere
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(0.08, 0.08), 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(visual, "rotation", TAU * 2.0, 0.32)
	await tween.finished
	visual.visible = false
	
	# Spawn visual physical Pal Sphere on ground
	var sphere_spr = Sprite2D.new()
	sphere_spr.texture = preload("res://assets/items/mega_sphere.png")
	sphere_spr.global_position = global_position + Vector2(0, -20)
	get_parent().add_child(sphere_spr)
	
	# Drop to ground with bounce
	var drop_tw = create_tween()
	drop_tw.tween_property(sphere_spr, "position:y", sphere_spr.position.y + 20, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await drop_tw.finished
	
	# Shake 1
	await get_tree().create_timer(0.35).timeout
	var s_tw1 = create_tween()
	s_tw1.tween_property(sphere_spr, "rotation", -0.45, 0.08)
	s_tw1.tween_property(sphere_spr, "rotation", 0.0, 0.08)
	spawn_floating_text("Lắc 1... (33%)", Color(1.0, 0.85, 0.3))
	if AudioManager:
		AudioManager.play_sound("shake")
	
	# Shake 2
	await get_tree().create_timer(0.40).timeout
	var s_tw2 = create_tween()
	s_tw2.tween_property(sphere_spr, "position:y", sphere_spr.position.y - 6, 0.06)
	s_tw2.parallel().tween_property(sphere_spr, "rotation", 0.45, 0.08)
	s_tw2.tween_property(sphere_spr, "position:y", sphere_spr.position.y, 0.06)
	s_tw2.parallel().tween_property(sphere_spr, "rotation", 0.0, 0.08)
	spawn_floating_text("Lắc 2... (66%)", Color(1.0, 0.95, 0.2))
	if AudioManager:
		AudioManager.play_sound("shake")
	
	# Shake 3
	await get_tree().create_timer(0.40).timeout
	var s_tw3 = create_tween()
	s_tw3.tween_property(sphere_spr, "rotation", -0.3, 0.05)
	s_tw3.tween_property(sphere_spr, "rotation", 0.3, 0.05)
	s_tw3.tween_property(sphere_spr, "rotation", 0.0, 0.05)
	spawn_floating_text("Lắc 3... Hồi hộp!", Color(0.4, 1.0, 0.5))
	if AudioManager:
		AudioManager.play_sound("shake")
	
	await get_tree().create_timer(0.35).timeout
	
	if result.succeeded:
		var succ_tw = create_tween()
		succ_tw.tween_property(sphere_spr, "scale", Vector2(1.5, 1.5), 0.15)
		succ_tw.tween_property(sphere_spr, "modulate", Color(2.5, 2.2, 0.5), 0.15)
		succ_tw.tween_property(sphere_spr, "scale", Vector2.ZERO, 0.2)
		await succ_tw.finished
		sphere_spr.queue_free()
	else:
		var fail_tw = create_tween()
		fail_tw.tween_property(sphere_spr, "scale", Vector2(1.6, 1.6), 0.08)
		fail_tw.tween_property(sphere_spr, "modulate:a", 0.0, 0.1)
		await fail_tw.finished
		sphere_spr.queue_free()
	commit_capture_result(result, player_ref)


func create_capture_request(catch_multiplier: float, roll: float, throw_pos: Vector2) -> CaptureRequest:
	var request := CaptureRequest.new(
		StringName(cur_data.get("id", "")),
		hp,
		max_hp,
		catch_multiplier,
		roll
	)
	request.is_asleep = state == State.SLEEP
	if throw_pos != Vector2.ZERO:
		var face_dir := Vector2.DOWN
		match facing_row:
			0: face_dir = Vector2.DOWN
			1: face_dir = Vector2.UP
			2: face_dir = Vector2.LEFT
			3: face_dir = Vector2.RIGHT
		var throw_direction := (global_position - throw_pos).normalized()
		request.is_back_strike = face_dir.dot(throw_direction) > 0.25
	return request


func resolve_capture_request(request: CaptureRequest) -> CaptureResult:
	if request != null:
		request.already_capturing = request.already_capturing or state == State.CAPTURING or capture_attempt_active
		request.already_defeated = request.already_defeated or defeat_committed
	return CaptureResolver.resolve(request)


func commit_capture_result(result: CaptureResult, player_ref: Node2D) -> void:
	if not capture_attempt_active or result == null or not result.is_resolved():
		return
	capture_attempt_active = false
	if result.succeeded:
		capture_succeeded(player_ref)
	else:
		capture_failed(player_ref)

func capture_succeeded(player_ref: Node2D) -> CaptureOwnershipResult:
	var ownership_token := get_capture_ownership_token()
	var species_id := StringName(cur_data.get("id", ""))
	if capture_ownership_committed:
		return CaptureOwnershipResult.new(
			CaptureOwnershipResult.Status.DUPLICATE,
			ownership_token,
			species_id
		)

	var ownership_result := CaptureOwnershipResult.new(
		CaptureOwnershipResult.Status.INVALID_REQUEST,
		ownership_token,
		species_id
	)
	if is_instance_valid(player_ref) and player_ref.has_method("on_pet_captured"):
		ownership_result = player_ref.call(
			"on_pet_captured",
			cur_data,
			level,
			ownership_token,
			randf(),
			randf()
		) as CaptureOwnershipResult
		if ownership_result == null:
			ownership_result = CaptureOwnershipResult.new(
				CaptureOwnershipResult.Status.INVALID_REQUEST,
				ownership_token,
				species_id
			)

	if not ownership_result.is_accepted():
		restore_after_capture_ownership_rejection(player_ref)
		return ownership_result

	capture_ownership_committed = true
	spawn_floating_text("★ THU PHỤC HOÀN TOÀN! ★", Color(0.2, 1.0, 0.4))
	if AudioManager:
		AudioManager.play_sound("success")
	queue_free()
	return ownership_result


func get_capture_ownership_token() -> StringName:
	if capture_ownership_token.is_empty():
		capture_ownership_token = StringName("wild_capture_%d" % get_instance_id())
	return capture_ownership_token


func restore_after_capture_ownership_rejection(player_ref: Node2D) -> void:
	capture_attempt_active = false
	var transition := resolve_creature_transition(CreatureTransitionPolicy.EVENT_CAPTURE_REJECTED, true, 0.0, player_ref)
	if not apply_creature_transition(transition, player_ref):
		return
	visual.visible = true
	visual.rotation = 0.0
	visual.scale = Vector2.ONE
	visual.modulate = Color.WHITE
	spawn_floating_text("Không thể chuyển Pet vào đội hình.", Color(1.0, 0.45, 0.25))


func capture_failed(player_ref: Node2D) -> void:
	var transition := resolve_creature_transition(CreatureTransitionPolicy.EVENT_CAPTURE_REJECTED, true, 0.0, player_ref)
	if not apply_creature_transition(transition, player_ref):
		return
	visual.visible = true
	visual.rotation = 0.0
	visual.modulate = Color(2.5, 0.3, 0.3)
	
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(1.5, 1.5), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", Vector2.ONE, 0.12)
	
	is_enraged = true
	move_speed *= 1.5
	attack_power = int(attack_power * 1.4)
	
	spawn_floating_text("💢 THOÁT CẦU! CUỒNG NỘ (+50% TỐC ĐỘ)!", Color(1.0, 0.15, 0.15))
	# Howl to call pack when escaping sphere!
	if is_instance_valid(player_ref):
		pack_howl_alert(player_ref)

func spawn_floating_text(txt: String, color: Color) -> void:
	var float_node = FLOATING_TEXT_SCENE.instantiate()
	float_node.global_position = global_position + Vector2(randf_range(-12, 12), -28)
	float_node.text = txt
	float_node.color = color
	get_parent().add_child(float_node)
