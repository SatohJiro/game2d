extends SceneTree

var _failures := PackedStringArray()

func _initialize() -> void:
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
	if _failures.is_empty():
		print("Night raid state validation passed: encounter identity, actors and cycle coherence are deterministic.")
		quit.call_deferred(0)
	else:
		for failure in _failures: printerr("NIGHT RAID STATE VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
