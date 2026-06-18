extends Node

const MatchSettings = preload("res://source/data-model/MatchSettings.gd")
const MatchScene = preload("res://source/match/Match.tscn")
const PlayerScene = preload("res://source/match/players/Player.tscn")
const PlainAndSimpleMap = preload("res://source/match/maps/PlainAndSimple.tscn")


func _ready():
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var match_node = MatchScene.instantiate()
	match_node.settings = _create_match_settings()
	match_node.map = PlainAndSimpleMap.instantiate()
	_add_test_players(match_node)
	add_child(match_node)
	for frame in range(8):
		await get_tree().process_frame

	var players = _participant_players()
	assert(players.size() == 2, "runtime player switch test should start two players")
	assert(
		match_node.visible_player == players[0],
		"match should start from the configured visible player"
	)
	_assert_player_visibility_groups(players[0], players[1])
	_assert_single_visible_resource_bar(match_node, players[0])

	var visible_player_changed = []
	var changed_callback = func(previous_player, new_player):
		visible_player_changed.append([previous_player, new_player])
	MatchSignals.visible_player_changed.connect(changed_callback)

	var menu = match_node.find_child("Menu", true, false)
	menu._refresh_perspective_selector()
	await get_tree().process_frame
	var perspective_row = menu.find_child("PerspectiveRow", true, false)
	var perspective_option = menu.find_child("PerspectiveOptionButton", true, false)
	assert(perspective_row.visible, "spectator battles should expose runtime perspective switching")
	assert(
		perspective_option.get_item_count() == players.size(),
		"perspective selector should list participating players"
	)
	assert(
		perspective_option.selected == 0,
		"perspective selector should start on the current visible player"
	)

	perspective_option.item_selected.emit(1)
	for frame in range(12):
		await get_tree().process_frame

	assert(
		match_node.visible_player == players[1],
		"selecting another perspective should update Match.visible_player"
	)
	assert(
		visible_player_changed.size() == 1
		and visible_player_changed[0][0] == players[0]
		and visible_player_changed[0][1] == players[1],
		"runtime perspective switching should emit one visible-player change event"
	)
	_assert_player_visibility_groups(players[1], players[0])
	_assert_fog_mapping_has_no_stale_revealers(match_node)
	_assert_single_visible_resource_bar(match_node, players[1])
	_assert_minimap_tracks_player(match_node, players[1])
	await _assert_all_players_visibility_survives_perspective_switch(match_node, players)

	if MatchSignals.visible_player_changed.is_connected(changed_callback):
		MatchSignals.visible_player_changed.disconnect(changed_callback)
	get_tree().paused = false
	match_node.queue_free()
	await get_tree().process_frame
	get_tree().quit()


func _create_match_settings():
	var match_settings = MatchSettings.new()
	match_settings.visible_player = 0
	match_settings.visibility = MatchSettings.Visibility.PER_PLAYER
	match_settings.starting_resource_a = 12
	match_settings.starting_resource_b = 6
	return match_settings


func _add_test_players(match_node):
	var players_node = match_node.find_child("Players", false, false)
	for player_index in range(2):
		var player = PlayerScene.instantiate()
		player.name = "RuntimeSwitchPlayer{0}".format([player_index + 1])
		player.color = Constants.Player.COLORS[player_index]
		player.team_id = player_index
		player.resource_a = 12
		player.resource_b = 6
		players_node.add_child(player)


func _participant_players():
	return get_tree().get_nodes_in_group("players").filter(
		func(player):
			return not ("participates_in_match" in player) or player.participates_in_match
	)


func _assert_player_visibility_groups(visible_player, hidden_player):
	for unit in get_tree().get_nodes_in_group("units"):
		if unit.player == visible_player:
			assert(
				unit.is_in_group("revealed_units"),
				"new visible player's units should become fog revealers"
			)
		elif unit.player == hidden_player:
			assert(
				not unit.is_in_group("revealed_units"),
				"previous visible player's units should stop revealing fog"
			)


func _assert_fog_mapping_has_no_stale_revealers(match_node):
	var fog_of_war = match_node.fog_of_war
	for mapped_unit in fog_of_war._unit_to_circles_mapping.keys():
		assert(
			mapped_unit.is_in_group("revealed_units")
			or mapped_unit.is_in_group("temporary_revealers"),
			"fog texture mappings should be cleaned up after switching perspective"
		)


func _assert_single_visible_resource_bar(match_node, player):
	var resources = match_node.find_child("Resources", true, false)
	var visible_bars = resources.get_children().filter(func(bar): return bar.visible)
	assert(
		visible_bars.size() == 1,
		"per-player runtime perspective should show one resource bar"
	)
	assert(
		visible_bars[0].player == player,
		"resource bar should follow the current visible player"
	)


func _assert_minimap_tracks_player(match_node, player):
	var minimap = match_node.find_child("Minimap", true, false)
	assert(
		minimap._get_minimap_player() == player,
		"minimap radar state should follow the current visible player"
	)


func _assert_all_players_visibility_survives_perspective_switch(match_node, players):
	for unit in get_tree().get_nodes_in_group("units"):
		if players.has(unit.player):
			unit.add_to_group("revealed_units")
	match_node.settings.visibility = MatchSettings.Visibility.ALL_PLAYERS
	match_node.visible_player = players[0]
	for frame in range(6):
		await get_tree().process_frame
	for unit in get_tree().get_nodes_in_group("units"):
		if players.has(unit.player):
			assert(
				unit.is_in_group("revealed_units"),
				"all-player visibility should stay fully revealed when perspective changes"
			)
