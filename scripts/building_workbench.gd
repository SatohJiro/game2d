extends StaticBody2D
class_name BuildingWorkbench

@export var max_health: int = 200
var health: int = 200
var _pending_restored_health: int = -1

@onready var visual: Sprite2D = $Sprite2D
@onready var label: Label = $Label

func _ready() -> void:
	add_to_group("buildings")
	add_to_group("workbenches")
	health = _pending_restored_health if _pending_restored_health >= 1 else max_health
	_pending_restored_health = -1
	if label:
		label.visible = false

func create_persistence_state() -> WorkbenchPlacementState:
	return WorkbenchPlacementState.new(health)

func apply_persistence_state(state: WorkbenchPlacementState) -> bool:
	if state == null or not state.is_valid(): return false
	if is_node_ready(): health = state.health
	else: _pending_restored_health = state.health
	return true

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
