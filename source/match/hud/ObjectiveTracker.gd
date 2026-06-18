extends PanelContainer

const Human = preload("res://source/match/players/human/Human.gd")
const Structure = preload("res://source/match/units/Structure.gd")
const Worker = preload("res://source/match/units/Worker.gd")

@onready var _title_label = find_child("TitleLabel")
@onready var _objective_label = find_child("ObjectiveLabel")
@onready var _mission_progress_bar = find_child("MissionProgressBar")
@onready var _progress_label = find_child("ProgressLabel")
@onready var _breakdown_label = find_child("BreakdownLabel")
@onready var _match = find_parent("Match")

var _refresh_pending = false
var _watched_unit_ids = {}
var _max_enemy_anchors_seen = 0


func _ready():
	visible = false
	_style_panel()
	_connect_match_signals()
	call_deferred("_refresh")


func _connect_match_signals():
	if not MatchSignals.match_started.is_connected(_on_match_started):
		MatchSignals.match_started.connect(_on_match_started)
	if not MatchSignals.visible_player_changed.is_connected(_on_visible_player_changed):
		MatchSignals.visible_player_changed.connect(_on_visible_player_changed)
	if not MatchSignals.unit_spawned.is_connected(_on_unit_spawned):
		MatchSignals.unit_spawned.connect(_on_unit_spawned)
	if not MatchSignals.unit_died.is_connected(_on_unit_changed):
		MatchSignals.unit_died.connect(_on_unit_changed)
	if not MatchSignals.unit_sold.is_connected(_on_unit_changed):
		MatchSignals.unit_sold.connect(_on_unit_changed)
	if not MatchSignals.unit_construction_finished.is_connected(_on_unit_changed):
		MatchSignals.unit_construction_finished.connect(_on_unit_changed)
	if not MatchSignals.unit_captured.is_connected(_on_unit_captured):
		MatchSignals.unit_captured.connect(_on_unit_captured)


func _on_match_started():
	_refresh_deferred()


func _on_visible_player_changed(_previous_player, _new_player):
	_refresh_deferred()


func _on_unit_spawned(unit):
	_watch_unit(unit)
	_refresh_deferred()


func _on_unit_changed(_unit):
	_refresh_deferred()


func _on_unit_captured(_unit, _previous_player, _new_player):
	_refresh_deferred()


func _watch_current_units():
	for unit in get_tree().get_nodes_in_group("units"):
		_watch_unit(unit)


func _watch_unit(unit):
	if unit == null or not is_instance_valid(unit):
		return
	var unit_id = unit.get_instance_id()
	if _watched_unit_ids.has(unit_id):
		return
	_watched_unit_ids[unit_id] = true
	if not unit.tree_exited.is_connected(_on_unit_tree_exited):
		unit.tree_exited.connect(_on_unit_tree_exited)


func _on_unit_tree_exited():
	_refresh_deferred()


func _refresh_deferred():
	if _refresh_pending or not is_inside_tree():
		return
	_refresh_pending = true
	call_deferred("_refresh")


func _refresh():
	_refresh_pending = false
	if _match == null:
		_match = find_parent("Match")
	var tracked_player = _get_tracked_player()
	if tracked_player == null:
		visible = false
		return
	_watch_current_units()
	var progress = _enemy_progress(tracked_player)
	_max_enemy_anchors_seen = maxi(_max_enemy_anchors_seen, progress["anchors"])
	var total_anchors = _max_enemy_anchors_seen
	visible = true
	_title_label.text = tr("OBJECTIVE_TRACKER_TITLE")
	_objective_label.text = tr("OBJECTIVE_TRACKER_ELIMINATION")
	if progress["enemy_teams"] <= 0:
		_update_progress_bar(0, total_anchors, true)
		_progress_label.text = tr("OBJECTIVE_PROGRESS_COMPLETE")
		_breakdown_label.text = ""
	else:
		_update_progress_bar(progress["anchors"], total_anchors, false)
		_progress_label.text = "{0}: {1}    {2}: {3}".format(
			[
				tr("OBJECTIVE_PROGRESS_ENEMY_TEAMS"),
				progress["enemy_teams"],
				tr("OBJECTIVE_PROGRESS_ANCHORS"),
				_anchor_ratio_text(progress["anchors"], total_anchors),
			]
		)
		_breakdown_label.text = "{0}: {1}    {2}: {3}".format(
			[
				tr("OBJECTIVE_PROGRESS_STRUCTURES"),
				progress["structures"],
				tr("OBJECTIVE_PROGRESS_WORKERS"),
				progress["workers"],
			]
		)


func _enemy_progress(tracked_player):
	var enemy_team_keys = {}
	var anchors = 0
	var structures = 0
	var workers = 0
	for unit in get_tree().get_nodes_in_group("units"):
		if not _is_elimination_anchor(unit):
			continue
		var unit_player = unit.player if "player" in unit else null
		if not _player_participates(unit_player) or not tracked_player.is_enemy_with(unit_player):
			continue
		anchors += 1
		if unit is Structure:
			structures += 1
		if unit is Worker:
			workers += 1
		enemy_team_keys[_team_key(unit_player)] = true
	return {
		"enemy_teams": enemy_team_keys.size(),
		"anchors": anchors,
		"structures": structures,
		"workers": workers,
	}


func _update_progress_bar(remaining_anchors, total_anchors, complete):
	if _mission_progress_bar == null:
		return
	_mission_progress_bar.max_value = 100.0
	_mission_progress_bar.value = _objective_completion_percent(
		remaining_anchors, total_anchors, complete
	)
	_mission_progress_bar.tooltip_text = "{0}: {1}".format(
		[
			tr("OBJECTIVE_PROGRESS_ANCHORS"),
			_anchor_ratio_text(remaining_anchors, total_anchors),
		]
	)


func _objective_completion_percent(remaining_anchors, total_anchors, complete):
	if complete:
		return 100.0
	if total_anchors <= 0:
		return 0.0
	var destroyed_anchors = max(0, total_anchors - remaining_anchors)
	return clampf((float(destroyed_anchors) / float(total_anchors)) * 100.0, 0.0, 100.0)


func _anchor_ratio_text(remaining_anchors, total_anchors):
	if total_anchors <= 0:
		return str(remaining_anchors)
	return "{0}/{1}".format([remaining_anchors, total_anchors])


func _is_elimination_anchor(unit):
	return (
		(unit is Structure or unit is Worker)
		and unit.is_inside_tree()
		and (not ("hp" in unit) or unit.hp == null or unit.hp > 0)
	)


func _get_tracked_player():
	var human_players = get_tree().get_nodes_in_group("players").filter(
		func(player): return player is Human
	)
	if not human_players.is_empty():
		return human_players[0]
	if _match != null and _match.visible_player != null:
		return _match.visible_player
	var participating_players = get_tree().get_nodes_in_group("players").filter(_player_participates)
	if not participating_players.is_empty():
		return participating_players[0]
	return null


func _team_key(player):
	if "team_id" in player and player.team_id >= 0:
		return "team:{0}".format([player.team_id])
	return "player:{0}".format([player.get_instance_id()])


func _player_participates(player):
	return player != null and (not ("participates_in_match" in player) or player.participates_in_match)


func _style_panel():
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color(0.025, 0.045, 0.052, 0.9)
	panel.border_color = Color(0.34, 0.68, 0.72, 1.0)
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.corner_radius_top_left = 3
	panel.corner_radius_top_right = 3
	panel.corner_radius_bottom_right = 3
	panel.corner_radius_bottom_left = 3
	add_theme_stylebox_override("panel", panel)
	_style_progress_bar()


func _style_progress_bar():
	if _mission_progress_bar == null:
		return
	var background = StyleBoxFlat.new()
	background.bg_color = Color(0.018, 0.030, 0.035, 0.96)
	background.border_color = Color(0.12, 0.24, 0.28, 1.0)
	background.border_width_left = 1
	background.border_width_top = 1
	background.border_width_right = 1
	background.border_width_bottom = 1
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.34, 0.88, 0.47, 1.0)
	fill.border_color = Color(0.54, 1.0, 0.58, 1.0)
	fill.border_width_left = 1
	fill.border_width_top = 1
	fill.border_width_right = 1
	fill.border_width_bottom = 1
	_mission_progress_bar.add_theme_stylebox_override("background", background)
	_mission_progress_bar.add_theme_stylebox_override("fill", fill)
