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
	var idle_state := int(state_values.get("IDLE", 0))
	var wander_state := int(state_values.get("WANDER", 1))
	var chase_state := int(state_values.get("CHASE", 2))
	var attack_state := int(state_values.get("ATTACK", 3))
	var suspicious_state := int(state_values.get("SUSPICIOUS", 10))
	var capturing_state := int(state_values.get("CAPTURING", 7))
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
	_expect(int(creature.get("transition_apply_count")) == 1, "Creature transition apply count mismatch")
	_expect(not bool(creature.call("apply_creature_transition", wander_result)), "stale transition result must not apply twice")
	_expect(int(creature.get("transition_apply_count")) == 1, "stale transition must not increment apply count")

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
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
