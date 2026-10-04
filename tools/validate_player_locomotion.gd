extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_stamina_and_sprint()
	_test_roll_lifecycle()
	_test_velocity_precedence_and_multipliers()
	_test_zero_large_delta_and_determinism()
	await _test_player_adapter()
	await _clean_tree()
	if _failures.is_empty():
		print("Player locomotion validation passed: stamina, sprint, roll, velocity precedence and Player adapter are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			printerr("PLAYER LOCOMOTION VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _test_stamina_and_sprint() -> void:
	var state := PlayerLocomotionState.new()
	state.set_stamina(90.0)
	var idle := state.tick(0.5, PlayerMovementInput.new(), Vector2.ZERO, 175.0, 245.0, 1.0, 0.5)
	_expect(is_equal_approx(state.stamina, 94.5), "idle stamina regen multiplier mismatch")
	_expect(not idle.is_sprinting and idle.velocity == Vector2.ZERO, "idle result mismatch")

	state.set_stamina(100.0)
	var sprint := state.tick(1.0, PlayerMovementInput.new(Vector2.RIGHT, true), Vector2.ZERO, 175.0, 245.0, 1.0, 1.0)
	_expect(sprint.is_sprinting, "valid sprint input must activate sprint")
	_expect(is_equal_approx(state.stamina, 76.0), "sprint stamina drain mismatch")
	_expect(sprint.velocity == Vector2(245.0, 0.0), "sprint target velocity mismatch")

	state.set_stamina(PlayerLocomotionState.SPRINT_MIN_STAMINA)
	var exhausted := state.tick(1.0, PlayerMovementInput.new(Vector2.RIGHT, true), Vector2.ZERO, 175.0, 245.0, 1.0, 1.0)
	_expect(not exhausted.is_sprinting, "sprint at minimum threshold must be rejected")
	_expect(exhausted.velocity == Vector2(175.0, 0.0), "rejected sprint must use walk speed")
	_expect(is_equal_approx(state.stamina, 23.0), "rejected sprint must use idle regen rule")


func _test_roll_lifecycle() -> void:
	var state := PlayerLocomotionState.new()
	_expect(state.try_start_roll(Vector2(2.0, 0.0)), "roll should start with sufficient stamina")
	_expect(state.stamina == 80.0 and state.is_invulnerable, "roll start must pay cost and enable invulnerability")
	_expect(not state.try_start_roll(Vector2.UP), "active roll must reject a second start")

	var active := state.tick(0.10, PlayerMovementInput.new(), Vector2.ZERO, 175.0, 245.0, 1.0, 1.0)
	_expect(active.roll_frame and active.is_rolling and active.is_invulnerable, "active roll result mismatch")
	_expect(is_equal_approx(active.velocity.x, 296.875), "roll decay velocity mismatch")
	var recovery := state.tick(0.17, PlayerMovementInput.new(), active.velocity, 175.0, 245.0, 1.0, 1.0)
	_expect(recovery.roll_frame and recovery.is_rolling and not recovery.is_invulnerable, "roll recovery must end i-frames before movement")
	var ended := state.tick(0.05, PlayerMovementInput.new(), recovery.velocity, 175.0, 245.0, 1.0, 1.0)
	_expect(ended.roll_frame and ended.roll_ended and not ended.is_rolling, "roll end transition mismatch")
	_expect(ended.velocity == Vector2.ZERO, "roll end must stop roll velocity")

	state.set_stamina(19.0)
	_expect(not state.try_start_roll(Vector2.RIGHT), "roll must reject insufficient stamina")
	_expect(state.stamina == 19.0, "rejected roll must not consume stamina")


func _test_velocity_precedence_and_multipliers() -> void:
	var state := PlayerLocomotionState.new()
	var knockback := state.tick(0.1, PlayerMovementInput.new(), Vector2(500.0, 0.0), 175.0, 245.0, 1.0, 1.0)
	_expect(knockback.velocity == Vector2(410.0, 0.0), "idle locomotion must decay external knockback instead of resetting it")

	var limited := PlayerLocomotionState.new().tick(1.0, PlayerMovementInput.new(Vector2.RIGHT), Vector2.ZERO, 175.0, 245.0, 0.5, 1.0)
	_expect(limited.velocity == Vector2(87.5, 0.0), "needs movement multiplier integration mismatch")


func _test_zero_large_delta_and_determinism() -> void:
	var paused := PlayerLocomotionState.new()
	paused.set_stamina(50.0)
	var zero := paused.tick(0.0, PlayerMovementInput.new(Vector2.RIGHT, true), Vector2(12.0, 3.0), 175.0, 245.0, 1.0, 1.0)
	_expect(paused.stamina == 50.0 and not paused.is_sprinting, "zero delta must preserve locomotion state")
	_expect(zero.velocity == Vector2(12.0, 3.0), "zero delta must preserve current velocity")

	var large := PlayerLocomotionState.new()
	large.tick(100.0, PlayerMovementInput.new(Vector2.RIGHT, true), Vector2.ZERO, 175.0, 245.0, 1.0, 1.0)
	_expect(large.stamina == 0.0, "large sprint delta must clamp stamina at zero")
	large.set_stamina(100.0)
	large.try_start_roll(Vector2.DOWN)
	var ended := large.tick(100.0, PlayerMovementInput.new(), Vector2.ZERO, 175.0, 245.0, 1.0, 1.0)
	_expect(ended.roll_ended and ended.velocity == Vector2.ZERO, "large roll delta must resolve a clean end")

	var first := PlayerLocomotionState.new()
	var second := PlayerLocomotionState.new()
	var input := PlayerMovementInput.new(Vector2(1.0, 1.0), true)
	var first_result := first.tick(0.25, input, Vector2(20.0, -10.0), 175.0, 245.0, 0.8, 0.5)
	var second_result := second.tick(0.25, input, Vector2(20.0, -10.0), 175.0, 245.0, 0.8, 0.5)
	_expect(first_result.velocity.is_equal_approx(second_result.velocity), "same locomotion input must resolve deterministic velocity")
	_expect(first.stamina == second.stamina and first.is_sprinting == second.is_sprinting, "same locomotion input must resolve deterministic state")


func _test_player_adapter() -> void:
	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	if packed_main == null:
		_failures.append("unable to load main scene")
		return
	var main_scene := packed_main.instantiate()
	root.add_child(main_scene)
	for frame in range(5):
		await process_frame

	var player := get_first_node_in_group("player")
	_expect(player != null and player.has_method("read_movement_input"), "Player locomotion adapter is missing")
	if player == null:
		return
	var player_parent := player.get_parent()
	player_parent.remove_child(player)
	var state: PlayerLocomotionState = player.get("locomotion_state")
	_expect(state != null, "Player locomotion state is missing")
	if state != null:
		player.set("stamina", 42.0)
		_expect(state.stamina == 42.0, "legacy stamina property must write the state source of truth")
		player.set("max_stamina", 35.0)
		_expect(state.max_stamina == 35.0 and state.stamina == 35.0, "legacy max stamina property must clamp state")
		state.try_start_roll(Vector2.LEFT)
		_expect(bool(player.get("is_rolling")) and bool(player.get("is_invulnerable")), "legacy roll properties must read locomotion state")
	player.free()


func _clean_tree() -> void:
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
