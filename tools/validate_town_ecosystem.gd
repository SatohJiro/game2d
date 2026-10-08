extends SceneTree

## AT-F: town ecosystem validation.
## - NPC data is complete: art exists, spots valid, dialogue localizes.
## - NPCs and anchors spawn under their chunk nodes; interact works.
## - Ambient ecosystem owns its critter pools.

var _failures: Array[String] = []


func _initialize() -> void:
	Localization.set_locale("vi")
	_run.call_deferred()


func _run() -> void:
	_test_npc_db()
	_test_in_game()
	_finish()


func _test_npc_db() -> void:
	var npcs := NpcDB.all()
	_expect(npcs.size() >= 4, "town must define at least 4 NPCs, found %d" % npcs.size())
	for entry in npcs:
		var npc := entry as Dictionary
		_expect(ResourceLoader.exists(String(npc["art"])), "NPC art must exist: %s" % String(npc["art"]))
		var tex := load(String(npc["art"])) as Texture2D
		if tex != null:
			_expect(tex.get_width() == 64 and tex.get_height() == 64, "NPC art must be 64x64: %s" % String(npc["id"]))
		var home := npc["home"] as Vector2
		_expect(home.length() > 10.0, "NPC home must be placed: %s" % String(npc["id"]))
		for phase in [&"day", &"dusk", &"night", &"dawn"]:
			var spot := NpcDB.spot_for(npc, phase)
			_expect(spot.length() > 10.0, "NPC %s must have a %s spot" % [String(npc["id"]), String(phase)])
		var line := Localization.text(String(npc["dialogue"]))
		_expect(line != String(npc["dialogue"]), "NPC dialogue must localize: %s" % String(npc["dialogue"]))
		var name_text := Localization.text(String(npc["name_key"]))
		_expect(name_text != String(npc["name_key"]), "NPC name must localize: %s" % String(npc["name_key"]))


func _test_in_game() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main scene must load")
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var player := _find_player(main)
	_expect(player != null, "player must exist")
	if player == null:
		return
	# Market chunk: merchant NPC + station/market anchors nearby.
	player.global_position = Vector2(1400, 700)
	for i in 14:
		await physics_frame
	var merchant := _find_node(main, "TownNPC_merchant_taro")
	_expect(merchant != null, "merchant NPC must spawn in the market chunk")
	var station := _find_node(main, "TownAnchor_town_station")
	_expect(station != null, "station anchor must spawn in its chunk")
	if merchant != null:
		_expect(merchant.has_method("interact"), "NPC must be interactable")
		_expect(merchant.has_method("set_phase"), "NPC must follow schedules")
		merchant.set_phase(&"night")
		var prompt := String(merchant.call("interaction_prompt_name"))
		_expect(Localization.text(prompt) != prompt, "NPC prompt must localize: %s" % prompt)
	# Shrine chunk: elder NPC visits by day; anchor present.
	player.global_position = Vector2(1536, -700)
	for i in 14:
		await physics_frame
	var shrine := _find_node(main, "TownAnchor_shrine")
	_expect(shrine != null, "shrine anchor must spawn in its chunk")
	var ecosystem := main.get("ecosystem") as AmbientEcosystem
	_expect(ecosystem != null, "main must own an AmbientEcosystem")
	if ecosystem != null:
		_expect(ecosystem.get_child_count() == 33, "ecosystem must pool 33 critters, found %d" % ecosystem.get_child_count())
		ecosystem.update_ecosystem(&"day", false, false, 0.016, player.global_position)
		ecosystem.update_ecosystem(&"night", false, false, 0.016, player.global_position)
	main.queue_free()
	for i in 90:
		await process_frame


func _find_player(node: Node) -> Node:
	if node.get_script() != null and String(node.get_script().resource_path).ends_with("player.gd"):
		return node
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null


func _find_node(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_node(child, node_name)
		if found != null:
			return found
	return null


func _finish() -> void:
	if _failures.is_empty():
		print("Town ecosystem validation passed: NPCs, anchors and ambient critters are live.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit.call_deferred(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
