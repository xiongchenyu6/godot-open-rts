extends Node

const MenuScene = preload("res://source/match/Menu.tscn")
const TECH_DIVIDE_MAP_PATH = "res://source/match/maps/TechDivide.tscn"


class FakeMatch:
	extends Node

	var map_path = "res://source/match/maps/TechDivide.tscn"
	var visible_player = null

	func _init():
		name = "Match"


class FakePlayer:
	extends Node

	var team_id = -1
	var participates_in_match = true

	func _init(a_team_id):
		team_id = a_team_id


func _ready():
	Engine.time_scale = 1.0
	get_tree().paused = false

	var menu = MenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var speed_label = menu.find_child("SpeedLabel", true, false)
	var speed_option = menu.find_child("SpeedOptionButton", true, false)
	var controls_button = menu.find_child("ControlsButton", true, false)
	var controls_panel = menu.find_child("ControlsPanel", true, false)
	var controls_label = menu.find_child("ControlsHelpLabel", true, false)
	var perspective_row = menu.find_child("PerspectiveRow", true, false)
	var perspective_option = menu.find_child("PerspectiveOptionButton", true, false)
	var status_label = menu.find_child("StatusLabel", true, false)
	var setup_button = menu.find_child("SetupButton", true, false)
	assert(status_label != null, "match menu should expose a battle status summary")
	assert(setup_button != null, "match menu should expose a return-to-setup button")
	assert(setup_button.text == tr("RETURN_TO_SETUP"), "setup button should use translated text")
	assert(
		status_label.text.contains(tr("MATCH_STATUS_TITLE")),
		"battle status should show a translated title"
	)
	assert(
		status_label.text.contains(tr("MATCH_STATUS_NO_MATCH")),
		"standalone match menu should handle missing match context"
	)
	assert(speed_label != null, "match menu should expose a game speed label")
	assert(speed_option != null, "match menu should expose a game speed selector")
	assert(perspective_row != null, "match menu should create a spectator perspective row")
	assert(perspective_option != null, "match menu should create a spectator perspective selector")
	assert(
		not perspective_row.visible,
		"standalone match menu should hide the spectator perspective selector"
	)
	assert(speed_label.text == tr("MATCH_SPEED"), "speed selector should use translated label")
	assert(
		speed_option.tooltip_text == tr("MATCH_SPEED_TOOLTIP"),
		"speed selector should explain its purpose"
	)
	assert(speed_option.get_item_count() == menu.SPEED_OPTIONS.size(), "speed selector should expose all speeds")
	assert(speed_option.selected == 1, "normal speed should be selected by default")
	assert(controls_button != null, "match menu should expose a controls help button")
	assert(controls_panel != null, "match menu should expose a controls help panel")
	assert(controls_label != null, "match menu should expose controls help copy")
	assert(controls_button.text == tr("MATCH_CONTROLS_BUTTON"), "controls button should use translated text")
	assert(
		controls_button.tooltip_text == tr("MATCH_CONTROLS_TOOLTIP"),
		"controls button should explain its purpose"
	)
	assert(not controls_panel.visible, "controls help should stay collapsed until requested")
	assert(
		controls_label.text.contains(tr("MATCH_CONTROLS_TITLE")),
		"controls help should show a translated title"
	)
	assert(
		controls_label.text.contains(tr("MATCH_CONTROLS_SELECTION")),
		"controls help should document selection shortcuts"
	)
	assert(
		controls_label.text.contains(tr("MATCH_CONTROLS_SUPPORT")),
		"controls help should document support power shortcuts"
	)
	controls_button.pressed.emit()
	assert(controls_panel.visible, "controls button should expand the controls help panel")
	assert(
		controls_button.text == tr("MATCH_CONTROLS_HIDE_BUTTON"),
		"expanded controls button should offer to hide the panel"
	)
	controls_button.pressed.emit()
	assert(not controls_panel.visible, "controls button should collapse the controls help panel")

	speed_option.item_selected.emit(3)
	assert(is_equal_approx(Engine.time_scale, 1.5), "selecting a speed should update Engine.time_scale")
	assert(
		status_label.text.contains(tr("MATCH_SPEED_FASTER")),
		"battle status should refresh when speed changes"
	)

	menu._toggle()
	assert(menu.visible, "Escape menu toggle should show the menu")
	assert(get_tree().paused, "Escape menu toggle should pause the match")
	menu._on_resume_button_pressed()
	assert(not menu.visible, "resume should hide the menu")
	assert(not get_tree().paused, "resume should unpause the match")

	Engine.time_scale = 1.0
	menu.queue_free()

	await _assert_match_status_map_name_is_localized()
	await _assert_ai_spectator_perspective_switches_runtime_visible_player()
	get_tree().quit()


func _assert_match_status_map_name_is_localized():
	var original_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("zh_CN")

	var fake_match = FakeMatch.new()
	add_child(fake_match)
	var menu = MenuScene.instantiate()
	fake_match.add_child(menu)
	await get_tree().process_frame

	var status_label = menu.find_child("StatusLabel", true, false)
	assert(
		status_label.text.contains(tr("MAP_NAME_TECH_DIVIDE")),
		"Chinese battle status should translate the active map name"
	)
	assert(
		not status_label.text.contains(Constants.Match.MAPS[TECH_DIVIDE_MAP_PATH]["name"]),
		"Chinese battle status should not fall back to the English map name"
	)

	fake_match.remove_child(menu)
	menu.queue_free()
	remove_child(fake_match)
	fake_match.queue_free()
	TranslationServer.set_locale(original_locale)


func _assert_ai_spectator_perspective_switches_runtime_visible_player():
	var fake_match = FakeMatch.new()
	add_child(fake_match)
	var players = []
	for player_index in range(3):
		var player = FakePlayer.new(player_index)
		player.name = "FakePlayer{0}".format([player_index + 1])
		player.add_to_group("players")
		fake_match.add_child(player)
		players.append(player)
	fake_match.visible_player = players[0]

	var menu = MenuScene.instantiate()
	fake_match.add_child(menu)
	await get_tree().process_frame

	var perspective_row = menu.find_child("PerspectiveRow", true, false)
	var perspective_label = menu.find_child("PerspectiveLabel", true, false)
	var perspective_option = menu.find_child("PerspectiveOptionButton", true, false)
	assert(perspective_row.visible, "AI spectator matches should expose perspective switching")
	assert(
		perspective_label.text == tr("MATCH_PERSPECTIVE"),
		"perspective selector should use translated label text"
	)
	assert(
		perspective_option.tooltip_text == tr("MATCH_PERSPECTIVE_TOOLTIP"),
		"perspective selector should use translated tooltip text"
	)
	assert(
		perspective_option.get_item_count() == players.size(),
		"perspective selector should list every participating AI player"
	)
	assert(perspective_option.selected == 0, "initial visible player should be selected")
	assert(
		perspective_option.get_item_text(1)
		== tr("MATCH_PERSPECTIVE_PLAYER").format(
			[2, tr("MATCH_PERSPECTIVE_TEAM").format([2])]
		),
		"perspective item labels should include localized player and team text"
	)

	perspective_option.item_selected.emit(1)
	assert(
		fake_match.visible_player == players[1],
		"selecting a spectator perspective should change the runtime visible player"
	)

	fake_match.remove_child(menu)
	menu.queue_free()
	for player in players:
		fake_match.remove_child(player)
		player.queue_free()
	remove_child(fake_match)
	fake_match.queue_free()
	await get_tree().process_frame
