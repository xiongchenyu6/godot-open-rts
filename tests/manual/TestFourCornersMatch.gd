extends Node

const MatchSettings = preload("res://source/data-model/MatchSettings.gd")
const PlayerSettings = preload("res://source/data-model/PlayerSettings.gd")
const MatchScene = preload("res://source/match/Match.tscn")
const FourCornersMap = preload("res://source/match/maps/FourCorners.tscn")


func _ready():
	var match_node = MatchScene.instantiate()
	match_node.settings = _create_match_settings()
	match_node.map = FourCornersMap.instantiate()
	add_child(match_node)

	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		player.set_process(false)
	var participant_players = players.filter(
		func(player):
			return not ("participates_in_match" in player) or player.participates_in_match
	)
	var neutral_players = players.filter(
		func(player): return "participates_in_match" in player and not player.participates_in_match
	)
	assert(
		participant_players.size() == 4,
		"Four Corners test should create a four-player skirmish"
	)
	assert(neutral_players.size() == 1, "Four Corners should include one neutral tech owner")
	assert(
		neutral_players[0].find_child("WestOilDerrick", true, false) != null
		and neutral_players[0].find_child("EastOilDerrick", true, false) != null,
		"Four Corners should include two neutral oil derricks"
	)
	assert(
		neutral_players[0].find_child("NorthTechAirport", true, false) != null
		and neutral_players[0].find_child("SouthTechAirport", true, false) != null,
		"Four Corners should include two neutral tech airports"
	)
	assert(
		neutral_players[0].find_child("NorthEastTechHospital", true, false) != null
		and neutral_players[0].find_child("SouthWestTechHospital", true, false) != null,
		"Four Corners should include two neutral tech hospitals"
	)
	assert(
		neutral_players[0].find_child("NorthWestTechRepairDepot", true, false) != null
		and neutral_players[0].find_child("SouthEastTechRepairDepot", true, false) != null,
		"Four Corners should include two neutral tech repair depots"
	)
	var supply_crates = match_node.map.find_child("SupplyCrates", true, false)
	assert(supply_crates != null, "Four Corners should include supply crates")
	assert(supply_crates.get_child_count() == 4, "Four Corners should include four supply crates")
	assert(
		supply_crates.find_child("NorthEastRepairCrate", true, false).effect_type == "repair"
		and supply_crates.find_child("SouthEastVeterancyCrate", true, false).effect_type == "veterancy",
		"Four Corners should include repair and veterancy crate variants"
	)
	for player in participant_players:
		assert(
			player.resource_a == 16 and player.resource_b == 8,
			"starting resource settings should be applied to spawned players"
		)

	for _i in range(4):
		await get_tree().process_frame

	assert(match_node.map.size == Vector2(72, 72), "Four Corners should use the registered size")
	assert(
		match_node.map.find_child("SpawnPoints").get_child_count() == 4,
		"Four Corners should start four players"
	)
	assert(
		get_tree().get_nodes_in_group("units").size() >= 12,
		"each player should receive a starting base, worker, and scout unit"
	)
	match_node.queue_free()
	await get_tree().process_frame
	get_tree().quit()


func _create_match_settings():
	var match_settings = MatchSettings.new()
	match_settings.visible_player = 0
	match_settings.visibility = MatchSettings.Visibility.PER_PLAYER
	match_settings.starting_resource_a = 16
	match_settings.starting_resource_b = 8
	var controllers = [
		Constants.PlayerType.HUMAN,
		Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_EASY,
		Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI,
		Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_HARD,
	]
	for player_id in range(controllers.size()):
		var player_settings = PlayerSettings.new()
		player_settings.controller = controllers[player_id]
		player_settings.color = Constants.Player.COLORS[player_id]
		match_settings.players.append(player_settings)
	return match_settings
