extends SceneTree

var _failures := PackedStringArray()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var pending := WorldBossState.new()
	_expect(pending.is_valid(), "canonical pending state must be valid")
	var active := WorldBossState.new(WorldBossState.ACTIVE, WorldBossState.INSTANCE_ID, 217, Vector2(340.5, 220.25))
	var restored := WorldBossState.from_dto(JSON.parse_string(JSON.stringify(active.to_dto())))
	_expect(restored != null and restored.lifecycle_id == WorldBossState.ACTIVE and restored.instance_id == WorldBossState.INSTANCE_ID and restored.hp == 217 and restored.position.is_equal_approx(Vector2(340.5, 220.25)), "active state must round-trip stable identity, HP and position")
	_expect(WorldBossState.from_dto(WorldBossState.new(WorldBossState.ACTIVE, &"boss.random", 217, Vector2.ZERO).to_dto()) == null, "active state must reject an unstable instance ID")
	_expect(WorldBossState.from_dto(WorldBossState.new(WorldBossState.ACTIVE, WorldBossState.INSTANCE_ID, 0, Vector2.ZERO).to_dto()) == null, "active state must reject defeated HP")
	var fractional_hp := active.to_dto()
	fractional_hp["hp"] = 216.5
	_expect(WorldBossState.from_dto(fractional_hp) == null, "active state must reject fractional JSON HP")
	_expect(WorldBossState.from_dto(WorldBossState.new(WorldBossState.DEFEATED, WorldBossState.INSTANCE_ID, 1, Vector2.ZERO).to_dto()) == null, "defeated state must reject remaining HP")
	var defeated := WorldBossState.from_dto(WorldBossState.new(WorldBossState.DEFEATED, WorldBossState.INSTANCE_ID, 0, Vector2.ZERO).to_dto())
	_expect(defeated != null and defeated.lifecycle_id == WorldBossState.DEFEATED, "canonical defeated ledger state must round-trip")
	await _test_world_owner()
	if _failures.is_empty():
		print("World boss state validation passed: lifecycle identity, HP and position contract is deterministic.")
		quit.call_deferred(0)
	else:
		for failure in _failures: printerr("WORLD BOSS STATE VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)

func _test_world_owner() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var world := packed.instantiate()
	root.add_child(world)
	await process_frame
	world.set("boss_spawned", false)
	world.set("world_boss_state", WorldBossState.new())
	_expect(bool(world.call("spawn_boss", false)), "pending world owner must spawn its boss")
	var actor := world.get("world_boss_actor") as Node2D
	_expect(is_instance_valid(actor) and actor.is_in_group("persistent_world_bosses"), "spawned world boss must have one owned actor and stable group")
	var count_before := get_nodes_in_group("persistent_world_bosses").size()
	_expect(not bool(world.call("spawn_boss", false)) and get_nodes_in_group("persistent_world_bosses").size() == count_before, "duplicate world-boss spawn must fail closed")
	var ordinary := Node2D.new()
	world.get_node("Creatures").add_child(ordinary)
	_expect(not bool(world.call("commit_world_boss_defeat", ordinary, WorldBossState.INSTANCE_ID)), "ordinary creature must not commit world-boss defeat")
	ordinary.add_to_group("persistent_altar_bosses")
	ordinary.set_meta("encounter_instance_id", WorldBossState.INSTANCE_ID)
	_expect(not bool(world.call("commit_world_boss_defeat", ordinary, WorldBossState.INSTANCE_ID)), "altar boss must not commit world-boss defeat")
	actor.emit_signal("defeated", actor, WorldBossState.INSTANCE_ID)
	var state := world.get("world_boss_state") as WorldBossState
	_expect(state.lifecycle_id == WorldBossState.DEFEATED and world.get("world_boss_actor") == null, "owned actor defeat signal must commit defeated lifecycle exactly once")
	_expect(not bool(world.call("commit_world_boss_defeat", actor, WorldBossState.INSTANCE_ID)), "duplicate defeat callback must fail closed")
	world.call("apply_world_boss_state", WorldBossState.new())
	_expect(bool(world.call("spawn_boss", false)), "capture lifecycle fixture must spawn a fresh owned boss")
	var captured_actor := world.get("world_boss_actor") as Node2D
	_expect(not bool(world.call("commit_world_boss_removal", captured_actor, WorldBossState.INSTANCE_ID, &"creature.removal.unknown")), "unknown removal reason must fail closed")
	captured_actor.emit_signal("removed", captured_actor, WorldBossState.INSTANCE_ID, &"creature.removal.captured")
	state = world.get("world_boss_state") as WorldBossState
	_expect(state.lifecycle_id == WorldBossState.DEFEATED and world.get("world_boss_actor") == null, "owned captured removal must commit terminal lifecycle")
	_expect(not bool(world.call("commit_world_boss_removal", captured_actor, WorldBossState.INSTANCE_ID, &"creature.removal.captured")), "duplicate captured removal must fail closed")
	root.remove_child(world)
	world.free()
	await process_frame
	await process_frame
