extends Area2D

@export var damage: int = 25
var lifetime: float = 0.20
var hit_bodies: Array = []
var player_ref: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Animate slash frame 0 -> 3
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "frame", 3, lifetime)
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body in hit_bodies:
		return
	hit_bodies.append(body)
	
	if body.is_in_group("wild_creatures") and body.has_method("take_damage"):
		body.take_damage(damage, global_position, player_ref)
		spawn_hit_sparks(body.global_position)
		trigger_hitstop()
		if player_ref and player_ref.has_method("shake_camera"):
			player_ref.shake_camera(4.0)
	elif body.has_method("hit_by_tool"):
		body.hit_by_tool(damage, player_ref)
		spawn_hit_sparks(body.global_position)

func _on_area_entered(area: Node) -> void:
	var parent_obj = area.get_parent()
	if parent_obj and parent_obj.has_method("hit_by_tool") and not (parent_obj in hit_bodies):
		hit_bodies.append(parent_obj)
		parent_obj.hit_by_tool(damage, player_ref)
		spawn_hit_sparks(parent_obj.global_position)

func trigger_hitstop() -> void:
	Engine.time_scale = 0.08
	await get_tree().create_timer(0.045, false, false, true).timeout
	Engine.time_scale = 1.0

func spawn_hit_sparks(hit_pos: Vector2) -> void:
	if not is_inside_tree(): return
	for i in range(3):
		var spark = Sprite2D.new()
		spark.texture = preload("res://assets/fx/spark.png")
		spark.modulate = Color(2.5, 1.8, 0.4)
		spark.global_position = hit_pos + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		get_parent().add_child(spark)
		
		var tw = create_tween()
		var dir = Vector2(randf_range(-24, 24), randf_range(-24, 24))
		tw.tween_property(spark, "global_position", spark.global_position + dir, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(spark, "scale", Vector2(0.3, 0.3), 0.18)
		tw.chain().tween_callback(spark.queue_free)
