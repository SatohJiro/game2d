extends SceneTree

const Coordinator = preload("res://systems/save/save_coordinator.gd")
const CoordinatorResult = preload("res://systems/save/save_coordinator_result.gd")
const SnapshotAdapter = preload("res://systems/save/save_snapshot_adapter.gd")
const Schema = preload("res://systems/save/save_v1_schema.gd")

var _failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed_player := load("res://scenes/player.tscn") as PackedScene
	if packed_player == null:
		printerr("SAVE COORDINATOR VALIDATION FAILURE: unable to load Player scene")
		quit(1)
		return
	var directory := "user://save_coordinator_test_%d" % Time.get_ticks_usec()
	var primary := "%s/slot_1.json" % directory
	var coordinator: RefCounted = Coordinator.new(primary)
	var fixture := Node2D.new()
	root.add_child(fixture)
	var player := packed_player.instantiate()
	fixture.add_child(player)
	await process_frame
	player.set("hud_ref", null)
	player.set("base_manager_ref", null)

	_set_runtime(player, Vector2(15.5, -8.0), 3, 66, 17)
	var first_save: RefCounted = coordinator.save_player(player, &"save.slot_1", 100, 125.5)
	_expect(first_save.status == CoordinatorResult.Status.SAVED, "explicit coordinator save must succeed")
	_set_runtime(player, Vector2(99.0, 101.0), 8, 12, 1)
	var primary_load: RefCounted = coordinator.load_player(player)
	_expect(primary_load.status == CoordinatorResult.Status.LOADED_PRIMARY and is_equal_approx(primary_load.world_clock_seconds, 125.5), "load must report primary source and world clock")
	_expect(_runtime_matches(player, Vector2(15.5, -8.0), 3, 66, 17), "primary round trip must restore Player state")

	_set_runtime(player, Vector2(30.0, 40.0), 4, 70, 23)
	_expect(coordinator.save_player(player, &"save.slot_1", 200, 222.0).is_success(), "second save must create backup")
	var corrupt := FileAccess.open(primary, FileAccess.WRITE)
	if corrupt == null:
		_failures.append("unable to create corrupt primary fixture")
	else:
		corrupt.store_string("{broken json")
		corrupt.close()
	_set_runtime(player, Vector2.ZERO, 1, 1, 0)
	var backup_load: RefCounted = coordinator.load_player(player)
	_expect(backup_load.status == CoordinatorResult.Status.LOADED_BACKUP and is_equal_approx(backup_load.world_clock_seconds, 125.5), "recovery load must expose backup source and clock")
	_expect(_runtime_matches(player, Vector2(15.5, -8.0), 3, 66, 17), "backup recovery must restore the previous committed state")

	var state_before := _runtime_snapshot(player)
	_write_corrupt("%s.bak" % primary)
	var rejected: RefCounted = coordinator.load_player(player)
	_expect(rejected.status == CoordinatorResult.Status.REPOSITORY_FAILED, "corrupt primary and backup must fail before migration/apply")
	_expect(_runtime_snapshot(player) == state_before, "failed coordinator load must not mutate runtime")

	await _test_world_clock_owner()
	await _test_world_boss_round_trip()
	await _test_night_raid_round_trip()

	root.remove_child(fixture)
	fixture.free()
	await process_frame
	await process_frame
	_cleanup(directory, primary)
	if _failures.is_empty():
		print("Save coordinator validation passed: explicit round trip, recovery source and failure atomicity are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			printerr("SAVE COORDINATOR VALIDATION FAILURE: %s" % failure)
		quit.call_deferred(1)


func _test_world_clock_owner() -> void:
	var packed_main := load("res://scenes/main.tscn") as PackedScene
	if packed_main == null:
		_failures.append("unable to load Main scene for world clock owner")
		return
	var directory := "user://world_clock_owner_test_%d" % Time.get_ticks_usec()
	var primary := "%s/slot_1.json" % directory
	var world: Node = packed_main.instantiate()
	root.add_child(world)
	await process_frame
	world.set_process(false)
	_expect(world.call("configure_save_path", primary), "world owner must accept an explicit repository path")
	world.set("day_time", 140.0)
	world.set("raid_triggered_this_cycle", true)
	world.set("night_raid_state", NightRaidState.new(NightRaidState.CLEARED, NightRaidState.ENCOUNTER_ID, 0, []))
	world.set("boss_spawned", false)
	world.set("boss_timer", 23.5)
	world.set("spawn_timer", 2.25)
	var creature_count_before: int = world.get_node("Creatures").get_child_count()
	var direct_snapshot: RefCounted = SnapshotAdapter.create_player_snapshot(world.get("player"), &"save.slot_1", 300, 140.0, true, false, 23.5, 2.25)
	if direct_snapshot.is_accepted():
		var decoded: Variant = JSON.parse_string(JSON.stringify(direct_snapshot.snapshot))
		var decoded_validation: RefCounted = Schema.validate(decoded)
		_expect(decoded_validation.is_valid(), "world owner JSON snapshot must remain valid: %s" % decoded_validation.errors)
	var saved: RefCounted = world.call("save_game", 300, &"save.slot_1")
	_expect(saved.status == CoordinatorResult.Status.SAVED and is_equal_approx(saved.world_clock_seconds, 140.0), "world owner must pass its clock into save (status=%s errors=%s)" % [saved.status, saved.errors])
	world.set("day_time", 9.0)
	world.set("raid_triggered_this_cycle", false)
	world.set("boss_spawned", true)
	world.set("boss_timer", 0.0)
	world.set("spawn_timer", 4.0)
	var loaded: RefCounted = world.call("load_game")
	_expect(loaded.is_loaded() and is_equal_approx(float(world.get("day_time")), 140.0) and bool(world.get("raid_triggered_this_cycle")) and not bool(world.get("boss_spawned")) and is_equal_approx(float(world.get("boss_timer")), 23.5) and is_equal_approx(float(world.get("spawn_timer")), 2.25), "world owner must commit clock and cycle timers only after successful load (status=%s errors=%s)" % [loaded.status, loaded.errors])
	_expect(world.get_node("Creatures").get_child_count() == creature_count_before, "world-cycle load must not spawn duplicate raid creatures")
	_write_corrupt(primary)
	_write_corrupt("%s.bak" % primary)
	world.set("day_time", 44.0)
	world.set("raid_triggered_this_cycle", false)
	world.set("boss_spawned", false)
	world.set("boss_timer", 12.0)
	world.set("spawn_timer", 1.5)
	var rejected_world_load: RefCounted = world.call("load_game")
	_expect(not rejected_world_load.is_loaded() and is_equal_approx(float(world.get("day_time")), 44.0) and not bool(world.get("raid_triggered_this_cycle")) and is_equal_approx(float(world.get("boss_timer")), 12.0) and is_equal_approx(float(world.get("spawn_timer")), 1.5), "failed world load must preserve runtime cycle state")
	root.remove_child(world)
	world.free()
	await process_frame
	await process_frame
	_cleanup(directory, primary)


func _test_world_boss_round_trip() -> void:
	var packed_main := load("res://scenes/main.tscn") as PackedScene
	var directory := "user://world_boss_owner_test_%d" % Time.get_ticks_usec()
	var primary := "%s/slot_1.json" % directory
	var world: Node = packed_main.instantiate()
	root.add_child(world)
	await process_frame
	world.set_process(false)
	world.call("configure_save_path", primary)
	_expect(bool(world.call("spawn_boss", false)), "world boss fixture must spawn")
	var actor := world.get("world_boss_actor") as Node2D
	actor.global_position = Vector2(301.5, 177.25)
	actor.set("hp", 217)
	var player_exp_before := int(world.get("player").get("exp_val"))
	var drops_before := get_nodes_in_group("dropped_items").size()
	_expect(world.call("save_game", 401, &"save.slot_1").is_success(), "active world boss save must succeed")
	world.call("apply_world_boss_state", WorldBossState.new(WorldBossState.DEFEATED, WorldBossState.INSTANCE_ID, 0, Vector2.ZERO))
	var active_load: RefCounted = world.call("load_game")
	var restored_actor := world.get("world_boss_actor") as Node2D
	var restored_state := world.get("world_boss_state") as WorldBossState
	_expect(active_load.is_loaded() and restored_state.lifecycle_id == WorldBossState.ACTIVE, "active world boss lifecycle must round-trip")
	_expect(is_instance_valid(restored_actor) and int(restored_actor.get("hp")) == 217 and restored_actor.global_position.is_equal_approx(Vector2(301.5, 177.25)), "active load must restore boss HP and position")
	_expect(get_nodes_in_group("persistent_world_bosses").size() == 1 and int(world.get("player").get("exp_val")) == player_exp_before and get_nodes_in_group("dropped_items").size() == drops_before, "active load must create one actor without EXP or drops")
	restored_actor.emit_signal("removed", restored_actor, WorldBossState.INSTANCE_ID, &"creature.removal.captured")
	if restored_actor.get_parent() != null: restored_actor.get_parent().remove_child(restored_actor)
	restored_actor.free()
	_expect(world.call("save_game", 402, &"save.slot_1").is_success(), "defeated world boss save must succeed")
	world.call("apply_world_boss_state", WorldBossState.new(WorldBossState.ACTIVE, WorldBossState.INSTANCE_ID, 100, Vector2(20, 30)))
	var defeated_load: RefCounted = world.call("load_game")
	_expect(defeated_load.is_loaded() and (world.get("world_boss_state") as WorldBossState).lifecycle_id == WorldBossState.DEFEATED and get_nodes_in_group("persistent_world_bosses").is_empty(), "defeated load must remove actor and lock respawn")
	world.call("apply_world_boss_state", WorldBossState.new(WorldBossState.ACTIVE, WorldBossState.INSTANCE_ID, 91, Vector2(40, 50)))
	var preserved_actor: Node2D = world.get("world_boss_actor") as Node2D
	_write_corrupt(primary)
	_write_corrupt("%s.bak" % primary)
	var rejected: RefCounted = world.call("load_game")
	_expect(not rejected.is_loaded() and world.get("world_boss_actor") == preserved_actor and (world.get("world_boss_state") as WorldBossState).hp == 91, "corrupt load must preserve current world-boss actor and state")
	root.remove_child(world)
	world.free()
	await process_frame
	await process_frame
	_cleanup(directory, primary)


func _test_night_raid_round_trip() -> void:
	var packed_main := load("res://scenes/main.tscn") as PackedScene
	var directory := "user://night_raid_owner_test_%d" % Time.get_ticks_usec()
	var primary := "%s/slot_1.json" % directory
	var world: Node = packed_main.instantiate()
	root.add_child(world)
	await process_frame
	world.set_process(false)
	world.call("configure_save_path", primary)
	world.set("day_time", 140.0)
	_expect(world.call("trigger_night_raid", false), "night raid fixture must spawn")
	var saved_state := world.call("create_night_raid_persistence_state") as NightRaidState
	var first_actor: Node2D = world.get("night_raid_actors")[saved_state.actors[0].instance_id]
	first_actor.global_position = Vector2(211.5, -74.25)
	first_actor.set("hp", 7)
	var player_exp_before := int(world.get("player").get("exp_val"))
	var drops_before := get_nodes_in_group("dropped_items").size()
	_expect(world.call("save_game", 501, &"save.slot_1").is_success(), "active night raid save must succeed")
	world.call("apply_night_raid_state", NightRaidState.new(NightRaidState.CLEARED, NightRaidState.ENCOUNTER_ID, 0, []))
	var active_load: RefCounted = world.call("load_game")
	var restored_state := world.get("night_raid_state") as NightRaidState
	var restored_actor: Node2D = world.get("night_raid_actors")[restored_state.actors[0].instance_id]
	_expect(active_load.is_loaded() and restored_state.lifecycle_id == NightRaidState.ACTIVE and restored_state.actors.size() == 3, "active night raid roster must round-trip")
	_expect(int(restored_actor.get("hp")) == 7 and restored_actor.global_position.is_equal_approx(Vector2(211.5, -74.25)), "active raid load must restore resolved HP and position")
	_expect(get_nodes_in_group("persistent_night_raid_actors").size() == 3 and int(world.get("player").get("exp_val")) == player_exp_before and get_nodes_in_group("dropped_items").size() == drops_before, "active raid load must restore exactly three actors without rewards")
	for actor: Node in (world.get("night_raid_actors") as Dictionary).values():
		world.call("commit_night_raid_actor_removal", actor, actor.get_meta("encounter_instance_id"))
	_expect(world.call("save_game", 502, &"save.slot_1").is_success(), "cleared night raid save must succeed")
	world.call("apply_night_raid_state", saved_state)
	var cleared_load: RefCounted = world.call("load_game")
	_expect(cleared_load.is_loaded() and (world.get("night_raid_state") as NightRaidState).lifecycle_id == NightRaidState.CLEARED and get_nodes_in_group("persistent_night_raid_actors").is_empty(), "cleared raid load must not spawn actors")
	world.call("apply_night_raid_state", saved_state)
	var preserved: Dictionary = (world.get("night_raid_actors") as Dictionary).duplicate()
	_write_corrupt(primary)
	_write_corrupt("%s.bak" % primary)
	var rejected: RefCounted = world.call("load_game")
	_expect(not rejected.is_loaded() and world.get("night_raid_actors") == preserved, "failed load must preserve current night raid ownership")
	root.remove_child(world)
	world.free()
	await process_frame
	await process_frame
	_cleanup(directory, primary)


func _set_runtime(player: Node, position: Vector2, level: int, hp: int, wood: int) -> void:
	player.global_position = position
	player.set("level", level)
	player.set("max_exp", PlayerProgressionState.expected_max_exp(level))
	player.set("stat_points", level * PlayerProgressionState.POINTS_PER_LEVEL)
	var stats: Dictionary = player.get("stats")
	stats.merge({"str": 0, "vit": 0, "sta": 0, "agi": 0}, true)
	player.set("weapon_name", PlayerEquipmentCatalog.weapon_display_name(PlayerEquipmentCatalog.WOOD_SWORD))
	player.set("weapon_damage", PlayerEquipmentCatalog.weapon_damage(PlayerEquipmentCatalog.WOOD_SWORD))
	player.set("has_armor", false)
	player.call("recalculate_stats")
	player.set("hp", hp)
	var inventory: Dictionary = player.get("inventory")
	inventory["Gỗ"] = wood


func _runtime_matches(player: Node, position: Vector2, level: int, hp: int, wood: int) -> bool:
	return player.global_position == position and player.get("level") == level and player.get("hp") == hp and player.get("inventory").get("Gỗ") == wood


func _runtime_snapshot(player: Node) -> Dictionary:
	return {"position": player.global_position, "level": player.get("level"), "hp": player.get("hp"), "inventory": player.get("inventory").duplicate(true), "party": player.get("pet_party").duplicate(true), "active": player.get("active_pet_node")}


func _write_corrupt(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("unable to create corrupt backup fixture")
		return
	file.store_string("not json")
	file.close()


func _cleanup(directory: String, primary: String) -> void:
	for path in [primary, "%s.bak" % primary, "%s.tmp" % primary]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
