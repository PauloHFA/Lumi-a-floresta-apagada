# scripts/autoload/audio_manager.gd
extends Node

const _SFX_PATHS: Dictionary = {
	"jump": "res://assets/audio/sfx/jump.wav",
	"double_jump": "res://assets/audio/sfx/double_jump.wav",
	"land": "res://assets/audio/sfx/land.wav",
	"collect": "res://assets/audio/sfx/collect.wav",
	"hurt": "res://assets/audio/sfx/hurt.wav",
	"death": "res://assets/audio/sfx/death.wav",
	"levelup": "res://assets/audio/sfx/levelup.wav",
	"pulse": "res://assets/audio/sfx/pulse.wav",
	"checkpoint": "res://assets/audio/sfx/checkpoint.wav",
	"click": "res://assets/audio/sfx/click.wav",
	"dash": "res://assets/audio/sfx/dash.wav",
	"bounce": "res://assets/audio/sfx/bounce.wav",
	"crystal": "res://assets/audio/sfx/crystal.wav",
	"voice_pip": "res://assets/audio/sfx/voice_pip.wav",
}

const _MUSIC_PATHS: Dictionary = {
	"menu": "res://assets/audio/music/menu.wav",
	"mystery": "res://assets/audio/music/mystery.wav",
	"aerial": "res://assets/audio/music/aerial.wav",
	"epic": "res://assets/audio/music/epic.wav",
}

var _sfx: Dictionary = {}
var _music: Dictionary = {}

var _music_player: AudioStreamPlayer
var _current_track: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_audio_resources()
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)

func _load_audio_resources() -> void:
	for sfx_key: String in _SFX_PATHS.keys():
		var path: String = _SFX_PATHS[sfx_key]
		if ResourceLoader.exists(path):
			_sfx[sfx_key] = load(path)
	for music_key: String in _MUSIC_PATHS.keys():
		var path: String = _MUSIC_PATHS[music_key]
		if ResourceLoader.exists(path):
			_music[music_key] = load(path)

func play_sfx(sfx_name: String, pitch_variation: float = 0.05) -> void:
	if not _sfx.has(sfx_name):
		if _SFX_PATHS.has(sfx_name) and ResourceLoader.exists(_SFX_PATHS[sfx_name]):
			_sfx[sfx_name] = load(_SFX_PATHS[sfx_name])
		else:
			return
	var p := AudioStreamPlayer.new()
	p.stream = _sfx[sfx_name]
	p.bus = "SFX"
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func play_music(track_name: String) -> void:
	if _current_track == track_name and _music_player.playing:
		return
	if not _music.has(track_name):
		if _MUSIC_PATHS.has(track_name) and ResourceLoader.exists(_MUSIC_PATHS[track_name]):
			_music[track_name] = load(_MUSIC_PATHS[track_name])
		else:
			return
	_current_track = track_name
	_music_player.stream = _music[track_name]
	_music_player.play()

func stop_music() -> void:
	_current_track = ""
	_music_player.stop()

func _on_music_finished() -> void:
	if _current_track != "":
		_music_player.play()
