extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_layout()
	await _test_panel_render()
	await _test_intents()
	await _test_main_integration()
	if _failures.is_empty():
		print("Minimap validation passed: tile layout, discovered-only picker, intent boundary and Main travel wiring are valid.")
		quit.call_deferred(0)
	else:
		for failure in _failures: push_error(failure)
		quit.call_deferred(1)


func _make_tile(chunk_key: String, x: int, y: int, discovered: bool, active: bool, current: bool = false) -> Dictionary:
	return {
		"chunk_key": chunk_key,
		"coordinate": [x, y],
		"discovered": discovered,
		"active": active,
		"current": current,
	}


func _test_layout() -> void:
	var tiles: Array[Dictionary] = [
		_make_tile("chunk.p0.p0", 0, 0, true, true, true),
		_make_tile("chunk.p1.p0", 1, 0, true, false),
		_make_tile("chunk.p0.p1", 0, 1, false, true),
	]
	var layout := MinimapView.compute_layout(tiles, 30.0)
	var rects: Dictionary = layout["rects"]
	_expect(rects["chunk.p0.p0"] == Rect2(Vector2.ZERO, Vector2(30.0, 30.0)), "origin tile must sit at the grid origin")
	_expect(rects["chunk.p1.p0"] == Rect2(Vector2(33.0, 0.0), Vector2(30.0, 30.0)), "positive-x tile must offset by tile size plus gap")
	_expect(rects["chunk.p0.p1"] == Rect2(Vector2(0.0, 33.0), Vector2(30.0, 30.0)), "positive-y tile must offset by tile size plus gap")
	_expect(layout["size"] == Vector2(63.0, 63.0), "grid size must span the tile bounds exactly")
	var signed_tiles: Array[Dictionary] = [
		_make_tile("chunk.n1.p0", -1, 0, true, true),
		_make_tile("chunk.p0.p0", 0, 0, true, true),
	]
	var signed_layout := MinimapView.compute_layout(signed_tiles, 30.0)
	var signed_rects: Dictionary = signed_layout["rects"]
	_expect(signed_rects["chunk.n1.p0"] == Rect2(Vector2.ZERO, Vector2(30.0, 30.0)), "negative chunk must anchor the grid start")
	_expect(signed_rects["chunk.p0.p0"] == Rect2(Vector2(33.0, 0.0), Vector2(30.0, 30.0)), "origin must shift right of the negative chunk")
	var empty := MinimapView.compute_layout([], 30.0)
	_expect((empty["rects"] as Dictionary).is_empty() and (empty["size"] as Vector2) == Vector2.ZERO, "empty snapshot must produce an empty layout")
	var view := MinimapView.new()
	root.add_child(view)
	view.set_tiles(tiles)
	_expect(view.get_tile_rect("chunk.p1.p0") == Rect2(Vector2(33.0, 0.0), Vector2(30.0, 30.0)), "view must expose computed tile rects")
	_expect(view.custom_minimum_size == Vector2(63.0, 63.0), "view minimum size must match the grid")
	view.queue_free()


func _make_panel() -> MinimapPanel:
	var packed := load("res://scenes/minimap.tscn") as PackedScene
	var panel := packed.instantiate() as MinimapPanel
	root.add_child(panel)
	await process_frame
	return panel


func _test_panel_render() -> void:
	var panel := await _make_panel()
	var snapshot := {
		"revision": 2,
		"center_key": "chunk.p0.p0",
		"discovered_count": 2,
		"tiles": [
			_make_tile("chunk.p0.p0", 0, 0, true, true, true),
			_make_tile("chunk.p1.p0", 1, 0, true, false),
			_make_tile("chunk.p0.p1", 0, 1, false, true),
		],
	}
	panel.render_snapshot(snapshot)
	var ids := panel.get_listed_destination_ids()
	_expect(ids == [&"fast_travel.chunk.p0.p0", &"fast_travel.chunk.p1.p0"], "picker must list exactly the discovered destinations, sorted")
	_expect(not ids.has(&"fast_travel.chunk.p0.p1"), "fogged active chunk must not appear in the picker")
	_expect(panel.get_snapshot()["discovered_count"] == 2, "panel must retain the rendered snapshot")
	panel.queue_free()
	await process_frame


func _test_intents() -> void:
	var panel := await _make_panel()
	panel.render_snapshot({
		"revision": 1, "center_key": "chunk.p0.p0", "discovered_count": 1,
		"tiles": [_make_tile("chunk.p0.p0", 0, 0, true, true, true)],
	})
	var emitted: Array = []
	panel.travel_requested.connect(func(destination_id: StringName) -> void: emitted.append(destination_id))
	panel.confirm_selection()
	_expect(emitted.is_empty(), "confirming with no selection must not emit a travel intent")
	_expect(not panel.select_destination(&"fast_travel.nope"), "selecting an unknown destination must fail")
	panel.confirm_selection()
	_expect(emitted.is_empty(), "unknown destination must never emit a travel intent")
	_expect(panel.select_destination(&"fast_travel.chunk.p0.p0"), "selecting a listed destination must succeed")
	panel.confirm_selection()
	_expect(emitted == [&"fast_travel.chunk.p0.p0"], "confirming a valid selection must emit exactly its destination ID")
	panel.queue_free()
	await process_frame


func _clear_creatures(main: Node) -> void:
	var container := main.get("creature_container") as Node
	for child in container.get_children():
		if is_instance_valid(child):
			child.queue_free()
	await process_frame
	await process_frame


func _test_main_integration() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_failures.append("unable to load main scene for minimap validation")
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var player: Node2D = main.get("player")
	var inventory: Dictionary = player.get("inventory")
	InventoryTransaction.new(inventory).add(FastTravelPolicy.COST_ITEM_ID, 2)
	var adapter := main.get("chunk_discovery_adapter") as ChunkDiscoveryAdapter
	adapter.observe_center(Vector2i(1, 0))
	adapter.observe_center(Vector2i(0, 0))
	await _clear_creatures(main)

	_expect(bool(main.call("toggle_minimap")), "toggling the minimap must open it")
	var minimap := main.get("minimap_panel") as MinimapPanel
	_expect(minimap != null and minimap.is_open() and minimap.visible, "minimap panel must be visible after toggle")
	_expect(minimap.get_listed_destination_ids().has(&"fast_travel.chunk.p1.p0"), "Main minimap must list the discovered remote chunk")
	_expect(minimap.select_destination(&"fast_travel.chunk.p1.p0"), "destination selection must succeed")
	minimap.confirm_selection()
	_expect((player.get("global_position") as Vector2) == Vector2(1536.0, 512.0), "confirming a destination must travel the player through Main")
	var current_key := ""
	for tile in (minimap.get_snapshot().get("tiles", []) as Array):
		if tile is Dictionary and bool((tile as Dictionary).get("current", false)):
			current_key = String((tile as Dictionary).get("chunk_key", ""))
	_expect(current_key == "chunk.p1.p0", "minimap snapshot must refresh the current tile after travel")
	_expect(not bool(main.call("toggle_minimap")), "toggling again must close the minimap")
	_expect(not minimap.is_open() and not minimap.visible, "minimap panel must hide after toggle")
	main.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
