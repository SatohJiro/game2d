extends Node
# AudioManager: Plays genuine 16-bit sound effects and background music

static var instance: Node = null

var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer = null
const POOL_SIZE = 8

var sounds: Dictionary = {}

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Load sound effects
	sounds["slash"] = load("res://assets/sfx/sword.wav")
	sounds["hit"] = load("res://assets/sfx/hit.wav")
	sounds["sphere_throw"] = load("res://assets/sfx/fireball.wav")
	sounds["shake"] = load("res://assets/sfx/alert.wav")
	sounds["success"] = load("res://assets/sfx/success.wav")
	sounds["level_up"] = load("res://assets/sfx/powerup.wav")
	sounds["pickup"] = load("res://assets/sfx/coin.wav")
	sounds["jump"] = load("res://assets/sfx/jump.wav")
	
	# Setup SFX players
	for i in range(POOL_SIZE):
		var asp = AudioStreamPlayer.new()
		asp.bus = &"Master"
		add_child(asp)
		sfx_players.append(asp)
	
	# Setup BGM player
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Master"
	music_player.volume_db = -8.0
	add_child(music_player)
	if DisplayServer.get_name() != "headless":
		_play_music_internal("res://assets/music/adventure_begin.ogg")


func _exit_tree() -> void:
	if music_player != null:
		music_player.stop()
		music_player.stream = null
	for player in sfx_players:
		player.stop()
		player.stream = null
	sfx_players.clear()
	sounds.clear()
	music_player = null
	if instance == self:
		instance = null

static func play_music(music_path: String) -> void:
	if instance and instance.has_method("_play_music_internal"):
		instance._play_music_internal(music_path)

func _play_music_internal(music_path: String) -> void:
	var stream = load(music_path)
	if stream and music_player:
		music_player.stream = stream
		music_player.play()

static func play_sound(sound_name: String) -> void:
	if instance and instance.has_method("_play_sound_internal"):
		instance._play_sound_internal(sound_name)

func _play_sound_internal(sound_name: String) -> void:
	if not sounds.has(sound_name):
		return
	var stream: AudioStream = sounds[sound_name]
	if not stream:
		return
	
	for asp in sfx_players:
		if not asp.playing:
			asp.stream = stream
			asp.pitch_scale = randf_range(0.96, 1.04)
			asp.volume_db = -2.0
			asp.play()
			return
