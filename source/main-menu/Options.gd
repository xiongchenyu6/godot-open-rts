extends Control

const LOCALE_OPTIONS = [
	{"key": "OPTIONS_LANGUAGE_SYSTEM", "locale": ""},
	{"key": "OPTIONS_LANGUAGE_CHINESE", "locale": "zh_CN"},
	{"key": "OPTIONS_LANGUAGE_ENGLISH", "locale": "en"},
	{"key": "OPTIONS_LANGUAGE_POLISH", "locale": "pl"},
]
const VOLUME_SLIDER_SCALE = 100.0
const AUDIO_VOLUME_CONTROLS = [
	{
		"name": "MasterVolume",
		"label_key": "OPTIONS_MASTER_VOLUME",
		"getter": "master_volume",
		"method": "_on_master_volume_value_changed",
	},
	{
		"name": "MusicVolume",
		"label_key": "OPTIONS_MUSIC_VOLUME",
		"getter": "music_volume",
		"method": "_on_music_volume_value_changed",
	},
	{
		"name": "SfxVolume",
		"label_key": "OPTIONS_SFX_VOLUME",
		"getter": "sfx_volume",
		"method": "_on_sfx_volume_value_changed",
	},
	{
		"name": "VoiceVolume",
		"label_key": "OPTIONS_VOICE_VOLUME",
		"getter": "voice_volume",
		"method": "_on_voice_volume_value_changed",
	},
]

@onready var _screen = find_child("Screen")
@onready var _language = find_child("Language")
@onready var _mouse_movement_restricted = find_child("MouseMovementRestricted")
@onready var _video_label = find_child("VideoLabel")
@onready var _language_label = find_child("LanguageLabel")
@onready var _mouse_label = find_child("MouseLabel")
@onready var _back_button = find_child("BackButton")
var _audio_label = null


func _ready():
	_setup_audio_controls()
	_localize_static_text()
	_mouse_movement_restricted.button_pressed = Globals.options.mouse_restricted
	_screen.selected = Globals.options.screen
	_select_locale(Globals.options.locale)
	_refresh_audio_controls()


func _on_mouse_movement_restricted_pressed():
	Globals.options.mouse_restricted = _mouse_movement_restricted.button_pressed
	_save_options()


func _on_screen_item_selected(index):
	Globals.options.screen = {
		0: Globals.options.Screen.FULL,
		1: Globals.options.Screen.WINDOW,
	}[index]
	_save_options()


func _on_language_item_selected(index):
	Globals.options.locale = LOCALE_OPTIONS[index]["locale"]
	_save_options()
	_localize_static_text()
	_select_locale(Globals.options.locale)


func _on_master_volume_value_changed(value):
	Globals.options.master_volume = _slider_value_to_volume(value)
	_refresh_audio_controls()
	_save_options()


func _on_music_volume_value_changed(value):
	Globals.options.music_volume = _slider_value_to_volume(value)
	_refresh_audio_controls()
	_save_options()


func _on_sfx_volume_value_changed(value):
	Globals.options.sfx_volume = _slider_value_to_volume(value)
	_refresh_audio_controls()
	_save_options()


func _on_voice_volume_value_changed(value):
	Globals.options.voice_volume = _slider_value_to_volume(value)
	_refresh_audio_controls()
	_save_options()


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://source/main-menu/Main.tscn")


func _localize_static_text():
	if _video_label != null:
		_video_label.text = tr("OPTIONS_VIDEO")
	if _language_label != null:
		_language_label.text = tr("OPTIONS_LANGUAGE")
	if _mouse_label != null:
		_mouse_label.text = tr("OPTIONS_MOUSE")
	if _mouse_movement_restricted != null:
		_mouse_movement_restricted.text = tr("OPTIONS_MOUSE_RESTRICTED")
	if _back_button != null:
		_back_button.text = tr("BACK")
	_setup_screen_options()
	_setup_language_options()
	_refresh_audio_controls()


func _setup_screen_options():
	if _screen == null:
		return
	_screen.clear()
	_screen.add_item(tr("OPTIONS_SCREEN_FULLSCREEN"), Globals.options.Screen.FULL)
	_screen.add_item(tr("OPTIONS_SCREEN_WINDOW"), Globals.options.Screen.WINDOW)
	_screen.select(Globals.options.screen)


func _setup_language_options():
	if _language == null:
		return
	_language.clear()
	for option_id in range(LOCALE_OPTIONS.size()):
		_language.add_item(tr(LOCALE_OPTIONS[option_id]["key"]), option_id)


func _select_locale(locale):
	if _language == null:
		return
	for option_id in range(LOCALE_OPTIONS.size()):
		if LOCALE_OPTIONS[option_id]["locale"] == locale:
			_language.select(option_id)
			return
	_language.select(0)


func _setup_audio_controls():
	var content = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer")
	if content == null:
		return
	var audio_panel = content.find_child("AudioPanel", false, false)
	if audio_panel == null:
		audio_panel = _create_audio_panel()
		content.add_child(audio_panel)
	var language_panel = content.find_child("PanelContainer3", false, false)
	if language_panel != null:
		content.move_child(audio_panel, language_panel.get_index() + 1)
	_audio_label = audio_panel.find_child("AudioLabel", true, false)
	for config in AUDIO_VOLUME_CONTROLS:
		var slider = audio_panel.find_child("{0}Slider".format([config["name"]]), true, false)
		if slider == null:
			continue
		var method = Callable(self, config["method"])
		if not slider.value_changed.is_connected(method):
			slider.value_changed.connect(method)


func _create_audio_panel():
	var panel = PanelContainer.new()
	panel.name = "AudioPanel"
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	var rows = VBoxContainer.new()
	rows.name = "AudioRows"
	_audio_label = Label.new()
	_audio_label.name = "AudioLabel"
	_audio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var label_panel = Panel.new()
	label_panel.name = "Panel"
	label_panel.show_behind_parent = true
	label_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_audio_label.add_child(label_panel)
	rows.add_child(_audio_label)
	for config in AUDIO_VOLUME_CONTROLS:
		rows.add_child(_create_volume_row(config))
	margin.add_child(rows)
	panel.add_child(margin)
	return panel


func _create_volume_row(config):
	var row = HBoxContainer.new()
	row.name = "{0}Row".format([config["name"]])
	row.add_theme_constant_override("separation", 8)
	var label = Label.new()
	label.name = "{0}Label".format([config["name"]])
	label.custom_minimum_size = Vector2(112, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var slider = HSlider.new()
	slider.name = "{0}Slider".format([config["name"]])
	slider.min_value = 0.0
	slider.max_value = VOLUME_SLIDER_SCALE
	slider.step = 5.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_NONE
	row.add_child(slider)
	var value_label = Label.new()
	value_label.name = "{0}ValueLabel".format([config["name"]])
	value_label.custom_minimum_size = Vector2(44, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	return row


func _refresh_audio_controls():
	var audio_panel = find_child("AudioPanel", true, false)
	if audio_panel == null:
		return
	if _audio_label == null:
		_audio_label = audio_panel.find_child("AudioLabel", true, false)
	if _audio_label != null:
		_audio_label.text = tr("OPTIONS_AUDIO")
	for config in AUDIO_VOLUME_CONTROLS:
		var label = audio_panel.find_child("{0}Label".format([config["name"]]), true, false)
		var slider = audio_panel.find_child("{0}Slider".format([config["name"]]), true, false)
		var value_label = audio_panel.find_child(
			"{0}ValueLabel".format([config["name"]]), true, false
		)
		var volume = float(Globals.options.get(config["getter"]))
		if label != null:
			label.text = tr(config["label_key"])
		if slider != null:
			slider.set_value_no_signal(round(volume * VOLUME_SLIDER_SCALE))
		if value_label != null:
			value_label.text = _format_volume_percent(volume)


func _format_volume_percent(volume):
	return "{0}%".format([int(round(_slider_value_to_volume(volume * VOLUME_SLIDER_SCALE) * 100.0))])


func _slider_value_to_volume(value):
	return clampf(float(value) / VOLUME_SLIDER_SCALE, 0.0, 1.0)


func _save_options():
	ResourceSaver.save(Globals.options, Constants.OPTIONS_FILE_PATH)
