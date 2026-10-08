class_name MinimapView
extends Control

## Read-only fog/minimap tile renderer (U2.6d presentation).
##
## Renders tile dictionaries from ChunkDiscoveryState.create_view_snapshot().
## Each tile carries chunk_key, coordinate [x, y], discovered, active and
## current flags. Layout math is pure (compute_layout) so it is verifiable
## headless; _draw() only presents the computed rects.
## State is never color-only: current tiles get a thick inner border plus a
## center dot, discovered tiles get corner ticks, fog tiles get cross-hatch.

const TILE_SIZE := 30.0
const TILE_GAP := 3.0

var _tiles: Array[Dictionary] = []
var _rects: Dictionary = {}
var _grid_size := Vector2.ZERO


static func compute_layout(tiles: Array[Dictionary], tile_size: float) -> Dictionary:
	var rects: Dictionary = {}
	if tiles.is_empty() or tile_size <= 0.0:
		return {"rects": rects, "size": Vector2.ZERO}
	var min_c := Vector2i(1 << 30, 1 << 30)
	var max_c := Vector2i(-(1 << 30), -(1 << 30))
	var coords: Dictionary = {}
	for tile in tiles:
		if not tile is Dictionary:
			continue
		var key := String((tile as Dictionary).get("chunk_key", ""))
		if key.is_empty() or coords.has(key):
			continue
		var coord := _tile_coordinate(tile as Dictionary)
		coords[key] = coord
		min_c.x = mini(min_c.x, coord.x)
		min_c.y = mini(min_c.y, coord.y)
		max_c.x = maxi(max_c.x, coord.x)
		max_c.y = maxi(max_c.y, coord.y)
	if coords.is_empty():
		return {"rects": rects, "size": Vector2.ZERO}
	var step := tile_size + TILE_GAP
	for key in coords:
		var coord: Vector2i = coords[key]
		var pos := Vector2(float(coord.x - min_c.x) * step, float(coord.y - min_c.y) * step)
		rects[key] = Rect2(pos, Vector2(tile_size, tile_size))
	var size := Vector2(
		float(max_c.x - min_c.x + 1) * step - TILE_GAP,
		float(max_c.y - min_c.y + 1) * step - TILE_GAP
	)
	return {"rects": rects, "size": size}


static func _tile_coordinate(tile: Dictionary) -> Vector2i:
	var raw: Array = tile.get("coordinate", [0, 0])
	if raw.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(raw[0]), int(raw[1]))


func set_tiles(tiles: Array[Dictionary]) -> void:
	_tiles = tiles.duplicate()
	var layout := compute_layout(_tiles, TILE_SIZE)
	_rects = layout["rects"] as Dictionary
	_grid_size = layout["size"] as Vector2
	custom_minimum_size = _grid_size
	queue_redraw()


func get_tile_rect(chunk_key: String) -> Rect2:
	return _rects.get(chunk_key, Rect2()) as Rect2


func _draw() -> void:
	for tile in _tiles:
		var key := String(tile.get("chunk_key", ""))
		if not _rects.has(key):
			continue
		var rect: Rect2 = _rects[key]
		var discovered := bool(tile.get("discovered", false))
		var active := bool(tile.get("active", false))
		var current := bool(tile.get("current", false))
		if discovered:
			draw_rect(rect, Color(0.28, 0.55, 0.38, 1.0), true)
		elif active:
			_draw_fog_tile(rect)
		else:
			draw_rect(rect, Color(0.10, 0.11, 0.14, 1.0), true)
		draw_rect(rect, Color(0.05, 0.06, 0.08, 1.0), false, 1.0)
		if current:
			draw_rect(rect.grow(-3.0), Color(1.0, 0.9, 0.35, 1.0), false, 3.0)
			draw_circle(rect.get_center(), 3.0, Color(1.0, 0.9, 0.35, 1.0))
		elif discovered:
			var tick := 5.0
			var tick_color := Color(0.92, 1.0, 0.95, 0.9)
			draw_line(rect.position, rect.position + Vector2(tick, 0.0), tick_color, 2.0)
			draw_line(rect.position, rect.position + Vector2(0.0, tick), tick_color, 2.0)


func _draw_fog_tile(rect: Rect2) -> void:
	draw_rect(rect, Color(0.16, 0.18, 0.23, 1.0), true)
	var cross := Color(0.32, 0.35, 0.42, 0.8)
	draw_line(rect.position, rect.end, cross, 1.0)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), cross, 1.0)
