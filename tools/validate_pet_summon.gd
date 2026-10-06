extends SceneTree

const SummonRequest = preload("res://systems/pet/pet_summon_request.gd")
const SummonResult = preload("res://systems/pet/pet_summon_result.gd")
const SummonPolicy = preload("res://systems/pet/pet_summon_policy.gd")
const CommandRequest = preload("res://systems/pet/pet_command_request.gd")
const CommandResult = preload("res://systems/pet/pet_command_result.gd")
const CommandPolicy = preload("res://systems/pet/pet_command_policy.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_policy()
	_test_command_policy()
	await _test_player_adapter()
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("Pet validation passed: stable summon lifecycle and deterministic command stance transitions are valid.")
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


func _test_command_policy() -> void:
	_expect(CommandPolicy.resolve(null).status == CommandResult.Status.INVALID_REQUEST, "null command must be invalid")
	_expect(CommandPolicy.resolve(CommandRequest.new(CommandPolicy.COMMAND_CYCLE_STANCE, &"creature.flam", CommandPolicy.STANCE_AUTO_WORK)).status == CommandResult.Status.INVALID_REQUEST, "command must require pet instance identity")
	_expect(CommandPolicy.resolve(CommandRequest.new(&"pet.command.unknown", &"pet.one", CommandPolicy.STANCE_AUTO_WORK)).status == CommandResult.Status.UNSUPPORTED_COMMAND, "unknown command must fail closed")
	var work_to_combat: RefCounted = CommandPolicy.resolve(CommandRequest.new(CommandPolicy.COMMAND_CYCLE_STANCE, &"pet.one", CommandPolicy.STANCE_AUTO_WORK))
	var combat_to_follow: RefCounted = CommandPolicy.resolve(CommandRequest.new(CommandPolicy.COMMAND_CYCLE_STANCE, &"pet.one", CommandPolicy.STANCE_COMBAT_ASSIST))
	var follow_to_work: RefCounted = CommandPolicy.resolve(CommandRequest.new(CommandPolicy.COMMAND_CYCLE_STANCE, &"pet.one", CommandPolicy.STANCE_FOLLOW_PROTECT))
	_expect(work_to_combat.is_applied() and work_to_combat.next_stance_id == CommandPolicy.STANCE_COMBAT_ASSIST, "auto-work must cycle to combat-assist")
	_expect(combat_to_follow.is_applied() and combat_to_follow.next_stance_id == CommandPolicy.STANCE_FOLLOW_PROTECT, "combat-assist must cycle to follow-protect")
	_expect(follow_to_work.is_applied() and follow_to_work.next_stance_id == CommandPolicy.STANCE_AUTO_WORK, "follow-protect must cycle to auto-work")
	var direct_combat: RefCounted = CommandPolicy.resolve(CommandRequest.new(CommandPolicy.COMMAND_COMBAT_ASSIST, &"pet.one", CommandPolicy.STANCE_AUTO_WORK))
	var direct_follow: RefCounted = CommandPolicy.resolve(CommandRequest.new(CommandPolicy.COMMAND_FOLLOW_PROTECT, &"pet.one", CommandPolicy.STANCE_AUTO_WORK))
	var direct_work: RefCounted = CommandPolicy.resolve(CommandRequest.new(CommandPolicy.COMMAND_AUTO_WORK, &"pet.one", CommandPolicy.STANCE_COMBAT_ASSIST))
	var idempotent: RefCounted = CommandPolicy.resolve(CommandRequest.new(CommandPolicy.COMMAND_AUTO_WORK, &"pet.one", CommandPolicy.STANCE_AUTO_WORK))
	_expect(direct_combat.next_stance_id == CommandPolicy.STANCE_COMBAT_ASSIST and direct_combat.is_applied(), "explicit combat command mismatch")
	_expect(direct_follow.next_stance_id == CommandPolicy.STANCE_FOLLOW_PROTECT and direct_follow.is_applied(), "explicit follow command mismatch")
	_expect(direct_work.next_stance_id == CommandPolicy.STANCE_AUTO_WORK and direct_work.is_applied(), "explicit work command mismatch")
	_expect(idempotent.status == CommandResult.Status.NO_CHANGE and idempotent.is_resolved() and not idempotent.is_applied(), "same explicit stance must resolve as no-change")


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
	var invalid_command: RefCounted = first_node.call("apply_pet_command", &"pet.command.unknown")
	_expect(invalid_command.status == CommandResult.Status.UNSUPPORTED_COMMAND and first_node.call("get_stance_id") == CommandPolicy.STANCE_AUTO_WORK, "invalid command must not mutate actor stance")
	var command_one: RefCounted = first_node.call("apply_pet_command", CommandPolicy.COMMAND_CYCLE_STANCE)
	var command_two: RefCounted = first_node.call("apply_pet_command", CommandPolicy.COMMAND_CYCLE_STANCE)
	var command_three: RefCounted = first_node.call("apply_pet_command", CommandPolicy.COMMAND_CYCLE_STANCE)
	_expect(command_one.next_stance_id == CommandPolicy.STANCE_COMBAT_ASSIST, "actor first command mismatch")
	_expect(command_two.next_stance_id == CommandPolicy.STANCE_FOLLOW_PROTECT, "actor second command mismatch")
	_expect(command_three.next_stance_id == CommandPolicy.STANCE_AUTO_WORK and first_node.call("get_stance_id") == CommandPolicy.STANCE_AUTO_WORK, "actor command cycle must return to auto-work")
	var direct_actor: RefCounted = first_node.call("apply_pet_command", CommandPolicy.COMMAND_FOLLOW_PROTECT)
	var same_actor: RefCounted = first_node.call("apply_pet_command", CommandPolicy.COMMAND_FOLLOW_PROTECT)
	_expect(direct_actor.is_applied() and first_node.call("get_stance_id") == CommandPolicy.STANCE_FOLLOW_PROTECT, "actor explicit follow command mismatch")
	_expect(same_actor.status == CommandResult.Status.NO_CHANGE and first_node.call("get_stance_id") == CommandPolicy.STANCE_FOLLOW_PROTECT, "actor idempotent command must preserve stance")

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
