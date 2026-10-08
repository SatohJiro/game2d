class_name LightingDirector
extends Node2D

## AT-C: lighting for Paloria Luminous Town.
## - Drives a CanvasModulate with the WorldClock color ramp.
## - Night lamps: PointLight2D at town lantern/shrine/station/clock positions.
## - Star field fades in at night (screen-space CanvasLayer).
## - Respects reduce_motion: no flicker, no drifting.

const LAMP_KINDS := [&"lantern", &"shrine", &"station", &"landmark", &"bulletin"]

var _modulate: CanvasModulate
var _lamps: Array[PointLight2D] = []
var _stars: CanvasLayer
var _star_alpha := 0.0
var _flicker_time := 0.0


func _ready() -> void:
	_modulate = CanvasModulate.new()
	_modulate.name = "TownAmbient"
	add_child(_modulate)
	_build_lamps()
	_build_stars()


func _build_lamps() -> void:
	for entry in TownLayout.all():
		var s := entry as Dictionary
		if not LAMP_KINDS.has(s["kind"]):
			continue
		var lamp := PointLight2D.new()
		lamp.position = s["position"] as Vector2
		lamp.color = Color(1.0, 0.72, 0.35)
		lamp.energy = 0.0
		lamp.texture_scale = 6.0
		add_child(lamp)
		_lamps.append(lamp)


func _build_stars() -> void:
	_stars = CanvasLayer.new()
	_stars.layer = -5
	_stars.name = "StarField"
	var control := _StarCanvas.new()
	control.name = "Stars"
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stars.add_child(control)
	add_child(_stars)


func update_clock(progress: float, reduce_motion: bool, delta: float) -> void:
	_modulate.color = WorldClock.ambient_color(progress)
	var dark := WorldClock.is_dark(progress)
	var target := 1.0 if dark else 0.0
	_flicker_time += delta
	for lamp in _lamps:
		var energy := target * 0.9
		if dark and not reduce_motion:
			energy *= 0.92 + 0.08 * sin(_flicker_time * 7.0 + lamp.position.x)
		lamp.energy = lerpf(lamp.energy, energy, minf(1.0, delta * 3.0))
	# Stars fade with night depth.
	var night_depth := 0.0
	if progress >= 0.65 and progress < 0.88:
		night_depth = 1.0
	elif progress >= 0.58 and progress < 0.65:
		night_depth = (progress - 0.58) / 0.07
	elif progress >= 0.88 and progress < 0.94:
		night_depth = 1.0 - (progress - 0.88) / 0.06
	_star_alpha = lerpf(_star_alpha, night_depth, minf(1.0, delta * 2.0))
	var canvas := _stars.get_node_or_null("Stars") as _StarCanvas
	if canvas != null:
		canvas.alpha = 0.0 if reduce_motion else _star_alpha


func lamp_count() -> int:
	return _lamps.size()


func lamp_energy() -> float:
	if _lamps.is_empty():
		return 0.0
	return (_lamps[0] as PointLight2D).energy


class _StarCanvas extends Control:
	var alpha := 0.0
	var _points: PackedVector2Array = PackedVector2Array()

	func _init() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261008
		for i in 90:
			_points.append(Vector2(rng.randf() * 1600.0, rng.randf() * 900.0))

	func _draw() -> void:
		if alpha <= 0.01:
			return
		for p in _points:
			var sx := fmod(p.x, size.x)
			var sy := fmod(p.y, size.y * 0.7)
			draw_circle(Vector2(sx, sy), 1.2, Color(1, 1, 1, alpha * 0.8))

	func _process(_delta: float) -> void:
		queue_redraw()
