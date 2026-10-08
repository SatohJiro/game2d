class_name TownAnchor
extends Area2D

## AT-F: interactable town anchor (station, bulletin, shrine, fishing spot).
## Full systems (shop/fishing/quests) arrive in U5; the anchor registers the
## spot, shows a context prompt, and answers with a flavor line.

var anchor_id := &""
var dialogue_key := &""

static var _float_scene: PackedScene


func setup(p_anchor_id: StringName, p_dialogue_key: StringName) -> void:
	anchor_id = p_anchor_id
	dialogue_key = p_dialogue_key
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 36.0
	shape.shape = circle
	add_child(shape)


func interact(_player: Node) -> void:
	if _float_scene == null:
		_float_scene = load("res://scenes/floating_text.tscn") as PackedScene
	if _float_scene == null:
		return
	var label := _float_scene.instantiate() as Node2D
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(0, -40)
	if label.has_method("set_text"):
		label.set_text(Localization.text(String(dialogue_key)), Color(0.85, 0.95, 1.0))


func interaction_prompt_name() -> StringName:
	return &"prompt.target.town_anchor"
