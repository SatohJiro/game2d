extends SceneTree

## AT-C: WorldClock + lighting/weather validation.
## - Phase boundaries and darkness windows match the design contract.
## - Weather is deterministic per (save_id, day_index).
## - In-game: lamps glow at night, off at day; rain visuals activate on rain days.

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_world_clock()
	_test_weather_determinism()
	_test_directors()
	_finish()


func _test_world_clock() -> void:
	_expect(WorldClock.phase_for_progress(0.0) == WorldClock.Phase.DAY, "progress 0.0 must be DAY")
	_expect(WorldClock.phase_for_progress(0.44) == WorldClock.Phase.DAY, "progress 0.44 must be DAY")
	_expect(WorldClock.phase_for_progress(0.5) == WorldClock.Phase.DUSK, "progress 0.5 must be DUSK")
	_expect(WorldClock.phase_for_progress(0.7) == WorldClock.Phase.NIGHT, "progress 0.7 must be NIGHT")
	_expect(WorldClock.phase_for_progress(0.95) == WorldClock.Phase.DAWN, "progress 0.95 must be DAWN")
	_expect(not WorldClock.is_dark(0.2), "midday must not be dark")
	_expect(WorldClock.is_dark(0.7), "night must be dark")
	_expect(WorldClock.is_dark(0.95), "dawn must be dark")
	_expect(WorldClock.phase_name(WorldClock.Phase.DUSK) == &"dusk", "phase name must be dusk")
	var c_day := WorldClock.ambient_color(0.2)
	var c_night := WorldClock.ambient_color(0.75)
	_expect(c_day.r > 0.9 and c_day.g > 0.9, "day ambient must be bright")
	_expect(c_night.r < 0.6 and c_night.b > 0.4, "night ambient must be indigo-dim")


func _test_weather_determinism() -> void:
	var a := WeatherDirector.weather_for("save.slot_1", 3)
	var b := WeatherDirector.weather_for("save.slot_1", 3)
	_expect(a == b, "weather must be deterministic for the same inputs")
	var seen := {}
	for day in 40:
		seen[WeatherDirector.weather_for("save.slot_1", day)] = true
	_expect(seen.size() >= 2, "40 days must produce at least 2 weather states, got %d" % seen.size())


func _test_directors() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main scene must load")
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var lighting := main.get("lighting_director") as LightingDirector
	var weather := main.get("weather_director") as WeatherDirector
	_expect(lighting != null, "main must own a LightingDirector")
	_expect(weather != null, "main must own a WeatherDirector")
	if lighting == null or weather == null:
		return
	_expect(lighting.lamp_count() >= 5, "town must place at least 5 lamps, found %d" % lighting.lamp_count())
	# Night: lamps on.
	lighting.update_clock(0.75, false, 2.0)
	_expect(lighting.lamp_energy() > 0.3, "lamps must glow at night, energy=%f" % lighting.lamp_energy())
	# Day: lamps off.
	lighting.update_clock(0.2, false, 2.0)
	_expect(lighting.lamp_energy() < 0.15, "lamps must be off at day, energy=%f" % lighting.lamp_energy())
	# Rain day: find one deterministically, drive the director, check visuals.
	var rain_day := -1
	for day in 60:
		if WeatherDirector.weather_for("save.slot_1", day) == WeatherDirector.Weather.RAIN:
			rain_day = day
			break
	_expect(rain_day >= 0, "must find a deterministic rain day within 60 days")
	if rain_day >= 0:
		weather.update_clock(rain_day * WorldClock.DAY_DURATION + 10.0, "save.slot_1", false, 0.1)
		_expect(weather.current_weather() == WeatherDirector.Weather.RAIN, "director must report RAIN")
		var rain_node := weather.get_node_or_null("WeatherDim/Rain")
		_expect(rain_node != null and (rain_node as CanvasItem).visible, "rain visuals must activate on rain days")
	main.queue_free()


func _finish() -> void:
	if _failures.is_empty():
		print("Town atmosphere validation passed: WorldClock, lighting and weather directors are coherent.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit.call_deferred(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
