extends "res://tests/manual/Match.gd"

const StructureScript = preload("res://source/match/units/Structure.gd")
const WorkerScript = preload("res://source/match/units/Worker.gd")

@onready var _briefing = $HUD/MatchBriefingAnchor/MatchBriefing
@onready var _objectives_button = $HUD/BriefingButtonAnchor/ObjectivesButton
@onready var _objective_tracker = $HUD/ObjectiveTrackerAnchor/ObjectiveTracker
@onready var _match_menu = $Menu


func _ready():
	super()
	await get_tree().process_frame

	_assert(_briefing.visible, "briefing should be visible when the match starts")
	_assert(not _objectives_button.visible, "objectives button should hide while briefing is open")
	_assert(_objective_tracker.visible, "objective tracker should stay visible during the match")
	_assert_label_text("TitleLabel", tr("BRIEFING_TITLE"))
	_assert_label_text("ObjectiveLabel", tr("BRIEFING_OBJECTIVE_ELIMINATION"))
	_assert_label_contains("DetailsLabel", tr("BRIEFING_ENEMIES"))
	_assert_label_contains("DetailsLabel", "1")
	_assert_label_contains("DetailsLabel", tr("RESOURCE_A"))
	_assert_label_contains("DetailsLabel", "8")
	_assert_label_contains("DetailsLabel", tr("RESOURCE_B"))
	_assert_label_contains("DetailsLabel", "4")
	_assert_label_contains("OpeningLabel", tr("BRIEFING_OPENING_TITLE"))
	_assert_label_contains("OpeningLabel", tr("BRIEFING_OPENING_ECONOMY"))
	_assert_tracker_label_text("TitleLabel", tr("OBJECTIVE_TRACKER_TITLE"))
	_assert_tracker_label_text("ObjectiveLabel", tr("OBJECTIVE_TRACKER_ELIMINATION"))
	_assert_tracker_label_contains("ProgressLabel", tr("OBJECTIVE_PROGRESS_ENEMY_TEAMS"))
	_assert_tracker_label_contains("ProgressLabel", "1")
	_assert_tracker_label_contains("ProgressLabel", tr("OBJECTIVE_PROGRESS_ANCHORS"))
	_assert_tracker_label_contains("ProgressLabel", "3/3")
	_assert_tracker_label_contains("BreakdownLabel", tr("OBJECTIVE_PROGRESS_STRUCTURES"))
	_assert_tracker_label_contains("BreakdownLabel", tr("OBJECTIVE_PROGRESS_WORKERS"))
	var progress_bar = _objective_tracker.find_child("MissionProgressBar", true, false)
	_assert(progress_bar != null, "objective tracker should expose a mission progress bar")
	_assert(progress_bar.max_value == 100.0, "objective progress bar should use percent values")
	_assert(progress_bar.value == 0.0, "objective progress should start at zero completion")
	await _remove_one_enemy_anchor()
	_assert_tracker_label_contains("ProgressLabel", "2/3")
	_assert(
		progress_bar.value > 30.0 and progress_bar.value < 35.0,
		"objective progress bar should advance after one enemy anchor is removed"
	)
	await _remove_remaining_enemy_anchors()
	_assert_tracker_label_text("ProgressLabel", tr("OBJECTIVE_PROGRESS_COMPLETE"))
	_assert(progress_bar.value == 100.0, "objective progress bar should fill on completion")
	_match_menu._refresh_status_summary()
	var menu_status_label = _match_menu.find_child("StatusLabel", true, false)
	_assert(menu_status_label != null, "match menu should expose a battle status label")
	_assert(
		menu_status_label.text.contains(tr("MATCH_STATUS_TITLE")),
		"match menu status should show its translated title"
	)
	_assert(
		menu_status_label.text.contains(tr("OBJECTIVE_TRACKER_ELIMINATION")),
		"match menu status should include the active objective"
	)
	_assert(
		menu_status_label.text.contains(tr("OBJECTIVE_PROGRESS_ENEMY_TEAMS"))
		and menu_status_label.text.contains("1"),
		"match menu status should show active enemy teams"
	)
	_assert(
		menu_status_label.text.contains(tr("OBJECTIVE_PROGRESS_ANCHORS"))
		and menu_status_label.text.contains("0"),
		"match menu status should show remaining enemy anchors after completion"
	)

	_briefing.auto_hide_seconds = 0.05
	_briefing.show_briefing()
	await get_tree().create_timer(0.12).timeout
	_assert(not _briefing.visible, "briefing should auto-hide after its configured duration")

	_briefing.auto_hide_seconds = 0.0
	_briefing.show_briefing()
	await get_tree().process_frame
	_assert(_briefing.visible, "briefing should be visible after reopening")
	_briefing.find_child("CloseButton", true, false).pressed.emit()
	await get_tree().process_frame
	_assert(not _briefing.visible, "briefing close button should hide the panel")
	_assert(_objectives_button.visible, "objectives button should appear after closing briefing")

	_objectives_button.pressed.emit()
	await get_tree().process_frame
	_assert(_briefing.visible, "objectives button should reopen the briefing")
	_assert(not _objectives_button.visible, "objectives button should hide after reopening briefing")

	get_tree().quit()


func _remove_one_enemy_anchor():
	var anchors = _enemy_anchors()
	_assert(anchors.size() == 3, "test match should start with three enemy anchors")
	anchors[0].queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _remove_remaining_enemy_anchors():
	for anchor in _enemy_anchors():
		anchor.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _enemy_anchors():
	return get_tree().get_nodes_in_group("adversary_units").filter(
		func(unit): return (
			(unit is StructureScript or unit is WorkerScript)
			and unit.is_inside_tree()
			and (not ("hp" in unit) or unit.hp == null or unit.hp > 0)
		)
	)


func _assert_label_text(label_name, expected_text):
	var label = _briefing.find_child(label_name, true, false)
	_assert(label != null, "{0} should exist".format([label_name]))
	_assert(label.text == expected_text, "{0} should read '{1}'".format([label_name, expected_text]))


func _assert_label_contains(label_name, expected_text):
	var label = _briefing.find_child(label_name, true, false)
	_assert(label != null, "{0} should exist".format([label_name]))
	_assert(
		label.text.contains(str(expected_text)),
		"{0} should contain '{1}' but was '{2}'".format([label_name, expected_text, label.text])
	)


func _assert_tracker_label_text(label_name, expected_text):
	var label = _objective_tracker.find_child(label_name, true, false)
	_assert(label != null, "tracker {0} should exist".format([label_name]))
	_assert(
		label.text == expected_text,
		"tracker {0} should read '{1}' but was '{2}'".format(
			[label_name, expected_text, label.text]
		)
	)


func _assert_tracker_label_contains(label_name, expected_text):
	var label = _objective_tracker.find_child(label_name, true, false)
	_assert(label != null, "tracker {0} should exist".format([label_name]))
	_assert(
		label.text.contains(str(expected_text)),
		"tracker {0} should contain '{1}' but was '{2}'".format(
			[label_name, expected_text, label.text]
		)
	)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
