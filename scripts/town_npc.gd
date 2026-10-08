class_name TownNPC
extends CharacterBody2D

## AT-F: schedule-driven town NPC. Walks to its per-phase hangout spot,
## idles with a 4-frame cycle, and answers interact() with a dialogue line.

const SPEED := 42.0
const ARRIVE_DISTANCE := 12.0

var npc_id := &""
var _sprite: Sprite2D
var _target := Vector2.ZERO
var _anim_timer := 0.0
var _facing_row := 0
var _dialogue_label: Label

static var _float_scene: PackedScene


func setup(p_npc_id: StringName) -> void:
	npc_id = p_npc_id
	var data := NpcDB.find(npc_id)
	_sprite = Sprite2D.new()
	_sprite.texture = load(String(data["art"])) as Texture2D
	_sprite.hframes = 4
	_sprite.vframes = 4
	add_child(_sprite)
	var area := Area2D.new()
	area.name = "InteractArea"
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 26.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	var body_shape := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 8.0
	body_shape.shape = body_circle
	add_child(body_shape)
	global_position = data["home"] as Vector2
	_target = global_position


func _physics_process(delta: float) -> void:
	var to_target := _target - global_position
	if to_target.length() > ARRIVE_DISTANCE:
		var dir := to_target.normalized()
		velocity = dir * SPEED
		_anim_timer += delta * 8.0
		_facing_row = 3 if dir.x > 0.5 else (2 if dir.x < -0.5 else (0 if dir.y > 0 else 1))
	else:
		velocity = Vector2.ZERO
		_anim_timer = 0.0
	move_and_slide()
	if _sprite != null:
		_sprite.frame = _facing_row * 4 + (int(_anim_timer) % 4)


func set_phase(phase: StringName) -> void:
	var data := NpcDB.find(npc_id)
	if data.is_empty():
		return
	_target = NpcDB.spot_for(data, phase)


func interact(_player: Node) -> void:
	var data := NpcDB.find(npc_id)
	if data.is_empty():
		return
	_say(Localization.text(String(data["dialogue"])))


func interaction_prompt_name() -> StringName:
	return &"prompt.target.npc"


func _say(text: String) -> void:
	if _float_scene == null:
		_float_scene = load("res://scenes/floating_text.tscn") as PackedScene
	if _float_scene == null:
		return
	var label := _float_scene.instantiate() as Node2D
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(0, -28)
	if label.has_method("set_text"):
		label.set_text(text, Color(1.0, 0.95, 0.8))
