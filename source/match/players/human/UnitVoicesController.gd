extends Node

const Structure = preload("res://source/match/units/Structure.gd")
const ResourceUnit = preload("res://source/match/units/non-player/ResourceUnit.gd")

var _last_event_handled = null
var _last_ack_event = 0
var _last_command_key = ""

@onready var _audio_player = find_child("AudioStreamPlayer")
@onready var _player = get_parent()


func _ready() -> void:
	MatchSignals.unit_selected.connect(_on_unit_selected)
	MatchSignals.unit_targeted.connect(_on_unit_action_requested)
	MatchSignals.terrain_targeted.connect(_on_unit_action_requested)
	MatchSignals.unit_command_confirmed.connect(_on_unit_command_confirmed)


func _handle_event(event):
	if _audio_player.playing:
		return false
	_last_event_handled = event
	_audio_player.stream = Constants.Match.VoiceNarrator.EVENT_TO_ASSET_MAPPING[event]
	_audio_player.volume_db = _voice_volume_db()
	_audio_player.play()
	return true


func _on_unit_selected(unit):
	if _is_owned_voice_unit(unit):
		_handle_event(Constants.Match.VoiceNarrator.Events.UNIT_HELLO)


func _on_unit_action_requested(_ignore):
	if _has_owned_voice_units(get_tree().get_nodes_in_group("selected_units")):
		_handle_acknowledgement("")


func _on_unit_command_confirmed(command_key, units):
	if _has_owned_voice_units(units):
		_handle_acknowledgement(command_key)


func _handle_acknowledgement(command_key):
	var event = (
		Constants.Match.VoiceNarrator.Events.UNIT_ACK_1
		if _last_ack_event == 0
		else Constants.Match.VoiceNarrator.Events.UNIT_ACK_2
	)
	if _handle_event(event):
		_last_ack_event = (_last_ack_event + 1) % 2
		_last_command_key = command_key


func _has_owned_voice_units(units):
	for unit in units:
		if _is_owned_voice_unit(unit):
			return true
	return false


func _is_owned_voice_unit(unit):
	return (
		unit != null
		and is_instance_valid(unit)
		and not unit is Structure
		and not unit is ResourceUnit
		and "player" in unit
		and unit.player == _player
	)


func _voice_volume_db():
	if Globals.options != null and Globals.options.has_method("voice_volume_db"):
		return Globals.options.voice_volume_db(0.0)
	return 0.0
