extends Node

const Structure = preload("res://source/match/units/Structure.gd")

const SELECT_SOUND = preload("res://assets/sfx/ui_select.wav")
const COMMAND_SOUND = preload("res://assets/sfx/command_confirm.wav")
const HIT_SOUND = preload("res://assets/sfx/weapon_hit.wav")
const EXPLOSION_SOUND = preload("res://assets/sfx/explosion_small.wav")
const PRODUCTION_START_SOUND = preload("res://assets/sfx/production_start.wav")
const PRODUCTION_READY_SOUND = preload("res://assets/sfx/production_ready.wav")
const CONSTRUCTION_STARTED_SOUND = preload("res://assets/sfx/construction_started.wav")
const CONSTRUCTION_CANCELED_SOUND = preload("res://assets/sfx/construction_canceled.wav")
const ERROR_SOUND = preload("res://assets/sfx/error.wav")
const LOW_POWER_SOUND = preload("res://assets/sfx/low_power_warning.wav")
const REPAIR_STARTED_SOUND = preload("res://assets/sfx/repair_started.wav")
const STRUCTURE_CAPTURED_SOUND = preload("res://assets/sfx/structure_captured.wav")
const STRUCTURE_LOST_SOUND = preload("res://assets/sfx/structure_lost.wav")
const STRUCTURE_SOLD_SOUND = preload("res://assets/sfx/structure_sold.wav")
const SUPPLY_CRATE_SOUND = preload("res://assets/sfx/supply_crate.wav")
const UNIT_PROMOTED_SOUND = preload("res://assets/sfx/unit_promoted.wav")
const SUPPORT_POWER_READY_SOUND = preload("res://assets/sfx/support_power_ready.wav")
const SUPPORT_POWER_FIRE_SOUND = preload("res://assets/sfx/support_power_fire.wav")
const SUPERWEAPON_WARNING_SOUND = preload("res://assets/sfx/superweapon_warning.wav")

const PLAYERS_COUNT = 16
const HIT_SOUND_COOLDOWN_MS = 80
const EXPLOSION_SOUND_COOLDOWN_MS = 140

const SOUND_SELECT = "select"
const SOUND_COMMAND = "command"
const SOUND_HIT = "hit"
const SOUND_EXPLOSION = "explosion"
const SOUND_PRODUCTION_START = "production_start"
const SOUND_PRODUCTION_READY = "production_ready"
const SOUND_CONSTRUCTION_STARTED = "construction_started"
const SOUND_CONSTRUCTION_CANCELED = "construction_canceled"
const SOUND_ERROR = "error"
const SOUND_LOW_POWER = "low_power"
const SOUND_REPAIR_STARTED = "repair_started"
const SOUND_STRUCTURE_CAPTURED = "structure_captured"
const SOUND_STRUCTURE_LOST = "structure_lost"
const SOUND_STRUCTURE_SOLD = "structure_sold"
const SOUND_SUPPLY_CRATE = "supply_crate"
const SOUND_UNIT_PROMOTED = "unit_promoted"
const SOUND_PRODUCTION_BLOCKED = "production_blocked"
const SOUND_SUPPORT_POWER_READY = "support_power_ready"
const SOUND_SUPPORT_POWER_FIRE = "support_power_fire"
const SOUND_ENEMY_SUPPORT_POWER = "enemy_support_power"
const SOUND_ENEMY_SUPERWEAPON_CHARGING = "enemy_superweapon_charging"
const SOUND_ENEMY_SUPERWEAPON_READY = "enemy_superweapon_ready"
const SOUND_ENEMY_SUPERWEAPON_LAUNCHED = "enemy_superweapon_launched"

var _audio_players = []
var _last_hit_sound_timestamp = 0
var _last_explosion_sound_timestamp = 0
var _last_sound_tag = ""
var _last_sound_stream = null
var _was_low_power = null

@onready var _player = get_parent()


func _ready():
	for _i in range(PLAYERS_COUNT):
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		_audio_players.append(audio_player)

	MatchSignals.unit_selected.connect(_on_unit_selected)
	MatchSignals.terrain_targeted.connect(_on_target_requested)
	MatchSignals.unit_targeted.connect(_on_target_requested)
	MatchSignals.unit_command_confirmed.connect(_on_unit_command_confirmed)
	MatchSignals.unit_damaged.connect(_on_unit_damaged)
	MatchSignals.unit_died.connect(_on_unit_died)
	MatchSignals.unit_production_started.connect(_on_unit_production_started)
	MatchSignals.unit_production_blocked.connect(_on_unit_production_blocked)
	MatchSignals.unit_production_finished.connect(_on_unit_production_finished)
	MatchSignals.unit_construction_started.connect(_on_unit_construction_started)
	MatchSignals.unit_construction_canceled.connect(_on_unit_construction_canceled)
	MatchSignals.unit_construction_finished.connect(_on_unit_construction_finished)
	MatchSignals.unit_repair_started.connect(_on_unit_repair_started)
	MatchSignals.unit_sell_started.connect(_on_unit_sell_started)
	MatchSignals.unit_captured.connect(_on_unit_captured)
	MatchSignals.unit_promoted.connect(_on_unit_promoted)
	MatchSignals.supply_crate_collected.connect(_on_supply_crate_collected)
	MatchSignals.not_enough_resources_for_production.connect(_on_not_enough_resources)
	MatchSignals.not_enough_resources_for_construction.connect(_on_not_enough_resources)
	MatchSignals.support_power_charging.connect(_on_support_power_charging)
	MatchSignals.support_power_ready.connect(_on_support_power_ready)
	MatchSignals.support_power_activated.connect(_on_support_power_activated)
	_refresh_power_state(false)


func _process(_delta):
	_refresh_power_state()


func _play(stream, volume_db = 0.0, sound_tag = ""):
	var audio_player = _free_audio_player()
	if audio_player == null:
		return
	audio_player.stream = stream
	audio_player.volume_db = _sfx_volume_db(volume_db)
	audio_player.pitch_scale = randf_range(0.96, 1.04)
	audio_player.play()
	_last_sound_tag = sound_tag
	_last_sound_stream = stream


func _free_audio_player():
	for audio_player in _audio_players:
		if not audio_player.playing:
			return audio_player
	return null


func _sfx_volume_db(base_volume_db):
	if Globals.options != null and Globals.options.has_method("sfx_volume_db"):
		return Globals.options.sfx_volume_db(base_volume_db)
	return base_volume_db


func _visible_to_player(unit):
	return unit != null and "visible" in unit and unit.visible


func _controlled_selected_units():
	return get_tree().get_nodes_in_group("selected_units").filter(
		func(unit): return "player" in unit and unit.player == _player
	)


func _unit_owned_by_player(unit):
	return unit != null and "player" in unit and unit.player == _player


func _on_unit_selected(unit):
	if _unit_owned_by_player(unit):
		_play(SELECT_SOUND, -5.0 if unit is Structure else -3.0, SOUND_SELECT)


func _on_target_requested(_target):
	if not _controlled_selected_units().is_empty():
		_play(COMMAND_SOUND, -4.0, SOUND_COMMAND)


func _on_unit_command_confirmed(_command_key, units):
	for unit in units:
		if _unit_owned_by_player(unit):
			_play(COMMAND_SOUND, -4.0, SOUND_COMMAND)
			return


func _on_unit_damaged(unit):
	if not _visible_to_player(unit):
		return
	var current_timestamp = Time.get_ticks_msec()
	if current_timestamp - _last_hit_sound_timestamp < HIT_SOUND_COOLDOWN_MS:
		return
	_last_hit_sound_timestamp = current_timestamp
	_play(HIT_SOUND, -7.0, SOUND_HIT)


func _on_unit_died(unit):
	if not _visible_to_player(unit):
		return
	var current_timestamp = Time.get_ticks_msec()
	if current_timestamp - _last_explosion_sound_timestamp < EXPLOSION_SOUND_COOLDOWN_MS:
		return
	_last_explosion_sound_timestamp = current_timestamp
	_play(EXPLOSION_SOUND, -4.0, SOUND_EXPLOSION)


func _on_unit_production_started(_unit_prototype, producer_unit):
	if _unit_owned_by_player(producer_unit):
		_play(PRODUCTION_START_SOUND, -6.0, SOUND_PRODUCTION_START)


func _on_unit_production_blocked(_unit_prototype, producer_unit):
	if _unit_owned_by_player(producer_unit):
		_play(ERROR_SOUND, -4.0, SOUND_PRODUCTION_BLOCKED)


func _on_unit_production_finished(_unit, producer_unit):
	if _unit_owned_by_player(producer_unit):
		_play(PRODUCTION_READY_SOUND, -5.0, SOUND_PRODUCTION_READY)


func _on_unit_construction_finished(unit):
	if _unit_owned_by_player(unit):
		_play(PRODUCTION_READY_SOUND, -4.0, SOUND_PRODUCTION_READY)


func _on_unit_construction_started(unit):
	if _unit_owned_by_player(unit):
		_play(CONSTRUCTION_STARTED_SOUND, -5.0, SOUND_CONSTRUCTION_STARTED)


func _on_unit_construction_canceled(unit):
	if _unit_owned_by_player(unit):
		_play(CONSTRUCTION_CANCELED_SOUND, -5.0, SOUND_CONSTRUCTION_CANCELED)


func _on_unit_repair_started(unit):
	if _unit_owned_by_player(unit):
		_play(REPAIR_STARTED_SOUND, -5.0, SOUND_REPAIR_STARTED)


func _on_unit_sell_started(unit):
	if _unit_owned_by_player(unit):
		_play(STRUCTURE_SOLD_SOUND, -4.0, SOUND_STRUCTURE_SOLD)


func _on_not_enough_resources(player):
	if player == _player:
		_play(ERROR_SOUND, -4.0, SOUND_ERROR)


func _on_unit_captured(_unit, previous_player, new_player):
	if new_player == _player:
		_play(STRUCTURE_CAPTURED_SOUND, -4.0, SOUND_STRUCTURE_CAPTURED)
	elif previous_player == _player:
		_play(STRUCTURE_LOST_SOUND, -3.0, SOUND_STRUCTURE_LOST)


func _on_unit_promoted(unit, rank):
	if rank > 0 and _unit_owned_by_player(unit):
		_play(UNIT_PROMOTED_SOUND, -4.0, SOUND_UNIT_PROMOTED)


func _on_supply_crate_collected(_crate, unit, _effect_type):
	if _unit_owned_by_player(unit):
		_play(SUPPLY_CRATE_SOUND, -5.0, SOUND_SUPPLY_CRATE)


func _refresh_power_state(emit_sound = true):
	if _player == null or not _player.has_method("is_low_power"):
		return
	var is_low_power = _player.is_low_power()
	if _was_low_power == null:
		_was_low_power = is_low_power
		return
	if emit_sound and is_low_power and not _was_low_power:
		_play(LOW_POWER_SOUND, -3.0, SOUND_LOW_POWER)
	_was_low_power = is_low_power


func _on_support_power_charging(power_id, player, _charge_seconds):
	if _player_is_enemy(player) and _is_superweapon(power_id):
		_play(SUPERWEAPON_WARNING_SOUND, -2.0, SOUND_ENEMY_SUPERWEAPON_CHARGING)


func _on_support_power_ready(power_id, player):
	if player == _player:
		_play(SUPPORT_POWER_READY_SOUND, -4.0, SOUND_SUPPORT_POWER_READY)
	elif _player_is_enemy(player) and _is_superweapon(power_id):
		_play(SUPERWEAPON_WARNING_SOUND, -2.0, SOUND_ENEMY_SUPERWEAPON_READY)


func _on_support_power_activated(power_id, player, _target_position):
	if player == _player:
		_play(SUPPORT_POWER_FIRE_SOUND, -3.0, SOUND_SUPPORT_POWER_FIRE)
	elif _player_is_enemy(player):
		if _is_superweapon(power_id):
			_play(SUPERWEAPON_WARNING_SOUND, -1.5, SOUND_ENEMY_SUPERWEAPON_LAUNCHED)
		else:
			_play(SUPPORT_POWER_FIRE_SOUND, -5.0, SOUND_ENEMY_SUPPORT_POWER)


func _player_is_enemy(player):
	return player != null and _player != null and _player.is_enemy_with(player)


func _is_superweapon(power_id):
	return (
		Constants.Match.SupportPowers.DEFINITIONS.has(power_id)
		and Constants.Match.SupportPowers.DEFINITIONS[power_id].get("superweapon", false)
	)
