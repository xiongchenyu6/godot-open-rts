extends PanelContainer

const Human = preload("res://source/match/players/human/Human.gd")
const Structure = preload("res://source/match/units/Structure.gd")

const MAX_MESSAGES = 5
const DEFAULT_MESSAGE_LIFETIME_SECONDS = 5.0
const FADE_SECONDS = 0.75
const UNDER_ATTACK_NOTIFICATION_THRESHOLD_MS = 10 * 1000
const WEB_REFRESH_INTERVAL_SECONDS = 0.2

var message_lifetime_seconds = DEFAULT_MESSAGE_LIFETIME_SECONDS

var _messages = []
var _last_under_attack_notification_timestamp = -UNDER_ATTACK_NOTIFICATION_THRESHOLD_MS
var _was_low_power = null
var _web_refresh_elapsed = WEB_REFRESH_INTERVAL_SECONDS

@onready var _match = find_parent("Match")
@onready var _messages_box = find_child("Messages")


func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_connect_signals()
	_refresh_power_state(false)


func _process(delta):
	if OS.has_feature("web"):
		_web_refresh_elapsed += delta
		if _web_refresh_elapsed < WEB_REFRESH_INTERVAL_SECONDS:
			return
		_web_refresh_elapsed = 0.0
	_remove_expired_messages()
	_refresh_power_state()


func push_message(
	message_key,
	format_args = [],
	focus_position = null,
	battle_event_ping_type = Constants.Match.BattleEventPing.GENERIC
):
	if _messages_box == null:
		return
	var label = _create_message_label(_format_message(message_key, format_args), focus_position)
	_messages_box.add_child(label)
	_messages_box.move_child(label, 0)
	_messages.push_front(
		{
			"label": label,
			"expires_at": _now() + message_lifetime_seconds,
			"focus_position": focus_position,
		}
	)
	if _is_focus_position(focus_position):
		MatchSignals.battle_event_recorded.emit(focus_position)
		MatchSignals.battle_event_ping_requested.emit(focus_position, battle_event_ping_type)
	while _messages.size() > MAX_MESSAGES:
		_remove_message(_messages.size() - 1)
	_update_visibility()


func clear_messages():
	for index in range(_messages.size() - 1, -1, -1):
		_remove_message(index)
	_update_visibility()


func _connect_signals():
	MatchSignals.match_started.connect(
		func(): push_message("BATTLE_NOTIFICATION_BATTLE_STARTED")
	)
	MatchSignals.match_finished_with_victory.connect(
		func(): push_message("BATTLE_NOTIFICATION_VICTORY")
	)
	MatchSignals.match_finished_with_defeat.connect(
		func(): push_message("BATTLE_NOTIFICATION_DEFEAT")
	)
	MatchSignals.unit_damaged.connect(_on_unit_damaged)
	MatchSignals.unit_died.connect(_on_unit_died)
	MatchSignals.unit_sold.connect(_on_unit_sold)
	MatchSignals.unit_captured.connect(_on_unit_captured)
	MatchSignals.unit_promoted.connect(_on_unit_promoted)
	MatchSignals.supply_crate_collected.connect(_on_supply_crate_collected)
	MatchSignals.unit_production_blocked.connect(_on_unit_production_blocked)
	MatchSignals.unit_production_finished.connect(_on_unit_production_finished)
	MatchSignals.unit_construction_finished.connect(_on_unit_construction_finished)
	MatchSignals.support_power_activated.connect(_on_support_power_activated)
	MatchSignals.support_power_charging.connect(_on_support_power_charging)
	MatchSignals.support_power_ready.connect(_on_support_power_ready)
	MatchSignals.not_enough_resources_for_production.connect(_on_not_enough_resources)
	MatchSignals.not_enough_resources_for_construction.connect(_on_not_enough_resources)
	MatchSignals.unit_group_assigned.connect(_on_unit_group_assigned)
	MatchSignals.unit_group_cleared.connect(_on_unit_group_cleared)


func _on_unit_damaged(unit):
	if not _unit_belongs_to_human(unit):
		return
	var current_timestamp = Time.get_ticks_msec()
	if (
		current_timestamp - _last_under_attack_notification_timestamp
		< UNDER_ATTACK_NOTIFICATION_THRESHOLD_MS
	):
		return
	_last_under_attack_notification_timestamp = current_timestamp
	push_message(
		(
			"BATTLE_NOTIFICATION_BASE_UNDER_ATTACK"
			if unit is Structure
			else "BATTLE_NOTIFICATION_UNIT_UNDER_ATTACK"
		),
		[],
		_position_for_unit(unit)
	)


func _on_unit_died(unit):
	if _unit_belongs_to_human(unit):
		push_message("BATTLE_NOTIFICATION_UNIT_LOST", [], _position_for_unit(unit))
	_refresh_power_state()


func _on_unit_sold(_unit):
	_refresh_power_state()


func _on_unit_captured(unit, previous_player, new_player):
	var human_player = _get_human_player()
	if new_player == human_player:
		push_message("BATTLE_NOTIFICATION_STRUCTURE_CAPTURED", [], _position_for_unit(unit))
	elif previous_player == human_player:
		push_message("BATTLE_NOTIFICATION_STRUCTURE_LOST", [], _position_for_unit(unit))
	_refresh_power_state()


func _on_unit_promoted(unit, rank):
	if rank <= 0 or not _unit_belongs_to_human(unit):
		return
	push_message(
		"BATTLE_NOTIFICATION_UNIT_PROMOTED",
		[_rank_name(rank)],
		_position_for_unit(unit)
	)


func _on_supply_crate_collected(crate, unit, effect_type):
	if not _unit_belongs_to_human(unit):
		return
	push_message(_supply_crate_message_key(effect_type), [], _position_for_unit(crate))


func _on_unit_production_blocked(_unit_prototype, producer_unit):
	if _unit_belongs_to_human(producer_unit):
		push_message(
			"BATTLE_NOTIFICATION_PRODUCTION_BLOCKED",
			[],
			_position_for_unit(producer_unit)
		)


func _on_unit_production_finished(unit, producer_unit):
	if _unit_belongs_to_human(producer_unit):
		push_message("BATTLE_NOTIFICATION_UNIT_READY", [], _position_for_unit(unit))


func _on_unit_construction_finished(unit):
	if _unit_belongs_to_human(unit):
		push_message("BATTLE_NOTIFICATION_STRUCTURE_READY", [], _position_for_unit(unit))
	_refresh_power_state()


func _on_support_power_activated(power_id, player, target_position):
	var power_name = power_id
	if Constants.Match.SupportPowers.DEFINITIONS.has(power_id):
		power_name = tr(Constants.Match.SupportPowers.DEFINITIONS[power_id]["name_key"])
	if player == _get_human_player():
		push_message(
			"BATTLE_NOTIFICATION_SUPPORT_POWER_USED",
			[power_name],
			target_position,
			Constants.Match.BattleEventPing.SUPPORT_POWER
		)
	elif _player_is_enemy_of_human(player):
		push_message(
			_enemy_support_power_message_key(power_id),
			[power_name],
			target_position,
			(
				Constants.Match.BattleEventPing.ENEMY_SUPERWEAPON
				if _is_superweapon(power_id)
				else Constants.Match.BattleEventPing.ENEMY_SUPPORT_POWER
			)
		)


func _on_support_power_charging(power_id, player, charge_seconds):
	if not _is_superweapon(power_id):
		return
	var power_name = power_id
	if Constants.Match.SupportPowers.DEFINITIONS.has(power_id):
		power_name = tr(Constants.Match.SupportPowers.DEFINITIONS[power_id]["name_key"])
	if player == _get_human_player():
		push_message(
			"BATTLE_NOTIFICATION_SUPERWEAPON_CHARGING",
			[power_name, ceili(charge_seconds)]
		)
	elif _player_is_enemy_of_human(player):
		push_message(
			"BATTLE_NOTIFICATION_ENEMY_SUPERWEAPON_CHARGING",
			[power_name, ceili(charge_seconds)]
		)


func _on_support_power_ready(power_id, player):
	var power_name = power_id
	if Constants.Match.SupportPowers.DEFINITIONS.has(power_id):
		power_name = tr(Constants.Match.SupportPowers.DEFINITIONS[power_id]["name_key"])
	if player == _get_human_player():
		push_message("BATTLE_NOTIFICATION_SUPPORT_POWER_READY", [power_name])
	elif _player_is_enemy_of_human(player) and _is_superweapon(power_id):
		push_message("BATTLE_NOTIFICATION_ENEMY_SUPERWEAPON_READY", [power_name])


func _on_not_enough_resources(player):
	if player == _get_human_player():
		push_message("BATTLE_NOTIFICATION_INSUFFICIENT_FUNDS")


func _on_unit_group_assigned(group_id, units):
	if units.is_empty():
		return
	push_message(
		"BATTLE_NOTIFICATION_CONTROL_GROUP_ASSIGNED",
		[group_id, units.size()],
		_control_group_focus_position(units)
	)


func _on_unit_group_cleared(group_id):
	push_message("BATTLE_NOTIFICATION_CONTROL_GROUP_CLEARED", [group_id])


func _refresh_power_state(emit_notification = true):
	var player = _get_human_player()
	if player == null:
		return
	var is_low_power = player.is_low_power()
	if _was_low_power == null:
		_was_low_power = is_low_power
		return
	if emit_notification and is_low_power and not _was_low_power:
		push_message("BATTLE_NOTIFICATION_LOW_POWER")
	_was_low_power = is_low_power


func _unit_belongs_to_human(unit):
	if unit == null or not is_instance_valid(unit):
		return false
	var player = _get_human_player()
	if player == null:
		return false
	if "player" in unit and unit.player == player:
		return true
	return unit.is_in_group("controlled_units")


func _position_for_unit(unit):
	if unit == null or not is_instance_valid(unit):
		return null
	if not unit.is_inside_tree() and unit.has_meta("death_position"):
		return unit.get_meta("death_position")
	return unit.global_position


func _control_group_focus_position(units):
	var valid_units = units.filter(
		func(unit): return unit != null and is_instance_valid(unit) and unit.is_inside_tree()
	)
	if valid_units.is_empty():
		return null
	return Utils.Match.Unit.Movement.calculate_aabb_crowd_pivot_yless(valid_units)


func _is_focus_position(position):
	return position is Vector3


func _get_human_player():
	if _match != null and "visible_player" in _match and _match.visible_player is Human:
		return _match.visible_player
	for player in get_tree().get_nodes_in_group("players"):
		if player is Human:
			return player
	return null


func _player_is_enemy_of_human(player):
	var human_player = _get_human_player()
	return human_player != null and player != null and human_player.is_enemy_with(player)


func _enemy_support_power_message_key(power_id):
	return (
		"BATTLE_NOTIFICATION_ENEMY_SUPERWEAPON_USED"
		if _is_superweapon(power_id)
		else "BATTLE_NOTIFICATION_ENEMY_SUPPORT_POWER_USED"
	)


func _is_superweapon(power_id):
	return (
		Constants.Match.SupportPowers.DEFINITIONS.has(power_id)
		and Constants.Match.SupportPowers.DEFINITIONS[power_id].get("superweapon", false)
	)


func _format_message(message_key, format_args):
	var text = tr(message_key)
	if not format_args.is_empty():
		text = text.format(format_args)
	return text


func _rank_name(rank):
	match clampi(rank, 0, Constants.Match.Veterancy.MAX_RANK):
		1:
			return tr("SELECTION_VETERAN")
		2:
			return tr("SELECTION_ELITE")
		_:
			return tr("SELECTION_GREEN")


func _supply_crate_message_key(effect_type):
	match effect_type:
		"resources":
			return "BATTLE_NOTIFICATION_SUPPLY_CRATE_RESOURCES"
		"repair":
			return "BATTLE_NOTIFICATION_SUPPLY_CRATE_REPAIR"
		"veterancy":
			return "BATTLE_NOTIFICATION_SUPPLY_CRATE_VETERANCY"
		_:
			return "BATTLE_NOTIFICATION_SUPPLY_CRATE"


func _create_message_label(text, focus_position = null):
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_STOP if _is_focus_position(focus_position) else Control.MOUSE_FILTER_IGNORE
	if _is_focus_position(focus_position):
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		label.tooltip_text = tr("BATTLE_NOTIFICATION_FOCUS_TOOLTIP")
		label.gui_input.connect(func(event): _on_message_gui_input(event, focus_position))
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.78, 0.96, 0.90, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _on_message_gui_input(event, focus_position):
	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
		and _focus_battle_event(focus_position)
	):
		get_viewport().set_input_as_handled()


func _focus_battle_event(focus_position):
	if not _is_focus_position(focus_position):
		return false
	var camera = _battlefield_camera()
	if camera == null or not camera.has_method("set_position_safely"):
		return false
	camera.set_position_safely(focus_position)
	return true


func _battlefield_camera():
	if _match == null:
		_match = find_parent("Match")
	if _match == null:
		return null
	return _match.get_node_or_null("IsometricCamera3D")


func _remove_expired_messages():
	var now = _now()
	for index in range(_messages.size() - 1, -1, -1):
		var message = _messages[index]
		var remaining = message["expires_at"] - now
		if remaining <= 0.0:
			_remove_message(index)
			continue
		var label = message["label"]
		if is_instance_valid(label):
			label.modulate.a = clampf(remaining / FADE_SECONDS, 0.0, 1.0) if remaining < FADE_SECONDS else 1.0
	_update_visibility()


func _remove_message(index):
	var label = _messages[index]["label"]
	_messages.remove_at(index)
	if is_instance_valid(label):
		var parent = label.get_parent()
		if parent != null:
			parent.remove_child(label)
		label.queue_free()


func _update_visibility():
	visible = not _messages.is_empty()


func _now():
	return Time.get_ticks_msec() / 1000.0
