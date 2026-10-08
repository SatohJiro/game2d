extends SceneTree

## U4.3: player attack follows the art-bible phases:
## windup (0.15s, row 4, no damage yet) -> strike (slash spawns at contact,
## SFX, row 5) -> recovery (cooldown 0.28s total).

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main scene must load")
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var player = _find_player(main)
	_expect(player != null, "player must exist in main scene")
	if player == null:
		_finish()
		return
	_test_attack_phases(player)
	_finish()


func _find_player(node: Node) -> Node:
	if node.name == "Player" or (node.get_script() != null and String(node.get_script().resource_path).ends_with("player.gd")):
		return node
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null


func _count_slashes(player: Node) -> int:
	var count := 0
	var parent := player.get_parent()
	if parent == null:
		return 0
	for child in parent.get_children():
		var script: Resource = child.get_script()
		if script != null and String(script.resource_path).ends_with("slash_effect.gd"):
			count += 1
	return count


func _test_attack_phases(player: Node) -> void:
	var before := _count_slashes(player)
	player.perform_attack(Vector2.RIGHT)
	# Windup: no slash yet, timer covers windup + strike, cooldown set.
	_expect(_count_slashes(player) == before, "no slash during windup")
	_expect(absf(player.get("attack_anim_timer") - 0.28) < 0.03, "attack timer must cover windup+strike")
	_expect(absf(player.get("attack_cooldown") - 0.28) < 0.03, "cooldown must cover windup+strike")
	await create_timer(0.05).timeout
	_expect(_count_slashes(player) == before, "still no slash mid-windup")
	await create_timer(0.15).timeout
	# Strike: slash spawns exactly at contact.
	_expect(_count_slashes(player) == before + 1, "slash must spawn at strike start")
	await create_timer(0.15).timeout
	_expect(not bool(player.get("is_attacking")), "attack must end after strike")
	_expect(not bool(player.get("_slash_armed")), "slash must be disarmed after spawn")


func _finish() -> void:
	if _failures.is_empty():
		print("Attack timing validation passed: windup telegraphs, slash spawns at contact, cooldown covers recovery.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit.call_deferred(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
