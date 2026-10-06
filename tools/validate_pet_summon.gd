extends SceneTree

const SummonRequest = preload("res://systems/pet/pet_summon_request.gd")
const SummonResult = preload("res://systems/pet/pet_summon_result.gd")
const SummonPolicy = preload("res://systems/pet/pet_summon_policy.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_policy()
	await _test_player_adapter()
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("Pet summon validation passed: stable active identity and single-node lifecycle are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			printerr("PET SUMMON VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _test_policy() -> void:
	_expect(SummonPolicy.resolve(null).status == SummonResult.Status.INVALID_REQUEST, "null request must be invalid")
	_expect(SummonPolicy.resolve(SummonRequest.new(&"creature.flam", &"", true, false)).status == SummonResult.Status.INVALID_REQUEST, "non-pet identity must be invalid")
	_expect(SummonPolicy.resolve(SummonRequest.new(&"pet.one", &"", false, false)).status == SummonResult.Status.INVALID_REQUEST, "missing roster instance must be invalid")
	_expect(SummonPolicy.resolve(SummonRequest.new(&"pet.one", &"", true, false)).status == SummonResult.Status.SUMMON, "empty active slot must summon")
	_expect(SummonPolicy.resolve(SummonRequest.new(&"pet.one", &"pet.one", true, true)).status == SummonResult.Status.NO_CHANGE, "same live instance must not respawn")
	_expect(SummonPolicy.resolve(SummonRequest.new(&"pet.two", &"pet.one", true, true)).status == SummonResult.Status.REPLACE, "different live instance must replace")
	_expect(SummonPolicy.resolve(SummonRequest.new(&"pet.one", &"pet.one", true, false)).status == SummonResult.Status.REPLACE, "stale active identity must recover by replacement")


func _test_player_adapter() -> void:
	var packed_player := load("res://scenes/player.tscn") as PackedScene
	if packed_player == null:
		_failures.append("unable to load Player scene")
		return
	var fixture := Node2D.new()
	root.add_child(fixture)
	var player := packed_player.instantiate()
	fixture.add_child(player)
	await process_frame
	player.set("hud_ref", null)
	player.set("base_manager_ref", null)
	var party: Array[Dictionary] = player.get("pet_party")
	party.clear()
	var species := LegacySpeciesAdapter.create_stable_snapshot(0, {
		"name": "Flam",
		"element": "Lửa",
		"power": 20,
		"max_hp": 100,
		"speed": 100.0,
	})
	party.append({"instance_id": &"pet.one", "species_id": LegacySpeciesAdapter.FLAM_ID, "species_data": species, "level": 1, "rarity_badge": "★", "trait": "Test"})
	party.append({"instance_id": &"pet.two", "species_id": LegacySpeciesAdapter.FLAM_ID, "species_data": species.duplicate(true), "level": 2, "rarity_badge": "★", "trait": "Test"})

	var first: RefCounted = player.call("swap_active_pet", 0)
	var first_node: Node2D = player.get("active_pet_node")
	_expect(first.status == SummonResult.Status.SUMMON, "first slot must summon")
	_expect(first_node != null and first_node.get("pet_instance_id") == &"pet.one", "summoned node must carry roster instance ID")
	_expect(get_nodes_in_group("companion_pets").size() == 1, "first summon must create exactly one companion node")

	var same: RefCounted = player.call("swap_active_pet", 0)
	_expect(same.status == SummonResult.Status.NO_CHANGE and player.get("active_pet_node") == first_node, "same slot must preserve the existing node")
	_expect(get_nodes_in_group("companion_pets").size() == 1, "same slot must not duplicate companion node")

	var replacement: RefCounted = player.call("swap_active_pet", 1)
	var second_node: Node2D = player.get("active_pet_node")
	_expect(replacement.status == SummonResult.Status.REPLACE, "second slot must replace active instance")
	_expect(second_node != first_node and second_node.get("pet_instance_id") == &"pet.two", "replacement node must carry selected instance ID")
	_expect(player.get("active_pet_instance_id") == &"pet.two", "Player active identity must follow accepted replacement")
	_expect(get_nodes_in_group("companion_pets").size() == 1, "replacement must leave exactly one companion node in tree")

	root.remove_child(fixture)
	fixture.free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
