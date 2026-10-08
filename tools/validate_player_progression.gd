extends SceneTree

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := PlayerProgressionState.new(
		4, 80, PlayerProgressionState.expected_max_exp(4), 2,
		{"str": 2, "vit": 1, "sta": 2, "agi": 1},
		PlayerEquipmentCatalog.PAL_BLADE, PlayerEquipmentCatalog.PAL_WARRIOR_ARMOR,
		PlayerProgressionState.expected_max_hp(4, 1, PlayerEquipmentCatalog.PAL_WARRIOR_ARMOR),
		PlayerProgressionState.expected_max_stamina(2), 120.0, 110.0,
		PlayerNeedsState.BUFF_SPEED, 45.5
	)
	_expect(state.is_valid(), "coherent progression state must be valid")
	var decoded: Variant = JSON.parse_string(JSON.stringify(state.to_dto()))
	var restored := PlayerProgressionState.from_dto(decoded)
	_expect(restored != null and restored.weapon_id == PlayerEquipmentCatalog.PAL_BLADE and restored.stats["sta"] == 2, "progression state must survive JSON round trip")

	var bad_budget := state.to_dto(); bad_budget["stat_points"] = 3
	_expect(PlayerProgressionState.from_dto(bad_budget) == null, "stat allocation plus unspent budget must equal level budget")
	var bad_threshold := state.to_dto(); bad_threshold["max_exp"] = 999
	_expect(PlayerProgressionState.from_dto(bad_threshold) == null, "max EXP must match deterministic level threshold")
	var bad_exp := state.to_dto(); bad_exp["exp"] = bad_exp["max_exp"]
	_expect(PlayerProgressionState.from_dto(bad_exp) == null, "EXP must remain below current threshold")
	var bad_weapon := state.to_dto(); bad_weapon["weapon_id"] = "Kiếm Sắt Rèn Kỹ"
	_expect(PlayerProgressionState.from_dto(bad_weapon) == null, "localized weapon text must not become identity")
	var bad_armor := state.to_dto(); bad_armor["armor_id"] = "equipment.armor.unknown"
	_expect(PlayerProgressionState.from_dto(bad_armor) == null, "unknown armor ID must fail closed")
	var bad_hp := state.to_dto(); bad_hp["max_hp"] = int(bad_hp["max_hp"]) + 1
	_expect(PlayerProgressionState.from_dto(bad_hp) == null, "max HP must be derived coherently from level/vitality/armor")
	var bad_stamina := state.to_dto(); bad_stamina["max_stamina"] = 999.0
	_expect(PlayerProgressionState.from_dto(bad_stamina) == null, "max stamina must be derived coherently from stamina stat")
	var bad_buff := state.to_dto(); bad_buff["buff_id"] = "needs.buff.unknown"
	_expect(PlayerProgressionState.from_dto(bad_buff) == null, "unknown buff ID must fail closed")
	var empty_timed_buff := state.to_dto(); empty_timed_buff["buff_id"] = ""; empty_timed_buff["buff_time_remaining"] = 1.0
	_expect(PlayerProgressionState.from_dto(empty_timed_buff) == null, "empty buff ID must have zero duration")

	var legacy := PlayerProgressionState.create_legacy_default(3, 99999)
	_expect(legacy.is_valid() and legacy.exp == legacy.max_exp - 1 and legacy.stat_points == 6, "legacy fallback must clamp EXP and preserve the full unspent level budget")
	_expect(legacy.weapon_id == PlayerEquipmentCatalog.WOOD_SWORD and legacy.armor_id == PlayerEquipmentCatalog.NO_ARMOR and legacy.buff_id == PlayerNeedsState.BUFF_NONE, "legacy fallback must use conservative default equipment and no buff")
	_expect(PlayerEquipmentCatalog.weapon_damage(PlayerEquipmentCatalog.PAL_BLADE) == 85 and PlayerEquipmentCatalog.armor_max_hp_bonus(PlayerEquipmentCatalog.PAL_WARRIOR_ARMOR) == 60, "equipment catalog must own derived combat tuning")

	if _failures.is_empty():
		print("Player progression validation passed: stat budget, equipment IDs, derived maxima and buff metadata are coherent.")
		quit.call_deferred(0)
	else:
		for failure in _failures: printerr("PLAYER PROGRESSION VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
