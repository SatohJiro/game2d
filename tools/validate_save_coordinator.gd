extends SceneTree

const Coordinator = preload("res://systems/save/save_coordinator.gd")
const CoordinatorResult = preload("res://systems/save/save_coordinator_result.gd")

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
