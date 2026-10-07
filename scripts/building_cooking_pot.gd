extends StaticBody2D
class_name BuildingCookingPot

@export var max_health: int = 200
var health: int = 200
var _pending_restored_health: int = -1

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var fire_light: PointLight2D = $Visual/FireLight
@onready var smoke_particles: CPUParticles2D = $Visual/SmokeParticles
@onready var label: Label = $Label
@onready var interaction_area: Area2D = $InteractionArea

var is_cooking: bool = false
var cooking_timer: float = 0.0
var cooking_duration: float = 3.0
var current_recipe: Dictionary = {}
var player_in_range: CharacterBody2D = null

const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")
const DROPPED_ITEM_SCENE = preload("res://scenes/dropped_item.tscn")

var cooking_recipes: Array[Dictionary] = [
	{
		"id": "cooked_meat",
		"name": "Thịt Nướng Xông Khói",
		"desc": "Thịt thơm lừng giòn rụm (+50 Đói, +30 Máu, Buff Giữ Ấm 3p)",
		"icon": preload("res://assets/items/cooked_meat.png"),
		"cost": {"Thịt Tươi": 1, "Gỗ": 1},
		"yield_item": "Thịt Nướng Xông Khói",
		"cook_time": 2.5
	},
	{
		"id": "hearty_stew",
		"name": "Súp Hầm Sơn Hào",
		"desc": "Bồi bổ sinh lực (+70 Đói, +40 Khát, +60 Máu, Tăng hồi thể lực)",
		"icon": preload("res://assets/items/hearty_stew.png"),
		"cost": {"Thịt Tươi": 1, "Quả Mọng Hồi Máu": 2, "Gỗ": 1},
		"yield_item": "Súp Hầm Sơn Hào",
		"cook_time": 3.5
	},
	{
		"id": "purified_water",
		"name": "Nước Tinh Khiết Đun Sôi",
		"desc": "Nước uống thanh lọc an toàn (+60 Khát, Giải mọi độc tố)",
		"icon": preload("res://assets/items/purified_water.png"),
		"cost": {"Gỗ": 1},
		"yield_item": "Nước Tinh Khiết Đun Sôi",
		"cook_time": 1.8
	},
	{
		"id": "berry_jam",
		"name": "Mứt Dâu Rừng Dẻo",
		"desc": "Ngọt ngào thanh mát (+40 Đói, +30 Thể lực, +15% Tốc độ chạy)",
		"icon": preload("res://assets/items/strawberry.png"),
		"cost": {"Quả Mọng Hồi Máu": 3, "Gỗ": 1},
		"yield_item": "Mứt Dâu Rừng Dẻo",
		"cook_time": 2.0
	},
	{
		"id": "fresh_bread",
		"name": "Bánh Mì Lúa Mì Nướng",
		"desc": "Thơm bùi ấm bụng (+55 Đói, Giảm 50% tốc độ tụt đói trong 5p)",
		"icon": preload("res://assets/items/bread.png"),
		"cost": {"Lúa Mì Hoàng Kim": 2, "Gỗ": 1},
		"yield_item": "Bánh Mì Lúa Mì Nướng",
		"cook_time": 2.8
	}
]

func _ready() -> void:
	add_to_group("cooking_pots")
	add_to_group("heat_sources") # Allows warming player up in cold weather!
	add_to_group("buildings")
	health = _pending_restored_health if _pending_restored_health >= 1 else max_health
	_pending_restored_health = -1
	label.visible = false
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = body as CharacterBody2D
		label.visible = true
		label.text = "[E] Bếp Nấu Ăn Dã Ngoại"

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		label.visible = false
		close_cooking_menu()

func _process(delta: float) -> void:
	# Subtle flame flicker
	if fire_light:
		fire_light.energy = 0.95 + sin(Time.get_ticks_msec() * 0.015) * 0.25
	
	if is_cooking:
		cooking_timer -= delta
		if smoke_particles:
			smoke_particles.emitting = true
		
		# Simmering wobble animation
		visual.position.x = sin(Time.get_ticks_msec() * 0.05) * 1.0
		visual.position.y = cos(Time.get_ticks_msec() * 0.04) * 0.8
		
		if cooking_timer <= 0:
			finish_cooking()
	else:
		visual.position = Vector2.ZERO
		if smoke_particles:
			smoke_particles.emitting = false

func interact(player_ref: CharacterBody2D) -> void:
	if is_cooking:
		spawn_floating_text("🍲 Đang nấu: %.1fs..." % cooking_timer, Color(1.0, 0.85, 0.3))
		return
	open_cooking_menu(player_ref)

func open_cooking_menu(player_ref: CharacterBody2D) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("open_cooking_modal"):
		hud.open_cooking_modal(self, player_ref, cooking_recipes)

func close_cooking_menu() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("close_cooking_modal"):
		hud.close_cooking_modal()

func start_cooking(recipe: Dictionary, player_ref: CharacterBody2D) -> bool:
	if is_cooking:
		return false
	
	# Verify costs
	var cost = recipe.get("cost", {})
	for item in cost:
		if player_ref.inventory.get(item, 0) < cost[item]:
			spawn_floating_text("Thiếu nguyên liệu: %s!" % item, Color(1.0, 0.35, 0.35))
			return false
	
	# Deduct costs
	for item in cost:
		player_ref.inventory[item] -= cost[item]
	player_ref.update_hud()
	
	current_recipe = recipe
	is_cooking = true
	cooking_duration = recipe.get("cook_time", 2.5)
	cooking_timer = cooking_duration
	
	spawn_floating_text("🔥 Bắt đầu nấu: %s..." % recipe.get("name", ""), Color(1.0, 0.75, 0.2))
	if AudioManager:
		AudioManager.play_sound("shake")
	
	# Squash stretch puff
	var tw = create_tween()
	tw.tween_property(visual, "scale", Vector2(1.2, 0.8), 0.15)
	tw.tween_property(visual, "scale", Vector2.ONE, 0.15)
	return true

func finish_cooking() -> void:
	is_cooking = false
	var yield_item = current_recipe.get("yield_item", "Thịt Nướng Xông Khói")
	
	if player_in_range and is_instance_valid(player_in_range):
		player_in_range.add_item(yield_item, 1)
		spawn_floating_text("✨ NẤU XONG: +1 %s!" % yield_item, Color(0.3, 1.0, 0.4))
	else:
		var drop = DROPPED_ITEM_SCENE.instantiate()
		drop.item_name = yield_item
		drop.count = 1
		drop.global_position = global_position + Vector2(0, 14)
		get_parent().add_child(drop)
		spawn_floating_text("✨ Nấu xong: Rơi trên đất!", Color(0.3, 1.0, 0.4))
	
	if AudioManager:
		AudioManager.play_sound("success")
	
	var tw = create_tween()
	tw.tween_property(visual, "scale", Vector2(1.3, 1.3), 0.15).set_trans(Tween.TRANS_BACK)
	tw.tween_property(visual, "scale", Vector2.ONE, 0.2)


func create_persistence_state() -> CookingPotPlacementState:
	if not is_cooking:
		return CookingPotPlacementState.new(&"", 0.0, health)
	return CookingPotPlacementState.new(
		CookingRecipeCatalog.from_legacy(String(current_recipe.get("id", ""))),
		cooking_timer,
		health
	)


func apply_persistence_state(state: CookingPotPlacementState) -> bool:
	if state == null or not state.is_valid():
		return false
	var resolved_recipe: Dictionary = {}
	if state.recipe_id != &"":
		var legacy_id := CookingRecipeCatalog.to_legacy(state.recipe_id)
		for recipe: Dictionary in cooking_recipes:
			if String(recipe.get("id", "")) == legacy_id:
				resolved_recipe = recipe.duplicate(true)
				break
		if resolved_recipe.is_empty():
			return false
	_commit_restored_health(state.health)
	if state.recipe_id == &"":
		is_cooking = false
		cooking_timer = 0.0
		current_recipe = {}
		return true
	current_recipe = resolved_recipe
	cooking_duration = float(resolved_recipe.get("cook_time", 0.0))
	cooking_timer = state.remaining_seconds
	is_cooking = true
	return true


func _commit_restored_health(restored_health: int) -> void:
	if is_node_ready():
		health = restored_health
	else:
		_pending_restored_health = restored_health


func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	health -= amount
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.6, 0.4, 0.4), 0.08)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		queue_free()

func spawn_floating_text(txt: String, color: Color) -> void:
	var float_node = FLOATING_TEXT_SCENE.instantiate()
	float_node.global_position = global_position + Vector2(randf_range(-10, 10), -28)
	float_node.text = txt
	float_node.color = color
	get_parent().add_child(float_node)
