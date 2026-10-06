extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_resolver_contract()
	await _test_actor_adapters()
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame
	if _failures.is_empty():
		print("Combat validation passed: deterministic damage result and Player/Creature adapters are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			printerr("COMBAT VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _test_resolver_contract() -> void:
	var invalid := DamageRequest.new(&"player", &"wild", 10, 10, 0)
	_expect(CombatResolver.resolve(invalid).status == DamageResult.Status.INVALID_REQUEST, "zero damage must be invalid")

	var friendly := DamageRequest.new(&"wild", &"wild", 10, 10, 3)
	var friendly_result := CombatResolver.resolve(friendly)
	_expect(friendly_result.status == DamageResult.Status.FRIENDLY_FIRE_BLOCKED, "friendly damage must be blocked")
	_expect(friendly_result.remaining_hp == 10, "friendly block must preserve HP")

	var defended := DamageRequest.new(&"player", &"wild", 20, 20, 5)
	defended.defense = 8
	var defended_result := CombatResolver.resolve(defended)
	_expect(defended_result.is_applied() and defended_result.applied_damage == 0, "defense must clamp damage at zero")
	_expect(defended_result.remaining_hp == 20, "zero applied damage must preserve HP")

	var lethal := DamageRequest.new(&"player", &"wild", 7, 20, 10, Vector2.ZERO, Vector2.RIGHT)
	lethal.knockback_strength = 160.0
	lethal.tags = PackedStringArray(["melee"])
	var first := CombatResolver.resolve(lethal)
	var second := CombatResolver.resolve(lethal)
	_expect(first.applied_damage == second.applied_damage and first.remaining_hp == second.remaining_hp, "same request must resolve deterministically")
	_expect(first.defeated and first.remaining_hp == 0, "lethal result mismatch")
	_expect(first.knockback == Vector2(160.0, 0.0), "knockback result mismatch")
	_expect(first.tags.has("melee"), "damage tags must be preserved")

	var already := DamageRequest.new(&"player", &"wild", 0, 20, 10)
	_expect(CombatResolver.resolve(already).status == DamageResult.Status.ALREADY_DEFEATED, "zero HP must not resolve a second defeat")
	var immune := DamageRequest.new(&"wild", &"player", 20, 20, 5)
	immune.immune = true
	_expect(CombatResolver.resolve(immune).status == DamageResult.Status.IMMUNE, "immune request status mismatch")


func _test_actor_adapters() -> void:
	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	if packed_main == null:
		_failures.append("unable to load main scene")
		return
	var main_scene := packed_main.instantiate()
	root.add_child(main_scene)
	for frame in range(5):
		await process_frame

	var player := get_first_node_in_group("player")
	_expect(player != null and player.has_method("apply_damage_request"), "Player combat adapter is missing")
	if player != null:
		var player_hp := int(player.get("hp"))
		var player_max_hp := int(player.get("max_hp"))
		var request := DamageRequest.new(&"wild", &"player", player_hp, player_max_hp, 3)
		var result: DamageResult = player.call("apply_damage_request", request)
		_expect(result.is_applied() and int(player.get("hp")) == player_hp - 3, "Player adapter HP mutation mismatch")
		player.set("hp", player_hp)

	var creature := get_first_node_in_group("wild_creatures")
	_expect(creature != null and creature.has_method("apply_damage_request") and creature.has_method("resolve_burn_tick_damage"), "Creature combat adapter is missing")
	if creature != null:
		var creature_hp := int(creature.get("hp"))
		var creature_max_hp := int(creature.get("max_hp"))
		var request := DamageRequest.new(&"player", &"wild", creature_hp, creature_max_hp, 4)
		var result: DamageResult = creature.call("apply_damage_request", request)
		_expect(result.is_applied() and int(creature.get("hp")) == creature_hp - 4, "Creature adapter HP mutation mismatch")
		creature.set("hp", creature_hp)
		var burn_request: DamageRequest = creature.call("create_burn_tick_damage_request")
		_expect(burn_request.base_damage == 8 and burn_request.tags.has("status") and burn_request.tags.has("burn") and burn_request.tags.has("fire"), "Burn tick request must preserve damage and stable tags")
		var burn_result: DamageResult = creature.call("resolve_burn_tick_damage")
		_expect(burn_result.is_applied() and burn_result.applied_damage == 8 and int(creature.get("hp")) == creature_hp - 8, "Burn tick must commit through combat result")
		creature.set("hp", creature_hp)
		creature.set("defeat_committed", true)
		var duplicate_burn: DamageResult = creature.call("resolve_burn_tick_damage")
		_expect(duplicate_burn.status == DamageResult.Status.ALREADY_DEFEATED and int(creature.get("hp")) == creature_hp, "Committed defeat must reject a duplicate burn tick")
		creature.set("defeat_committed", false)
		creature.set("hp", creature_hp)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
