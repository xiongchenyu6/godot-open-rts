extends Node

const BATTLE_LOOP = preload("res://assets/music/rts_battle_loop.ogg")

@export var volume_db = -19.0

@onready var _audio_player = AudioStreamPlayer.new()


func _ready():
	add_child(_audio_player)
	_audio_player.stream = BATTLE_LOOP
	_audio_player.volume_db = _music_volume_db()
	_audio_player.finished.connect(_audio_player.play)
	if "loop" in _audio_player.stream:
		_audio_player.stream.loop = true
	_audio_player.play()


func _music_volume_db():
	if Globals.options != null and Globals.options.has_method("music_volume_db"):
		return Globals.options.music_volume_db(volume_db)
	return volume_db
