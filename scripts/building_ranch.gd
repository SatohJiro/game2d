extends StaticBody2D
class_name BuildingRanch

@export var max_health: int = 350
var health: int = 350

var food_count: int = 8
var assigned_pets: Array[Dictionary] = []
var production_timer: float = 0.0

@onready var visual: Node2D = $Visual
@onready var prompt_label: Label = $PromptLabel
@onready var hay_bed: Sprite2D = $Visual/HayBed
@onready var feed_barrel: Sprite2D = $Visual/FeedBarrel

const DROPPED_ITEM_SCENE = preload("res://scenes/dropped_item.tscn")
const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")
const SHADOW_TEX = preload("res://assets/fx/shadow.png")

const PET_TEXTURES: Dictionary = {
	"Flam": preload("res://assets/monsters/flam_sheet.png"),
	"Slime": preload("res://assets/monsters/slime_sheet.png"),
	"Mushroom": preload("res://assets/monsters/mushroom_sheet.png"),
	"Beast": preload("res://assets/monsters/beast_sheet.png")
}

# Living visual animals wandering in the pen
var animal_nodes: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("buildings")
	add_to_group("ranches")
	health = max_health
	if prompt_label:
		prompt_label.visible = false
	
	if has_node("InteractArea"):
		var area = $InteractArea
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	# Default starter pet in ranch (Lovely Slime)
	if assigned_pets.size() == 0:
		assigned_pets.append({
			"assignment_id": RanchPlacementState.STARTER_RESIDENT_ID,
			"species_id": LegacySpeciesAdapter.SLIME_ID,
			"species_data": LegacySpeciesAdapter.create_runtime_snapshot_for_id(LegacySpeciesAdapter.SLIME_ID),
		})
	
	refresh_ranch_animals()

func refresh_ranch_animals() -> void:
	for entry in animal_nodes:
		if is_instance_valid(entry["node"]):
			entry["node"].queue_free()
	animal_nodes.clear()
	
	for i in range(assigned_pets.size()):
		var p_data = assigned_pets[i]
		var s_name = p_data.get("species_data", {}).get("name", "Slime")
		var a_node = Node2D.new()
		a_node.name = "RanchPet_" + str(i)
		
		# Shadow
		var shad = Sprite2D.new()
		shad.texture = SHADOW_TEX
		shad.scale = Vector2(0.7, 0.45)
		shad.position = Vector2(0, 8)
		shad.modulate = Color(0, 0, 0, 0.4)
		a_node.add_child(shad)
		
		# Sprite
		var spr = Sprite2D.new()
		spr.texture = PET_TEXTURES.get(s_name, PET_TEXTURES["Slime"])
		spr.hframes = 4
		spr.vframes = 4
		spr.frame = 0
		spr.scale = Vector2(1.1, 1.1)
		a_node.add_child(spr)
		
		var init_pos = Vector2(randf_range(-16, 16), randf_range(-10, 10))
		a_node.position = init_pos
		visual.add_child(a_node)
		
		animal_nodes.append({
			"node": a_node,
			"sprite": spr,
			"name": s_name,
			"state": "wander",
			"state_timer": randf_range(1.5, 3.5),
			"target_pos": init_pos,
			"anim_time": 0.0
		})

func _process(delta: float) -> void:
	# Update Living Ranch Pets
	for entry in animal_nodes:
		update_animal_behavior(entry, delta)
	
	if assigned_pets.size() == 0:
		return
	
	production_timer += delta
	# Production cycle every 10 seconds if food is available
	if production_timer >= 10.0:
		production_timer = 0.0
		produce_ranch_goods()

func update_animal_behavior(entry: Dictionary, delta: float) -> void:
	var a_node = entry["node"] as Node2D
	var spr = entry["sprite"] as Sprite2D
	if not is_instance_valid(a_node) or not is_instance_valid(spr):
		return
	
	entry["state_timer"] -= delta
	entry["anim_time"] += delta * 6.0
	
	match entry["state"]:
		"wander":
			var cur_pos = a_node.position
			var targ = entry["target_pos"] as Vector2
			var dir = (targ - cur_pos)
			if dir.length() > 2.0:
				a_node.position = cur_pos.move_toward(targ, 24.0 * delta)
				spr.scale.x = -1.1 if dir.x < 0 else 1.1
				spr.frame = int(entry["anim_time"]) % 4
				a_node.position.y += sin(Time.get_ticks_msec() * 0.01) * 0.4
			else:
				spr.frame = 0
			
			if entry["state_timer"] <= 0.0:
				var roll = randf()
				if roll < 0.35 and food_count > 0:
					# Go eat at feed barrel
					entry["state"] = "eat"
					entry["state_timer"] = randf_range(3.0, 5.0)
					entry["target_pos"] = Vector2(16, 2)
				elif roll < 0.65:
					# Go rest at hay bed
					entry["state"] = "sleep"
					entry["state_timer"] = randf_range(4.0, 7.0)
					entry["target_pos"] = Vector2(-12, -4)
				else:
					entry["state_timer"] = randf_range(2.0, 4.0)
					entry["target_pos"] = Vector2(randf_range(-22, 22), randf_range(-14, 14))
		
		"eat":
			var cur_pos = a_node.position
			var targ = entry["target_pos"] as Vector2
			if cur_pos.distance_to(targ) > 3.0:
				a_node.position = cur_pos.move_toward(targ, 32.0 * delta)
				spr.frame = int(entry["anim_time"]) % 4
			else:
				# Bobbing head down eating
				spr.frame = 0
				spr.position.y = sin(Time.get_ticks_msec() * 0.015) * 2.5
				if int(entry["state_timer"] * 10) % 25 == 0:
					spawn_mini_emotion(a_node.global_position, "🥣")
				
				if entry["state_timer"] <= 0.0:
					spr.position.y = 0.0
					entry["state"] = "wander"
					entry["state_timer"] = randf_range(2.0, 4.0)
					entry["target_pos"] = Vector2(randf_range(-20, 20), randf_range(-12, 12))
		
		"sleep":
			var cur_pos = a_node.position
			var targ = entry["target_pos"] as Vector2
			if cur_pos.distance_to(targ) > 3.0:
				a_node.position = cur_pos.move_toward(targ, 22.0 * delta)
				spr.frame = int(entry["anim_time"]) % 4
			else:
				# Sleep breathing on hay bed
				spr.frame = 0
				spr.scale.y = 0.85 + sin(Time.get_ticks_msec() * 0.003) * 0.06
				if int(entry["state_timer"] * 10) % 30 == 0:
					spawn_mini_emotion(a_node.global_position, "💤")
				
				if entry["state_timer"] <= 0.0:
					spr.scale.y = 1.1
					entry["state"] = "wander"
					entry["state_timer"] = randf_range(2.0, 4.0)
					entry["target_pos"] = Vector2(randf_range(-20, 20), randf_range(-12, 12))

func spawn_mini_emotion(pos: Vector2, icon: String) -> void:
	var float_node = FLOATING_TEXT_SCENE.instantiate()
	float_node.global_position = pos + Vector2(0, -18)
	float_node.text = icon
	float_node.color = Color(1.0, 0.9, 0.3)
	get_parent().add_child(float_node)

func produce_ranch_goods() -> void:
	if food_count <= 0:
		spawn_floating_text("Chuồng hết thức ăn! [Bấm E thêm thức ăn]", Color(1.0, 0.4, 0.4))
		return
	
	food_count -= 1
	
	for i in range(assigned_pets.size()):
		var pet_data = assigned_pets[i]
		var species_name = pet_data.get("species_data", {}).get("name", "Slime")
		var drop_name = "Thịt Tươi"
		var drop_count = 1
		
		match species_name:
			"Flam":
				drop_name = "Hạt Nhiệt Lửa"
				drop_count = randi_range(1, 2)
			"Slime":
				drop_name = "Tinh Chất Thạch Lam"
				drop_count = randi_range(2, 3)
			"Mushroom":
				drop_name = "Thảo Dược Pal"
				drop_count = randi_range(1, 2)
			"Beast":
				drop_name = "Thịt Tươi"
				drop_count = randi_range(1, 2)
			_:
				drop_name = "Quả Mọng Hồi Máu"
				drop_count = 2
		
		# Happy jump animation on animal
		if i < animal_nodes.size():
			var a_entry = animal_nodes[i]
			var a_spr = a_entry["sprite"] as Sprite2D
			if is_instance_valid(a_spr):
				var j_tw = create_tween()
				j_tw.tween_property(a_spr, "scale", Vector2(1.4, 0.7), 0.1)
				j_tw.tween_property(a_spr, "scale", Vector2(0.9, 1.4), 0.12)
				j_tw.tween_property(a_spr, "scale", Vector2(1.1, 1.1), 0.1)
		
		# Spawn physical dropped item inside ranch
		for j in range(drop_count):
			var item = DROPPED_ITEM_SCENE.instantiate()
			var spawn_pos = global_position + Vector2(randf_range(-22, 22), randf_range(-14, 16))
			item.global_position = spawn_pos
			item.item_name = drop_name
			item.amount = 1
			get_parent().add_child(item)
		
		spawn_floating_text("♥ %s sản xuất: +%d %s!" % [species_name, drop_count, drop_name], Color(0.4, 1.0, 0.5))
	
	if AudioManager:
		AudioManager.play_sound("pickup")

func interact(player: CharacterBody2D) -> void:
	if not player: return
	
	# Option 1: Add food if player has Berries or Wheat
	if player.inventory.get("Quả Mọng Hồi Máu", 0) > 0:
		player.inventory["Quả Mọng Hồi Máu"] -= 1
		food_count += 4
		player.update_hud()
		spawn_floating_text("+4 Thức ăn chuồng (Hiện có: %d)" % food_count, Color(0.3, 0.9, 1.0))
		if AudioManager:
			AudioManager.play_sound("pickup")
		update_prompt()
		return
	elif player.inventory.get("Lúa Mì Hoàng Kim", 0) > 0:
		player.inventory["Lúa Mì Hoàng Kim"] -= 1
		food_count += 8
		player.update_hud()
		spawn_floating_text("+8 Thức ăn thượng hạng! (Hiện có: %d)" % food_count, Color(1.0, 0.85, 0.2))
		if AudioManager:
			AudioManager.play_sound("pickup")
		update_prompt()
		return
	
	# Option 2: Assign pet from player party if slot open
	if player.pet_party.size() > 0 and assigned_pets.size() < 2:
		var pet_entry: Dictionary = player.pet_party[0].duplicate(true)
		pet_entry["assignment_id"] = pet_entry.get("instance_id", &"")
		assigned_pets.append(pet_entry)
		refresh_ranch_animals()
		spawn_floating_text("Đã đưa [%s] vào Chuồng Chăn Nuôi!" % pet_entry["species_data"]["name"], Color(0.4, 1.0, 0.5))
		if AudioManager:
			AudioManager.play_sound("powerup")
		update_prompt()
		return
	
	spawn_floating_text("Chuồng Pal: %d Pet | %d Thức ăn (Cần Quả mọng/Lúa mì)" % [assigned_pets.size(), food_count], Color(1.0, 0.8, 0.3))

func update_prompt() -> void:
	if not prompt_label: return
	prompt_label.text = "[E] Thêm Thức Ăn (%d) | Pet: %d/2" % [food_count, assigned_pets.size()]


func create_persistence_state() -> RanchPlacementState:
	var assignments: Array[Dictionary] = []
	for entry: Dictionary in assigned_pets:
		assignments.append({
			"assignment_id": StringName(entry.get("assignment_id", entry.get("instance_id", &""))),
			"species_id": StringName(entry.get("species_id", entry.get("species_data", {}).get("id", &""))),
		})
	return RanchPlacementState.new(food_count, assignments, production_timer)


func apply_persistence_state(state: RanchPlacementState) -> bool:
	if state == null or not state.is_valid():
		return false
	var restored: Array[Dictionary] = []
	for assignment: Dictionary in state.assignments:
		var species_id := StringName(assignment["species_id"])
		restored.append({
			"assignment_id": StringName(assignment["assignment_id"]),
			"instance_id": StringName(assignment["assignment_id"]) if StringName(assignment["assignment_id"]) != RanchPlacementState.STARTER_RESIDENT_ID else &"",
			"species_id": species_id,
			"species_data": LegacySpeciesAdapter.create_runtime_snapshot_for_id(species_id),
		})
	food_count = state.food_count
	assigned_pets = restored
	production_timer = state.production_timer
	return true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and prompt_label:
		update_prompt()
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and prompt_label:
		prompt_label.visible = false

func spawn_floating_text(txt: String, color: Color) -> void:
	var float_node = FLOATING_TEXT_SCENE.instantiate()
	float_node.global_position = global_position + Vector2(randf_range(-12, 12), -32)
	float_node.text = txt
	float_node.color = color
	get_parent().add_child(float_node)

func take_damage(amount: int) -> void:
	health -= amount
	var tween = create_tween()
	tween.tween_property(visual, "modulate", Color(1.5, 0.4, 0.4), 0.08)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		queue_free()
