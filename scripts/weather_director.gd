class_name WeatherDirector
extends Node2D

## AT-C: deterministic weather for Paloria Luminous Town.
## States: clear / cloudy / rain. Weather is a pure function of
## (save_id, day_index) — deterministic, saved implicitly via world time,
## and never changes rewards or spawns (visual/atmosphere only).

enum Weather { CLEAR, CLOUDY, RAIN }

const RAIN_DROPS := 90
const CLOUD_COUNT := 6

var _weather: int = Weather.CLEAR
var _day_index := -1
var _save_id := ""
var _rain_layer: _RainCanvas
var _drops: Array[Dictionary] = []
var _cloud_layer: CanvasLayer
var _dim: ColorRect


func _ready() -> void:
	_build_rain()
	_build_clouds()


func _build_rain() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 80
	layer.name = "WeatherDim"
	_dim = ColorRect.new()
	_dim.name = "RainDim"
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.25, 0.30, 0.45, 0.18)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	layer.add_child(_dim)
	_rain_layer = _RainCanvas.new()
	_rain_layer.name = "Rain"
	(_rain_layer as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
	(_rain_layer as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rain_layer.visible = false
	layer.add_child(_rain_layer)
	add_child(layer)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for i in RAIN_DROPS:
		_drops.append({
			"x": rng.randf(), "y": rng.randf(),
			"speed": rng.randf_range(0.9, 1.3), "len": rng.randf_range(10.0, 18.0),
		})


func _build_clouds() -> void:
	_cloud_layer = CanvasLayer.new()
	_cloud_layer.layer = -4
	_cloud_layer.name = "Clouds"
	var canvas := _CloudCanvas.new()
	canvas.name = "CloudDrift"
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cloud_layer.add_child(canvas)
	add_child(_cloud_layer)


static func weather_for(save_id: String, day_index: int) -> int:
	var h := 2166136261
	for c in (save_id + ":" + str(day_index)):
		h = ((h ^ c.unicode_at(0)) * 16777619) & 0xFFFFFFFF
	var r := h % 100
	if r < 60:
		return Weather.CLEAR
	if r < 82:
		return Weather.CLOUDY
	return Weather.RAIN


func update_clock(day_time: float, save_id: String, reduce_motion: bool, delta: float) -> int:
	var day_index := int(floor(day_time / WorldClock.DAY_DURATION))
	if day_index != _day_index or save_id != _save_id:
		_day_index = day_index
		_save_id = save_id
		_weather = WeatherDirector.weather_for(save_id, day_index)
		_apply_weather(reduce_motion)
	if _weather == Weather.RAIN and not reduce_motion:
		_tick_rain(delta)
	return _weather


func current_weather() -> int:
	return _weather


func _apply_weather(reduce_motion: bool) -> void:
	var raining := _weather == Weather.RAIN and not reduce_motion
	_rain_layer.visible = raining
	_dim.visible = raining
	var clouds := _cloud_layer.get_node_or_null("CloudDrift") as _CloudCanvas
	if clouds != null:
		clouds.coverage = 0.65 if _weather == Weather.CLOUDY else (0.35 if raining else 0.12)


func _tick_rain(delta: float) -> void:
	for drop in _drops:
		drop["y"] = float(drop["y"]) + float(drop["speed"]) * delta
		if float(drop["y"]) > 1.05:
			drop["y"] = -0.05
			drop["x"] = fmod(float(drop["x"]) + 0.13, 1.1) - 0.05
	(_rain_layer as _RainCanvas).set_drops(_drops)
	_rain_layer.queue_redraw()


class _RainCanvas extends Control:
	var _drops: Array = []

	func set_drops(drops: Array) -> void:
		_drops = drops

	func _draw() -> void:
		for drop in _drops:
			var x := float(drop["x"]) * size.x
			var y := float(drop["y"]) * size.y
			var l := float(drop["len"])
			draw_line(Vector2(x, y), Vector2(x - l * 0.25, y + l), Color(0.65, 0.75, 0.95, 0.55), 1.5)


class _CloudCanvas extends Control:
	var coverage := 0.12
	var _offset := 0.0

	func _process(delta: float) -> void:
		_offset = fmod(_offset + delta * 6.0, 400.0)
		queue_redraw()

	func _draw() -> void:
		if coverage <= 0.01:
			return
		for i in 6:
			var x := fmod(i * 320.0 + _offset, size.x + 320.0) - 160.0
			var y := 60.0 + (i % 3) * 46.0
			_cloud_ellipse(Rect2(x, y, 220, 54), Color(1, 1, 1, coverage * 0.5))

	func _cloud_ellipse(rect: Rect2, color: Color) -> void:
		draw_set_transform(rect.get_center(), 0.0, Vector2(rect.size.x / 2.0, rect.size.y / 2.0))
		draw_circle(Vector2.ZERO, 1.0, color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
