extends Node

const MatchFlow = preload("res://source/match/MatchFlow.gd")
const MatchSettings = preload("res://source/data-model/MatchSettings.gd")
const PlayerSettings = preload("res://source/data-model/PlayerSettings.gd")

const TECH_DIVIDE_MAP_PATH = "res://source/match/maps/TechDivide.tscn"


class FakeMatch:
	extends Node

	var settings = null
	var map_path = "res://source/match/maps/PlainAndSimple.tscn"


func _ready():
	var settings = MatchSettings.new()
	var player = PlayerSettings.new()
	player.controller = Constants.PlayerType.HUMAN
	settings.players.append(player)

	var match_node = FakeMatch.new()
	match_node.name = "Match"
	match_node.settings = settings
	add_child(match_node)

	var caller = Node.new()
	caller.name = "Caller"
	match_node.add_child(caller)

	await get_tree().process_frame
	get_tree().paused = true
	Engine.time_scale = 1.5
	var restarted = MatchFlow.restart_match_from(caller)

	assert(restarted, "restart should create a loading scene from a match node")
	assert(not get_tree().paused, "restart should unpause the tree")
	assert(Engine.time_scale == 1.0, "restart should reset match speed")
	var loading = get_tree().current_scene
	assert(loading != null and loading.name == "Loading", "restart should switch to Loading")
	assert(loading.map_path == match_node.map_path, "restart should reuse the current map path")
	assert(loading.match_settings != settings, "restart should duplicate match settings")
	assert(loading.match_settings.players.size() == 1, "restart should preserve player settings")
	assert(
		loading.match_settings.players[0].controller == Constants.PlayerType.HUMAN,
		"restart should preserve player controllers"
	)

	get_tree().paused = true
	Engine.time_scale = 1.5
	MatchFlow.exit_to_setup_menu(get_tree())
	await _wait_for_current_scene("Play")
	assert(not get_tree().paused, "returning to setup should unpause the tree")
	assert(Engine.time_scale == 1.0, "returning to setup should reset match speed")
	assert(
		get_tree().current_scene != null and get_tree().current_scene.name == "Play",
		"returning to setup should switch to the skirmish setup scene"
	)

	get_tree().current_scene.queue_free()
	get_tree().current_scene = null
	await get_tree().process_frame
	await _assert_return_to_setup_preserves_match_configuration()

	get_tree().current_scene.queue_free()
	get_tree().quit()


func _assert_return_to_setup_preserves_match_configuration():
	var settings = MatchSettings.new()
	settings.starting_resource_a = 16
	settings.starting_resource_b = 8
	settings.players.append(
		_player_settings(Constants.PlayerType.HUMAN, Constants.Player.COLORS[4], 0, 0)
	)
	settings.players.append(
		_player_settings(
			Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_HARD,
			Constants.Player.COLORS[7],
			1,
			1
		)
	)
	settings.visible_player = 0

	var match_node = FakeMatch.new()
	match_node.name = "Match"
	match_node.map_path = TECH_DIVIDE_MAP_PATH
	match_node.settings = settings
	add_child(match_node)

	var caller = Node.new()
	caller.name = "Caller"
	match_node.add_child(caller)

	get_tree().paused = true
	Engine.time_scale = 1.5
	var returned = MatchFlow.exit_to_setup_menu_from(caller)
	assert(returned, "returning to setup from a match node should create a restored setup scene")
	await get_tree().process_frame

	var play_menu = get_tree().current_scene
	assert(play_menu != null and play_menu.name == "Play", "restored setup should switch to Play")
	assert(not get_tree().paused, "restored setup should unpause the tree")
	assert(Engine.time_scale == 1.0, "restored setup should reset match speed")
	assert(
		play_menu._selected_map_list_path() == TECH_DIVIDE_MAP_PATH,
		"restored setup should preserve the selected map"
	)
	var restored_settings = play_menu._create_match_settings()
	assert(
		restored_settings.starting_resource_a == 16 and restored_settings.starting_resource_b == 8,
		"restored setup should preserve starting resources"
	)
	assert(restored_settings.players.size() == 2, "restored setup should preserve active players")
	assert(
		restored_settings.players[0].controller == Constants.PlayerType.HUMAN,
		"restored setup should preserve the human player"
	)
	assert(
		restored_settings.players[0].color == Constants.Player.COLORS[4],
		"restored setup should preserve human color"
	)
	assert(restored_settings.players[0].team_id == 0, "restored setup should preserve human team")
	assert(
		restored_settings.players[1].controller == Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_HARD,
		"restored setup should preserve AI difficulty"
	)
	assert(
		restored_settings.players[1].color == Constants.Player.COLORS[7],
		"restored setup should preserve AI color"
	)
	assert(restored_settings.players[1].team_id == 1, "restored setup should preserve AI team")
	assert(
		restored_settings.players[1].spawn_index_offset == 1,
		"restored setup should preserve empty spawn slots between active players"
	)


func _player_settings(controller, color, team_id, spawn_index_offset):
	var settings = PlayerSettings.new()
	settings.controller = controller
	settings.color = color
	settings.team_id = team_id
	settings.spawn_index_offset = spawn_index_offset
	return settings


func _wait_for_current_scene(scene_name, max_frames = 10):
	for _i in range(max_frames):
		await get_tree().process_frame
		if get_tree().current_scene != null and get_tree().current_scene.name == scene_name:
			return
