class_name AmbientEcosystem
extends Node2D

## AT-F: ambient critters that make the town feel alive.
## - Butterflies wander near flowers/water on clear days.
## - Sakura petals drift down around sakura trees.
## - Birds perch on power lines by day and roost at night.
## Pooled, deterministic-ish, and frozen when reduce_motion is on.

const BUTTERFLY_COUNT := 8
const PETAL_COUNT := 22
const BIRD_COUNT := 3

const WANDER_SPOTS := [
	Vector2(1536, 1420), Vector2(1200, 560), Vector2(1900, 850),
	Vector2(1400, 700), Vector2(2600, 700),
]
const SAKURA_SPOTS := [Vector2(1200, 560), Vector2(2600, 700)]
const PERCH_SPOTS := [Vector2(1250, 610), Vector2(1650, 610), Vector2(1500, 270)]

var _critters: Array[Node2D] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in BUTTERFLY_COUNT:
		var b := _Butterfly.new()
		b.home = WANDER_SPOTS[i % WANDER_SPOTS.size()]
		b.phase = rng.randf() * TAU
		add_child(b)
		_critters.append(b)
	for i in PETAL_COUNT:
		var p := _Petal.new()
		p.tree_pos = SAKURA_SPOTS[i % SAKURA_SPOTS.size()]
		p.reset(true)
		add_child(p)
		_critters.append(p)
	for i in BIRD_COUNT:
		var bird := _PerchedBird.new()
		bird.position = PERCH_SPOTS[i % PERCH_SPOTS.size()]
		add_child(bird)
		_critters.append(bird)


func update_ecosystem(phase: StringName, raining: bool, reduce_motion: bool, delta: float, player_pos: Vector2) -> void:
	var day_active := phase == &"day" and not raining
	for c in _critters:
		if c is _Butterfly:
			(c as _Butterfly).tick(delta, day_active and not reduce_motion, player_pos)
		elif c is _Petal:
			(c as _Petal).tick(delta, not reduce_motion)
		elif c is _PerchedBird:
			(c as _PerchedBird).tick(day_active)


class _Butterfly extends Node2D:
	var home := Vector2.ZERO
	var phase := 0.0
	var _t := 0.0

	func _ready() -> void:
		position = home
		_t = phase

	func tick(delta: float, active: bool, player_pos: Vector2) -> void:
		visible = active and position.distance_to(player_pos) < 900.0
		if not visible:
			return
		_t += delta
		var target := home + Vector2(cos(_t * 0.7 + phase) * 60.0, sin(_t * 1.1 + phase) * 40.0)
		position = position.lerp(target, minf(1.0, delta * 2.0))
		queue_redraw()

	func _draw() -> void:
		var flap: float = absf(sin(_t * 14.0))
		var w: float = 2.0 + flap * 3.0
		draw_colored_polygon([Vector2(0, 0), Vector2(-w, -3), Vector2(-w, 3)], Color(1.0, 0.8, 0.4))
		draw_colored_polygon([Vector2(0, 0), Vector2(w, -3), Vector2(w, 3)], Color(1.0, 0.85, 0.5))
		draw_circle(Vector2.ZERO, 1.0, Color(0.2, 0.15, 0.1))


class _Petal extends Node2D:
	var tree_pos := Vector2.ZERO
	var _vel := Vector2.ZERO
	var _rot := 0.0
	var _rng := RandomNumberGenerator.new()

	func reset(anywhere: bool = false) -> void:
		_rng.seed = randi()
		position = tree_pos + Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-70, 0) if anywhere else -70.0)
		_vel = Vector2(_rng.randf_range(-12, 12), _rng.randf_range(18, 34))
		_rot = _rng.randf() * TAU

	func tick(delta: float, active: bool) -> void:
		visible = active
		if not active:
			return
		position += _vel * delta + Vector2(sin(_rot * 3.0) * 10.0 * delta, 0)
		_rot += delta * 2.0
		if position.y > tree_pos.y + 40.0:
			reset()
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, _rot, Vector2(1, 0.6))
		draw_circle(Vector2.ZERO, 2.2, Color(0.95, 0.65, 0.76, 0.9))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class _PerchedBird extends Node2D:
	var _hop := 0.0

	func tick(day_active: bool) -> void:
		var was := visible
		visible = day_active
		if visible and not was:
			_hop = 0.2
		if _hop > 0.0:
			_hop -= get_process_delta_time()
		queue_redraw()

	func _draw() -> void:
		var lift := -3.0 if _hop > 0.0 else 0.0
		draw_circle(Vector2(0, lift), 3.0, Color(0.25, 0.25, 0.3))
		draw_circle(Vector2(2.5, -2.5 + lift), 1.8, Color(0.25, 0.25, 0.3))
		draw_circle(Vector2(3.0, -2.8 + lift), 0.6, Color(1, 1, 1))
		draw_line(Vector2(4.2, -2.5 + lift), Vector2(5.5, -2.2 + lift), Color(0.9, 0.7, 0.2), 1.0)
