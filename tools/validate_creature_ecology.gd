extends SceneTree

const CREATURE_SCENE_PATH := "res://scenes/creature.tscn"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_damage_panic_policy()
	_test_transition_contract()
	await _test_actor_adapter()
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("Creature ecology validation passed: deterministic damage-panic policy and actor transition adapter are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			printerr("CREATURE ECOLOGY VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _test_damage_panic_policy() -> void:
	var panic := CreatureEcologyPolicy.resolve_damage_panic(CreatureEcologyRequest.new(&"creature.slime", true, 34, 100, false, false, false))
	_expect(panic.should_panic_flee(), "prey below 35 percent HP must panic")
	_expect(panic.transition_event_id == CreatureTransitionPolicy.EVENT_ECOLOGY_DAMAGE_PANIC, "panic result must expose stable transition event")
	_expect(is_equal_approx(panic.state_duration, 3.5), "panic duration compatibility mismatch")

	var boundary := CreatureEcologyPolicy.resolve_damage_panic(CreatureEcologyRequest.new(&"creature.slime", true, 35, 100, false, false, false))
	_expect(boundary.status == CreatureEcologyResult.Status.NO_CHANGE, "exactly 35 percent HP must not panic")
	_expect(CreatureEcologyPolicy.resolve_damage_panic(CreatureEcologyRequest.new(&"creature.flam", false, 1, 100, false, false, false)).status == CreatureEcologyResult.Status.NO_CHANGE, "neutral Flam must not use prey panic")
	_expect(CreatureEcologyPolicy.resolve_damage_panic(CreatureEcologyRequest.new(&"creature.slime", true, 1, 100, true, false, false)).status == CreatureEcologyResult.Status.NO_CHANGE, "defeated prey must not enter FLEE")
	_expect(CreatureEcologyPolicy.resolve_damage_panic(CreatureEcologyRequest.new(&"creature.slime", true, 1, 100, false, true, false)).status == CreatureEcologyResult.Status.NO_CHANGE, "enraged prey must not panic")
	_expect(CreatureEcologyPolicy.resolve_damage_panic(CreatureEcologyRequest.new(&"creature.slime", true, 1, 100, false, false, true)).status == CreatureEcologyResult.Status.PROTECTED, "capture-active prey must be protected")
	_expect(CreatureEcologyPolicy.resolve_damage_panic(null).status == CreatureEcologyResult.Status.INVALID_REQUEST, "null ecology request must be invalid")
	_expect(CreatureEcologyPolicy.resolve_damage_panic(CreatureEcologyRequest.new(&"item.wrong", true, 1, 100, false, false, false)).status == CreatureEcologyResult.Status.INVALID_REQUEST, "wrong species domain must be invalid")
	_expect(CreatureEcologyPolicy.resolve_damage_panic(CreatureEcologyRequest.new(&"creature.slime", true, 101, 100, false, false, false)).status == CreatureEcologyResult.Status.INVALID_REQUEST, "HP above max must be invalid")


func _test_transition_contract() -> void:
	var request := CreatureTransitionRequest.new(&"creature.state.legacy", CreatureTransitionPolicy.EVENT_ECOLOGY_DAMAGE_PANIC, true, true, 10.0, false, 3.5)
	var result := CreatureTransitionPolicy.resolve(request)
	_expect(result.is_changed() and result.to_state_id == CreatureTransitionPolicy.STATE_FLEE, "damage panic event must enter FLEE from legacy combat state")
	_expect(is_equal_approx(result.next_timer, 3.5) and result.target_action == CreatureTransitionResult.TargetAction.KEEP, "damage panic transition must preserve timer and threat target")
	var invalid_timer := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_CHASE, CreatureTransitionPolicy.EVENT_ECOLOGY_DAMAGE_PANIC, true, true, 10.0, false, 0.0))
	_expect(invalid_timer.status == CreatureTransitionResult.Status.INVALID_REQUEST, "damage panic transition must reject non-positive duration")


func _test_actor_adapter() -> void:
	var packed := load(CREATURE_SCENE_PATH) as PackedScene
	if packed == null:
		_failures.append("unable to load Creature scene")
		return
	var fixture := Node2D.new()
	root.add_child(fixture)

	var flam := packed.instantiate()
	fixture.add_child(flam)
	await process_frame
	flam.set("hp", 1)
	flam.set("max_hp", 80)
	flam.set("is_enraged", false)
	var flam_result: CreatureEcologyResult = flam.call("resolve_damage_panic", false)
	_expect(flam_result.status == CreatureEcologyResult.Status.NO_CHANGE, "typed neutral Flam actor must not panic at low HP")

	var slime := packed.instantiate()
	slime.set("species_index", 1)
	fixture.add_child(slime)
	await process_frame
	slime.set("hp", 30)
	slime.set("max_hp", 110)
	slime.set("is_enraged", false)
	var state_values: Dictionary = slime.get_script().get_script_constant_map().get("State", {})
	slime.set("state", int(state_values.get("CHASE", 2)))
	var slime_result: CreatureEcologyResult = slime.call("resolve_damage_panic", false)
	_expect(slime_result.should_panic_flee(), "legacy prey actor must preserve low-HP panic decision")
	var transition: CreatureTransitionResult = slime.call("resolve_creature_transition", slime_result.transition_event_id, true, slime_result.state_duration)
	_expect(bool(slime.call("apply_creature_transition", transition)), "actor must apply accepted ecology transition")
	_expect(int(slime.get("state")) == int(state_values.get("FLEE", 10)), "actor ecology adapter must enter FLEE")
	_expect(is_equal_approx(float(slime.get("state_timer")), 3.5), "actor ecology adapter must preserve 3.5-second duration")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
