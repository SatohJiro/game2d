extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_hp_curve_and_spheres()
	_test_status_modifiers_and_rolls()
	_test_invalid_and_guard_statuses()
	_test_determinism()
	await _test_creature_adapter()
	await _clean_tree()
	if _failures.is_empty():
		print("Capture validation passed: deterministic chance, injected roll, status modifiers and Creature adapter are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			printerr("CAPTURE VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _test_hp_curve_and_spheres() -> void:
	var full := CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 100, 100, 1.0, 0.5))
	var low := CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 25, 100, 1.0, 0.5))
	var zero := CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 0, 100, 1.0, 0.5))
	_expect(is_equal_approx(full.base_chance, 0.25), "full-HP base chance mismatch")
	_expect(is_equal_approx(low.base_chance, 0.775), "low-HP base chance mismatch")
	_expect(is_equal_approx(zero.base_chance, 0.95), "zero-HP base chance mismatch")

	var mega := CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 100, 100, 2.0, 0.5))
	var giga := CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 100, 100, 4.0, 0.5))
	var minimum := CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 100, 100, 0.1, 0.5))
	_expect(is_equal_approx(mega.final_chance, 0.5), "mega sphere multiplier mismatch")
	_expect(is_equal_approx(giga.final_chance, CaptureResolver.MAX_FINAL_CHANCE), "maximum final chance clamp mismatch")
	_expect(is_equal_approx(minimum.final_chance, CaptureResolver.MIN_FINAL_CHANCE), "minimum final chance clamp mismatch")


func _test_status_modifiers_and_rolls() -> void:
	var sleep_request := CaptureRequest.new(&"creature.test", 100, 100, 1.0, 0.5)
	sleep_request.is_asleep = true
	var sleep := CaptureResolver.resolve(sleep_request)
	_expect(is_equal_approx(sleep.applied_multiplier, 1.4), "sleep multiplier bonus mismatch")
	_expect(is_equal_approx(sleep.final_chance, 0.35) and sleep.tags.has("sleep"), "sleep capture result mismatch")

	var back_request := CaptureRequest.new(&"creature.test", 100, 100, 1.0, 0.5)
	back_request.is_back_strike = true
	var back := CaptureResolver.resolve(back_request)
	_expect(is_equal_approx(back.applied_multiplier, 1.35), "back-strike multiplier bonus mismatch")
	_expect(is_equal_approx(back.final_chance, 0.3375) and back.tags.has("back_strike"), "back-strike result mismatch")

	var combined_request := CaptureRequest.new(&"creature.test", 100, 100, 1.0, 0.4375)
	combined_request.is_asleep = true
	combined_request.is_back_strike = true
	var combined := CaptureResolver.resolve(combined_request)
	_expect(is_equal_approx(combined.applied_multiplier, 1.75), "combined modifier mismatch")
	_expect(is_equal_approx(combined.final_chance, 0.4375), "combined final chance mismatch")
	_expect(combined.succeeded, "roll equal to chance must succeed")
	_expect(CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 100, 100, 1.0, 0.0)).succeeded, "roll zero must succeed")
	_expect(not CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 0, 100, 4.0, 1.0)).succeeded, "roll one must fail under 0.98 cap")


func _test_invalid_and_guard_statuses() -> void:
	_expect(CaptureResolver.resolve(null).status == CaptureResult.Status.INVALID_REQUEST, "null request status mismatch")
	_expect(CaptureResolver.resolve(CaptureRequest.new(&"", 1, 0, 1.0, 0.5)).status == CaptureResult.Status.INVALID_REQUEST, "zero max HP must be invalid")
	_expect(CaptureResolver.resolve(CaptureRequest.new(&"", 101, 100, 1.0, 0.5)).status == CaptureResult.Status.INVALID_REQUEST, "HP above max must be invalid")
	_expect(CaptureResolver.resolve(CaptureRequest.new(&"", 50, 100, 0.0, 0.5)).status == CaptureResult.Status.INVALID_REQUEST, "zero sphere multiplier must be invalid")
	_expect(CaptureResolver.resolve(CaptureRequest.new(&"", 50, 100, 1.0, -0.1)).status == CaptureResult.Status.INVALID_REQUEST, "negative roll must be invalid")
	_expect(CaptureResolver.resolve(CaptureRequest.new(&"", 50, 100, 1.0, 1.1)).status == CaptureResult.Status.INVALID_REQUEST, "roll above one must be invalid")

	var invalid_target := CaptureRequest.new(&"", 50, 100, 1.0, 0.5)
	invalid_target.target_valid = false
	_expect(CaptureResolver.resolve(invalid_target).status == CaptureResult.Status.INVALID_TARGET, "invalid target status mismatch")
	var capturing := CaptureRequest.new(&"", 50, 100, 1.0, 0.5)
	capturing.already_capturing = true
	_expect(CaptureResolver.resolve(capturing).status == CaptureResult.Status.ALREADY_CAPTURING, "duplicate capture status mismatch")
	var defeated := CaptureRequest.new(&"", 0, 100, 1.0, 0.5)
	defeated.already_defeated = true
	_expect(CaptureResolver.resolve(defeated).status == CaptureResult.Status.ALREADY_DEFEATED, "defeated target status mismatch")


func _test_determinism() -> void:
	var request := CaptureRequest.new(&"creature.test", 30, 120, 2.0, 0.42)
	request.is_asleep = true
	request.is_back_strike = true
	var first := CaptureResolver.resolve(request)
	var second := CaptureResolver.resolve(request)
	_expect(first.status == second.status and first.succeeded == second.succeeded, "same request must resolve the same status/outcome")
	_expect(is_equal_approx(first.final_chance, second.final_chance), "same request must resolve the same chance")
	_expect(first.tags == second.tags, "same request must resolve the same tags")


func _test_creature_adapter() -> void:
	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	if packed_main == null:
		_failures.append("unable to load main scene")
		return
	var main_scene := packed_main.instantiate()
	root.add_child(main_scene)
	for frame in range(5):
		await process_frame

	var creature := get_first_node_in_group("wild_creatures")
	_expect(creature != null and creature.has_method("resolve_capture_request"), "Creature capture adapter is missing")
	if creature == null:
		return
	var creature_parent := creature.get_parent()
	creature_parent.remove_child(creature)
	var script_constants: Dictionary = creature.get_script().get_script_constant_map()
	var state_values: Dictionary = script_constants.get("State", {})
	creature.set("state", int(state_values.get("SLEEP", -1)))
	creature.set("facing_row", 0)
	var throw_position: Vector2 = creature.global_position + Vector2.UP * 10.0
	var request: CaptureRequest = creature.call("create_capture_request", 1.0, 0.0, throw_position)
	_expect(request.is_asleep, "Creature adapter must snapshot sleep before CAPTURING transition")
	_expect(request.is_back_strike, "Creature adapter back-strike projection mismatch")
	var result: CaptureResult = creature.call("resolve_capture_request", request)
	_expect(result.is_resolved() and result.tags.has("sleep") and result.tags.has("back_strike"), "Creature adapter modifier resolution mismatch")

	creature.set("capture_attempt_active", true)
	var duplicate_request: CaptureRequest = creature.call("create_capture_request", 1.0, 0.0, Vector2.ZERO)
	var duplicate: CaptureResult = creature.call("resolve_capture_request", duplicate_request)
	_expect(duplicate.status == CaptureResult.Status.ALREADY_CAPTURING, "Creature adapter must reject concurrent capture")
	creature.free()


func _clean_tree() -> void:
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
