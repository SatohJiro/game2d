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
	var creature_count_before: int = world.get_node("Creatures").get_child_count()
	var direct_snapshot: RefCounted = SnapshotAdapter.create_player_snapshot(world.get("player"), &"save.slot_1", 300, 140.0, true)
	if direct_snapshot.is_accepted():
		var decoded: Variant = JSON.parse_string(JSON.stringify(direct_snapshot.snapshot))
		var decoded_validation: RefCounted = Schema.validate(decoded)
		_expect(decoded_validation.is_valid(), "world owner JSON snapshot must remain valid: %s" % decoded_validation.errors)
	var saved: RefCounted = world.call("save_game", 300, &"save.slot_1")
	_expect(saved.status == CoordinatorResult.Status.SAVED and is_equal_approx(saved.world_clock_seconds, 140.0), "world owner must pass its clock into save (status=%s errors=%s)" % [saved.status, saved.errors])
	world.set("day_time", 9.0)
	world.set("raid_triggered_this_cycle", false)
	var loaded: RefCounted = world.call("load_game")
	_expect(loaded.is_loaded() and is_equal_approx(float(world.get("day_time")), 140.0) and bool(world.get("raid_triggered_this_cycle")), "world owner must commit clock and raid guard only after successful load (status=%s errors=%s)" % [loaded.status, loaded.errors])
	_expect(world.get_node("Creatures").get_child_count() == creature_count_before, "world-cycle load must not spawn duplicate raid creatures")
	_write_corrupt(primary)
	_write_corrupt("%s.bak" % primary)
	world.set("day_time", 44.0)
	world.set("raid_triggered_this_cycle", false)
	var rejected_world_load: RefCounted = world.call("load_game")
	_expect(not rejected_world_load.is_loaded() and is_equal_approx(float(world.get("day_time")), 44.0) and not bool(world.get("raid_triggered_this_cycle")), "failed world load must preserve runtime clock and raid guard")
	root.remove_child(world)
	world.free()
	await process_frame
	await process_frame
	_cleanup(directory, primary)


func _set_runtime(player: Node, position: Vector2, level: int, hp: int, wood: int) -> void:
	player.global_position = position
	player.set("level", level)
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
