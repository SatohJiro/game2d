extends Node
## AudioDirector (AT-E): music + ambience direction for Paloria Luminous Town.
## Autoload, ordered before AudioManager. Creates the Music/Ambience/SFX/UI
## buses, crossfades music cues from MusicContext snapshots, and mixes
## ambience beds. Gameplay never touches file paths.

static var instance: Node = null

const CUE_STREAMS := {
	&"music.town.day": "res://assets/audio/music/music_town_day.ogg",
	&"music.town.dusk": "res://assets/audio/music/music_town_dusk.ogg",
	&"music.town.night": "res://assets/audio/music/music_town_night.ogg",
	&"music.town.rain": "res://assets/audio/music/music_town_rain.ogg",
	&"music.shrine.story": "res://assets/audio/music/music_shrine_story.ogg",
	&"music.outskirts.danger": "res://assets/audio/music/music_outskirts_danger.ogg",
}

const BED_STREAMS := {
	&"amb.wind": "res://assets/audio/ambience/amb_wind.ogg",
	&"amb.birds": "res://assets/audio/ambience/amb_birds.ogg",
	&"amb.cicadas": "res://assets/audio/ambience/amb_cicadas.ogg",
	&"amb.crickets": "res://assets/audio/ambience/amb_crickets.ogg",
	&"amb.rain": "res://assets/audio/ambience/amb_rain.ogg",
	&"amb.water": "res://assets/audio/ambience/amb_water.ogg",
	&"amb.train": "res://assets/audio/ambience/amb_train.ogg",
}

const CROSSFADE_SECONDS := 2.5

## Test seam: when false, cue switches assign streams without starting
## playback (keeps headless validators deterministic; no audio thread race).
var playback_enabled := true

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _standby: AudioStreamPlayer
var _fade := 0.0
var _current_cue := &""
var _beds: Dictionary = {}
var _bed_targets: Dictionary = {}


func _enter_tree() -> void:
	instance = self
	_ensure_bus(&"Music")
	_ensure_bus(&"Ambience")
	_ensure_bus(&"SFX")
	_ensure_bus(&"UI")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_a = _make_player(&"Music", -10.0)
	_music_b = _make_player(&"Music", -10.0)
	_active = _music_a
	_standby = _music_b
	for bed_id in BED_STREAMS.keys():
		var player := _make_player(&"Ambience", -60.0)
		player.stream = load(String(BED_STREAMS[bed_id])) as AudioStream
		_beds[bed_id] = player
		_bed_targets[bed_id] = 0.0


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(String(bus_name)) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, String(bus_name))
		AudioServer.set_bus_send(AudioServer.get_bus_index(String(bus_name)), &"Master")


func _make_player(bus: StringName, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	player.volume_db = volume_db
	add_child(player)
	return player


## Drive the director from a MusicContext snapshot. Call ~1/sec.
func update_context(ctx: Dictionary) -> void:
	var cue := MusicContext.cue_for(ctx)
	if cue != _current_cue:
		_switch_cue(cue)
	var mix := MusicContext.ambience_mix(ctx)
	for bed_id in mix.keys():
		_bed_targets[bed_id] = float(mix[bed_id])


func _switch_cue(cue: StringName) -> void:
	var path := String(CUE_STREAMS.get(cue, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return  # missing cue: keep current music, never crash
	_current_cue = cue
	_standby.stream = load(path) as AudioStream
	_standby.volume_db = -60.0
	if playback_enabled:
		_standby.play()
	_fade = 0.0


func _process(delta: float) -> void:
	if not playback_enabled:
		return
	# Music crossfade.
	if _standby.playing and _fade < 1.0:
		_fade = minf(1.0, _fade + delta / CROSSFADE_SECONDS)
		_active.volume_db = lerpf(-10.0, -60.0, _fade)
		_standby.volume_db = lerpf(-60.0, -10.0, _fade)
		if _fade >= 1.0:
			_active.stop()
			var tmp := _active
			_active = _standby
			_standby = tmp
	# Ambience bed gains glide toward targets.
	for bed_id in _beds.keys():
		var player := _beds[bed_id] as AudioStreamPlayer
		var target_gain := float(_bed_targets.get(bed_id, 0.0))
		var target_db := -60.0 if target_gain <= 0.01 else lerpf(-28.0, -10.0, target_gain)
		player.volume_db = lerpf(player.volume_db, target_db, minf(1.0, delta * 1.5))
		if target_gain > 0.01 and not player.playing:
			player.play()
		elif target_gain <= 0.01 and player.volume_db < -55.0 and player.playing:
			player.stop()


static func current_cue() -> StringName:
	if instance != null and instance.has_method("_get_cue"):
		return instance._get_cue()
	return &""


func _get_cue() -> StringName:
	return _current_cue


static func bed_player_count() -> int:
	if instance != null:
		return (instance as Node).get("_beds").size()
	return 0
