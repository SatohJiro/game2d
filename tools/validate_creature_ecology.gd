extends SceneTree

const CREATURE_SCENE_PATH := "res://scenes/creature.tscn"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_damage_panic_policy()
	_test_prey_selection_policy()
	_test_grazing_policy()
	_test_sleep_policy()
	_test_drinking_policy()
	_test_transition_contract()
	await _test_actor_adapter()
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame
	# Let AudioServer release short-lived presentation streams after autoload teardown.
	await create_timer(0.25).timeout
	if _failures.is_empty():
		print("Creature ecology validation passed: damage panic, prey selection, grazing, sleep, drinking, hunt lifecycle, predator threat and actor adapters are valid.")
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
	var aborted := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_HUNTING_PREY, CreatureTransitionPolicy.EVENT_ECOLOGY_HUNT_ABORTED, true, false, -1.0))
	_expect(aborted.is_changed() and aborted.to_state_id == CreatureTransitionPolicy.STATE_IDLE and is_equal_approx(aborted.next_timer, 2.0), "hunt abort must return to IDLE for two seconds")
	var contact := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_HUNTING_PREY, CreatureTransitionPolicy.EVENT_ECOLOGY_HUNT_CONTACT, true, false, -1.0))
	_expect(contact.is_changed() and contact.to_state_id == CreatureTransitionPolicy.STATE_IDLE and is_equal_approx(contact.next_timer, 3.0), "hunt contact must return to IDLE for three seconds")
	var stale_source := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_IDLE, CreatureTransitionPolicy.EVENT_ECOLOGY_HUNT_ABORTED, true, false, -1.0))
	_expect(stale_source.status == CreatureTransitionResult.Status.NO_CHANGE, "hunt exit must reject a non-hunting source")
	var protected := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_HUNTING_PREY, CreatureTransitionPolicy.EVENT_ECOLOGY_HUNT_CONTACT, true, false, -1.0, false, 0.0, true))
	_expect(protected.status == CreatureTransitionResult.Status.PROTECTED, "protected hunt contact must not transition")
	var predator_threat := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_IDLE, CreatureTransitionPolicy.EVENT_ECOLOGY_PREDATOR_THREAT, true, true, 30.0))
	_expect(predator_threat.is_changed() and predator_threat.to_state_id == CreatureTransitionPolicy.STATE_FLEE and is_equal_approx(predator_threat.next_timer, 4.0), "predator threat must enter four-second FLEE")
	_expect(predator_threat.target_action == CreatureTransitionResult.TargetAction.SET, "predator threat must set the threat target")
	var invalid_predator := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_IDLE, CreatureTransitionPolicy.EVENT_ECOLOGY_PREDATOR_THREAT, true, false, -1.0))
	_expect(invalid_predator.status == CreatureTransitionResult.Status.NO_CHANGE, "predator threat must reject an invalid predator")
	var already_fleeing := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_FLEE, CreatureTransitionPolicy.EVENT_ECOLOGY_PREDATOR_THREAT, true, true, 30.0))
	_expect(already_fleeing.status == CreatureTransitionResult.Status.NO_CHANGE, "predator threat must preserve an existing FLEE lifecycle")
	var capturing_panic := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_CAPTURING, CreatureTransitionPolicy.EVENT_ECOLOGY_PREDATOR_THREAT, true, true, 30.0, false, 0.0, true))
	_expect(capturing_panic.status == CreatureTransitionResult.Status.PROTECTED, "capture-active predator panic must be protected")


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


func _test_grazing_policy() -> void:
	var accepted := CreatureGrazingPolicy.resolve(CreatureGrazingRequest.new(&"creature.slime", true, 0.219999, false))
	_expect(accepted.should_graze() and accepted.transition_event_id == CreatureTransitionPolicy.EVENT_ECOLOGY_GRAZING_ENTRY, "prey roll below 0.22 must graze")
	_expect(CreatureGrazingPolicy.resolve(CreatureGrazingRequest.new(&"creature.slime", true, 0.22, false)).status == CreatureGrazingResult.Status.NO_CHANGE, "exact 0.22 grazing boundary must fail")
	_expect(CreatureGrazingPolicy.resolve(CreatureGrazingRequest.new(&"creature.flam", false, 0.0, false)).status == CreatureGrazingResult.Status.NO_CHANGE, "neutral Flam must not graze")
	_expect(CreatureGrazingPolicy.resolve(CreatureGrazingRequest.new(&"creature.slime", true, 0.0, true)).status == CreatureGrazingResult.Status.PROTECTED, "protected prey must not graze")
	_expect(CreatureGrazingPolicy.resolve(CreatureGrazingRequest.new(&"creature.slime", true, -0.01, false)).status == CreatureGrazingResult.Status.INVALID_REQUEST, "negative grazing roll must be invalid")
	_expect(CreatureGrazingPolicy.resolve(CreatureGrazingRequest.new(&"creature.slime", true, 1.01, false)).status == CreatureGrazingResult.Status.INVALID_REQUEST, "grazing roll above one must be invalid")
	_expect(CreatureGrazingPolicy.resolve(null).status == CreatureGrazingResult.Status.INVALID_REQUEST, "null grazing request must be invalid")
	var transition := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_IDLE, CreatureTransitionPolicy.EVENT_ECOLOGY_GRAZING_ENTRY, true, false, -1.0, false, 2.5))
	_expect(transition.is_changed() and transition.to_state_id == CreatureTransitionPolicy.STATE_GRAZING and is_equal_approx(transition.next_timer, 2.5), "grazing event must enter GRAZING with injected duration")
	var wrong_source := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_WANDER, CreatureTransitionPolicy.EVENT_ECOLOGY_GRAZING_ENTRY, true, false, -1.0, false, 3.0))
	_expect(wrong_source.status == CreatureTransitionResult.Status.NO_CHANGE, "grazing entry must only apply from IDLE")


func _test_sleep_policy() -> void:
	var accepted := CreatureSleepPolicy.resolve(CreatureSleepRequest.new(&"creature.flam", false, false, 0.179999, false))
	_expect(accepted.should_sleep() and accepted.transition_event_id == CreatureTransitionPolicy.EVENT_ECOLOGY_SLEEP_ENTRY, "peaceful roll below 0.18 must sleep")
	_expect(CreatureSleepPolicy.resolve(CreatureSleepRequest.new(&"creature.flam", false, false, 0.18, false)).status == CreatureSleepResult.Status.NO_CHANGE, "exact 0.18 sleep boundary must fail")
	_expect(CreatureSleepPolicy.resolve(CreatureSleepRequest.new(&"creature.flam", true, false, 0.0, false)).status == CreatureSleepResult.Status.NO_CHANGE, "night raider must not sleep")
	_expect(CreatureSleepPolicy.resolve(CreatureSleepRequest.new(&"creature.flam", false, true, 0.0, false)).status == CreatureSleepResult.Status.NO_CHANGE, "enraged creature must not sleep")
	_expect(CreatureSleepPolicy.resolve(CreatureSleepRequest.new(&"creature.flam", false, false, 0.0, true)).status == CreatureSleepResult.Status.PROTECTED, "protected sleep request must not change")
	_expect(CreatureSleepPolicy.resolve(CreatureSleepRequest.new(&"item.wrong", false, false, 0.0, false)).status == CreatureSleepResult.Status.INVALID_REQUEST, "wrong sleep species domain must be invalid")
	_expect(CreatureSleepPolicy.resolve(null).status == CreatureSleepResult.Status.INVALID_REQUEST, "null sleep request must be invalid")
	var transition := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_IDLE, CreatureTransitionPolicy.EVENT_ECOLOGY_SLEEP_ENTRY, true, false, -1.0, false, 6.0))
	_expect(transition.is_changed() and transition.to_state_id == CreatureTransitionPolicy.STATE_SLEEP and is_equal_approx(transition.next_timer, 6.0), "sleep entry must accept the legacy minimum duration")
	var stale_source := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_WANDER, CreatureTransitionPolicy.EVENT_ECOLOGY_SLEEP_ENTRY, true, false, -1.0, false, 11.0))
	_expect(stale_source.status == CreatureTransitionResult.Status.NO_CHANGE, "sleep entry must only apply from IDLE")
	var invalid_duration := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_IDLE, CreatureTransitionPolicy.EVENT_ECOLOGY_SLEEP_ENTRY, true, false, -1.0, false, 11.01))
	_expect(invalid_duration.status == CreatureTransitionResult.Status.INVALID_REQUEST, "sleep entry must reject duration outside the legacy range")


func _test_drinking_policy() -> void:
	var accepted := CreatureDrinkingPolicy.resolve(CreatureDrinkingRequest.new(&"creature.flam", true, 319.999, 0.249999, false))
	_expect(accepted.should_drink() and accepted.transition_event_id == CreatureTransitionPolicy.EVENT_ECOLOGY_DRINKING_ENTRY, "water and roll below strict boundaries must drink")
	_expect(CreatureDrinkingPolicy.resolve(CreatureDrinkingRequest.new(&"creature.flam", true, 320.0, 0.0, false)).status == CreatureDrinkingResult.Status.NO_CHANGE, "exact 320px water boundary must fail")
	_expect(CreatureDrinkingPolicy.resolve(CreatureDrinkingRequest.new(&"creature.flam", true, 10.0, 0.25, false)).status == CreatureDrinkingResult.Status.NO_CHANGE, "exact 0.25 drinking boundary must fail")
	_expect(CreatureDrinkingPolicy.resolve(CreatureDrinkingRequest.new(&"creature.flam", false, -1.0, 0.0, false)).status == CreatureDrinkingResult.Status.NO_CHANGE, "missing water source must not drink")
	_expect(CreatureDrinkingPolicy.resolve(CreatureDrinkingRequest.new(&"creature.flam", true, 10.0, 0.0, true)).status == CreatureDrinkingResult.Status.PROTECTED, "protected drinking request must not change")
	_expect(CreatureDrinkingPolicy.resolve(CreatureDrinkingRequest.new(&"creature.flam", true, -1.0, 0.0, false)).status == CreatureDrinkingResult.Status.INVALID_REQUEST, "negative available-water distance must be invalid")
	_expect(CreatureDrinkingPolicy.resolve(null).status == CreatureDrinkingResult.Status.INVALID_REQUEST, "null drinking request must be invalid")
	var transition := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_IDLE, CreatureTransitionPolicy.EVENT_ECOLOGY_DRINKING_ENTRY, true, false, -1.0, false, 3.0))
	_expect(transition.is_changed() and transition.to_state_id == CreatureTransitionPolicy.STATE_DRINKING and is_equal_approx(transition.next_timer, 3.0), "drinking entry must accept the legacy minimum duration")
	var stale_source := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_WANDER, CreatureTransitionPolicy.EVENT_ECOLOGY_DRINKING_ENTRY, true, false, -1.0, false, 5.0))
	_expect(stale_source.status == CreatureTransitionResult.Status.NO_CHANGE, "drinking entry must only apply from IDLE")
	var invalid_duration := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(CreatureTransitionPolicy.STATE_IDLE, CreatureTransitionPolicy.EVENT_ECOLOGY_DRINKING_ENTRY, true, false, -1.0, false, 5.01))
	_expect(invalid_duration.status == CreatureTransitionResult.Status.INVALID_REQUEST, "drinking entry must reject duration outside the legacy range")


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
	var flam_grazing: CreatureGrazingResult = flam.call("resolve_grazing_entry", 0.0)
	_expect(flam_grazing.status == CreatureGrazingResult.Status.NO_CHANGE, "typed neutral Flam actor must not accept grazing")
	flam.set("is_night_raider", false)
	flam.set("is_enraged", false)
	var flam_sleep: CreatureSleepResult = flam.call("resolve_sleep_entry", 0.0)
	_expect(flam_sleep.should_sleep(), "peaceful actor must accept injected sleep roll")
	_expect(bool(flam.call("apply_sleep_entry", flam_sleep, 11.0)), "actor must apply accepted sleep transition")
	var flam_states: Dictionary = flam.get_script().get_script_constant_map().get("State", {})
	_expect(int(flam.get("state")) == int(flam_states.get("SLEEP", 8)) and is_equal_approx(float(flam.get("state_timer")), 11.0), "actor sleep state/duration mismatch")
	var sleep_apply_count := int(flam.get("transition_apply_count"))
	_expect(not bool(flam.call("apply_sleep_entry", flam_sleep, 11.0)), "repeated sleep result must be rejected as stale")
	_expect(int(flam.get("transition_apply_count")) == sleep_apply_count, "stale sleep result must not mutate actor state")
	flam.set("state", int(flam_states.get("CAPTURING", 7)))
	_expect((flam.call("resolve_sleep_entry", 0.0) as CreatureSleepResult).status == CreatureSleepResult.Status.PROTECTED, "capturing actor sleep request must be protected")
	flam.set("state", int(flam_states.get("IDLE", 0)))
	flam.set("is_night_raider", true)
	var sleep_rolls_before_guard := int(flam.get("sleep_roll_count"))
	flam.call("start_wander")
	_expect(int(flam.get("sleep_roll_count")) == sleep_rolls_before_guard, "night-raider guard must short-circuit sleep RNG")
	flam.set("state", int(flam_states.get("IDLE", 0)))
	flam.set("is_night_raider", false)
	flam.set("is_enraged", true)
	flam.call("start_wander")
	_expect(int(flam.get("sleep_roll_count")) == sleep_rolls_before_guard, "enraged guard must short-circuit sleep RNG")
	flam.set("is_enraged", false)
	flam.set("state", int(flam_states.get("IDLE", 0)))
	flam.set("has_water_source", false)
	var drinking_rolls_before_missing := int(flam.get("drinking_roll_count"))
	_expect((flam.call("resolve_drinking_entry", 0.0) as CreatureDrinkingResult).status == CreatureDrinkingResult.Status.NO_CHANGE, "actor missing-water snapshot must not drink")
	flam.set("has_water_source", true)
	flam.set("water_source_pos", Vector2(100.0, 0.0))
	flam.global_position = Vector2.ZERO
	var flam_drinking: CreatureDrinkingResult = flam.call("resolve_drinking_entry", 0.0)
	_expect(flam_drinking.should_drink(), "actor must accept injected drinking roll in range")
	_expect(bool(flam.call("apply_drinking_entry", flam_drinking, 5.0)), "actor must apply accepted drinking transition")
	_expect(int(flam.get("state")) == int(flam_states.get("DRINKING", 12)) and is_equal_approx(float(flam.get("state_timer")), 5.0), "actor drinking state/duration mismatch")
	_expect((flam.get("wander_dir") as Vector2).is_equal_approx(Vector2.RIGHT), "accepted drinking must preserve pond direction")
	var drinking_apply_count := int(flam.get("transition_apply_count"))
	_expect(not bool(flam.call("apply_drinking_entry", flam_drinking, 5.0)), "repeated drinking result must be rejected as stale")
	_expect(int(flam.get("transition_apply_count")) == drinking_apply_count, "stale drinking result must not mutate actor state")
	flam.set("state", int(flam_states.get("CAPTURING", 7)))
	_expect((flam.call("resolve_drinking_entry", 0.0) as CreatureDrinkingResult).status == CreatureDrinkingResult.Status.PROTECTED, "capturing actor drinking request must be protected")
	flam.set("state", int(flam_states.get("IDLE", 0)))
	flam.set("has_water_source", false)
	flam.call("start_wander")
	_expect(int(flam.get("drinking_roll_count")) == drinking_rolls_before_missing, "missing-water guard must short-circuit drinking RNG")

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
	slime.set("state", idle_state_from(slime))
	var slime_grazing: CreatureGrazingResult = slime.call("resolve_grazing_entry", 0.0)
	_expect(slime_grazing.should_graze(), "prey actor must accept injected grazing roll")
	_expect(bool(slime.call("apply_grazing_entry", slime_grazing, 4.0)), "prey actor must apply accepted grazing transition")
	_expect(int(slime.get("state")) == int(state_values.get("GRAZING", 13)) and is_equal_approx(float(slime.get("state_timer")), 4.0), "prey actor grazing state/duration mismatch")
	slime.set("state", int(state_values.get("CAPTURING", 7)))
	_expect((slime.call("resolve_grazing_entry", 0.0) as CreatureGrazingResult).status == CreatureGrazingResult.Status.PROTECTED, "capturing actor grazing request must be protected")

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
	_expect(int(eligible_prey.get("state")) == int(predator_states.get("FLEE", 10)), "selected prey must enter FLEE through predator-threat transition")
	_expect(eligible_prey.get("target") == predator and is_equal_approx(float(eligible_prey.get("state_timer")), 4.0), "predator panic must preserve threat target and four-second timer")
	var panic_apply_count := int(eligible_prey.get("transition_apply_count"))
	_expect(not bool(eligible_prey.call("panic_from_predator", predator)), "already-fleeing prey must reject repeated predator panic")
	_expect(int(eligible_prey.get("transition_apply_count")) == panic_apply_count, "repeated predator panic must not mutate actor state")
	eligible_prey.set("state", int(predator_states.get("CAPTURING", 7)))
	_expect(not bool(eligible_prey.call("panic_from_predator", predator)), "capturing prey must reject predator panic")
	eligible_prey.set("state", int(predator_states.get("IDLE", 0)))
	_expect(not bool(eligible_prey.call("panic_from_predator", null)), "invalid predator must not start FLEE")
	var threat_transition: CreatureTransitionResult = eligible_prey.call("resolve_creature_transition", CreatureTransitionPolicy.EVENT_ECOLOGY_PREDATOR_THREAT, true, 0.0, predator)
	_expect(bool(eligible_prey.call("apply_creature_transition", threat_transition, predator)), "accepted predator-threat result must apply")
	var count_after_threat := int(eligible_prey.get("transition_apply_count"))
	_expect(not bool(eligible_prey.call("apply_creature_transition", threat_transition, predator)), "repeated predator-threat result must be rejected as stale")
	_expect(int(eligible_prey.get("transition_apply_count")) == count_after_threat, "stale predator-threat result must not mutate actor state")

	var apply_count_before_abort := int(predator.get("transition_apply_count"))
	predator.set("prey_target", null)
	predator.call("handle_prey_hunt", 0.0)
	_expect(int(predator.get("state")) == int(predator_states.get("IDLE", 0)) and is_equal_approx(float(predator.get("state_timer")), 2.0), "invalid prey must exit hunt through the two-second abort transition")
	_expect(int(predator.get("transition_apply_count")) == apply_count_before_abort + 1, "hunt abort must apply exactly once")

	predator.set("state", int(predator_states.get("HUNTING_PREY", 14)))
	predator.set("state_timer", 0.0)
	predator.set("prey_target", eligible_prey)
	var timeout_result: CreatureTransitionResult = predator.call("resolve_creature_transition", CreatureTransitionPolicy.EVENT_ECOLOGY_HUNT_ABORTED, true)
	_expect(bool(predator.call("apply_prey_hunt_exit", timeout_result)), "hunt timeout result must apply")
	var count_after_timeout := int(predator.get("transition_apply_count"))
	_expect(not bool(predator.call("apply_prey_hunt_exit", timeout_result)), "repeated hunt result must be rejected as stale")
	_expect(int(predator.get("transition_apply_count")) == count_after_timeout and predator.get("prey_target") == null, "stale hunt result must not mutate actor state")

	predator.set("state", int(predator_states.get("HUNTING_PREY", 14)))
	predator.set("state_timer", 6.0)
	predator.set("prey_target", eligible_prey)
	eligible_prey.global_position = Vector2(30.0, 0.0)
	var prey_hp_before := int(eligible_prey.get("hp"))
	predator.call("handle_prey_hunt", 0.0)
	_expect(int(eligible_prey.get("hp")) == prey_hp_before - int(float(predator.get("attack_power")) * 0.7), "hunt contact must preserve 0.7 attack-power damage")
	_expect(int(predator.get("state")) == int(predator_states.get("IDLE", 0)) and is_equal_approx(float(predator.get("state_timer")), 3.0), "hunt contact must apply the three-second recovery")
	_expect(predator.get("prey_target") == null, "accepted hunt contact must clear only the prey target")

	var query_before_block := int(predator.get("ecology_query_count"))
	predator.set("state", int(predator_states.get("CHASE", 2)))
	predator.call("check_predator_prey_ecosystem")
	_expect(int(predator.get("ecology_query_count")) == query_before_block, "blocked predator must skip group scan")
	var flam_queries_before := int(flam.get("ecology_query_count"))
	flam.call("check_predator_prey_ecosystem")
	_expect(int(flam.get("ecology_query_count")) == flam_queries_before, "typed neutral Flam must skip ecology group scan")
	fixture.free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func idle_state_from(creature: Node) -> int:
	var values: Dictionary = creature.get_script().get_script_constant_map().get("State", {})
	return int(values.get("IDLE", 0))
