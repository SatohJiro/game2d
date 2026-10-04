extends SceneTree

const CREATURE_SCENE_PATH := "res://scenes/creature.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_cadence()
	_test_policy_determinism_and_boundaries()
	await _test_creature_adapter()
	await _clean_tree()
	if _failures.is_empty():
		print("Creature perception validation passed: cadence, deterministic selection, state guards and adapter are valid.")
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
