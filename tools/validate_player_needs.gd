extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_deterministic_tick_and_clamps()
	_test_buffs_and_modifiers()
	_test_snapshot_boundary()
	await _test_player_adapter()
	await _clean_tree()
	if _failures.is_empty():
		print("Player needs validation passed: deterministic state, buffs, snapshots and Player adapter are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			printerr("PLAYER NEEDS VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _test_deterministic_tick_and_clamps() -> void:
	var first := PlayerNeedsState.new()
	var second := PlayerNeedsState.new()
	first.set_temperature(30.0)
	second.set_temperature(30.0)
	var first_result := first.tick(10.0, true, false)
	var second_result := second.tick(10.0, true, false)
	_expect(is_equal_approx(first.hunger, 97.2), "normal hunger drain mismatch")
	_expect(is_equal_approx(first.thirst, 95.5), "sprint thirst drain mismatch")
	_expect(is_equal_approx(first.body_temperature, 28.5), "ambient cooling mismatch")
	_expect(_same_snapshot(first_result.snapshot, second_result.snapshot), "same input must produce the same snapshot")

	var before_pause := first.create_snapshot()
	first.tick(0.0, true, true)
	_expect(_same_snapshot(before_pause, first.create_snapshot()), "zero delta must preserve state")
	first.tick(1000.0, true, false)
	_expect(first.hunger == 0.0 and first.thirst == 0.0, "large delta must clamp needs at zero")
	_expect(is_equal_approx(first.body_temperature, PlayerNeedsState.AMBIENT_TEMPERATURE), "large delta must not overshoot ambient temperature")


func _test_buffs_and_modifiers() -> void:
	var state := PlayerNeedsState.new()
	state.set_hunger(10.0)
	state.set_thirst(10.0)
	state.set_temperature(20.0)
	_expect(is_equal_approx(state.get_movement_multiplier(), 0.68), "low thirst and cold movement multiplier mismatch")
	_expect(is_equal_approx(state.get_stamina_regen_multiplier(), 0.5), "low hunger stamina multiplier mismatch")

	state.set_buff(PlayerNeedsState.BUFF_SPEED, 5.0)
	_expect(is_equal_approx(state.get_movement_multiplier(), 0.782), "speed buff multiplier mismatch")
	var expiry := state.tick(5.0, false, false)
	_expect(expiry.buff_expired and state.buff_id == PlayerNeedsState.BUFF_NONE, "buff must expire on its boundary")
	_expect(not state.tick(1.0, false, false).buff_expired, "buff expiry must be reported exactly once")

	state.set_temperature(30.0)
	state.set_buff(PlayerNeedsState.BUFF_WARMTH, 2.0)
	state.tick(1.0, false, false)
	_expect(is_equal_approx(state.body_temperature, 31.5), "warmth buff must warm toward comfort temperature")
	state.set_hunger(95.0)
	state.set_thirst(95.0)
	state.restore_hunger(20.0)
	state.restore_thirst(20.0)
	_expect(state.hunger == 100.0 and state.thirst == 100.0, "restoration must clamp at configured maximum")


func _test_snapshot_boundary() -> void:
	var state := PlayerNeedsState.new()
	state.set_hunger(50.0)
	state.set_buff(PlayerNeedsState.BUFF_SLOW_HUNGER, 10.0)
	var snapshot := state.create_snapshot()
	state.tick(1.0, false, false)
	_expect(snapshot.hunger == 50.0, "snapshot must not change after state mutation")
	_expect(snapshot.buff_id == &"needs.buff.slow_hunger", "snapshot must expose stable buff ID")
	_expect(snapshot.buff_display_name == "No Lâu Giảm Đói", "snapshot display adapter mismatch")


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
	_expect(player != null, "main scene did not register a player")
	if player == null:
		return
	var player_parent := player.get_parent()
	player_parent.remove_child(player)
	var state: PlayerNeedsState = player.get("needs_state")
	_expect(state != null, "Player needs state adapter is missing")
	if state != null:
		player.set("hunger", 42.0)
		_expect(state.hunger == 42.0, "legacy hunger property must write the state source of truth")
		state.restore_thirst(10.0)
		_expect(float(player.get("thirst")) == state.thirst, "legacy thirst property must read the state source of truth")
		player.set("food_buff_name", "Tăng Tốc Chạy (+15%)")
		player.set("food_buff_timer", 12.0)
		_expect(state.buff_id == PlayerNeedsState.BUFF_SPEED and state.buff_time_remaining == 12.0, "legacy buff properties must map to stable state")
	player.free()


func _same_snapshot(first: PlayerNeedsSnapshot, second: PlayerNeedsSnapshot) -> bool:
	return (
		is_equal_approx(first.hunger, second.hunger)
		and is_equal_approx(first.thirst, second.thirst)
		and is_equal_approx(first.body_temperature, second.body_temperature)
		and first.buff_id == second.buff_id
		and is_equal_approx(first.buff_time_remaining, second.buff_time_remaining)
	)


func _clean_tree() -> void:
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
