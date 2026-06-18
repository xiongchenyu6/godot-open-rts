extends Node

const MatchScene = preload("res://source/match/Match.tscn")
const MatchSettings = preload("res://source/data-model/MatchSettings.gd")
const PlainAndSimpleMap = preload("res://source/match/maps/PlainAndSimple.tscn")
const PlayerSettings = preload("res://source/data-model/PlayerSettings.gd")
const PlayScene = preload("res://source/main-menu/Play.tscn")
const SimpleClairvoyantAIScene = preload(
	"res://source/match/players/simple-clairvoyant-ai/SimpleClairvoyantAI.tscn"
)


func _ready():
	await _test_play_menu_exposes_ai_difficulty_options()
	_test_beginner_ai_profile()
	await _test_match_applies_hard_ai_profile()
	get_tree().paused = false
	get_tree().quit()


func _test_play_menu_exposes_ai_difficulty_options():
	var play_menu = PlayScene.instantiate()
	add_child(play_menu)
	await get_tree().process_frame

	var option_button = play_menu._get_player_option_nodes()[0]
	assert(
		_has_option_id(option_button, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_BEGINNER),
		"skirmish player slot should expose Beginner AI"
	)
	assert(
		_has_option_id(option_button, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_EASY),
		"skirmish player slot should expose Easy AI"
	)
	assert(
		_has_option_id(option_button, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI),
		"skirmish player slot should expose Normal AI"
	)
	assert(
		_has_option_id(option_button, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_HARD),
		"skirmish player slot should expose Hard AI"
	)

	play_menu._select_player_controller(
		option_button, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_HARD
	)
	assert(
		play_menu._selected_player_controller(option_button)
		== Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_HARD,
		"skirmish player slot should preserve selected AI difficulty"
	)

	play_menu.queue_free()
	await get_tree().process_frame


func _test_beginner_ai_profile():
	var ai_player = SimpleClairvoyantAIScene.instantiate()
	ai_player.apply_player_settings(_player_settings(Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_BEGINNER))
	assert(not ai_player.active_offense_enabled, "beginner AI should disable active offense")
	assert(ai_player.expected_number_of_battlegroups == 0, "beginner AI should not form attack groups")
	assert(
		ai_player.expected_number_of_units_in_battlegroup == 0,
		"beginner AI should not request offensive combat units"
	)
	assert(ai_player.expected_number_of_ag_turrets == 1, "beginner AI should still build basic defense")
	var offense_controller = ai_player.find_child("OffenseController", false, false)
	assert(offense_controller != null, "beginner AI should still have an offense controller node")
	assert(
		offense_controller.find_child("Timer", false, false) == null,
		"beginner AI offense controller should not start active offense refreshes"
	)
	ai_player.free()


func _test_match_applies_hard_ai_profile():
	var match_settings = MatchSettings.new()
	match_settings.players.append(_player_settings(Constants.PlayerType.HUMAN))
	match_settings.players.append(_player_settings(Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_HARD))
	match_settings.visible_player = 0

	var match_node = MatchScene.instantiate()
	match_node.settings = match_settings
	match_node.map = PlainAndSimpleMap.instantiate()
	add_child(match_node)
	await get_tree().process_frame

	var ai_player = match_node.find_child("SimpleClairvoyantAI", true, false)
	assert(ai_player != null, "match should instantiate a hard AI player")
	assert(ai_player.expected_number_of_workers == 4, "hard AI should build a stronger economy")
	assert(
		ai_player.expected_number_of_battlegroups == 3,
		"hard AI should prepare more battlegroups"
	)
	assert(
		ai_player.expected_number_of_units_in_battlegroup == 5,
		"hard AI should form larger battlegroups"
	)
	assert(
		ai_player.expected_number_of_prism_defense_obelisks == 2,
		"hard AI should invest in heavier defenses"
	)

	match_node.queue_free()
	await get_tree().process_frame


func _player_settings(controller):
	var player_settings = PlayerSettings.new()
	player_settings.controller = controller
	return player_settings


func _has_option_id(option_button, item_id):
	for item_index in range(option_button.get_item_count()):
		if option_button.get_item_id(item_index) == item_id:
			return true
	return false
