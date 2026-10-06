extends SceneTree

const Catalog = preload("res://systems/progression/base_quest_catalog.gd")
const ProgressState = preload("res://systems/progression/base_progress_state.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_catalog_and_state()
	_test_base_manager_adapter()
	if _failures.is_empty():
		print("Base progression validation passed: stable quest identity, coherent state and duplicate reward guard are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			printerr("BASE PROGRESSION VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _test_catalog_and_state() -> void:
	_expect(Catalog.QUEST_IDS.size() == 5, "catalog must expose five stable quests")
	_expect(Catalog.index_of(&"quest.base.automation") == 2, "stable quest lookup mismatch")
	var valid := ProgressState.new(3, &"quest.base.automation", [&"quest.base.survival", &"quest.base.organic_farming"])
	_expect(valid.is_valid(), "contiguous claimed prefix and matching level must be valid")
	_expect(ProgressState.from_dto(valid.to_dto()) != null, "state must survive DTO round trip")
	_expect(not ProgressState.new(3, &"quest.base.automation", [&"quest.base.organic_farming"]).is_valid(), "non-prefix claims must fail")
	_expect(not ProgressState.new(2, &"quest.base.automation", [&"quest.base.survival", &"quest.base.organic_farming"]).is_valid(), "base level must match claimed rewards")
	_expect(not ProgressState.new(2, &"quest.base.fortress", [&"quest.base.survival"]).is_valid(), "active quest must be next unclaimed identity")


func _test_base_manager_adapter() -> void:
	var manager := BaseManager.new()
	var state := ProgressState.new(4, &"quest.base.fortress", [&"quest.base.survival", &"quest.base.organic_farming", &"quest.base.automation"])
	_expect(manager.apply_persistence_state(state), "valid persistence state must apply")
	var projected: BaseProgressState = manager.create_persistence_state()
	_expect(projected.is_valid() and projected.to_dto() == state.to_dto(), "BaseManager persistence round trip mismatch")
	manager.current_quest_idx = 0
	var claims_before := manager.claimed_quest_ids.duplicate()
	var level_before := manager.base_level
	var player_stub := CharacterBody2D.new()
	manager.advance_quest(player_stub)
	_expect(manager.claimed_quest_ids == claims_before and manager.base_level == level_before, "claimed quest must not grant reward twice")
	player_stub.free()
	manager.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
