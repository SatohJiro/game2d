extends StaticBody2D
class_name BuildingTurret

@export var max_health: int = 350
var health: int = 350

var attack_range: float = 230.0
var fire_cooldown: float = 0.0
var damage: int = 32

@onready var visual: Sprite2D = $Sprite2D
@onready var barrel: Sprite2D = $Barrel
@onready var label: Label = $Label

const SPHERE_SCENE = preload("res://scenes/sphere.tscn")

func _ready() -> void:
	add_to_group("buildings")
	add_to_group("turrets")
	health = max_health
	if label:
		label.text = "Tháp Phòng Thủ"

func _physics_process(delta: float) -> void:
	if fire_cooldown > 0:
		fire_cooldown -= delta
	
	# Find nearest hostile creature
	var target = find_nearest_target()
	if target and is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		barrel.rotation = dir.angle()
		
		if fire_cooldown <= 0:
			fire_projectile(target, dir)
			fire_cooldown = 1.25

func find_nearest_target() -> Node2D:
	var creatures = get_tree().get_nodes_in_group("wild_creatures")
	var nearest: Node2D = null
	var min_dist = attack_range
	for c in creatures:
		if is_instance_valid(c) and c.hp > 0:
			var d = global_position.distance_to(c.global_position)
			if d < min_dist:
				min_dist = d
				nearest = c
	return nearest

func fire_projectile(target: Node2D, dir: Vector2) -> void:
	if not is_inside_tree(): return
	var p = Sprite2D.new()
	p.texture = preload("res://assets/fx/fireball.png")
	p.global_position = global_position + dir * 18.0
	p.scale = Vector2(1.2, 1.2)
	p.rotation = dir.angle()
	get_parent().add_child(p)
	
	if AudioManager:
		AudioManager.play_sound("sphere_throw")
	
	var tween = create_tween()
	var dest = target.global_position
	tween.tween_property(p, "global_position", dest, 0.28)
	tween.tween_callback(func():
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage, null)
		p.queue_free()
	)

func create_persistence_state() -> TurretPlacementState:
	return TurretPlacementState.new(clampf(fire_cooldown, 0.0, TurretPlacementState.FIRE_INTERVAL))

func apply_persistence_state(state: TurretPlacementState) -> bool:
	if state == null or not state.is_valid(): return false
	fire_cooldown = state.cooldown_remaining
	return true

func take_damage(amount: int) -> void:
	health -= amount
	var tween = create_tween()
	tween.tween_property(visual, "modulate", Color(1.6, 0.4, 0.4), 0.08)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		queue_free()
