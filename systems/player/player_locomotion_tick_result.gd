class_name PlayerLocomotionTickResult
extends RefCounted

var velocity: Vector2
var move_direction: Vector2
var is_sprinting: bool
var roll_frame: bool
var is_rolling: bool
var is_invulnerable: bool
var roll_ended: bool


func _init(
	resolved_velocity: Vector2,
	resolved_move_direction: Vector2,
	sprinting: bool,
	consumed_by_roll: bool,
	rolling: bool,
	invulnerable: bool,
	did_roll_end: bool = false
) -> void:
	velocity = resolved_velocity
	move_direction = resolved_move_direction
	is_sprinting = sprinting
	roll_frame = consumed_by_roll
	is_rolling = rolling
	is_invulnerable = invulnerable
	roll_ended = did_roll_end
