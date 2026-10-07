extends SceneTree

var _failures := PackedStringArray()

func _initialize() -> void:
	_run()

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
	if _failures.is_empty():
		print("World boss state validation passed: lifecycle identity, HP and position contract is deterministic.")
		quit(0)
	else:
		for failure in _failures: printerr("WORLD BOSS STATE VALIDATION FAILURE: %s" % failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
