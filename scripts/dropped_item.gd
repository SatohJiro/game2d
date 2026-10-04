extends Node2D
class_name DroppedItem

@export var item_name: String = "Gỗ"
@export var item_id: StringName = &""
@export var count: int = 1
@export var texture_override: Texture2D = null

var target_player: CharacterBody2D = null
var is_attracted: bool = false
var velocity: Vector2 = Vector2.ZERO
var bounce_offset: float = 0.0
var time_alive: float = 0.0

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var shadow: Sprite2D = $Shadow

func _ready() -> void:
	add_to_group("dropped_items")
	setup_visual()
	
	# Initial bounce pop animation
	var angle = randf_range(0, TAU)
	var speed = randf_range(35.0, 70.0)
	var pop_dir = Vector2(cos(angle), sin(angle))
	
	var tween = create_tween()
	var dest = global_position + pop_dir * speed
	tween.tween_property(self, "global_position", dest, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Squash & stretch on landing
	var bounce_tween = create_tween()
	bounce_tween.tween_property(visual, "position:y", -14.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property(visual, "position:y", 0.0, 0.17).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func setup_visual() -> void:
	if not sprite: return
	if texture_override:
		sprite.texture = texture_override
		return
	
	var visual_key := String(get_resolved_item_id())
	if visual_key.is_empty():
		visual_key = item_name
	match visual_key:
		"item.wood": sprite.texture = preload("res://assets/items/wood.png")
		"Gỗ": sprite.texture = preload("res://assets/items/wood.png")
		"Đá": sprite.texture = preload("res://assets/items/stone.png")
		"Quặng Pal": sprite.texture = preload("res://assets/items/pal_ore.png")
		"Thỏi Sắt": sprite.texture = preload("res://assets/items/iron_ingot.png")
		"Thỏi Pal": sprite.texture = preload("res://assets/items/pal_ingot.png")
		"Quả Mọng Hồi Máu": sprite.texture = preload("res://assets/items/berry.png")
		"Thịt Tươi": sprite.texture = preload("res://assets/items/beaf.png")
		_: sprite.texture = preload("res://assets/items/wood.png")

func _process(delta: float) -> void:
	time_alive += delta
	
	if not is_attracted:
		# Floating idle bobbing
		visual.position.y = sin(time_alive * 4.0) * 2.5
		
		# Check for player magnetic radius
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p = players[0]
			if is_instance_valid(p) and global_position.distance_to(p.global_position) < 70.0:
				target_player = p
				is_attracted = true
	else:
		if is_instance_valid(target_player):
			var dir = (target_player.global_position - global_position).normalized()
			var dist = global_position.distance_to(target_player.global_position)
			var fly_speed = clampf(380.0 + (100.0 - dist) * 4.0, 320.0, 750.0)
			global_position += dir * fly_speed * delta
			
			# Collected
			if dist < 20.0:
				collect()
		else:
			is_attracted = false

func collect() -> void:
	if not is_instance_valid(target_player):
		return

	var collected := false
	var resolved_item_id := get_resolved_item_id()
	if not resolved_item_id.is_empty() and target_player.has_method("add_item_by_id"):
		collected = bool(target_player.call("add_item_by_id", resolved_item_id, count))
	elif target_player.has_method("add_item"):
		collected = bool(target_player.call("add_item", item_name, count))

	if collected:
		target_player.spawn_floating_text("+%d %s" % [count, item_name], Color(0.4, 1.0, 0.6))
		queue_free()


func get_resolved_item_id() -> StringName:
	if ContentId.is_valid(item_id):
		return item_id
	return LegacyItemAdapter.to_content_id(item_name)
