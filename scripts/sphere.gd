extends Area2D

@export var max_arc_height: float = 55.0
var start_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var travel_time: float = 0.50
var elapsed_time: float = 0.0

var player_ref: Node2D = null
var catch_multiplier: float = 1.0
var item_id: StringName = CaptureSphereSelector.BASIC_ID
var sphere_name: String = "Cầu Thu Phục"
var has_hit: bool = false

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var shadow: Sprite2D = $Shadow

const DROPPED_ITEM_SCENE = preload("res://scenes/dropped_item.tscn")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	start_pos = global_position
	
	# Match visual sprite to sphere type
	if sprite:
		match item_id:
			CaptureSphereSelector.GIGA_ID: sprite.texture = preload("res://assets/items/giga_sphere.png")
			CaptureSphereSelector.MEGA_ID: sprite.texture = preload("res://assets/items/mega_sphere.png")
			_: sprite.texture = preload("res://assets/fx/energy_ball.png")


func configure_capture_sphere(new_item_id: StringName, new_catch_multiplier: float) -> bool:
	if not CaptureSphereSelector.is_supported(new_item_id):
		return false
	var expected_multiplier := CaptureSphereSelector.get_multiplier(new_item_id)
	if not is_equal_approx(new_catch_multiplier, expected_multiplier):
		return false
	item_id = new_item_id
	sphere_name = LegacyItemAdapter.to_legacy_key(item_id)
	catch_multiplier = expected_multiplier
	return not sphere_name.is_empty()

func launch(from_pos: Vector2, to_pos: Vector2) -> void:
	start_pos = from_pos
	target_pos = to_pos
	global_position = start_pos
	var distance = start_pos.distance_to(target_pos)
	travel_time = clampf(distance / 420.0, 0.35, 0.75)
	elapsed_time = 0.0

func _physics_process(delta: float) -> void:
	if has_hit:
		return
	
	elapsed_time += delta
	var t = clampf(elapsed_time / travel_time, 0.0, 1.0)
	
	# Horizontal ground position
	global_position = start_pos.lerp(target_pos, t)
	
	# Parabolic vertical flight arc
	var arc = 4.0 * max_arc_height * t * (1.0 - t)
	if visual:
		visual.position.y = -arc
	
	# Shadow scaling based on height
	if shadow:
		var shadow_scale = lerp(0.8, 0.45, arc / max_arc_height)
		shadow.scale = Vector2(shadow_scale, shadow_scale * 0.6)
	
	# Spin sphere in flight
	if sprite:
		sprite.rotation += delta * 18.0
	
	# Ground impact when reaching target
	if t >= 1.0:
		on_ground_impact()

func on_ground_impact() -> void:
	has_hit = true
	if AudioManager:
		AudioManager.play_sound("hit")
	
	# Spawn dust upon ground landing
	spawn_landing_dust()
	
	# If missed, drop as collectible item on the ground
	var drop := create_missed_drop()
	drop.global_position = global_position
	get_parent().call_deferred("add_child", drop)
	
	queue_free()


func create_missed_drop() -> Node2D:
	var drop := DROPPED_ITEM_SCENE.instantiate() as Node2D
	drop.set("item_id", item_id)
	drop.set("item_name", sphere_name)
	drop.set("count", 1)
	return drop

func spawn_landing_dust() -> void:
	if not is_inside_tree(): return
	var dust = Sprite2D.new()
	dust.texture = preload("res://assets/fx/dust.png")
	dust.global_position = global_position
	get_parent().add_child(dust)
	
	var tween = create_tween()
	tween.tween_property(dust, "scale", Vector2(1.5, 1.5), 0.28)
	tween.parallel().tween_property(dust, "modulate:a", 0.0, 0.28)
	tween.chain().tween_callback(dust.queue_free)

func _on_body_entered(body: Node) -> void:
	if has_hit: return
	if body.is_in_group("wild_creatures") and body.has_method("attempt_capture"):
		has_hit = true
		body.attempt_capture(player_ref, catch_multiplier, start_pos)
		queue_free()
