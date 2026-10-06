extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_hp_curve_and_spheres()
	_test_status_modifiers_and_rolls()
	_test_invalid_and_guard_statuses()
	_test_determinism()
	_test_sphere_selection()
	_test_sphere_scene_adapter()
	_test_species_mapping_and_ownership_resolver()
	await _test_creature_adapter()
	await _test_player_sphere_adapter()
	await _test_ownership_lifecycle_adapter()
	await _clean_tree()
	if _failures.is_empty():
		print("Capture validation passed: deterministic resolution, stable sphere transaction and atomic roster ownership are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			printerr("CAPTURE VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _test_hp_curve_and_spheres() -> void:
	var full := CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 100, 100, 1.0, 0.5))
	var low := CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 25, 100, 1.0, 0.5))
	var zero := CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 0, 100, 1.0, 0.5))
	_expect(is_equal_approx(full.base_chance, 0.25), "full-HP base chance mismatch")
	_expect(is_equal_approx(low.base_chance, 0.775), "low-HP base chance mismatch")
	_expect(is_equal_approx(zero.base_chance, 0.95), "zero-HP base chance mismatch")

	var mega := CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 100, 100, 2.0, 0.5))
	var giga := CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 100, 100, 4.0, 0.5))
	var minimum := CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 100, 100, 0.1, 0.5))
	_expect(is_equal_approx(mega.final_chance, 0.5), "mega sphere multiplier mismatch")
	_expect(is_equal_approx(giga.final_chance, CaptureResolver.MAX_FINAL_CHANCE), "maximum final chance clamp mismatch")
	_expect(is_equal_approx(minimum.final_chance, CaptureResolver.MIN_FINAL_CHANCE), "minimum final chance clamp mismatch")


func _test_status_modifiers_and_rolls() -> void:
	var sleep_request := CaptureRequest.new(&"creature.test", 100, 100, 1.0, 0.5)
	sleep_request.is_asleep = true
	var sleep := CaptureResolver.resolve(sleep_request)
	_expect(is_equal_approx(sleep.applied_multiplier, 1.4), "sleep multiplier bonus mismatch")
	_expect(is_equal_approx(sleep.final_chance, 0.35) and sleep.tags.has("sleep"), "sleep capture result mismatch")

	var back_request := CaptureRequest.new(&"creature.test", 100, 100, 1.0, 0.5)
	back_request.is_back_strike = true
	var back := CaptureResolver.resolve(back_request)
	_expect(is_equal_approx(back.applied_multiplier, 1.35), "back-strike multiplier bonus mismatch")
	_expect(is_equal_approx(back.final_chance, 0.3375) and back.tags.has("back_strike"), "back-strike result mismatch")

	var combined_request := CaptureRequest.new(&"creature.test", 100, 100, 1.0, 0.4375)
	combined_request.is_asleep = true
	combined_request.is_back_strike = true
	var combined := CaptureResolver.resolve(combined_request)
	_expect(is_equal_approx(combined.applied_multiplier, 1.75), "combined modifier mismatch")
	_expect(is_equal_approx(combined.final_chance, 0.4375), "combined final chance mismatch")
	_expect(combined.succeeded, "roll equal to chance must succeed")
	_expect(CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 100, 100, 1.0, 0.0)).succeeded, "roll zero must succeed")
	_expect(not CaptureResolver.resolve(CaptureRequest.new(&"creature.test", 0, 100, 4.0, 1.0)).succeeded, "roll one must fail under 0.98 cap")


func _test_invalid_and_guard_statuses() -> void:
	_expect(CaptureResolver.resolve(null).status == CaptureResult.Status.INVALID_REQUEST, "null request status mismatch")
	_expect(CaptureResolver.resolve(CaptureRequest.new(&"", 1, 0, 1.0, 0.5)).status == CaptureResult.Status.INVALID_REQUEST, "zero max HP must be invalid")
	_expect(CaptureResolver.resolve(CaptureRequest.new(&"", 101, 100, 1.0, 0.5)).status == CaptureResult.Status.INVALID_REQUEST, "HP above max must be invalid")
	_expect(CaptureResolver.resolve(CaptureRequest.new(&"", 50, 100, 0.0, 0.5)).status == CaptureResult.Status.INVALID_REQUEST, "zero sphere multiplier must be invalid")
	_expect(CaptureResolver.resolve(CaptureRequest.new(&"", 50, 100, 1.0, -0.1)).status == CaptureResult.Status.INVALID_REQUEST, "negative roll must be invalid")
	_expect(CaptureResolver.resolve(CaptureRequest.new(&"", 50, 100, 1.0, 1.1)).status == CaptureResult.Status.INVALID_REQUEST, "roll above one must be invalid")

	var invalid_target := CaptureRequest.new(&"", 50, 100, 1.0, 0.5)
	invalid_target.target_valid = false
	_expect(CaptureResolver.resolve(invalid_target).status == CaptureResult.Status.INVALID_TARGET, "invalid target status mismatch")
	var capturing := CaptureRequest.new(&"", 50, 100, 1.0, 0.5)
	capturing.already_capturing = true
	_expect(CaptureResolver.resolve(capturing).status == CaptureResult.Status.ALREADY_CAPTURING, "duplicate capture status mismatch")
	var defeated := CaptureRequest.new(&"", 0, 100, 1.0, 0.5)
	defeated.already_defeated = true
	_expect(CaptureResolver.resolve(defeated).status == CaptureResult.Status.ALREADY_DEFEATED, "defeated target status mismatch")


func _test_determinism() -> void:
	var request := CaptureRequest.new(&"creature.test", 30, 120, 2.0, 0.42)
	request.is_asleep = true
	request.is_back_strike = true
	var first := CaptureResolver.resolve(request)
	var second := CaptureResolver.resolve(request)
	_expect(first.status == second.status and first.succeeded == second.succeeded, "same request must resolve the same status/outcome")
	_expect(is_equal_approx(first.final_chance, second.final_chance), "same request must resolve the same chance")
	_expect(first.tags == second.tags, "same request must resolve the same tags")


func _test_sphere_selection() -> void:
	var none := CaptureSphereSelector.select({})
	_expect(none.status == CaptureSphereSelectionResult.Status.NONE_AVAILABLE, "empty sphere selection status mismatch")
	var basic := CaptureSphereSelector.select({CaptureSphereSelector.BASIC_ID: 2})
	_expect(basic.item_id == CaptureSphereSelector.BASIC_ID and basic.catch_multiplier == 1.0, "basic sphere selection mismatch")
	var mega := CaptureSphereSelector.select({CaptureSphereSelector.BASIC_ID: 2, CaptureSphereSelector.MEGA_ID: 1})
	_expect(mega.item_id == CaptureSphereSelector.MEGA_ID and mega.catch_multiplier == 2.0, "mega sphere priority/multiplier mismatch")
	var giga := CaptureSphereSelector.select({CaptureSphereSelector.BASIC_ID: 2, CaptureSphereSelector.MEGA_ID: 1, CaptureSphereSelector.GIGA_ID: 1})
	_expect(giga.item_id == CaptureSphereSelector.GIGA_ID and giga.catch_multiplier == 4.0, "giga sphere priority/multiplier mismatch")
	_expect(not CaptureSphereSelector.is_supported(&"item.unknown"), "unknown sphere ID must fail closed")
	_expect(LegacyItemAdapter.to_legacy_key(CaptureSphereSelector.BASIC_ID) == "Cầu Thu Phục", "basic sphere legacy mapping mismatch")
	_expect(LegacyItemAdapter.to_content_id("Mega Sphere") == CaptureSphereSelector.MEGA_ID, "mega sphere stable mapping mismatch")


func _test_sphere_scene_adapter() -> void:
	var packed_sphere := load("res://scenes/sphere.tscn") as PackedScene
	if packed_sphere == null:
		_failures.append("unable to load sphere scene")
		return
	var sphere := packed_sphere.instantiate()
	_expect(bool(sphere.call("configure_capture_sphere", CaptureSphereSelector.MEGA_ID, 2.0)), "Sphere must accept matching stable ID/multiplier")
	_expect(not bool(sphere.call("configure_capture_sphere", &"item.unknown", 1.0)), "Sphere must reject unknown stable ID")
	_expect(not bool(sphere.call("configure_capture_sphere", CaptureSphereSelector.MEGA_ID, 4.0)), "Sphere must reject mismatched multiplier")
	var drop: Node = sphere.call("create_missed_drop")
	_expect(drop.get("item_id") == CaptureSphereSelector.MEGA_ID, "missed sphere drop must preserve stable item ID")
	_expect(drop.get("item_name") == "Mega Sphere" and int(drop.get("count")) == 1, "missed sphere legacy adapter mismatch")
	drop.free()
	sphere.free()


func _test_species_mapping_and_ownership_resolver() -> void:
	_expect(LegacySpeciesAdapter.to_content_id(0) == LegacySpeciesAdapter.FLAM_ID, "Flam stable species mapping mismatch")
	_expect(LegacySpeciesAdapter.to_content_id(4) == LegacySpeciesAdapter.DRAGON_ID, "Dragon stable species mapping mismatch")
	_expect(LegacySpeciesAdapter.to_content_id(5).is_empty(), "unknown legacy species index must fail closed")
	_expect(LegacySpeciesAdapter.to_legacy_index(LegacySpeciesAdapter.MUSHROOM_ID) == 2, "stable species reverse mapping mismatch")
	_expect(not LegacySpeciesAdapter.is_supported(&"creature.unknown"), "unknown species ID must fail closed")

	var source := {
		"id": LegacySpeciesAdapter.FLAM_ID,
		"name": "Flam",
		"element": "Lửa",
		"power": 20,
		"max_hp": 100,
		"speed": 100.0,
	}
	var legendary_request := CaptureOwnershipRequest.new(
		&"capture.legendary",
		&"pet.legendary_1",
		LegacySpeciesAdapter.FLAM_ID,
		source,
		3,
		0.0,
		1.0
	)
	var legendary := CaptureOwnershipResolver.resolve(legendary_request)
	_expect(legendary.is_accepted(), "valid legendary ownership request must be accepted")
	_expect(legendary.rarity_badge == CaptureOwnershipResolver.LEGENDARY_BADGE, "legendary boundary mismatch")
	_expect(legendary.trait_name == CaptureOwnershipResolver.LEGENDARY_TRAIT, "legendary trait mismatch")
	_expect(legendary.rarity_id == &"pet.rarity.legendary" and legendary.trait_id == &"pet.trait.dragon_blessing", "legendary stable metadata mismatch")
	_expect(int(legendary.party_entry["species_data"]["power"]) == 30, "legendary power multiplier mismatch")
	_expect(int(legendary.party_entry["species_data"]["max_hp"]) == 150, "legendary HP multiplier mismatch")
	_expect(int(source["power"]) == 20 and int(source["max_hp"]) == 100, "ownership resolver must not mutate source snapshot")
	_expect(legendary.party_entry["instance_id"] == &"pet.legendary_1", "party entry must carry injected persistent instance ID")
	_expect(legendary.party_entry["species_id"] == LegacySpeciesAdapter.FLAM_ID, "party entry must carry stable species ID")
	_expect(legendary.reward_exp == CaptureOwnershipResolver.CAPTURE_REWARD_EXP, "capture reward EXP mismatch")

	var epic := CaptureOwnershipResolver.resolve(CaptureOwnershipRequest.new(
		&"capture.epic",
		&"pet.epic_1",
		LegacySpeciesAdapter.FLAM_ID,
		source,
		1,
		0.05,
		1.0
	))
	_expect(epic.rarity_badge == CaptureOwnershipResolver.EPIC_BADGE, "epic lower boundary mismatch")
	_expect(epic.trait_name == CaptureOwnershipResolver.EPIC_TRAITS[2], "epic trait upper roll mismatch")
	var rare := CaptureOwnershipResolver.resolve(CaptureOwnershipRequest.new(
		&"capture.rare",
		&"pet.rare_1",
		LegacySpeciesAdapter.FLAM_ID,
		source,
		1,
		0.20,
		0.0
	))
	_expect(rare.rarity_badge == CaptureOwnershipResolver.RARE_BADGE, "rare lower boundary mismatch")
	_expect(rare.trait_name == CaptureOwnershipResolver.RARE_TRAITS[0], "rare trait lower roll mismatch")
	var common := CaptureOwnershipResolver.resolve(CaptureOwnershipRequest.new(
		&"capture.common",
		&"pet.common_1",
		LegacySpeciesAdapter.FLAM_ID,
		source,
		1,
		0.45,
		0.5
	))
	_expect(common.rarity_badge == CaptureOwnershipResolver.COMMON_BADGE, "common lower boundary mismatch")
	_expect(common.party_entry["rarity_id"] == &"pet.rarity.common" and common.party_entry["trait_id"] == &"pet.trait.normal", "common party entry stable metadata mismatch")
	_expect(common.party_entry["stance_id"] == &"pet.stance.auto_work", "captured pet must start with stable auto-work stance")

	var duplicate_request := CaptureOwnershipRequest.new(&"capture.duplicate", &"pet.duplicate_1", LegacySpeciesAdapter.FLAM_ID, source, 1, 0.5, 0.5)
	duplicate_request.already_committed = true
	_expect(CaptureOwnershipResolver.resolve(duplicate_request).status == CaptureOwnershipResult.Status.DUPLICATE, "duplicate ownership status mismatch")
	_expect(CaptureOwnershipResolver.resolve(CaptureOwnershipRequest.new(&"", &"pet.invalid_1", LegacySpeciesAdapter.FLAM_ID, source, 1, 0.5, 0.5)).status == CaptureOwnershipResult.Status.INVALID_REQUEST, "empty capture token must be invalid")
	_expect(CaptureOwnershipResolver.resolve(CaptureOwnershipRequest.new(&"capture.bad_instance", &"creature.not_a_pet", LegacySpeciesAdapter.FLAM_ID, source, 1, 0.5, 0.5)).status == CaptureOwnershipResult.Status.INVALID_REQUEST, "non-pet instance ID must be invalid")
	_expect(CaptureOwnershipResolver.resolve(CaptureOwnershipRequest.new(&"capture.unknown", &"pet.unknown_1", &"creature.unknown", source, 1, 0.5, 0.5)).status == CaptureOwnershipResult.Status.UNKNOWN_SPECIES, "unknown species ownership status mismatch")
	var mismatched := source.duplicate(true)
	mismatched["id"] = LegacySpeciesAdapter.SLIME_ID
	_expect(CaptureOwnershipResolver.resolve(CaptureOwnershipRequest.new(&"capture.mismatch", &"pet.mismatch_1", LegacySpeciesAdapter.FLAM_ID, mismatched, 1, 0.5, 0.5)).status == CaptureOwnershipResult.Status.INVALID_REQUEST, "mismatched snapshot species ID must be invalid")
	_expect(CaptureOwnershipResolver.resolve(CaptureOwnershipRequest.new(&"capture.bad_roll", &"pet.bad_roll_1", LegacySpeciesAdapter.FLAM_ID, source, 1, 1.1, 0.5)).status == CaptureOwnershipResult.Status.INVALID_REQUEST, "out-of-range rarity roll must be invalid")

	var first := CaptureOwnershipResolver.resolve(CaptureOwnershipRequest.new(&"capture.repeat", &"pet.repeat_1", LegacySpeciesAdapter.FLAM_ID, source, 2, 0.19, 0.75))
	var second := CaptureOwnershipResolver.resolve(CaptureOwnershipRequest.new(&"capture.repeat", &"pet.repeat_1", LegacySpeciesAdapter.FLAM_ID, source, 2, 0.19, 0.75))
	_expect(first.rarity_badge == second.rarity_badge and first.trait_name == second.trait_name, "ownership resolver must be deterministic")
	_expect(first.party_entry == second.party_entry, "same ownership request must produce the same party entry")

func _test_creature_adapter() -> void:
	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	if packed_main == null:
		_failures.append("unable to load main scene")
		return
	var main_scene := packed_main.instantiate()
	root.add_child(main_scene)
	for frame in range(5):
		await process_frame

	var creature := get_first_node_in_group("wild_creatures")
	_expect(creature != null and creature.has_method("resolve_capture_request"), "Creature capture adapter is missing")
	if creature == null:
		return
	var creature_parent := creature.get_parent()
	creature_parent.remove_child(creature)
	var script_constants: Dictionary = creature.get_script().get_script_constant_map()
	var state_values: Dictionary = script_constants.get("State", {})
	creature.set("state", int(state_values.get("SLEEP", -1)))
	creature.set("facing_row", 0)
	var throw_position: Vector2 = creature.global_position + Vector2.UP * 10.0
	var request: CaptureRequest = creature.call("create_capture_request", 1.0, 0.0, throw_position)
	_expect(request.species_id == LegacySpeciesAdapter.to_content_id(int(creature.get("species_index"))), "Creature adapter must attach stable species ID")
	_expect(request.is_asleep, "Creature adapter must snapshot sleep before CAPTURING transition")
	_expect(request.is_back_strike, "Creature adapter back-strike projection mismatch")
	var result: CaptureResult = creature.call("resolve_capture_request", request)
	_expect(result.is_resolved() and result.tags.has("sleep") and result.tags.has("back_strike"), "Creature adapter modifier resolution mismatch")

	creature.set("capture_attempt_active", true)
	var duplicate_request: CaptureRequest = creature.call("create_capture_request", 1.0, 0.0, Vector2.ZERO)
	var duplicate: CaptureResult = creature.call("resolve_capture_request", duplicate_request)
	_expect(duplicate.status == CaptureResult.Status.ALREADY_CAPTURING, "Creature adapter must reject concurrent capture")
	creature.free()


func _test_player_sphere_adapter() -> void:
	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	if packed_main == null:
		_failures.append("unable to reload main scene for Player sphere adapter")
		return
	var main_scene := packed_main.instantiate()
	root.add_child(main_scene)
	for frame in range(5):
		await process_frame
	var player := get_first_node_in_group("player")
	_expect(player != null and player.has_method("select_capture_sphere") and player.has_method("spend_capture_sphere"), "Player sphere transaction adapter is missing")
	if player == null:
		return
	var inventory: Dictionary = player.get("inventory")
	inventory["Cầu Thu Phục"] = 0
	inventory["Mega Sphere"] = 0
	inventory["Giga Sphere"] = 0
	var none: CaptureSphereSelectionResult = player.call("select_capture_sphere")
	_expect(not none.is_selected(), "Player must report no available sphere")

	inventory["Cầu Thu Phục"] = 2
	inventory["Mega Sphere"] = 1
	inventory["Giga Sphere"] = 1
	var selected: CaptureSphereSelectionResult = player.call("select_capture_sphere")
	_expect(selected.item_id == CaptureSphereSelector.GIGA_ID, "Player must select highest-priority sphere")
	_expect(bool(player.call("spend_capture_sphere", selected)), "Player sphere spend must commit")
	_expect(inventory["Giga Sphere"] == 0 and inventory["Mega Sphere"] == 1 and inventory["Cầu Thu Phục"] == 2, "sphere spend must decrement exactly one selected item")

	var unknown := CaptureSphereSelectionResult.new(CaptureSphereSelectionResult.Status.OK, &"item.unknown", 1.0)
	var inventory_before_unknown := inventory.duplicate()
	_expect(not bool(player.call("spend_capture_sphere", unknown)), "unknown sphere spend must fail closed")
	_expect(inventory == inventory_before_unknown, "unknown sphere spend must not mutate inventory")

	player.set("is_building", true)
	var before_guard := int(inventory["Mega Sphere"])
	_expect(not bool(player.call("throw_pal_sphere")), "build mode must reject sphere launch")
	_expect(int(inventory["Mega Sphere"]) == before_guard, "build rejection must not spend sphere")
	player.set("is_building", false)
	player.set("sphere_cooldown", 0.5)
	_expect(not bool(player.call("throw_pal_sphere")), "cooldown must reject sphere launch")
	_expect(int(inventory["Mega Sphere"]) == before_guard, "cooldown rejection must not spend sphere")
	player.set("sphere_cooldown", 0.0)
	inventory["Giga Sphere"] = 0
	inventory["Mega Sphere"] = 1
	var player_parent := player.get_parent()
	var children_before := player_parent.get_child_count()
	var audio_manager := root.get_node_or_null("AudioManager")
	var sounds: Dictionary = audio_manager.get("sounds") if audio_manager != null else {}
	var sphere_sound: AudioStream = sounds.get("sphere_throw")
	sounds.erase("sphere_throw")
	var launch_succeeded := bool(player.call("throw_pal_sphere"))
	if sphere_sound != null:
		sounds["sphere_throw"] = sphere_sound
	_expect(launch_succeeded, "valid sphere launch must succeed")
	_expect(inventory["Mega Sphere"] == 0, "valid launch must spend exactly one selected sphere")
	var spawned_sphere: Node = null
	for child_index in range(children_before, player_parent.get_child_count()):
		var candidate := player_parent.get_child(child_index)
		if candidate.has_method("configure_capture_sphere"):
			spawned_sphere = candidate
			break
	_expect(spawned_sphere != null, "valid launch must add a sphere projectile")
	if spawned_sphere != null:
		_expect(spawned_sphere.get("item_id") == CaptureSphereSelector.MEGA_ID, "spawned projectile must carry stable sphere ID")
	for child_index in range(player_parent.get_child_count() - 1, children_before - 1, -1):
		var spawned_child := player_parent.get_child(child_index)
		player_parent.remove_child(spawned_child)
		spawned_child.free()


func _test_ownership_lifecycle_adapter() -> void:
	var packed_player := load("res://scenes/player.tscn") as PackedScene
	var packed_creature := load("res://scenes/creature.tscn") as PackedScene
	if packed_player == null or packed_creature == null:
		_failures.append("unable to load Player/Creature scenes for ownership lifecycle")
		return

	var fixture := Node2D.new()
	root.add_child(fixture)
	var player := packed_player.instantiate()
	fixture.add_child(player)
	await process_frame
	player.set("hud_ref", null)
	player.set("base_manager_ref", null)
	var party: Array[Dictionary] = player.get("pet_party")
	var committed_tokens: Dictionary = player.get("committed_capture_tokens")
	party.clear()
	committed_tokens.clear()
	player.set("exp_val", 0)
	player.set("max_exp", 100)

	var stable_source := LegacySpeciesAdapter.create_stable_snapshot(0, {
		"name": "Flam",
		"element": "Lửa",
		"power": 20,
		"max_hp": 100,
		"speed": 100.0,
	})
	var accepted: CaptureOwnershipResult = player.call(
		"on_pet_captured",
		stable_source,
		2,
		&"capture.player_adapter",
		0.45,
		0.5
	)
	_expect(accepted.is_accepted(), "Player ownership adapter must accept valid request")
	_expect(party.size() == 1 and int(player.get("exp_val")) == 75, "accepted ownership must append and reward exactly once")
	_expect(ContentId.domain_of(party[0]["instance_id"]) == &"pet", "Player party entry must expose a valid pet instance ID")
	_expect(party[0]["species_id"] == LegacySpeciesAdapter.FLAM_ID, "Player party entry must expose stable species ID")
	var duplicate: CaptureOwnershipResult = player.call(
		"on_pet_captured",
		stable_source,
		2,
		&"capture.player_adapter",
		0.0,
		0.0
	)
	_expect(duplicate.status == CaptureOwnershipResult.Status.DUPLICATE, "Player must reject duplicate capture token")
	_expect(party.size() == 1 and int(player.get("exp_val")) == 75, "duplicate ownership must not append or reward")
	var invalid_before := party.size()
	var invalid: CaptureOwnershipResult = player.call(
		"on_pet_captured",
		stable_source,
		2,
		&"capture.player_invalid",
		-0.1,
		0.5
	)
	_expect(invalid.status == CaptureOwnershipResult.Status.INVALID_REQUEST, "Player must reject invalid ownership input")
	_expect(party.size() == invalid_before and int(player.get("exp_val")) == 75, "invalid ownership must not mutate roster/reward")

	var audio_manager := root.get_node_or_null("AudioManager")
	var sounds: Dictionary = audio_manager.get("sounds") if audio_manager != null else {}
	var success_sound: AudioStream = sounds.get("success")
	sounds.erase("success")

	player.set("level", 1)
	player.set("exp_val", 0)
	player.set("max_exp", 1000)
	var accepted_creature := packed_creature.instantiate()
	accepted_creature.set("species_index", 1)
	fixture.add_child(accepted_creature)
	await process_frame
	var party_before_creature := party.size()
	var exp_before_creature := int(player.get("exp_val"))
	var creature_result: CaptureOwnershipResult = accepted_creature.call("capture_succeeded", player)
	_expect(creature_result.is_accepted(), "WildCreature must accept valid ownership commit")
	_expect(bool(accepted_creature.get("capture_ownership_committed")), "WildCreature accepted ownership flag mismatch")
	_expect(accepted_creature.is_queued_for_deletion(), "accepted WildCreature must queue despawn")
	var repeated_result: CaptureOwnershipResult = accepted_creature.call("capture_succeeded", player)
	_expect(repeated_result.status == CaptureOwnershipResult.Status.DUPLICATE, "WildCreature repeated success callback must be duplicate")
	_expect(party.size() == party_before_creature + 1, "WildCreature repeated callback must append exactly once")
	_expect(party[party.size() - 1]["instance_id"] != party[0]["instance_id"], "separate captures must receive unique pet instance IDs")
	_expect(int(player.get("exp_val")) == exp_before_creature + 75, "WildCreature repeated callback must reward exactly once")
	await process_frame
	_expect(not is_instance_valid(accepted_creature), "accepted WildCreature must despawn after commit")

	var rejected_creature := packed_creature.instantiate()
	rejected_creature.set("species_index", 2)
	fixture.add_child(rejected_creature)
	await process_frame
	var rejected_data: Dictionary = rejected_creature.get("cur_data")
	rejected_data["id"] = &"creature.unknown"
	rejected_creature.set("capture_attempt_active", true)
	var party_before_reject := party.size()
	var exp_before_reject := int(player.get("exp_val"))
	var rejected_result: CaptureOwnershipResult = rejected_creature.call("capture_succeeded", player)
	_expect(rejected_result.status == CaptureOwnershipResult.Status.UNKNOWN_SPECIES, "unknown species commit must be rejected")
	_expect(not rejected_creature.is_queued_for_deletion(), "rejected WildCreature must remain in world")
	_expect(not bool(rejected_creature.get("capture_attempt_active")), "rejected ownership must clear capture attempt")
	_expect(party.size() == party_before_reject and int(player.get("exp_val")) == exp_before_reject, "rejected ownership must not mutate roster/reward")

	if success_sound != null:
		sounds["success"] = success_sound
	fixture.remove_child(rejected_creature)
	rejected_creature.free()
	fixture.remove_child(player)
	player.free()
	root.remove_child(fixture)
	fixture.free()
	await process_frame

func _clean_tree() -> void:
	var audio_manager := root.get_node_or_null("AudioManager")
	if audio_manager != null:
		var audio_players: Array = audio_manager.get("sfx_players")
		for audio_player in audio_players:
			audio_player.stop()
			audio_player.stream = null
	for tween in get_processed_tweens():
		tween.kill()
	for child in root.get_children():
		child.free()
	for frame in range(5):
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
