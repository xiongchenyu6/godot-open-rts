extends Node

const Structure = preload("res://source/match/units/Structure.gd")

const UNDER_ATTACK_NOTIFICATION_THRESHOLD_MS = 10 * 1000

var _last_event_handled = null
var _last_under_attack_notification_timestamp = 0

@onready var _audio_player = find_child("AudioStreamPlayer")
@onready var _player = get_parent()


func _ready():
	MatchSignals.match_started.connect(
		_handle_event.bind(Constants.Match.VoiceNarrator.Events.MATCH_STARTED)
	)
	MatchSignals.match_aborted.connect(
		_handle_event.bind(Constants.Match.VoiceNarrator.Events.MATCH_ABORTED)
	)
	MatchSignals.match_finished_with_victory.connect(
		_handle_event.bind(Constants.Match.VoiceNarrator.Events.MATCH_FINISHED_WITH_VICTORY)
	)
	MatchSignals.match_finished_with_defeat.connect(
		_handle_event.bind(Constants.Match.VoiceNarrator.Events.MATCH_FINISHED_WITH_DEFEAT)
	)
	MatchSignals.unit_damaged.connect(_on_unit_damaged)
	MatchSignals.unit_died.connect(_on_unit_died)
	MatchSignals.unit_production_started.connect(_on_production_started)
	MatchSignals.unit_production_finished.connect(_on_production_finished)
	MatchSignals.not_enough_resources_for_production.connect(_on_not_enough_resources)
	MatchSignals.not_enough_resources_for_construction.connect(_on_not_enough_resources)
	MatchSignals.unit_construction_finished.connect(_on_construction_finished)
	MatchSignals.support_power_activated.connect(_on_support_power_activated)
	MatchSignals.support_power_ready.connect(_on_support_power_ready)


func _handle_event(event):
	if (
		_audio_player.playing
		and (
			_last_event_handled
			in [
				Constants.Match.VoiceNarrator.Events.MATCH_FINISHED_WITH_VICTORY,
				Constants.Match.VoiceNarrator.Events.MATCH_FINISHED_WITH_DEFEAT
			]
		)
	):
		return
	_last_event_handled = event
	_audio_player.stream = Constants.Match.VoiceNarrator.EVENT_TO_ASSET_MAPPING[event]
	_audio_player.volume_db = _voice_volume_db()
	_audio_player.play()


func _on_unit_damaged(unit):
	if unit.player != _player:
		return
	var current_timestamp = Time.get_ticks_msec()
	if (
		current_timestamp - _last_under_attack_notification_timestamp
		> UNDER_ATTACK_NOTIFICATION_THRESHOLD_MS
	):
		_handle_event(
			(
				Constants.Match.VoiceNarrator.Events.BASE_UNDER_ATTACK
				if unit is Structure
				else Constants.Match.VoiceNarrator.Events.UNIT_UNDER_ATTACK
			)
		)
	_last_under_attack_notification_timestamp = current_timestamp


func _on_unit_died(unit):
	if unit.is_in_group("controlled_units"):
		_handle_event(Constants.Match.VoiceNarrator.Events.UNIT_LOST)


func _on_production_started(_unit_prototype, producer_unit):
	if producer_unit.player == _player:
		_handle_event(Constants.Match.VoiceNarrator.Events.UNIT_PRODUCTION_STARTED)


func _on_production_finished(_unit, producer_unit):
	if producer_unit.player == _player:
		_handle_event(Constants.Match.VoiceNarrator.Events.UNIT_PRODUCTION_FINISHED)


func _on_construction_finished(unit):
	if unit.player == _player:
		_handle_event(Constants.Match.VoiceNarrator.Events.UNIT_CONSTRUCTION_FINISHED)


func _on_not_enough_resources(player):
	if player == get_parent():
		_handle_event(Constants.Match.VoiceNarrator.Events.NOT_ENOUGH_RESOURCES)


func _on_support_power_activated(power_id, player, _target_position):
	if player == _player:
		_handle_event(Constants.Match.VoiceNarrator.Events.SUPPORT_POWER_FIRED)
	elif _player_is_enemy(player):
		_handle_event(
			(
				Constants.Match.VoiceNarrator.Events.ENEMY_SUPERWEAPON_LAUNCHED
				if _is_superweapon(power_id)
				else Constants.Match.VoiceNarrator.Events.ENEMY_SUPPORT_POWER_FIRED
			)
		)


func _on_support_power_ready(power_id, player):
	if player == _player:
		_handle_event(Constants.Match.VoiceNarrator.Events.SUPPORT_POWER_READY)
	elif _player_is_enemy(player) and _is_superweapon(power_id):
		_handle_event(Constants.Match.VoiceNarrator.Events.ENEMY_SUPERWEAPON_READY)


func _player_is_enemy(player):
	return player != null and _player != null and _player.is_enemy_with(player)


func _is_superweapon(power_id):
	return (
		Constants.Match.SupportPowers.DEFINITIONS.has(power_id)
		and Constants.Match.SupportPowers.DEFINITIONS[power_id].get("superweapon", false)
	)


func _voice_volume_db():
	if Globals.options != null and Globals.options.has_method("voice_volume_db"):
		return Globals.options.voice_volume_db(0.0)
	return 0.0
