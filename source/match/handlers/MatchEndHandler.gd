extends CanvasLayer

const Human = preload("res://source/match/players/human/Human.gd")
const Structure = preload("res://source/match/units/Structure.gd")
const Worker = preload("res://source/match/units/Worker.gd")
const MatchFlow = preload("res://source/match/MatchFlow.gd")

@onready var _victory_tile = find_child("Victory")
@onready var _defeat_tile = find_child("Defeat")
@onready var _finish_tile = find_child("Finish")
@onready var _result_reason_value = find_child("ResultReasonValue")
@onready var _remaining_teams_value = find_child("RemainingTeamsValue")
@onready var _remaining_anchors_value = find_child("RemainingAnchorsValue")
@onready var _duration_value = find_child("DurationValue")
@onready var _enemy_units_value = find_child("EnemyUnitsValue")
@onready var _enemy_structures_value = find_child("EnemyStructuresValue")
@onready var _units_lost_value = find_child("UnitsLostValue")
@onready var _structures_lost_value = find_child("StructuresLostValue")
@onready var _resources_value = find_child("ResourcesValue")

var _started_at_msec = 0
var _enemy_units_destroyed = 0
var _enemy_structures_destroyed = 0
var _units_lost = 0
var _structures_lost = 0
var _counted_death_instance_ids = {}
var _result_reason_key = "MATCH_RESULT_FINISH_REASON"


func _ready():
	_started_at_msec = Time.get_ticks_msec()
	if not FeatureFlags.handle_match_end:
		queue_free()
		return
	hide()
	_setup_labels()
	_victory_tile.hide()
	_defeat_tile.hide()
	_finish_tile.hide()
	if not MatchSignals.unit_died.is_connected(_on_unit_died):
		MatchSignals.unit_died.connect(_on_unit_died)
	if not MatchSignals.unit_spawned.is_connected(_on_unit_spawned):
		MatchSignals.unit_spawned.connect(_on_unit_spawned)
	if not MatchSignals.unit_captured.is_connected(_on_unit_captured):
		MatchSignals.unit_captured.connect(_on_unit_captured)
	await find_parent("Match").ready
	for unit in get_tree().get_nodes_in_group("units"):
		_watch_unit(unit)


func _handle_defeat():
	_result_reason_key = "MATCH_RESULT_DEFEAT_REASON"
	_defeat_tile.show()
	_show()
	MatchSignals.match_finished_with_defeat.emit()


func _handle_victory():
	_result_reason_key = "MATCH_RESULT_VICTORY_REASON"
	_victory_tile.show()
	_show()
	MatchSignals.match_finished_with_victory.emit()


func _handle_finish():
	_result_reason_key = "MATCH_RESULT_FINISH_REASON"
	_finish_tile.show()
	_show()


func _show():
	_update_result_labels()
	_update_stats_labels()
	show()
	get_tree().paused = true


func _setup_labels():
	_victory_tile.find_child("Label").text = tr("MATCH_VICTORY_TITLE")
	_defeat_tile.find_child("Label").text = tr("MATCH_DEFEAT_TITLE")
	_finish_tile.find_child("Label").text = tr("MATCH_FINISH_TITLE")
	find_child("ResultTitleLabel").text = tr("MATCH_RESULT_TITLE")
	find_child("ResultReasonLabel").text = tr("MATCH_RESULT_REASON")
	find_child("RemainingTeamsLabel").text = tr("MATCH_RESULT_REMAINING_TEAMS")
	find_child("RemainingAnchorsLabel").text = tr("MATCH_RESULT_REMAINING_ANCHORS")
	find_child("StatsTitleLabel").text = tr("MATCH_STATS_TITLE")
	find_child("DurationLabel").text = tr("MATCH_STATS_DURATION")
	find_child("EnemyUnitsLabel").text = tr("MATCH_STATS_ENEMY_UNITS")
	find_child("EnemyStructuresLabel").text = tr("MATCH_STATS_ENEMY_STRUCTURES")
	find_child("UnitsLostLabel").text = tr("MATCH_STATS_UNITS_LOST")
	find_child("StructuresLostLabel").text = tr("MATCH_STATS_STRUCTURES_LOST")
	find_child("ResourcesLabel").text = tr("MATCH_STATS_RESOURCES")
	find_child("RestartButton").text = tr("RESTART_MATCH")
	find_child("SetupButton").text = tr("RETURN_TO_SETUP")
	find_child("ExitButton").text = tr("EXIT_TO_MENU")


func _on_unit_spawned(unit):
	_watch_unit(unit)


func _on_unit_captured(_unit, _previous_player, _new_player):
	_evaluate_match_end()


func _watch_unit(unit):
	if unit == null or not is_instance_valid(unit):
		return
	if not unit.tree_exited.is_connected(_on_unit_tree_exited):
		unit.tree_exited.connect(_on_unit_tree_exited)


func _on_unit_tree_exited():
	_evaluate_match_end()


func _on_unit_died(unit):
	if unit == null or not is_instance_valid(unit):
		return
	var death_instance_id = unit.get_instance_id()
	if _counted_death_instance_ids.has(death_instance_id):
		return
	_counted_death_instance_ids[death_instance_id] = true
	var tracked_player = _get_tracked_player()
	if tracked_player == null:
		return
	var death_player = unit.get_meta("death_player", null)
	if death_player == null and "player" in unit:
		death_player = unit.player
	if death_player == null:
		return
	if not _player_participates(death_player):
		return
	var is_structure = unit is Structure
	if tracked_player.is_allied_with(death_player):
		if is_structure:
			_structures_lost += 1
		else:
			_units_lost += 1
	else:
		if is_structure:
			_enemy_structures_destroyed += 1
		else:
			_enemy_units_destroyed += 1


func _evaluate_match_end():
	if visible or not is_inside_tree():
		return
	var active_players = _active_anchor_players()
	var human_players = get_tree().get_nodes_in_group("players").filter(
		func(player): return player is Human
	)
	if not human_players.is_empty() and not _has_active_ally(active_players, human_players[0]):
		_handle_defeat()
	elif (
		not human_players.is_empty()
		and _has_active_ally(active_players, human_players[0])
		and not _has_active_enemy(active_players, human_players[0])
	):
		_handle_victory()
	elif _active_team_count(active_players) == 1:
		_handle_finish()


func _update_result_labels():
	var active_players = _active_anchor_players()
	_result_reason_value.text = tr(_result_reason_key)
	_remaining_teams_value.text = str(_active_team_count(active_players))
	_remaining_anchors_value.text = str(_active_anchor_count())


func _active_anchor_players():
	var active_players = []
	for unit in get_tree().get_nodes_in_group("units"):
		if (
			_is_elimination_anchor(unit)
			and _player_participates(unit.player)
			and not unit.player in active_players
		):
			active_players.append(unit.player)
	return active_players


func _active_anchor_count():
	var count = 0
	for unit in get_tree().get_nodes_in_group("units"):
		if _is_elimination_anchor(unit) and _player_participates(unit.player):
			count += 1
	return count


func _is_elimination_anchor(unit):
	return (
		(unit is Structure or unit is Worker)
		and unit.is_inside_tree()
		and (not ("hp" in unit) or unit.hp == null or unit.hp > 0)
	)


func _has_active_ally(active_players, player):
	return active_players.any(func(active_player): return player.is_allied_with(active_player))


func _has_active_enemy(active_players, player):
	return active_players.any(func(active_player): return player.is_enemy_with(active_player))


func _active_team_count(active_players):
	var active_team_keys = Utils.Set.new()
	for player in active_players:
		active_team_keys.add(_team_key(player))
	return active_team_keys.size()


func _team_key(player):
	if "team_id" in player and player.team_id >= 0:
		return "team:{0}".format([player.team_id])
	return "player:{0}".format([player.get_instance_id()])


func _player_participates(player):
	return player != null and (not ("participates_in_match" in player) or player.participates_in_match)


func _update_stats_labels():
	_duration_value.text = _format_duration((Time.get_ticks_msec() - _started_at_msec) / 1000.0)
	_enemy_units_value.text = str(_enemy_units_destroyed)
	_enemy_structures_value.text = str(_enemy_structures_destroyed)
	_units_lost_value.text = str(_units_lost)
	_structures_lost_value.text = str(_structures_lost)
	_resources_value.text = _format_resources(_get_tracked_player())


func _format_duration(seconds):
	var total_seconds = max(0, int(floor(seconds)))
	var minutes = total_seconds / 60
	var remaining_seconds = total_seconds % 60
	return "%d:%02d" % [minutes, remaining_seconds]


func _format_resources(player):
	if player == null:
		return "A 0 / B 0"
	return "A {0} / B {1}".format([player.resource_a, player.resource_b])


func _get_tracked_player():
	var human_players = get_tree().get_nodes_in_group("players").filter(
		func(player): return player is Human
	)
	if not human_players.is_empty():
		return human_players[0]
	var match_node = find_parent("Match")
	if match_node != null and match_node.visible_player != null:
		return match_node.visible_player
	var players = get_tree().get_nodes_in_group("players").filter(_player_participates)
	return players[0] if not players.is_empty() else null


func _on_exit_button_pressed():
	MatchFlow.exit_to_main_menu(get_tree())


func _on_setup_button_pressed():
	MatchFlow.exit_to_setup_menu_from(self)


func _on_restart_button_pressed():
	MatchFlow.restart_match_from(self)
