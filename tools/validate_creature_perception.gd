extends SceneTree

const CREATURE_SCENE_PATH := "res://scenes/creature.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_cadence()
	_test_policy_determinism_and_boundaries()
	_test_transition_policy()
	await _test_creature_adapter()
	await _clean_tree()
	if _failures.is_empty():
		print("Creature validation passed: perception cadence, deterministic selection and transition ownership are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit.call_deferred(1)


func _test_cadence() -> void:
	var cadence := CreaturePerceptionCadence.new(0.20)
	_expect(not cadence.advance(0.05), "cadence queried before interval at tick 1")
	_expect(not cadence.advance(0.05), "cadence queried before interval at tick 2")
	_expect(not cadence.advance(0.05), "cadence queried before interval at tick 3")
	_expect(cadence.advance(0.05), "cadence did not query at interval")
	_expect(cadence.query_count == 1, "cadence query count mismatch after first interval")
	for _index in range(16):
		cadence.advance(0.05)
	_expect(cadence.query_count == 5, "one simulated second must produce five perception queries")
	_expect(not cadence.advance(0.0), "zero delta must not query")
	_expect(not cadence.advance(NAN), "non-finite delta must not query")


func _test_policy_determinism_and_boundaries() -> void:
	var candidates: Array[CreaturePerceptionCandidate] = [
		CreaturePerceptionCandidate.new(20, 80.0, 0.0),
		CreaturePerceptionCandidate.new(10, 80.0, 0.0),
		CreaturePerceptionCandidate.new(5, 20.0, 0.0, false),
		CreaturePerceptionCandidate.new(4, -1.0, 0.0),
	]
	var request := CreaturePerceptionRequest.new(false, false, false, 115.0, 180.0, candidates)
	var first := CreaturePerceptionPolicy.resolve(request)
	var second := CreaturePerceptionPolicy.resolve(request)
	_expect(first.decision == CreaturePerceptionResult.Decision.ALERT, "in-range candidate must alert")
	_expect(first.candidate_id == 10, "equal-distance tie must select lowest transient candidate ID")
	_expect(first.decision == second.decision and first.candidate_id == second.candidate_id, "same perception input must be deterministic")

	var boundary: Array[CreaturePerceptionCandidate] = [
		CreaturePerceptionCandidate.new(30, 115.0, 120.0),
	]
	var boundary_result := CreaturePerceptionPolicy.resolve(
		CreaturePerceptionRequest.new(false, false, false, 115.0, 180.0, boundary)
	)
	_expect(boundary_result.decision == CreaturePerceptionResult.Decision.SUSPICIOUS, "aggro boundary must preserve strict less-than rule")
	var already_suspicious := CreaturePerceptionPolicy.resolve(
		CreaturePerceptionRequest.new(false, false, true, 115.0, 180.0, boundary)
	)
	_expect(already_suspicious.decision == CreaturePerceptionResult.Decision.NONE, "suspicious state must not retrigger suspicion")

	var sleeping_far: Array[CreaturePerceptionCandidate] = [
		CreaturePerceptionCandidate.new(40, 89.0, 190.0),
	]
	var sleeping_far_result := CreaturePerceptionPolicy.resolve(
		CreaturePerceptionRequest.new(false, true, false, 115.0, 180.0, sleeping_far)
	)
	_expect(sleeping_far_result.decision == CreaturePerceptionResult.Decision.NONE, "sleep movement threshold must remain strict")
	var sleeping_near: Array[CreaturePerceptionCandidate] = [
		CreaturePerceptionCandidate.new(40, 39.0, 0.0),
	]
	_expect(
		CreaturePerceptionPolicy.resolve(
			CreaturePerceptionRequest.new(false, true, false, 115.0, 180.0, sleeping_near)
		).decision == CreaturePerceptionResult.Decision.ALERT,
		"close candidate must wake sleeping creature"
	)
	_expect(
		CreaturePerceptionPolicy.resolve(
			CreaturePerceptionRequest.new(true, false, false, 115.0, 180.0, candidates)
		).decision == CreaturePerceptionResult.Decision.NONE,
		"protected state must block perception transition"
	)
	var invalid_only: Array[CreaturePerceptionCandidate] = [
		CreaturePerceptionCandidate.new(0, 10.0, 200.0),
		CreaturePerceptionCandidate.new(2, INF, 200.0),
	]
	_expect(
		CreaturePerceptionPolicy.resolve(
			CreaturePerceptionRequest.new(false, false, false, 115.0, 180.0, invalid_only)
		).decision == CreaturePerceptionResult.Decision.NONE,
		"invalid candidates must be ignored"
	)
	var lost := CreaturePerceptionPolicy.resolve(
		CreaturePerceptionRequest.new(false, false, true, 115.0, 180.0, [])
	)
	_expect(lost.decision == CreaturePerceptionResult.Decision.NONE, "no candidate must preserve legacy timer-owned target loss")


func _test_transition_policy() -> void:
	var idle_wander := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_IDLE,
		CreatureTransitionPolicy.EVENT_IDLE_WANDER,
		true,
		false,
		-1.0,
		false,
		2.5
	))
	_expect(idle_wander.is_changed(), "IDLE wander transition must change")
	_expect(idle_wander.to_state_id == CreatureTransitionPolicy.STATE_WANDER, "IDLE wander target state mismatch")
	_expect(is_equal_approx(idle_wander.next_timer, 2.5), "injected wander timer mismatch")
	_expect(idle_wander.reason_id == CreatureTransitionPolicy.EVENT_IDLE_WANDER, "wander reason ID mismatch")

	var not_triggered := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_WANDER,
		CreatureTransitionPolicy.EVENT_WANDER_COMPLETE,
		false,
		false,
		-1.0,
		false,
		2.0
	))
	_expect(not_triggered.status == CreatureTransitionResult.Status.NO_CHANGE, "false transition condition must not change")

	var wander_complete := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_WANDER,
		CreatureTransitionPolicy.EVENT_WANDER_COMPLETE,
		true,
		false,
		-1.0,
		false,
		1.75
	))
	_expect(wander_complete.to_state_id == CreatureTransitionPolicy.STATE_IDLE, "WANDER completion target mismatch")
	_expect(is_equal_approx(wander_complete.next_timer, 1.75), "WANDER completion timer mismatch")

	var confirmed := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_SUSPICIOUS,
		CreatureTransitionPolicy.EVENT_SUSPICION_TIMEOUT,
		true,
		true,
		139.0
	))
	_expect(confirmed.to_state_id == CreatureTransitionPolicy.STATE_ALERT, "close suspicion target must confirm alert")
	_expect(confirmed.reason_id == CreatureTransitionPolicy.REASON_SUSPICION_CONFIRMED, "confirmed suspicion reason mismatch")
	_expect(confirmed.target_action == CreatureTransitionResult.TargetAction.KEEP, "confirmed suspicion must keep target")

	var lost := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_SUSPICIOUS,
		CreatureTransitionPolicy.EVENT_SUSPICION_TIMEOUT,
		true,
		true,
		140.0
	))
	_expect(lost.to_state_id == CreatureTransitionPolicy.STATE_WANDER, "suspicion distance boundary must lose target")
	_expect(lost.reason_id == CreatureTransitionPolicy.REASON_SUSPICION_LOST, "lost suspicion reason mismatch")
	_expect(lost.target_action == CreatureTransitionResult.TargetAction.CLEAR, "lost suspicion must clear target")

	var chase_lost := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_CHASE,
		CreatureTransitionPolicy.EVENT_CHASE_TARGET_LOST,
		true
	))
	_expect(chase_lost.to_state_id == CreatureTransitionPolicy.STATE_IDLE, "missing chase target must return IDLE")
	_expect(is_equal_approx(chase_lost.next_timer, 1.0), "missing chase target timer mismatch")

	var chase_far := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_CHASE,
		CreatureTransitionPolicy.EVENT_CHASE_OUT_OF_RANGE,
		true,
		true,
		451.0
	))
	_expect(chase_far.is_changed() and chase_far.target_action == CreatureTransitionResult.TargetAction.CLEAR, "far chase target must clear and return")
	var raid_far := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_CHASE,
		CreatureTransitionPolicy.EVENT_CHASE_OUT_OF_RANGE,
		true,
		true,
		451.0,
		true
	))
	_expect(raid_far.status == CreatureTransitionResult.Status.NO_CHANGE, "night raider must ignore chase leash")

	var protected := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_IDLE,
		CreatureTransitionPolicy.EVENT_IDLE_WANDER,
		true,
		false,
		-1.0,
		false,
		2.0,
		true
	))
	_expect(protected.status == CreatureTransitionResult.Status.PROTECTED, "protected request status mismatch")
	var invalid := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_IDLE,
		&"creature.transition.unknown",
		true
	))
	_expect(invalid.status == CreatureTransitionResult.Status.INVALID_REQUEST, "unknown transition event must be invalid")
	var repeat := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_SUSPICIOUS,
		CreatureTransitionPolicy.EVENT_SUSPICION_TIMEOUT,
		true,
		true,
		139.0
	))
	_expect(repeat.to_state_id == confirmed.to_state_id and repeat.reason_id == confirmed.reason_id, "transition policy must be deterministic")

	var perception_entry := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_IDLE,
		CreatureTransitionPolicy.EVENT_PERCEPTION_ALERT,
		true,
		true,
		40.0
	))
	_expect(perception_entry.to_state_id == CreatureTransitionPolicy.STATE_ALERT, "perception alert must enter ALERT")
	_expect(perception_entry.target_action == CreatureTransitionResult.TargetAction.SET, "perception alert must set selected target")
	var duplicate_suspicion := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_SUSPICIOUS,
		CreatureTransitionPolicy.EVENT_PERCEPTION_SUSPICIOUS,
		true,
		true,
		100.0
	))
	_expect(duplicate_suspicion.status == CreatureTransitionResult.Status.NO_CHANGE, "suspicion entry must not retrigger presentation")

	for natural_case in [
		[CreatureTransitionPolicy.STATE_SLEEP, CreatureTransitionPolicy.EVENT_SLEEP_COMPLETE, 2.0],
		[CreatureTransitionPolicy.STATE_DRINKING, CreatureTransitionPolicy.EVENT_DRINKING_COMPLETE, 2.5],
		[CreatureTransitionPolicy.STATE_GRAZING, CreatureTransitionPolicy.EVENT_GRAZING_COMPLETE, 2.0],
	]:
		var natural := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
			natural_case[0], natural_case[1], true
		))
		_expect(natural.to_state_id == CreatureTransitionPolicy.STATE_IDLE, "natural timeout must return IDLE")
		_expect(is_equal_approx(natural.next_timer, natural_case[2]), "natural timeout timer mismatch")

	var flee_lost := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_FLEE,
		CreatureTransitionPolicy.EVENT_FLEE_TARGET_LOST,
		true
	))
	_expect(flee_lost.to_state_id == CreatureTransitionPolicy.STATE_IDLE and flee_lost.target_action == CreatureTransitionResult.TargetAction.CLEAR, "FLEE target loss must clear target")
	var capture_rejected := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_CAPTURING,
		CreatureTransitionPolicy.EVENT_CAPTURE_REJECTED,
		true,
		true,
		20.0
	))
	_expect(capture_rejected.to_state_id == CreatureTransitionPolicy.STATE_CHASE, "capture rejection with target must restore CHASE")
	_expect(capture_rejected.target_action == CreatureTransitionResult.TargetAction.SET, "capture rejection must set valid player target")


func _test_creature_adapter() -> void:
	var packed := load(CREATURE_SCENE_PATH) as PackedScene
	if packed == null:
		_failures.append("unable to load Creature scene")
		return
	var fixture := Node2D.new()
	root.add_child(fixture)
	var creature := packed.instantiate()
	var player := CharacterBody2D.new()
	player.name = "PerceptionTestPlayer"
	player.add_to_group("player")
	fixture.add_child(creature)
	fixture.add_child(player)
	await process_frame
	var state_values: Dictionary = creature.get_script().get_script_constant_map().get("State", {})
	var runtime_species: Dictionary = creature.get("cur_data")
	var legacy_species_rows: Array = creature.get("species_data")
	_expect(runtime_species.get("id", &"") == LegacySpeciesAdapter.FLAM_ID, "Flam runtime must expose stable creature ID")
	_expect(int(runtime_species.get("max_hp", 0)) == 80, "Flam runtime HP must come through typed compatibility adapter")
	_expect(is_equal_approx(float(runtime_species.get("speed", 0.0)), 105.0), "Flam runtime speed compatibility mismatch")
	_expect(int(runtime_species.get("power", 0)) == 14, "Flam runtime power compatibility mismatch")
	_expect(runtime_species.get("drop_item", "") == LegacyItemAdapter.to_legacy_key(&"item.pal_ore"), "Flam stable drop reference must preserve legacy runtime key")
	_expect(not (legacy_species_rows[0] as Dictionary).has("max_hp"), "migrated Flam HP must not remain a parallel legacy source")
	var primary_skill := creature.get("primary_skill_definition") as SkillDefinition
	_expect(primary_skill != null, "Flam actor must resolve its typed primary skill")
	if primary_skill != null:
		_expect(primary_skill.content_id == LegacySpeciesAdapter.FLAM_FIREBALL_ID, "Flam actor skill must use stable skill ID")
		_expect(is_equal_approx(primary_skill.cooldown_seconds, 2.2), "Flam actor skill cooldown compatibility mismatch")
		_expect(is_equal_approx(primary_skill.recovery_seconds, 0.3), "Flam actor skill recovery compatibility mismatch")
		_expect(is_equal_approx(primary_skill.travel_distance, 240.0), "Flam actor projectile distance compatibility mismatch")
		_expect(is_equal_approx(primary_skill.travel_seconds, 0.55), "Flam actor projectile timing compatibility mismatch")
		_expect(is_equal_approx(primary_skill.hit_radius, 45.0), "Flam actor hit radius compatibility mismatch")
		_expect(is_equal_approx(primary_skill.damage_multiplier, 1.0), "Flam actor damage compatibility mismatch")
	var idle_state := int(state_values.get("IDLE", 0))
	var wander_state := int(state_values.get("WANDER", 1))
	var chase_state := int(state_values.get("CHASE", 2))
	var attack_state := int(state_values.get("ATTACK", 3))
	var suspicious_state := int(state_values.get("SUSPICIOUS", 10))
	var capturing_state := int(state_values.get("CAPTURING", 7))
	var sleep_state := int(state_values.get("SLEEP", 8))
	var alert_state := int(state_values.get("ALERT", 9))
	creature.set("is_elite", false)
	creature.set("is_night_raider", false)
	creature.global_position = Vector2.ZERO
	player.global_position = Vector2(150.0, 0.0)
	player.velocity = Vector2(120.0, 0.0)
	creature.set("perception_cadence", CreaturePerceptionCadence.new(0.20))

	creature.call("update_player_perception", 0.10)
	_expect(int(creature.get("perception_query_count")) == 0, "Creature adapter queried before cadence")
	_expect(int(creature.get("state")) == idle_state, "Creature adapter changed state before cadence")
	creature.call("update_player_perception", 0.10)
	_expect(int(creature.get("perception_query_count")) == 1, "Creature adapter query count mismatch")
	_expect(int(creature.get("state")) == suspicious_state, "Creature adapter must preserve suspicion behavior")
	_expect(creature.get("target") == player, "Creature adapter selected wrong target")

	creature.set("state", wander_state)
	creature.set("state_timer", 0.0)
	creature.set("target", player)
	var before_wander_apply := int(creature.get("transition_apply_count"))
	var wander_result := CreatureTransitionPolicy.resolve(CreatureTransitionRequest.new(
		CreatureTransitionPolicy.STATE_WANDER,
		CreatureTransitionPolicy.EVENT_WANDER_COMPLETE,
		true,
		true,
		150.0,
		false,
		1.75
	))
	_expect(bool(creature.call("apply_creature_transition", wander_result)), "Creature transition adapter must apply current-state result")
	_expect(int(creature.get("state")) == idle_state, "Creature transition adapter target state mismatch")
	_expect(is_equal_approx(float(creature.get("state_timer")), 1.75), "Creature transition adapter timer mismatch")
	_expect(creature.get("target") == player, "WANDER completion must preserve target compatibility")
	_expect(int(creature.get("transition_apply_count")) == before_wander_apply + 1, "Creature transition apply count mismatch")
	_expect(not bool(creature.call("apply_creature_transition", wander_result)), "stale transition result must not apply twice")
	_expect(int(creature.get("transition_apply_count")) == before_wander_apply + 1, "stale transition must not increment apply count")

	creature.set("state", idle_state)
	var entry_count := int(creature.get("transition_apply_count"))
	creature.call("trigger_suspicion", player)
	_expect(int(creature.get("state")) == suspicious_state and creature.get("target") == player, "suspicion entry must atomically commit state and target")
	_expect(int(creature.get("transition_apply_count")) == entry_count + 1, "suspicion entry must use transition apply owner")
	creature.call("trigger_suspicion", player)
	_expect(int(creature.get("transition_apply_count")) == entry_count + 1, "duplicate suspicion entry must not apply or present twice")

	creature.set("state", sleep_state)
	creature.set("state_timer", 0.0)
	var sleep_result: CreatureTransitionResult = creature.call("resolve_creature_transition", CreatureTransitionPolicy.EVENT_SLEEP_COMPLETE, true)
	_expect(bool(creature.call("apply_creature_transition", sleep_result)), "SLEEP timeout must apply through lifecycle owner")
	_expect(int(creature.get("state")) == idle_state and is_equal_approx(float(creature.get("state_timer")), 2.0), "SLEEP timeout adapter mismatch")

	creature.set("state", alert_state)
	creature.set("target", null)
	var alert_lost: CreatureTransitionResult = creature.call("resolve_creature_transition", CreatureTransitionPolicy.EVENT_ALERT_COMPLETE, true)
	_expect(bool(creature.call("apply_creature_transition", alert_lost)), "ALERT without target must exit lifecycle state")
	_expect(int(creature.get("state")) == idle_state, "ALERT without target must return IDLE")

	creature.set("state", chase_state)
	creature.set("target", null)
	var lost_result: CreatureTransitionResult = creature.call(
		"resolve_creature_transition",
		CreatureTransitionPolicy.EVENT_CHASE_TARGET_LOST,
		true
	)
	_expect(bool(creature.call("apply_creature_transition", lost_result)), "CHASE target-loss transition must apply")
	_expect(int(creature.get("state")) == idle_state and creature.get("target") == null, "CHASE target-loss adapter mismatch")

	creature.set("state", capturing_state)
	_expect(not bool(creature.call("finish_legacy_attack_recovery")), "capture state must reject legacy attack recovery")
	_expect(int(creature.get("state")) == capturing_state, "rejected attack recovery must preserve capture state")
	creature.set("state", attack_state)
	_expect(bool(creature.call("finish_legacy_attack_recovery")), "active legacy attack must recover to CHASE")
	_expect(int(creature.get("state")) == chase_state, "legacy attack recovery target mismatch")

	creature.set("state", capturing_state)
	creature.set("target", null)
	player.global_position = Vector2(10.0, 0.0)
	creature.call("update_player_perception", 0.20)
	_expect(int(creature.get("perception_query_count")) == 1, "protected state must skip the group query")
	_expect(int(creature.get("state")) == capturing_state and creature.get("target") == null, "CAPTURING state must reject perception transition")
	var capture_restore: CreatureTransitionResult = creature.call(
		"resolve_creature_transition",
		CreatureTransitionPolicy.EVENT_CAPTURE_REJECTED,
		true,
		0.0,
		player
	)
	_expect(bool(creature.call("apply_creature_transition", capture_restore, player)), "capture rejection must be the explicit CAPTURING exit")
	_expect(int(creature.get("state")) == chase_state and creature.get("target") == player, "capture rejection adapter must restore CHASE target")

	var slime := packed.instantiate()
	slime.set("species_index", 1)
	fixture.add_child(slime)
	await process_frame
	var slime_runtime: Dictionary = slime.get("cur_data")
	_expect(slime_runtime.get("id", &"") == LegacySpeciesAdapter.SLIME_ID, "Slime runtime must expose stable creature ID")
	var expected_slime_hp := int(110 * (2.4 if bool(slime.get("is_elite")) else 1.0))
	_expect(int(slime_runtime.get("max_hp", 0)) == 110 and int(slime.get("max_hp")) == expected_slime_hp, "Slime typed HP compatibility mismatch")
	_expect(is_equal_approx(float(slime_runtime.get("speed", 0.0)), 85.0), "Slime typed speed compatibility mismatch")
	_expect(int(slime_runtime.get("power", 0)) == 9, "Slime typed power compatibility mismatch")
	_expect(bool(slime_runtime.get("is_prey", false)) and not bool(slime_runtime.get("is_predator", true)), "Slime typed prey role mismatch")
	_expect(slime_runtime.get("drop_item", "") == LegacyItemAdapter.to_legacy_key(&"item.berry"), "Slime typed drop must preserve legacy runtime key")
	_expect(slime.get("primary_skill_definition") == null, "Slime hop must remain on the legacy attack path")
	var slime_legacy_rows: Array = slime.get("species_data")
	_expect(not (slime_legacy_rows[1] as Dictionary).has("max_hp"), "migrated Slime HP must not remain a parallel legacy source")
	_expect(LegacySpeciesAdapter.create_runtime_snapshot(-1, {}).is_empty(), "invalid species snapshot must fail closed")
	var mushroom := packed.instantiate()
	mushroom.set("species_index", 2)
	fixture.add_child(mushroom)
	await process_frame
	var mushroom_runtime: Dictionary = mushroom.get("cur_data")
	_expect(mushroom_runtime.get("id", &"") == LegacySpeciesAdapter.MUSHROOM_ID, "Mushroom runtime must expose stable creature ID")
	var expected_mushroom_hp := int(90 * (2.4 if bool(mushroom.get("is_elite")) else 1.0))
	_expect(int(mushroom_runtime.get("max_hp", 0)) == 90 and int(mushroom.get("max_hp")) == expected_mushroom_hp, "Mushroom typed HP compatibility mismatch")
	_expect(is_equal_approx(float(mushroom_runtime.get("speed", 0.0)), 95.0), "Mushroom typed speed compatibility mismatch")
	_expect(int(mushroom_runtime.get("power", 0)) == 11, "Mushroom typed power compatibility mismatch")
	_expect(bool(mushroom_runtime.get("is_prey", false)) and not bool(mushroom_runtime.get("is_predator", true)), "Mushroom typed prey role mismatch")
	_expect(mushroom_runtime.get("drop_item", "") == LegacyItemAdapter.to_legacy_key(&"item.berry_seed"), "Mushroom typed drop must preserve legacy runtime key")
	_expect(mushroom.get("primary_skill_definition") == null, "Mushroom spore must remain on the legacy attack path")
	var mushroom_legacy_rows: Array = mushroom.get("species_data")
	_expect(not (mushroom_legacy_rows[2] as Dictionary).has("max_hp"), "migrated Mushroom HP must not remain a parallel legacy source")
	var beast := packed.instantiate()
	beast.set("species_index", 3)
	fixture.add_child(beast)
	await process_frame
	var beast_runtime: Dictionary = beast.get("cur_data")
	_expect(beast_runtime.get("id", &"") == LegacySpeciesAdapter.BEAST_ID, "Beast runtime must expose stable creature ID")
	var expected_beast_hp := int(130 * (2.4 if bool(beast.get("is_elite")) else 1.0))
	_expect(int(beast_runtime.get("max_hp", 0)) == 130 and int(beast.get("max_hp")) == expected_beast_hp, "Beast typed HP compatibility mismatch")
	_expect(is_equal_approx(float(beast_runtime.get("speed", 0.0)), 115.0), "Beast typed speed compatibility mismatch")
	_expect(int(beast_runtime.get("power", 0)) == 16, "Beast typed power compatibility mismatch")
	_expect(bool(beast_runtime.get("is_predator", false)) and not bool(beast_runtime.get("is_prey", true)), "Beast typed predator role mismatch")
	_expect(beast_runtime.get("drop_item", "") == LegacyItemAdapter.to_legacy_key(&"item.fresh_meat"), "Beast typed drop must preserve legacy runtime key")
	_expect(beast.get("primary_skill_definition") == null, "Beast charge must remain on the legacy attack path")
	var beast_legacy_rows: Array = beast.get("species_data")
	_expect(not (beast_legacy_rows[3] as Dictionary).has("max_hp"), "migrated Beast HP must not remain a parallel legacy source")
	var dragon := packed.instantiate()
	dragon.set("species_index", 4)
	fixture.add_child(dragon)
	await process_frame
	var dragon_runtime: Dictionary = dragon.get("cur_data")
	_expect(dragon_runtime.get("id", &"") == LegacySpeciesAdapter.DRAGON_ID, "Dragon runtime must expose stable creature ID")
	_expect(bool(dragon.get("is_elite")), "Dragon must preserve forced-elite classification")
	_expect(int(dragon_runtime.get("max_hp", 0)) == 340 and int(dragon.get("max_hp")) == int(340 * 2.4), "Dragon typed HP and forced-elite scaling mismatch")
	_expect(is_equal_approx(float(dragon_runtime.get("speed", 0.0)), 95.0) and is_equal_approx(float(dragon.get("move_speed")), 95.0 * 1.15), "Dragon typed speed and forced-elite scaling mismatch")
	_expect(int(dragon_runtime.get("power", 0)) == 26 and int(dragon.get("attack_power")) == int(26 * 1.45), "Dragon typed power and forced-elite scaling mismatch")
	_expect(bool(dragon_runtime.get("is_predator", false)) and not bool(dragon_runtime.get("is_prey", true)), "Dragon typed predator role mismatch")
	_expect(dragon_runtime.get("drop_item", "") == LegacyItemAdapter.to_legacy_key(&"item.pal_ingot"), "Dragon typed drop must preserve legacy runtime key")
	_expect(dragon.get("primary_skill_definition") == null, "Dragon melee/fireball must remain on the legacy attack path")
	var dragon_legacy_rows: Array = dragon.get("species_data")
	_expect(not (dragon_legacy_rows[4] as Dictionary).has("max_hp"), "migrated Dragon HP must not remain a parallel legacy source")
	_expect(LegacySpeciesAdapter.create_runtime_snapshot(5, {}).is_empty(), "out-of-range species snapshot must fail closed")

	fixture.remove_child(dragon)
	dragon.free()
	fixture.remove_child(beast)
	beast.free()
	fixture.remove_child(mushroom)
	mushroom.free()
	fixture.remove_child(slime)
	slime.free()
	fixture.remove_child(creature)
	creature.free()
	fixture.remove_child(player)
	player.free()
	root.remove_child(fixture)
	fixture.free()
	await process_frame


func _clean_tree() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null:
		for player in audio_manager.get_children():
			if player is AudioStreamPlayer:
				player.stop()
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame
	await create_timer(0.25).timeout


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
