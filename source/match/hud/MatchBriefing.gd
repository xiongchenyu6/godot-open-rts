extends PanelContainer

@export var auto_hide_seconds = 14.0

var _auto_hide_token = 0

@onready var _title_label = find_child("TitleLabel")
@onready var _objective_label = find_child("ObjectiveLabel")
@onready var _details_label = find_child("DetailsLabel")
@onready var _opening_label = find_child("OpeningLabel")
@onready var _close_button = find_child("CloseButton")
@onready var _reopen_button = _find_reopen_button()
@onready var _match = find_parent("Match")


func _ready():
	visible = false
	_style_panel()
	if _close_button != null:
		_close_button.pressed.connect(dismiss)
	if _reopen_button != null:
		_reopen_button.pressed.connect(show_briefing)
		_reopen_button.text = tr("OBJECTIVES_BUTTON")
		_reopen_button.tooltip_text = tr("OBJECTIVES_BUTTON_TOOLTIP")
	_sync_reopen_button()
	MatchSignals.match_started.connect(show_briefing)


func show_briefing():
	if _match == null:
		return
	_refresh_text()
	visible = true
	modulate.a = 1.0
	_sync_reopen_button()
	_auto_hide_token += 1
	var token = _auto_hide_token
	if auto_hide_seconds > 0.0:
		await get_tree().create_timer(auto_hide_seconds).timeout
		if token == _auto_hide_token and visible:
			dismiss()


func dismiss():
	_auto_hide_token += 1
	hide()
	_sync_reopen_button()


func _refresh_text():
	_title_label.text = tr("BRIEFING_TITLE")
	_objective_label.text = tr("BRIEFING_OBJECTIVE_ELIMINATION")
	_details_label.text = _details_text()
	_opening_label.text = _opening_text()


func _details_text():
	var player_counts = _player_counts()
	return "{0}: {1}\n{2}: {3}\n{4}: {5} / {6}: {7}".format(
		[
			tr("BRIEFING_ENEMIES"),
			player_counts["enemies"],
			tr("BRIEFING_ALLIES"),
			player_counts["allies"],
			tr("RESOURCE_A"),
			_match.settings.starting_resource_a,
			tr("RESOURCE_B"),
			_match.settings.starting_resource_b
		]
	)


func _opening_text():
	var steps = [
		tr("BRIEFING_OPENING_ECONOMY"),
		tr("BRIEFING_OPENING_POWER"),
		tr("BRIEFING_OPENING_PRODUCTION"),
		tr("BRIEFING_OPENING_SCOUT"),
	]
	return "{0}\n- {1}".format([tr("BRIEFING_OPENING_TITLE"), "\n- ".join(steps)])


func _player_counts():
	var visible_player = _match.visible_player
	var players = get_tree().get_nodes_in_group("players").filter(
		func(player):
			return not ("participates_in_match" in player) or player.participates_in_match
	)
	var counts = {
		"allies": 0,
		"enemies": 0,
	}
	if visible_player == null:
		counts["enemies"] = players.size()
		return counts
	for player in players:
		if player == visible_player:
			continue
		if player.is_enemy_with(visible_player):
			counts["enemies"] += 1
		else:
			counts["allies"] += 1
	return counts


func _style_panel():
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color(0.035, 0.055, 0.065, 0.94)
	panel.border_color = Color(0.42, 0.78, 0.76, 1.0)
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.corner_radius_top_left = 3
	panel.corner_radius_top_right = 3
	panel.corner_radius_bottom_right = 3
	panel.corner_radius_bottom_left = 3
	add_theme_stylebox_override("panel", panel)


func _sync_reopen_button():
	if _reopen_button == null:
		return
	_reopen_button.visible = not visible


func _find_reopen_button():
	var hud = find_parent("HUD")
	if hud == null:
		return null
	return hud.find_child("ObjectivesButton", true, false)
