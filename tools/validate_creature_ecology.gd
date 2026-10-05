extends SceneTree

const CREATURE_SCENE_PATH := "res://scenes/creature.tscn"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_damage_panic_policy()
	_test_prey_selection_policy()
	_test_transition_contract()
	await _test_actor_adapter()
	await create_timer(1.0).timeout
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("Creature ecology validation passed: damage panic, deterministic prey selection and actor adapters are valid.")
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
	var hunt := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_IDLE, CreatureTransitionPolicy.EVENT_ECOLOGY_PREY_ACQUIRED, true, false, -1.0, false, 6.0))
	_expect(hunt.is_changed() and hunt.to_state_id == CreatureTransitionPolicy.STATE_HUNTING_PREY and is_equal_approx(hunt.next_timer, 6.0), "prey acquisition event must enter six-second hunt")


func _test_prey_selection_policy() -> void:
	var candidates: Array[CreatureEcologyCandidate] = [
		CreatureEcologyCandidate.new(&"candidate.far", &"creature.slime", true, false, 180.0),
		CreatureEcologyCandidate.new(&"candidate.near_z", &"creature.mushroom", true, false, 40.0),
		CreatureEcologyCandidate.new(&"candidate.near_a", &"creature.slime", true, false, 40.0),
	]
	var selected := CreatureEcologySelectionPolicy.resolve(CreatureEcologySelectionRequest.new(&"creature.beast", true, false, candidates))
	_expect(selected.is_selected(), "predator must select an eligible prey")
	_expect(selected.candidate_key == &"candidate.near_a", "nearest tie must use lexical scan-local key")
	_expect(is_equal_approx(selected.distance, 40.0) and is_equal_approx(selected.hunt_duration, 6.0), "selection distance/duration mismatch")

	var duplicates: Array[CreatureEcologyCandidate] = [
		CreatureEcologyCandidate.new(&"candidate.same", &"creature.slime", true, false, 100.0),
		CreatureEcologyCandidate.new(&"candidate.same", &"creature.slime", true, false, 60.0),
	]
	var duplicate_selected := CreatureEcologySelectionPolicy.resolve(CreatureEcologySelectionRequest.new(&"creature.beast", true, false, duplicates))
	_expect(duplicate_selected.is_selected() and is_equal_approx(duplicate_selected.distance, 60.0), "duplicate candidate key must deterministically keep nearest observation")

	var filtered: Array[CreatureEcologyCandidate] = [
		CreatureEcologyCandidate.new(&"candidate.capture", &"creature.slime", true, true, 10.0),
		CreatureEcologyCandidate.new(&"candidate.boundary", &"creature.slime", true, false, 210.0),
		CreatureEcologyCandidate.new(&"candidate.neutral", &"creature.flam", false, false, 20.0),
		CreatureEcologyCandidate.new(&"", &"item.invalid", true, false, 5.0),
	]
	_expect(CreatureEcologySelectionPolicy.resolve(CreatureEcologySelectionRequest.new(&"creature.beast", true, false, filtered)).status == CreatureEcologySelectionResult.Status.NONE_AVAILABLE, "capture, neutral, invalid and exact-boundary candidates must be filtered")
	_expect(CreatureEcologySelectionPolicy.resolve(CreatureEcologySelectionRequest.new(&"creature.flam", false, false, candidates)).status == CreatureEcologySelectionResult.Status.NONE_AVAILABLE, "neutral actor must not select prey")
	_expect(CreatureEcologySelectionPolicy.resolve(CreatureEcologySelectionRequest.new(&"creature.beast", true, true, candidates)).status == CreatureEcologySelectionResult.Status.PROTECTED, "blocked predator must not select prey")
	_expect(CreatureEcologySelectionPolicy.resolve(null).status == CreatureEcologySelectionResult.Status.INVALID_REQUEST, "null selection request must be invalid")


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

	var predator := packed.instantiate()
	predator.set("species_index", 3)
	fixture.add_child(predator)
	var captured_prey := packed.instantiate()
	captured_prey.set("species_index", 1)
	fixture.add_child(captured_prey)
	var eligible_prey := packed.instantiate()
	eligible_prey.set("species_index", 2)
	fixture.add_child(eligible_prey)
	await process_frame
	predator.global_position = Vector2.ZERO
	captured_prey.global_position = Vector2(30.0, 0.0)
	eligible_prey.global_position = Vector2(100.0, 0.0)
	captured_prey.set("capture_attempt_active", true)
	var predator_states: Dictionary = predator.get_script().get_script_constant_map().get("State", {})
	predator.set("state", int(predator_states.get("IDLE", 0)))
	predator.call("check_predator_prey_ecosystem")
	_expect(int(predator.get("ecology_query_count")) == 1, "eligible predator must perform exactly one ecology query")
	_expect(predator.get("prey_target") == eligible_prey, "actor must ignore captured nearer prey and select eligible candidate")
	_expect(int(predator.get("state")) == int(predator_states.get("HUNTING_PREY", 14)), "selected predator must enter HUNTING_PREY")
	_expect(is_equal_approx(float(predator.get("state_timer")), 6.0), "actor hunt duration must remain six seconds")

	var query_before_block := int(predator.get("ecology_query_count"))
	predator.set("state", int(predator_states.get("CHASE", 2)))
	predator.call("check_predator_prey_ecosystem")
	_expect(int(predator.get("ecology_query_count")) == query_before_block, "blocked predator must skip group scan")
	var flam_queries_before := int(flam.get("ecology_query_count"))
	flam.call("check_predator_prey_ecosystem")
	_expect(int(flam.get("ecology_query_count")) == flam_queries_before, "typed neutral Flam must skip ecology group scan")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
