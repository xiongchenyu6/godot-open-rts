extends CanvasLayer

const MatchFlow = preload("res://source/match/MatchFlow.gd")
const Human = preload("res://source/match/players/human/Human.gd")
const Structure = preload("res://source/match/units/Structure.gd")
const Worker = preload("res://source/match/units/Worker.gd")

const SPEED_OPTIONS = [
	{"label_key": "MATCH_SPEED_SLOW", "scale": 0.75},
	{"label_key": "MATCH_SPEED_NORMAL", "scale": 1.0},
	{"label_key": "MATCH_SPEED_FAST", "scale": 1.25},
	{"label_key": "MATCH_SPEED_FASTER", "scale": 1.5},
	{"label_key": "MATCH_SPEED_MAX", "scale": 2.0},
]
const CONTROLS_HELP_ROWS = [
	{"title_key": "MATCH_CONTROLS_SELECTION", "body_key": "MATCH_CONTROLS_SELECTION_DESC"},
	{"title_key": "MATCH_CONTROLS_MOVEMENT", "body_key": "MATCH_CONTROLS_MOVEMENT_DESC"},
	{"title_key": "MATCH_CONTROLS_COMBAT", "body_key": "MATCH_CONTROLS_COMBAT_DESC"},
	{"title_key": "MATCH_CONTROLS_PRODUCTION", "body_key": "MATCH_CONTROLS_PRODUCTION_DESC"},
	{"title_key": "MATCH_CONTROLS_STRUCTURES", "body_key": "MATCH_CONTROLS_STRUCTURES_DESC"},
	{"title_key": "MATCH_CONTROLS_GROUPS", "body_key": "MATCH_CONTROLS_GROUPS_DESC"},
	{"title_key": "MATCH_CONTROLS_SUPPORT", "body_key": "MATCH_CONTROLS_SUPPORT_DESC"},
	{"title_key": "MATCH_CONTROLS_EVENTS", "body_key": "MATCH_CONTROLS_EVENTS_DESC"},
]

var _speed_option_button = null
var _perspective_row = null
var _perspective_option_button = null
var _controls_button = null
var _controls_panel = null
var _controls_label = null
var _started_at_msec = 0

@onready var _status_label = find_child("StatusLabel", true, false)


func _ready():
	_started_at_msec = Time.get_ticks_msec()
	find_child("ResumeButton").text = tr("RESUME_MATCH")
	find_child("RestartButton").text = tr("RESTART_MATCH")
	find_child("SetupButton").text = tr("RETURN_TO_SETUP")
	find_child("ExitButton").text = tr("EXIT_TO_MENU")
	_refresh_status_summary()
	_setup_speed_selector()
	_setup_perspective_selector()
	_setup_controls_help()
	hide()


func _unhandled_input(event):
	if (
		event.is_action_pressed("toggle_match_menu")
		and ((not visible and not get_tree().paused) or (visible and get_tree().paused))
	):
		_toggle()


func _toggle():
	visible = not visible
	if visible:
		_refresh_perspective_selector()
		_refresh_status_summary()
	get_tree().paused = visible


func _on_resume_button_pressed():
	_toggle()


func _on_restart_button_pressed():
	MatchFlow.restart_match_from(self)


func _on_setup_button_pressed():
	MatchSignals.match_aborted.emit()
	await get_tree().create_timer(1.74).timeout  # Give voice narrator some time to finish.
	MatchFlow.exit_to_setup_menu_from(self)


func _on_exit_button_pressed():
	MatchSignals.match_aborted.emit()
	await get_tree().create_timer(1.74).timeout  # Give voice narrator some time to finish.
	MatchFlow.exit_to_main_menu(get_tree())


func _setup_speed_selector():
	var container = find_child("VBoxContainer")
	if container == null:
		return
	var row = container.find_child("SpeedRow", false, false)
	if row == null:
		row = HBoxContainer.new()
		row.name = "SpeedRow"
		row.add_theme_constant_override("separation", 10)
		container.add_child(row)
	var status_panel = container.find_child("StatusPanel", false, false)
	if status_panel == null:
		container.move_child(row, 0)
	else:
		container.move_child(row, status_panel.get_index() + 1)
	var label = row.find_child("SpeedLabel", false, false)
	if label == null:
		label = Label.new()
		label.name = "SpeedLabel"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)
	label.text = tr("MATCH_SPEED")
	_speed_option_button = row.find_child("SpeedOptionButton", false, false)
	if _speed_option_button == null:
		_speed_option_button = OptionButton.new()
		_speed_option_button.name = "SpeedOptionButton"
		_speed_option_button.focus_mode = Control.FOCUS_NONE
		_speed_option_button.custom_minimum_size = Vector2(132, 0)
		row.add_child(_speed_option_button)
	_speed_option_button.tooltip_text = tr("MATCH_SPEED_TOOLTIP")
	_speed_option_button.clear()
	for option_index in range(SPEED_OPTIONS.size()):
		_speed_option_button.add_item(tr(SPEED_OPTIONS[option_index]["label_key"]), option_index)
	if not _speed_option_button.item_selected.is_connected(_on_speed_option_selected):
		_speed_option_button.item_selected.connect(_on_speed_option_selected)
	_sync_speed_selector_to_engine()


func _setup_perspective_selector():
	var container = find_child("VBoxContainer")
	if container == null:
		return
	_perspective_row = container.find_child("PerspectiveRow", false, false)
	if _perspective_row == null:
		_perspective_row = HBoxContainer.new()
		_perspective_row.name = "PerspectiveRow"
		_perspective_row.add_theme_constant_override("separation", 10)
		container.add_child(_perspective_row)
	var speed_row = container.find_child("SpeedRow", false, false)
	var status_panel = container.find_child("StatusPanel", false, false)
	if speed_row != null:
		container.move_child(_perspective_row, speed_row.get_index() + 1)
	elif status_panel != null:
		container.move_child(_perspective_row, status_panel.get_index() + 1)
	var label = _perspective_row.find_child("PerspectiveLabel", false, false)
	if label == null:
		label = Label.new()
		label.name = "PerspectiveLabel"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_perspective_row.add_child(label)
	label.text = tr("MATCH_PERSPECTIVE")
	_perspective_option_button = _perspective_row.find_child(
		"PerspectiveOptionButton", false, false
	)
	if _perspective_option_button == null:
		_perspective_option_button = OptionButton.new()
		_perspective_option_button.name = "PerspectiveOptionButton"
		_perspective_option_button.focus_mode = Control.FOCUS_NONE
		_perspective_option_button.custom_minimum_size = Vector2(156, 0)
		_perspective_row.add_child(_perspective_option_button)
	_perspective_option_button.tooltip_text = tr("MATCH_PERSPECTIVE_TOOLTIP")
	if not _perspective_option_button.item_selected.is_connected(_on_perspective_option_selected):
		_perspective_option_button.item_selected.connect(_on_perspective_option_selected)
	_refresh_perspective_selector()


func _setup_controls_help():
	var container = find_child("VBoxContainer")
	if container == null:
		return
	_controls_button = container.find_child("ControlsButton", false, false)
	if _controls_button == null:
		_controls_button = Button.new()
		_controls_button.name = "ControlsButton"
		_controls_button.focus_mode = Control.FOCUS_NONE
		_controls_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(_controls_button)
	if not _controls_button.pressed.is_connected(_on_controls_button_pressed):
		_controls_button.pressed.connect(_on_controls_button_pressed)
	_controls_panel = container.find_child("ControlsPanel", false, false)
	if _controls_panel == null:
		_controls_panel = _create_controls_panel()
		container.add_child(_controls_panel)
	_order_controls_help(container)
	_refresh_controls_button()
	_refresh_controls_help()


func _create_controls_panel():
	var panel = PanelContainer.new()
	panel.name = "ControlsPanel"
	panel.visible = false
	var margin = MarginContainer.new()
	margin.name = "ControlsMargin"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	var scroll = ScrollContainer.new()
	scroll.name = "ControlsScroll"
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_controls_label = RichTextLabel.new()
	_controls_label.name = "ControlsHelpLabel"
	_controls_label.bbcode_enabled = true
	_controls_label.fit_content = true
	_controls_label.scroll_active = false
	_controls_label.selection_enabled = false
	_controls_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_controls_label)
	margin.add_child(scroll)
	panel.add_child(margin)
	return panel


func _order_controls_help(container):
	var perspective_row = container.find_child("PerspectiveRow", false, false)
	var speed_row = container.find_child("SpeedRow", false, false)
	var insert_after_index = 0
	if perspective_row != null:
		insert_after_index = perspective_row.get_index()
	elif speed_row != null:
		insert_after_index = speed_row.get_index()
	else:
		var status_panel = container.find_child("StatusPanel", false, false)
		if status_panel != null:
			insert_after_index = status_panel.get_index()
	container.move_child(_controls_button, insert_after_index + 1)
	container.move_child(_controls_panel, insert_after_index + 2)


func _refresh_controls_help():
	if _controls_label == null:
		_controls_label = find_child("ControlsHelpLabel", true, false)
	if _controls_label == null:
		return
	var lines = [
		"[b]{0}[/b]".format([tr("MATCH_CONTROLS_TITLE")]),
		tr("MATCH_CONTROLS_INTRO"),
	]
	for row in CONTROLS_HELP_ROWS:
		lines.append("")
		lines.append("[b]{0}[/b]".format([tr(row["title_key"])]))
		lines.append(tr(row["body_key"]))
	_controls_label.text = "\n".join(lines)


func _on_controls_button_pressed():
	if _controls_panel == null:
		return
	_controls_panel.visible = not _controls_panel.visible
	_refresh_controls_button()


func _refresh_controls_button():
	if _controls_button == null:
		return
	var controls_visible = _controls_panel != null and _controls_panel.visible
	_controls_button.text = tr(
		"MATCH_CONTROLS_HIDE_BUTTON" if controls_visible else "MATCH_CONTROLS_BUTTON"
	)
	_controls_button.tooltip_text = tr("MATCH_CONTROLS_TOOLTIP")


func _sync_speed_selector_to_engine():
	if _speed_option_button == null:
		return
	_speed_option_button.select(_speed_option_index_for_scale(Engine.time_scale))


func _speed_option_index_for_scale(scale):
	var closest_index = 0
	var closest_distance = INF
	for option_index in range(SPEED_OPTIONS.size()):
		var distance = absf(float(SPEED_OPTIONS[option_index]["scale"]) - scale)
		if distance < closest_distance:
			closest_distance = distance
			closest_index = option_index
	return closest_index


func _on_speed_option_selected(option_index):
	if option_index < 0 or option_index >= SPEED_OPTIONS.size():
		return
	Engine.time_scale = SPEED_OPTIONS[option_index]["scale"]
	_refresh_status_summary()


func _refresh_perspective_selector():
	if _perspective_row == null or _perspective_option_button == null:
		return
	var match_node = find_parent("Match")
	if match_node == null:
		_perspective_row.visible = false
		return
	var players = _participant_players()
	var can_switch = players.size() > 1 and not _has_human_player()
	_perspective_row.visible = can_switch
	_perspective_option_button.clear()
	if not can_switch:
		return
	for player_index in range(players.size()):
		_perspective_option_button.add_item(
			_player_perspective_label(players[player_index], player_index),
			player_index
		)
	var selected_index = players.find(match_node.visible_player)
	_perspective_option_button.select(maxi(0, selected_index))


func _on_perspective_option_selected(option_index):
	var match_node = find_parent("Match")
	if match_node == null:
		return
	var players = _participant_players()
	if option_index < 0 or option_index >= players.size():
		return
	match_node.visible_player = players[option_index]
	if match_node.has_method("focus_camera_on_player"):
		match_node.focus_camera_on_player(players[option_index])
	_refresh_status_summary()


func _player_perspective_label(player, player_index):
	var team_id = player.team_id if "team_id" in player else -1
	var team_text = (
		tr("MATCH_PERSPECTIVE_NO_TEAM")
		if team_id < 0
		else tr("MATCH_PERSPECTIVE_TEAM").format([team_id + 1])
	)
	return tr("MATCH_PERSPECTIVE_PLAYER").format([player_index + 1, team_text])


func _participant_players():
	return get_tree().get_nodes_in_group("players").filter(_player_participates)


func _has_human_player():
	return not get_tree().get_nodes_in_group("players").filter(
		func(player): return player is Human
	).is_empty()


func _refresh_status_summary():
	if _status_label == null:
		return
	var match_node = find_parent("Match")
	if match_node == null:
		_status_label.text = "\n".join(
			[
				"[b]{0}[/b]".format([tr("MATCH_STATUS_TITLE")]),
				tr("MATCH_STATUS_NO_MATCH"),
				"[u]{0}:[/u] {1}".format([tr("MATCH_STATUS_SPEED"), _speed_label_for_engine()]),
			]
		)
		return
	var tracked_player = _get_tracked_player(match_node)
	var progress = _enemy_progress(tracked_player)
	_status_label.text = "\n".join(
		[
			"[b]{0}[/b]".format([tr("MATCH_STATUS_TITLE")]),
			"[u]{0}:[/u] {1}".format(
				[tr("MATCH_STATUS_OBJECTIVE"), tr("OBJECTIVE_TRACKER_ELIMINATION")]
			),
			"[u]{0}:[/u] {1}    [u]{2}:[/u] {3}".format(
				[
					tr("MATCH_STATUS_MAP"),
					_match_map_name(match_node),
					tr("MATCH_STATUS_DURATION"),
					_format_duration((Time.get_ticks_msec() - _started_at_msec) / 1000.0),
				]
			),
			"[u]{0}:[/u] {1}    [u]{2}:[/u] {3}".format(
				[
					tr("OBJECTIVE_PROGRESS_ENEMY_TEAMS"),
					progress["enemy_teams"],
					tr("OBJECTIVE_PROGRESS_ANCHORS"),
					progress["anchors"],
				]
			),
			"[u]{0}:[/u] {1}".format([tr("MATCH_STATUS_SPEED"), _speed_label_for_engine()]),
		]
	)


func _match_map_name(match_node):
	if "map_path" in match_node and Constants.Match.MAPS.has(match_node.map_path):
		var map_definition = Constants.Match.MAPS[match_node.map_path]
		var name_key = str(map_definition.get("name_key", ""))
		if name_key != "":
			return tr(name_key)
		return str(map_definition.get("name", match_node.map_path))
	var map = match_node.get_node_or_null("Map")
	if map != null:
		return map.name
	return tr("MATCH_STATUS_UNKNOWN")


func _enemy_progress(tracked_player):
	var enemy_team_keys = {}
	var anchors = 0
	if tracked_player == null:
		return {
			"enemy_teams": 0,
			"anchors": 0,
		}
	for unit in get_tree().get_nodes_in_group("units"):
		if not _is_elimination_anchor(unit):
			continue
		var unit_player = unit.player if "player" in unit else null
		if not _player_participates(unit_player) or not tracked_player.is_enemy_with(unit_player):
			continue
		anchors += 1
		enemy_team_keys[_team_key(unit_player)] = true
	return {
		"enemy_teams": enemy_team_keys.size(),
		"anchors": anchors,
	}


func _is_elimination_anchor(unit):
	return (
		(unit is Structure or unit is Worker)
		and unit.is_inside_tree()
		and (not ("hp" in unit) or unit.hp == null or unit.hp > 0)
	)


func _get_tracked_player(match_node):
	var human_players = get_tree().get_nodes_in_group("players").filter(
		func(player): return player is Human
	)
	if not human_players.is_empty():
		return human_players[0]
	if "visible_player" in match_node and match_node.visible_player != null:
		return match_node.visible_player
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


func _speed_label_for_engine():
	return tr(SPEED_OPTIONS[_speed_option_index_for_scale(Engine.time_scale)]["label_key"])


func _format_duration(seconds):
	var total_seconds = max(0, int(floor(seconds)))
	var minutes = total_seconds / 60
	var remaining_seconds = total_seconds % 60
	return "%d:%02d" % [minutes, remaining_seconds]
