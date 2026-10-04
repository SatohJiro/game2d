class_name PlayerLocomotionState
extends RefCounted

const SPRINT_MIN_STAMINA := 5.0
const SPRINT_DRAIN_PER_SECOND := 24.0
const STAMINA_REGEN_PER_SECOND := 18.0
const ROLL_STAMINA_COST := 20.0
const ROLL_DURATION := 0.32
const ROLL_INVULNERABLE_UNTIL := 0.06
const MOVE_ACCELERATION := 1200.0
const IDLE_DECELERATION := 900.0

var max_stamina: float = 100.0
var stamina: float = 100.0
var is_sprinting: bool = false
var is_rolling: bool = false
var is_invulnerable: bool = false
var roll_timer: float = 0.0
var roll_direction: Vector2 = Vector2.ZERO
var roll_speed: float = 380.0


func tick(
	delta: float,
	input: PlayerMovementInput,
	current_velocity: Vector2,
	move_speed: float,
	sprint_speed: float,
	movement_multiplier: float,
	stamina_regen_multiplier: float
) -> PlayerLocomotionTickResult:
	if delta <= 0.0:
		return _result(current_velocity, input.move_direction, false)

	if is_rolling:
		roll_timer = maxf(0.0, roll_timer - delta)
		is_invulnerable = roll_timer > ROLL_INVULNERABLE_UNTIL
		var roll_ended := is_zero_approx(roll_timer)
		var resolved_velocity := Vector2.ZERO
		if not roll_ended:
			var speed_ratio := roll_timer / ROLL_DURATION * 0.7 + 0.3
			resolved_velocity = roll_direction * roll_speed * speed_ratio
		else:
			is_rolling = false
			is_invulnerable = false
			is_sprinting = false
		return _result(resolved_velocity, input.move_direction, true, roll_ended)

	var direction := input.move_direction.normalized() if input.move_direction.length_squared() > 1.0 else input.move_direction
	is_sprinting = input.sprint_held and direction != Vector2.ZERO and stamina > SPRINT_MIN_STAMINA
	if is_sprinting:
		stamina = maxf(0.0, stamina - SPRINT_DRAIN_PER_SECOND * delta)
	else:
		stamina = minf(max_stamina, stamina + STAMINA_REGEN_PER_SECOND * stamina_regen_multiplier * delta)

	var base_speed := sprint_speed if is_sprinting else move_speed
	var target_velocity := direction * base_speed * maxf(0.0, movement_multiplier)
	var resolved_velocity := current_velocity.move_toward(
		target_velocity,
		(MOVE_ACCELERATION if direction != Vector2.ZERO else IDLE_DECELERATION) * delta
	)
	return _result(resolved_velocity, direction, false)


func try_start_roll(direction: Vector2) -> bool:
	if is_rolling or stamina < ROLL_STAMINA_COST:
		return false
	stamina -= ROLL_STAMINA_COST
	is_sprinting = false
	is_rolling = true
	is_invulnerable = true
	roll_timer = ROLL_DURATION
	roll_direction = direction.normalized() if direction != Vector2.ZERO else Vector2.ZERO
	return true


func set_stamina(value: float) -> void:
	stamina = clampf(value, 0.0, max_stamina)


func set_max_stamina(value: float) -> void:
	max_stamina = maxf(0.0, value)
	stamina = minf(stamina, max_stamina)


func restore_full_stamina() -> void:
	stamina = max_stamina


func _result(current_velocity: Vector2, move_direction: Vector2, roll_frame: bool, roll_ended: bool = false) -> PlayerLocomotionTickResult:
	return PlayerLocomotionTickResult.new(
		current_velocity,
		move_direction,
		is_sprinting,
		roll_frame,
		is_rolling,
		is_invulnerable,
		roll_ended
	)
