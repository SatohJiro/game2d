class_name PlayerMovementInput
extends RefCounted

var move_direction: Vector2
var sprint_held: bool


func _init(initial_move_direction: Vector2 = Vector2.ZERO, initial_sprint_held: bool = false) -> void:
	move_direction = initial_move_direction.normalized() if initial_move_direction.length_squared() > 1.0 else initial_move_direction
	sprint_held = initial_sprint_held
