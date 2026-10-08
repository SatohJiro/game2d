class_name SaveApplyAdapter
extends RefCounted

const Schema = preload("res://systems/save/save_v1_schema.gd")
const ApplyPlan = preload("res://systems/save/save_apply_plan.gd")
const ApplyResult = preload("res://systems/save/save_apply_result.gd")
const PetMetadata = preload("res://systems/pet/pet_metadata_catalog.gd")
const BaseProgressStateModel = preload("res://systems/progression/base_progress_state.gd")
const BuildingPlacementRecordModel = preload("res://systems/building/building_placement_record.gd")
const ResourceDepletionRecordModel = preload("res://systems/world/resource_depletion_record.gd")


static func apply_player_snapshot(player: Node, snapshot: Variant) -> RefCounted:
	if player == null or not is_instance_valid(player) or not player.has_method("swap_active_pet"):
		return ApplyResult.new(ApplyResult.Status.INVALID_TARGET)
	var validation: RefCounted = Schema.validate(snapshot)
	if not validation.is_valid():
		return ApplyResult.new(ApplyResult.Status.INVALID_SNAPSHOT, 0.0, validation.errors)
	var errors := PackedStringArray()
	var plan: RefCounted = _create_plan(player, snapshot, errors)
	if plan == null:
		return ApplyResult.new(ApplyResult.Status.UNSUPPORTED_REFERENCE, 0.0, errors)
	return _commit(player, plan)


static func _create_plan(player: Node, snapshot: Dictionary, errors: PackedStringArray) -> RefCounted:
	var legacy_inventory := {}
	for item_key: Variant in snapshot["inventory"]:
		var item_id := StringName(item_key)
		var legacy_key := LegacyItemAdapter.to_legacy_key(item_id)
		if legacy_key.is_empty():
			errors.append("unsupported inventory ID: %s" % item_key)
			continue
		legacy_inventory[legacy_key] = int(snapshot["inventory"][item_key])

	var party: Array[Dictionary] = []
	var active_id := StringName(snapshot["player"]["active_pet_instance_id"])
	var active_index := -1
	var active_command_id := &""
	for pet_value: Variant in snapshot["pets"]:
		var pet: Dictionary = pet_value
		var species_id := StringName(pet["species_id"])
		var rarity_id := StringName(pet["rarity_id"])
		var trait_id := StringName(pet["trait_id"])
		var stance_id := StringName(pet["stance_id"])
		var species_data := LegacySpeciesAdapter.create_runtime_snapshot_for_id(species_id)
		var stance_command_id := _command_for_stance(stance_id)
		if species_data.is_empty():
			errors.append("unsupported pet species ID: %s" % species_id)
			continue
		if stance_command_id.is_empty():
			errors.append("unsupported pet stance ID: %s" % pet["stance_id"])
			continue
		if not PetMetadata.is_valid_rarity(rarity_id) or not PetMetadata.is_valid_trait(trait_id):
			errors.append("unsupported pet rarity/trait ID: %s / %s" % [rarity_id, trait_id])
			continue
		var entry := {
			"instance_id": StringName(pet["instance_id"]),
			"species_id": species_id,
			"species_data": species_data,
			"level": int(pet["level"]),
			"exp": int(pet["exp"]),
			"rarity_id": rarity_id,
			"trait_id": trait_id,
			"stance_id": stance_id,
			"rarity_badge": PetMetadata.rarity_badge(rarity_id),
			"trait": PetMetadata.trait_name(trait_id),
		}
		party.append(entry)
		if entry["instance_id"] == active_id:
			active_index = party.size() - 1
			active_command_id = stance_command_id

	if not errors.is_empty():
		return null
	var base_state := BaseProgressStateModel.from_dto(snapshot["base"])
	var base_manager: Variant = player.get("base_manager_ref")
	if base_state == null:
		errors.append("unsupported base progression state")
		return null
	if not is_instance_valid(base_manager) and not _is_default_base_state(base_state):
		errors.append("base progression owner is unavailable")
		return null
	if is_instance_valid(base_manager) and not base_manager.has_method("apply_persistence_state"):
		errors.append("base progression owner lacks apply boundary")
		return null
	var placements: Array[BuildingPlacementRecord] = []
	for value: Variant in snapshot["world"]["entity_deltas"]:
		var record := BuildingPlacementRecordModel.from_dto(value)
		if record == null:
			errors.append("unsupported building placement record")
			return null
		placements.append(record)
	var resource_depletions: Array[ResourceDepletionRecord] = []
	for value: Variant in snapshot["world"].get("resource_deltas", []):
		var record := ResourceDepletionRecordModel.from_dto(value)
		if record == null:
			errors.append("unsupported resource depletion record")
			return null
		resource_depletions.append(record)
	if not player.has_method("can_apply_resource_depletion_snapshot") or not bool(player.call("can_apply_resource_depletion_snapshot", resource_depletions)):
		errors.append("resource depletion owner or instance is unavailable")
		return null
	var player_data: Dictionary = snapshot["player"]
	var progression_state := PlayerProgressionState.from_dto(player_data.get("progression_state"))
	if progression_state == null:
		progression_state = PlayerProgressionState.create_legacy_default(int(player_data["level"]), int(player_data["exp"]))
	var cycle_state := WorldCycleState.from_dto(snapshot["world"].get("cycle_state", {"raid_triggered_this_cycle": false}), float(snapshot["world"]["clock_seconds"]))
	var boss_state: WorldBossState = WorldBossState.from_dto(snapshot["world"].get("world_boss_state"))
	if boss_state == null:
		boss_state = WorldBossState.new(WorldBossState.DEFEATED, WorldBossState.INSTANCE_ID, 0, Vector2.ZERO) if cycle_state.boss_spawned else WorldBossState.new()
	var raid_state: NightRaidState = NightRaidState.from_dto(snapshot["world"].get("night_raid_state"))
	if raid_state == null:
		raid_state = NightRaidState.new(NightRaidState.CLEARED, NightRaidState.ENCOUNTER_ID, int(floor(float(snapshot["world"]["clock_seconds"]) / NightRaidState.DAY_DURATION)), []) if cycle_state.raid_triggered_this_cycle else NightRaidState.new()
	return ApplyPlan.new(
		player_data,
		legacy_inventory,
		party,
		active_id,
		active_index,
		active_command_id,
		base_state,
		placements,
		resource_depletions,
		float(snapshot["world"]["clock_seconds"]),
		cycle_state.raid_triggered_this_cycle,
		cycle_state.boss_spawned,
		cycle_state.boss_timer,
		cycle_state.spawn_timer,
		boss_state,
		raid_state,
		progression_state
	)


static func _commit(player: Node, plan: RefCounted) -> RefCounted:
	_dismiss_active_pet(player)
	player.global_position = Vector2(float(plan.player_state["position"]["x"]), float(plan.player_state["position"]["y"]))
	var progression: PlayerProgressionState = plan.player_progression_state
	player.set("level", progression.level)
	player.set("exp_val", progression.exp)
	player.set("max_exp", progression.max_exp)
	player.set("stat_points", progression.stat_points)
	var runtime_stats: Dictionary = player.get("stats")
	runtime_stats.clear()
	runtime_stats.merge(progression.stats, true)
	player.set("weapon_name", PlayerEquipmentCatalog.weapon_display_name(progression.weapon_id))
	player.set("weapon_damage", PlayerEquipmentCatalog.weapon_damage(progression.weapon_id))
	player.set("has_armor", progression.armor_id == PlayerEquipmentCatalog.PAL_WARRIOR_ARMOR)
	player.set("max_hp", progression.max_hp)
	player.set("max_stamina", progression.max_stamina)
	player.set("max_hunger", progression.max_hunger)
	player.set("max_thirst", progression.max_thirst)
	var needs_state: PlayerNeedsState = player.get("needs_state")
	needs_state.set_buff(progression.buff_id, progression.buff_time_remaining)
	player.set("hp", mini(int(plan.player_state["hp"]), progression.max_hp))
	player.set("stamina", minf(float(plan.player_state["stamina"]), progression.max_stamina))
	player.set("hunger", minf(float(plan.player_state["hunger"]), progression.max_hunger))
	player.set("thirst", minf(float(plan.player_state["thirst"]), progression.max_thirst))
	player.set("body_temperature", float(plan.player_state["temperature"]))
	var inventory: Dictionary = player.get("inventory")
	inventory.clear()
	inventory.merge(plan.legacy_inventory, true)
	var party: Array = player.get("pet_party")
	party.clear()
	party.append_array(plan.pet_party.duplicate(true))
	if plan.active_pet_index >= 0:
		var summon_result: RefCounted = player.call("swap_active_pet", plan.active_pet_index)
		if summon_result == null or not summon_result.should_spawn():
			return ApplyResult.new(ApplyResult.Status.COMMIT_FAILED)
		var active_pet: Variant = player.get("active_pet_node")
		if not is_instance_valid(active_pet):
			return ApplyResult.new(ApplyResult.Status.COMMIT_FAILED)
		var stance_result: RefCounted = active_pet.call("apply_pet_command", plan.active_stance_command_id)
		if stance_result == null or not stance_result.is_resolved():
			return ApplyResult.new(ApplyResult.Status.COMMIT_FAILED)
	if player.has_method("update_hud"):
		player.call("update_hud")
	var base_manager: Variant = player.get("base_manager_ref")
	if is_instance_valid(base_manager) and not bool(base_manager.call("apply_persistence_state", plan.base_progress_state)):
		return ApplyResult.new(ApplyResult.Status.COMMIT_FAILED)
	if not bool(player.call("replace_persistent_buildings", plan.building_placements)):
		return ApplyResult.new(ApplyResult.Status.COMMIT_FAILED)
	if not bool(player.call("apply_resource_depletion_snapshot", plan.resource_depletions)):
		return ApplyResult.new(ApplyResult.Status.COMMIT_FAILED)
	return ApplyResult.new(ApplyResult.Status.APPLIED, plan.world_clock_seconds, PackedStringArray(), plan.raid_triggered_this_cycle, plan.boss_spawned, plan.boss_timer, plan.spawn_timer, plan.world_boss_state, plan.night_raid_state)


static func _is_default_base_state(state: BaseProgressState) -> bool:
	return state.base_level == 1 and state.active_quest_id == &"quest.base.survival" and state.claimed_quest_ids.is_empty()


static func _dismiss_active_pet(player: Node) -> void:
	var active_pet: Variant = player.get("active_pet_node")
	if is_instance_valid(active_pet):
		if active_pet.is_inside_tree() and active_pet.get_parent() != null:
			active_pet.get_parent().remove_child(active_pet)
		active_pet.queue_free()
	player.set("active_pet_node", null)
	player.set("active_pet_instance_id", &"")


static func _command_for_stance(stance_id: StringName) -> StringName:
	match stance_id:
		&"pet.stance.auto_work": return &"pet.command.auto_work"
		&"pet.stance.combat_assist": return &"pet.command.combat_assist"
		&"pet.stance.follow_protect": return &"pet.command.follow_protect"
	return &""
