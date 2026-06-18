extends Control

@export var force_web_platform_for_tests = false

@onready var _title_label = find_child("TitleLabel")
@onready var _subtitle_label = find_child("SubtitleLabel")
@onready var _operation_label = find_child("OperationLabel")
@onready var _status_label = find_child("StatusLabel")
@onready var _roster_label = find_child("RosterLabel")
@onready var _command_label = find_child("CommandLabel")
@onready var _play_button = find_child("PlayButton")
@onready var _options_button = find_child("OptionsButton")
@onready var _credits_button = find_child("CreditsButton")
@onready var _quit_button = find_child("QuitButton")
@onready var _systems_label = find_child("StatusStrip")


func _ready():
	_title_label.text = tr("GAME_TITLE")
	_subtitle_label.text = tr("GAME_SUBTITLE")
	_operation_label.text = tr("MAIN_OPERATION")
	_status_label.text = tr("MAIN_STATUS")
	_roster_label.text = tr("MAIN_ROSTER")
	_command_label.text = tr("MAIN_COMMAND")
	_systems_label.text = tr("MAIN_SYSTEMS_ONLINE")
	_play_button.text = tr("PLAY")
	_options_button.text = tr("OPTIONS")
	_credits_button.text = tr("CREDITS")
	_setup_platform_command_button()


func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://source/main-menu/Play.tscn")


func _on_options_button_pressed():
	get_tree().change_scene_to_file("res://source/main-menu/Options.tscn")


func _on_credits_button_pressed():
	get_tree().change_scene_to_file("res://source/main-menu/Credits.tscn")


func _on_quit_button_pressed():
	if _is_web_platform():
		_toggle_fullscreen()
		return
	get_tree().quit()


func _setup_platform_command_button():
	if _is_web_platform():
		_quit_button.text = tr("FULLSCREEN")
		_quit_button.tooltip_text = tr("FULLSCREEN_TOOLTIP")
		return
	_quit_button.text = tr("QUIT")
	_quit_button.tooltip_text = ""


func _is_web_platform():
	return force_web_platform_for_tests or OS.has_feature("web") or OS.get_name() == "Web"


func _toggle_fullscreen():
	var mode = DisplayServer.window_get_mode()
	if (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
