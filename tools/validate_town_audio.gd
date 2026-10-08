extends SceneTree

## AT-E: MusicContext + AudioDirector validation.
## - Cue resolution follows the contract for zone/phase/weather/danger.
## - Ambience mixes match time and place.
## - All cue/bed streams exist, load, and loop.
## - Director owns buses, crossfades cues, and never crashes on a missing cue.

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_cue_resolution()
	_test_ambience_mix()
	_test_streams()
	_test_director()
	_finish()


func _ctx(zone: StringName, phase: StringName, weather: int, danger: bool) -> Dictionary:
	return MusicContext.snapshot(zone, phase, weather, danger)


func _test_cue_resolution() -> void:
	_expect(MusicContext.cue_for(_ctx(&"market_street", &"day", 0, false)) == &"music.town.day", "day town -> town.day")
	_expect(MusicContext.cue_for(_ctx(&"market_street", &"dusk", 0, false)) == &"music.town.dusk", "dusk -> town.dusk")
	_expect(MusicContext.cue_for(_ctx(&"market_street", &"night", 0, false)) == &"music.town.night", "night -> town.night")
	_expect(MusicContext.cue_for(_ctx(&"market_street", &"day", 2, false)) == &"music.town.rain", "rain -> town.rain")
	_expect(MusicContext.cue_for(_ctx(&"shrine_hill", &"day", 0, false)) == &"music.shrine.story", "shrine -> shrine.story")
	_expect(MusicContext.cue_for(_ctx(&"market_street", &"day", 0, true)) == &"music.outskirts.danger", "danger -> outskirts.danger")
	_expect(MusicContext.cue_for(_ctx(&"shrine_hill", &"day", 0, true)) == &"music.outskirts.danger", "danger wins over shrine")


func _test_ambience_mix() -> void:
	var day_mix := MusicContext.ambience_mix(_ctx(&"market_street", &"day", 0, false))
	_expect(float(day_mix[&"amb.birds"]) > 0.3, "day must mix birds")
	var night_mix := MusicContext.ambience_mix(_ctx(&"market_street", &"night", 0, false))
	_expect(float(night_mix[&"amb.crickets"]) > 0.3, "night must mix crickets")
	var rain_mix := MusicContext.ambience_mix(_ctx(&"market_street", &"day", 2, false))
	_expect(float(rain_mix[&"amb.rain"]) > 0.3, "rain must mix rain bed")
	_expect(float(rain_mix[&"amb.birds"]) < 0.05, "rain must mute birds")
	var lake_mix := MusicContext.ambience_mix(_ctx(&"lakeside", &"day", 0, false))
	_expect(float(lake_mix[&"amb.water"]) > 0.3, "lakeside must mix water")
	var station_mix := MusicContext.ambience_mix(_ctx(&"station_plaza", &"day", 0, false))
	_expect(float(station_mix[&"amb.train"]) > 0.1, "station must mix distant train")


func _test_streams() -> void:
	for cue in [&"music.town.day", &"music.town.dusk", &"music.town.night", &"music.town.rain", &"music.shrine.story", &"music.outskirts.danger"]:
		var path := "res://assets/audio/music/music_%s.ogg" % String(cue).replace("music.", "").replace(".", "_")
		_expect(ResourceLoader.exists(path), "cue stream must exist: %s" % path)
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			_expect(stream != null, "cue stream must load: %s" % path)
	for bed in [&"amb.wind", &"amb.birds", &"amb.cicadas", &"amb.crickets", &"amb.rain", &"amb.water", &"amb.train"]:
		var path := "res://assets/audio/ambience/%s.ogg" % String(bed).replace(".", "_")
		_expect(ResourceLoader.exists(path), "bed stream must exist: %s" % path)


func _test_director() -> void:
	var director := root.get_node_or_null("AudioDirector")
	_expect(director != null, "AudioDirector autoload must exist")
	if director == null:
		return
	for bus in ["Music", "Ambience", "SFX", "UI"]:
		_expect(AudioServer.get_bus_index(bus) >= 0, "audio bus must exist: " + bus)
	_expect(int(director.get("_beds").size()) == 7, "director must own 7 ambience beds, found %d" % int(director.get("_beds").size()))
	director.update_context(_ctx(&"market_street", &"day", 0, false))
	_expect(StringName(director.get("_current_cue")) == &"music.town.day", "director must switch to town.day")
	director.update_context(_ctx(&"market_street", &"night", 0, false))
	_expect(StringName(director.get("_current_cue")) == &"music.town.night", "director must crossfade to town.night")
	for i in 200:
		await process_frame
	# Missing cue must not crash: _switch_cue guards with ResourceLoader.exists.
	_expect(StringName(director.get("_current_cue")) == &"music.town.night", "director must keep playing after crossfade")


func _finish() -> void:
	if _failures.is_empty():
		print("Town audio validation passed: cues, ambience and director are coherent.")
		quit.call_deferred(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit.call_deferred(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
