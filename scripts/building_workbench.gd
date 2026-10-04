extends StaticBody2D
class_name BuildingWorkbench

@export var max_health: int = 200
var health: int = 200

@onready var visual: Sprite2D = $Sprite2D
@onready var label: Label = $Label

func _ready() -> void:
	add_to_group("buildings")
	add_to_group("workbenches")
	health = max_health
	if label:
		label.visible = false

func interact(player: CharacterBody2D) -> void:
	if player.has_method("open_crafting_menu"):
		player.open_crafting_menu()

func take_damage(amount: int) -> void:
	health -= amount
	var tween = create_tween()
	tween.tween_property(visual, "modulate", Color(1.5, 0.4, 0.4), 0.08)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		queue_free()
