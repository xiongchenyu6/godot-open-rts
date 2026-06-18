extends "res://source/match/Match.gd"

const StructureScript = preload("res://source/match/units/Structure.gd")
const WorkerScript = preload("res://source/match/units/Worker.gd")

@export var eliminate_human = false
@export var test_locale = ""

var _result = ""
var _original_locale = ""


func _enter_tree():
	_original_locale = TranslationServer.get_locale()
	if test_locale != "":
		TranslationServer.set_locale(test_locale)


func _ready():
	FeatureFlags.handle_match_end = true
	super()
	MatchSignals.match_finished_with_victory.connect(func(): _result = "victory")
	MatchSignals.match_finished_with_defeat.connect(func(): _result = "defeat")
	await get_tree().process_frame

	var eliminated_player = $Players/Human if eliminate_human else $Players/Enemy
	var surviving_combat_unit = eliminated_player.find_child("Tank")
	assert(surviving_combat_unit != null, "test scene should keep a non-anchor combat unit alive")
	_record_simulated_enemy_unit_loss()

	_queue_free_units_matching(eliminated_player, func(unit): return unit is StructureScript)
	await get_tree().process_frame
	assert(
		_result == "",
		"player should not be eliminated while a rebuild-capable worker remains"
	)

	_queue_free_units_matching(eliminated_player, func(unit): return unit is WorkerScript)
	await _wait_for_result()
	assert(
		_result == ("defeat" if eliminate_human else "victory"),
		"match should end when the eliminated player has no buildings or workers"
	)
	assert(
		is_instance_valid(surviving_combat_unit) and surviving_combat_unit.is_inside_tree(),
		"ordinary combat units should not keep a player alive after base elimination"
	)
	_assert_end_controls()
	TranslationServer.set_locale(_original_locale)
	get_tree().paused = false
	get_tree().quit()


func _queue_free_units_matching(player, predicate):
	for unit in player.get_children():
		if predicate.call(unit):
			unit.queue_free()


func _wait_for_result(max_frames = 10):
	for _i in range(max_frames):
		await get_tree().process_frame
		if _result != "":
			return


func _assert_end_controls():
	var handler = find_child("MatchEndHandler", true, false)
	assert(handler != null and handler.visible, "match end handler should be visible")
	var restart_button = handler.find_child("RestartButton", true, false)
	var setup_button = handler.find_child("SetupButton", true, false)
	var exit_button = handler.find_child("ExitButton", true, false)
	assert(restart_button != null, "match end should expose a restart button")
	assert(setup_button != null, "match end should expose a return-to-setup button")
	assert(exit_button != null, "match end should expose an exit button")
	assert(restart_button.text == tr("RESTART_MATCH"), "restart button should use match copy")
	assert(setup_button.text == tr("RETURN_TO_SETUP"), "setup button should use match copy")
	assert(exit_button.text == tr("EXIT_TO_MENU"), "exit button should use menu copy")
	assert(
		handler.find_child("StatsTitleLabel", true, false).text == tr("MATCH_STATS_TITLE"),
		"match end should show a battle report title"
	)
	assert(
		handler.find_child("ResultTitleLabel", true, false).text == tr("MATCH_RESULT_TITLE"),
		"match end should show an outcome title"
	)
	assert(
		handler.find_child("RemainingTeamsLabel", true, false).text == tr("MATCH_RESULT_REMAINING_TEAMS"),
		"match end should localize remaining team label"
	)
	assert(
		handler.find_child("RemainingAnchorsLabel", true, false).text == tr("MATCH_RESULT_REMAINING_ANCHORS"),
		"match end should localize command-anchor label"
	)
	assert(
		handler.find_child("DurationLabel", true, false).text == tr("MATCH_STATS_DURATION"),
		"match end should localize duration label"
	)
	assert(
		handler.find_child("EnemyUnitsLabel", true, false).text == tr("MATCH_STATS_ENEMY_UNITS"),
		"match end should localize enemy unit stats label"
	)
	assert(
		handler.find_child("ResourcesLabel", true, false).text == tr("MATCH_STATS_RESOURCES"),
		"match end should localize resources stats label"
	)
	var expected_reason_key = (
		"MATCH_RESULT_DEFEAT_REASON" if eliminate_human else "MATCH_RESULT_VICTORY_REASON"
	)
	assert(
		handler.find_child("ResultReasonValue", true, false).text == tr(expected_reason_key),
		"match end should explain why the mission ended"
	)
	var expected_title_key = "MATCH_DEFEAT_TITLE" if eliminate_human else "MATCH_VICTORY_TITLE"
	var expected_tile_name = "Defeat" if eliminate_human else "Victory"
	assert(
		handler.find_child(expected_tile_name, true, false).find_child("Label", true, false).text
		== tr(expected_title_key),
		"match end banner should localize the final mission result"
	)
	assert(
		handler.find_child("RemainingTeamsValue", true, false).text == "1",
		"match end should show one remaining active team"
	)
	assert(
		handler.find_child("RemainingAnchorsValue", true, false).text == "2",
		"match end should count surviving command anchors"
	)
	assert(
		handler.find_child("EnemyUnitsValue", true, false).text == "1",
		"battle report should count enemy unit losses from the tracked player perspective; got {0}".format(
			[handler.find_child("EnemyUnitsValue", true, false).text]
		)
	)
	assert(
		handler.find_child("ResourcesValue", true, false).text.begins_with("A "),
		"battle report should show tracked player resources"
	)


func _record_simulated_enemy_unit_loss():
	var fake_unit = Node.new()
	fake_unit.set_meta("death_player", $Players/Enemy)
	MatchSignals.unit_died.emit(fake_unit)
	fake_unit.free()
