extends StaticBody2D
class_name BuildingFurnace

@export var max_health: int = 300
var health: int = 300

var ore_count: int = 0
var wood_count: int = 0
var iron_ingots_ready: int = 0
var pal_ingots_ready: int = 0

var smelt_timer: float = 0.0
var is_smelting: bool = false
var has_fire_pet_boost: bool = false

@onready var visual: Sprite2D = $Sprite2D
@onready var flame: ColorRect = $Flame
@onready var label: Label = $Label

const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")

func _ready() -> void:
	add_to_group("buildings")
	add_to_group("furnaces")
	health = max_health
	update_display()

func _process(delta: float) -> void:
	# Check for fire pet proximity
	has_fire_pet_boost = false
	var pets = get_tree().get_nodes_in_group("companion_pets")
	for pet in pets:
		if is_instance_valid(pet) and pet.species_index == 0: # Flam is species 0
			if global_position.distance_to(pet.global_position) < 80.0:
				has_fire_pet_boost = true
				break
	
	# Smelting logic
	if ore_count >= 2 and wood_count >= 1:
		is_smelting = true
		flame.visible = true
		flame.scale.y = 1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.35
		if has_fire_pet_boost:
			flame.color = Color(1.0, 0.4, 0.1, 0.95)
			smelt_timer += delta * 2.8 # 2.8x speed with Flam!
		else:
			flame.color = Color(1.0, 0.7, 0.2, 0.85)
			smelt_timer += delta
		
		if smelt_timer >= 5.0:
			smelt_timer = 0.0
			ore_count -= 2
			wood_count -= 1
			iron_ingots_ready += 1
			spawn_floating_text("+1 Thỏi Sắt!", Color(0.8, 0.9, 1.0))
			if AudioManager:
				AudioManager.play_sound("pickup")
			update_display()
	else:
		is_smelting = false
		flame.visible = false
		smelt_timer = 0.0

func interact(player: CharacterBody2D) -> void:
	# First, collect any ready ingots
	var collected = false
	if iron_ingots_ready > 0:
		player.add_item("Thỏi Sắt", iron_ingots_ready)
		spawn_floating_text("Nhận x%d Thỏi Sắt!" % iron_ingots_ready, Color(0.4, 1.0, 0.5))
		iron_ingots_ready = 0
		collected = true
	
	if pal_ingots_ready > 0:
		player.add_item("Thỏi Pal", pal_ingots_ready)
		spawn_floating_text("Nhận x%d Thỏi Pal!" % pal_ingots_ready, Color(0.3, 0.8, 1.0))
		pal_ingots_ready = 0
		collected = true
	
	# Deposit ore and wood from player if available
	var added = false
	var p_ore = player.inventory.get("Quặng Pal", 0)
	var p_wood = player.inventory.get("Gỗ", 0)
	
	if p_ore >= 2 and p_wood >= 1:
		var batch = min(p_ore / 2, p_wood)
		player.inventory["Quặng Pal"] -= batch * 2
		player.inventory["Gỗ"] -= batch
		ore_count += batch * 2
		wood_count += batch
		spawn_floating_text("Nạp x%d Quặng vào lò!" % (batch * 2), Color(1.0, 0.85, 0.3))
		added = true
		player.update_hud()
	
	if not collected and not added:
		spawn_floating_text("Cần ít nhất 2 Quặng Pal + 1 Gỗ để nung!", Color(1.0, 0.5, 0.5))
	
	update_display()

func update_display() -> void:
	if not label: return
	var status = ""
	if is_smelting:
		var boost_txt = " [LỬA FLAM 2.8x]" if has_fire_pet_boost else ""
		status = "\n🔥 Đang nung%s (%d Sắt sẵn sàng)" % [boost_txt, iron_ingots_ready]
	elif iron_ingots_ready > 0:
		status = "\n✨ Có %d Thỏi Sắt sẵn sàng [E nhận]" % iron_ingots_ready
	else:
		status = "\nTrống (Cần Quặng + Gỗ) [E nạp]"
	label.text = "Lò Luyện Kim" + status

func spawn_floating_text(text: String, color: Color) -> void:
	var ft = FLOATING_TEXT_SCENE.instantiate()
	ft.global_position = global_position + Vector2(0, -28)
	get_parent().add_child(ft)
	ft.set_text(text, color)

func take_damage(amount: int) -> void:
	health -= amount
	var tween = create_tween()
	tween.tween_property(visual, "modulate", Color(1.6, 0.4, 0.4), 0.08)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		queue_free()
