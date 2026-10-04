extends StaticBody2D
class_name BuildingChest

@export var max_health: int = 250
var health: int = 250

var stored_items: Dictionary = {
	"Gỗ": 0,
	"Đá": 0,
	"Quặng Pal": 0,
	"Thỏi Sắt": 0,
	"Thỏi Pal": 0,
	"Quả Mọng Hồi Máu": 0
}

@onready var visual: Sprite2D = $Sprite2D
@onready var label: Label = $Label

const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")

func _ready() -> void:
	add_to_group("buildings")
	add_to_group("chests")
	health = max_health
	update_display()

func deposit_from_pet(item_name: String, amount: int) -> void:
	stored_items[item_name] = stored_items.get(item_name, 0) + amount
	spawn_floating_text("Pet cất +%d %s!" % [amount, item_name], Color(0.4, 1.0, 0.6))
	update_display()

func interact(player: CharacterBody2D) -> void:
	# Quick deposit all compatible items from player into chest
	var total_deposited = 0
	for item in stored_items.keys():
		var count = player.inventory.get(item, 0)
		if count > 0:
			stored_items[item] += count
			player.inventory[item] = 0
			total_deposited += count
	
	if total_deposited > 0:
		spawn_floating_text("Đã cất %d vật phẩm vào rương!" % total_deposited, Color(0.3, 0.9, 1.0))
		if AudioManager:
			AudioManager.play_sound("pickup")
		player.update_hud()
	else:
		# If player has nothing to deposit, withdraw 5 of everything available
		var withdrawn = 0
		for item in stored_items.keys():
			if stored_items[item] > 0:
				var take = min(10, stored_items[item])
				stored_items[item] -= take
				player.add_item(item, take)
				withdrawn += take
		if withdrawn > 0:
			spawn_floating_text("Rút %d vật phẩm từ rương!" % withdrawn, Color(1.0, 0.85, 0.3))
		else:
			spawn_floating_text("Rương đang trống!", Color(0.8, 0.8, 0.8))
	
	update_display()

func update_display() -> void:
	if not label: return
	var total = 0
	for count in stored_items.values():
		total += count
	label.text = "Rương Kho Đồ\n[E] Cất/Rút (%d món)" % total

func spawn_floating_text(text: String, color: Color) -> void:
	var ft = FLOATING_TEXT_SCENE.instantiate()
	ft.global_position = global_position + Vector2(0, -26)
	get_parent().add_child(ft)
	ft.set_text(text, color)

func take_damage(amount: int) -> void:
	health -= amount
	var tween = create_tween()
	tween.tween_property(visual, "modulate", Color(1.5, 0.4, 0.4), 0.08)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		queue_free()
