extends SceneTree

var _failures := PackedStringArray()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var actors: Array[NightRaidActorState] = [
		NightRaidActorState.new(&"raid.night_actor_1", &"creature.flam", 2, 80, Vector2(320.5, -10.0)),
		NightRaidActorState.new(&"raid.night_actor_2", &"creature.beast", 5, 120, Vector2(-340.0, 40.25)),
	]
	var active := NightRaidState.new(NightRaidState.ACTIVE, NightRaidState.ENCOUNTER_ID, 0, actors)
	var restored := NightRaidState.from_dto(JSON.parse_string(JSON.stringify(active.to_dto())))
	_expect(restored != null and restored.actors.size() == 2 and restored.actors[1].species_id == &"creature.beast", "active raid must round-trip resolved actor state")
	_expect(restored != null and restored.is_coherent(true, 140.0), "active raid must be coherent with triggered guard and cycle")
	_expect(restored != null and not restored.is_coherent(false, 140.0), "active raid must reject an untriggered guard")
	_expect(restored != null and not restored.is_coherent(true, 320.0), "active raid must reject a stale cycle index")
	var duplicate: Array[NightRaidActorState] = [actors[0], NightRaidActorState.new(&"raid.night_actor_1", &"creature.slime", 3, 50, Vector2.ZERO)]
	_expect(not NightRaidState.new(NightRaidState.ACTIVE, NightRaidState.ENCOUNTER_ID, 0, duplicate).is_valid(), "raid actor instance IDs must be unique")
	_expect(not NightRaidActorState.new(&"raid.night_actor_3", &"creature.dragon", 3, 50, Vector2.ZERO).is_valid(), "raid state must reject species outside spawn policy")
	_expect(not NightRaidActorState.new(&"raid.night_actor_3", &"creature.slime", 3, 9999, Vector2.ZERO).is_valid(), "raid actor HP must not exceed derived elite maximum")
	var cleared := NightRaidState.from_dto(NightRaidState.new(NightRaidState.CLEARED, NightRaidState.ENCOUNTER_ID, 0, []).to_dto())
	_expect(cleared != null and cleared.is_coherent(true, 140.0), "cleared raid ledger must round-trip")
	_expect(NightRaidState.new().is_coherent(false, 10.0), "pending raid must match an untriggered guard")
	var world: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	world.process_mode = Node.PROCESS_MODE_DISABLED
	world.day_time = 140.0
	_expect(world.trigger_night_raid(false), "pending runtime raid must spawn exactly once")
	var owned: Dictionary = world.night_raid_actors
	_expect(owned.size() == 3, "runtime raid must own three stable actor slots")
	_expect(world.night_raid_state.lifecycle_id == NightRaidState.ACTIVE and world.night_raid_state.actors.size() == 3, "spawned raid must publish an active three-actor ledger")
	var seen := {}
	for instance_id: StringName in NightRaidActorState.VALID_INSTANCE_IDS:
		var actor: Node2D = owned.get(instance_id)
		_expect(actor != null and actor.is_in_group(world.NIGHT_RAID_ACTOR_GROUP), "each raid slot must own a grouped actor")
		if actor != null:
			_expect(actor.get_meta("encounter_id", &"") == NightRaidState.ENCOUNTER_ID and actor.get_meta("encounter_instance_id", &"") == instance_id, "each owned actor must carry encounter and slot metadata")
			seen[actor.get_instance_id()] = true
	_expect(seen.size() == 3, "raid slots must reference three unique actors")
	_expect(not world.trigger_night_raid(false) and world.night_raid_actors.size() == 3, "duplicate runtime trigger must fail closed without another spawn")
	var first_id := NightRaidActorState.VALID_INSTANCE_IDS[0]
	var first_actor: Node2D = world.night_raid_actors[first_id]
	var foreign := Node2D.new()
	foreign.set_meta("encounter_id", NightRaidState.ENCOUNTER_ID)
	foreign.set_meta("encounter_instance_id", first_id)
	foreign.add_to_group(world.NIGHT_RAID_ACTOR_GROUP)
	world.creature_container.add_child(foreign)
	_expect(not world.commit_night_raid_actor_removal(foreign, first_id), "foreign actor callback must not consume an owned raid slot")
	foreign.free()
	_expect(world.commit_night_raid_actor_removal(first_actor, first_id), "owned actor defeat must consume its raid slot")
	_expect(not world.commit_night_raid_actor_removal(first_actor, first_id), "duplicate actor callback must fail closed")
	_expect(world.night_raid_state.lifecycle_id == NightRaidState.ACTIVE and world.night_raid_state.actors.size() == 2, "partial removal must keep the raid active")
	var second_id := NightRaidActorState.VALID_INSTANCE_IDS[1]
	var second_actor: Node2D = world.night_raid_actors[second_id]
	second_actor.removed.emit(second_actor, second_id, &"creature.removal.unknown")
	_expect(world.night_raid_actors.size() == 2, "unrecognized removal reason must not consume a raid slot")
	second_actor.removed.emit(second_actor, second_id, &"creature.removal.captured")
	var third_id := NightRaidActorState.VALID_INSTANCE_IDS[2]
	var third_actor: Node2D = world.night_raid_actors[third_id]
	third_actor.defeated.emit(third_actor, third_id)
	_expect(world.night_raid_actors.is_empty(), "defeat and capture callbacks must aggregate all owned removals")
	_expect(world.night_raid_state.lifecycle_id == NightRaidState.CLEARED and world.night_raid_state.actors.is_empty(), "empty owned roster must transition to cleared exactly once")
	_expect(not world.commit_night_raid_actor_removal(third_actor, third_id), "cleared raid must reject later callbacks")
	root.remove_child(world)
	world.free()
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("Night raid state validation passed: persistence contract and three-slot runtime ownership are deterministic.")
		quit.call_deferred(0)
	else:
		for failure in _failures: printerr("NIGHT RAID STATE VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
