extends Resource

enum Screen { FULL = 0, WINDOW = 1 }

const MUTE_DB = -80.0

@export var screen: Screen = Screen.FULL:
	set = _set_screen
@export var mouse_restricted = false:
	set = _set_mouse_restricted
@export var locale = "":
	set = _set_locale
@export_range(0.0, 1.0, 0.01) var master_volume = 1.0:
	set = _set_master_volume
@export_range(0.0, 1.0, 0.01) var music_volume = 1.0:
	set = _set_music_volume
@export_range(0.0, 1.0, 0.01) var sfx_volume = 1.0:
	set = _set_sfx_volume
@export_range(0.0, 1.0, 0.01) var voice_volume = 1.0:
	set = _set_voice_volume


func _init():
	_apply_stored_options()


func _set_screen(value):
	screen = value
	_apply_screen()


func _set_mouse_restricted(value):
	mouse_restricted = value
	_apply_mouse_restricted()


func _set_locale(value):
	locale = str(value)
	_apply_locale()


func _set_master_volume(value):
	master_volume = _normalized_volume(value)


func _set_music_volume(value):
	music_volume = _normalized_volume(value)


func _set_sfx_volume(value):
	sfx_volume = _normalized_volume(value)


func _set_voice_volume(value):
	voice_volume = _normalized_volume(value)


func music_volume_db(base_volume_db = 0.0):
	return _scaled_volume_db(base_volume_db, music_volume)


func sfx_volume_db(base_volume_db = 0.0):
	return _scaled_volume_db(base_volume_db, sfx_volume)


func voice_volume_db(base_volume_db = 0.0):
	return _scaled_volume_db(base_volume_db, voice_volume)


func _apply_stored_options():
	_apply_locale()
	_apply_screen()
	_apply_mouse_restricted()


func _apply_screen():
	DisplayServer.window_set_mode(
		(
			DisplayServer.WINDOW_MODE_FULLSCREEN
			if screen == Screen.FULL
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
	)


func _apply_mouse_restricted():
	if mouse_restricted:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _apply_locale():
	if locale == "":
		TranslationServer.set_locale(OS.get_locale())
	else:
		TranslationServer.set_locale(locale)


func _scaled_volume_db(base_volume_db, channel_volume):
	var effective_volume = _normalized_volume(master_volume) * _normalized_volume(channel_volume)
	if effective_volume <= 0.0:
		return MUTE_DB
	return float(base_volume_db) + linear_to_db(effective_volume)


func _normalized_volume(value):
	return clampf(float(value), 0.0, 1.0)
