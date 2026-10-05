extends SceneTree

const CREATURE_SCENE_PATH := "res://scenes/creature.tscn"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_resolver_contract()
	await _test_actor_adapter()
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("Creature drop validation passed: deterministic Flam drop result and atomic actor commit are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			printerr("CREATURE DROP VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _test_resolver_contract() -> void:
	var normal := CreatureDropResolver.resolve(CreatureDropRequest.new(&"creature.flam", &"item.pal_ore", true, false, false, false, false, 2, 0))
	_expect(normal.is_accepted(), "valid normal drop request must be accepted")
	_expect(normal.primary_item_id == &"item.pal_ore" and normal.primary_count == 2, "normal primary drop mismatch")
	_expect(normal.bonus_item_id.is_empty() and normal.bonus_count == 0, "normal creature must not receive elite bonus")

	var elite := CreatureDropResolver.resolve(CreatureDropRequest.new(&"creature.flam", &"item.pal_ore", true, false, false, true, false, 5, 4))
	_expect(elite.is_accepted(), "valid elite drop request must be accepted")
	_expect(elite.primary_count == 5 and elite.bonus_item_id == CreatureDropResolver.ELITE_BONUS_ITEM_ID and elite.bonus_count == 4, "elite range/bonus mismatch")

	_expect(CreatureDropResolver.resolve(null).status == CreatureDropResult.Status.INVALID_REQUEST, "null request must be invalid")
	_expect(CreatureDropResolver.resolve(CreatureDropRequest.new(&"item.wrong", &"item.pal_ore", true, false, false, false, false, 1, 0)).status == CreatureDropResult.Status.INVALID_REQUEST, "wrong species domain must be invalid")
	_expect(CreatureDropResolver.resolve(CreatureDropRequest.new(&"creature.flam", &"creature.wrong", true, false, false, false, false, 1, 0)).status == CreatureDropResult.Status.INVALID_REQUEST, "wrong item domain must be invalid")
	_expect(CreatureDropResolver.resolve(CreatureDropRequest.new(&"creature.flam", &"item.pal_ore", false, false, false, false, false, 1, 0)).status == CreatureDropResult.Status.NOT_DEFEATED, "living creature must not drop")
	_expect(CreatureDropResolver.resolve(CreatureDropRequest.new(&"creature.flam", &"item.pal_ore", true, true, false, false, false, 1, 0)).status == CreatureDropResult.Status.CAPTURE_BLOCKED, "active capture must block defeat drops")
	_expect(CreatureDropResolver.resolve(CreatureDropRequest.new(&"creature.flam", &"item.pal_ore", true, false, true, false, false, 1, 0)).status == CreatureDropResult.Status.DUPLICATE, "committed defeat drop must be duplicate")
	_expect(CreatureDropResolver.resolve(CreatureDropRequest.new(&"creature.flam", &"item.pal_ore", true, false, false, false, false, 3, 0)).status == CreatureDropResult.Status.INVALID_REQUEST, "normal count outside 1..2 must be invalid")
	_expect(CreatureDropResolver.resolve(CreatureDropRequest.new(&"creature.flam", &"item.pal_ore", true, false, false, true, false, 3, 1)).status == CreatureDropResult.Status.INVALID_REQUEST, "elite bonus outside 2..4 must be invalid")

	var repeat := CreatureDropResolver.resolve(CreatureDropRequest.new(&"creature.flam", &"item.pal_ore", true, false, false, true, false, 3, 2))
	_expect(repeat.primary_count == 3 and repeat.bonus_count == 2, "same injected request must resolve deterministically")


func _test_actor_adapter() -> void:
	var packed := load(CREATURE_SCENE_PATH) as PackedScene
	if packed == null:
		_failures.append("unable to load Creature scene")
		return
	var fixture := Node2D.new()
	root.add_child(fixture)
	var creature := packed.instantiate()
	fixture.add_child(creature)
	await process_frame
	creature.set("is_elite", false)
	creature.set("is_alpha", false)
	creature.set("defeat_committed", true)
	creature.set("capture_attempt_active", false)
	creature.set("capture_ownership_committed", false)
	var request: CreatureDropRequest = creature.call("create_defeat_drop_request", 2, 0)
	_expect(request.species_id == LegacySpeciesAdapter.FLAM_ID, "actor request must carry stable Flam ID")
	_expect(request.primary_item_id == &"item.pal_ore", "actor request must source typed Flam drop reference")
	var result := CreatureDropResolver.resolve(request)
	_expect(bool(creature.call("commit_defeat_drop_result", result)), "actor must commit accepted drop result")
	await process_frame
	var drops: Array[Node] = []
	for child in fixture.get_children():
		if child is DroppedItem:
			drops.append(child)
	_expect(drops.size() == 2, "normal Flam must spawn two injected primary drops")
	for drop in drops:
		_expect(drop.get("item_id") == &"item.pal_ore" and int(drop.get("count")) == 1, "spawned Flam drop must preserve stable item ID and legacy quantity")
	_expect(not bool(creature.call("commit_defeat_drop_result", result)), "duplicate actor commit must be rejected")
	await process_frame
	var drop_count_after_duplicate := 0
	for child in fixture.get_children():
		if child is DroppedItem:
			drop_count_after_duplicate += 1
	_expect(drop_count_after_duplicate == 2, "duplicate commit must not spawn more drops")

	var mismatched := CreatureDropResult.new(CreatureDropResult.Status.ACCEPTED, &"creature.slime", &"item.pal_ore", 1)
	_expect(not bool(creature.call("commit_defeat_drop_result", mismatched)), "actor must reject a result for another species")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
