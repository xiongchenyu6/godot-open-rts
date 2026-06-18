extends "res://tests/manual/Match.gd"

@onready var _tank = $Players/Human/Tank
@onready var _worker = $Players/Human/Worker
@onready var _selection_info = $HUD/SelectionInfoAnchor/SelectionInfo
@onready var _group_handler = $Handlers/UnitGroupSelectionHandler


func _ready():
	super()
	await get_tree().process_frame

	_tank.find_child("Selection").select()
	await get_tree().process_frame
	_assert(_selection_info.visible, "selection info panel should appear for selected units")
	_assert(_label_text("NameLabel") == tr("TANK"), "single selection should show the unit name")
	_assert(
		_label_text("HealthLabel") == "{0} 10/10".format([tr("SELECTION_HP")]),
		"single selection should show unit HP"
	)
	_assert(
		_label_text("StatsLabel").contains(tr("SELECTION_ATK")),
		"single selection should show combat stats"
	)
	_assert(not _rank_badge().visible, "green single selection should not show a rank badge")
	_assert(
		_label_text("RankLabel") == "{0}: {1}".format(
			[tr("SELECTION_RANK"), tr("SELECTION_GREEN")]
		),
		"single selection should show green rank text"
	)
	_assert_selection_icon_visible("single selection should show a unit icon")

	_tank.hp -= 3
	await get_tree().process_frame
	_assert(
		_label_text("HealthLabel") == "{0} 7/10".format([tr("SELECTION_HP")]),
		"selection info should update when selected unit HP changes"
	)
	_tank.grant_veterancy_rank(1)
	await get_tree().process_frame
	_assert_rank_badge("V", "single promoted selection should show a veteran badge")
	_assert(
		_label_text("RankLabel") == "{0}: {1}".format(
			[tr("SELECTION_RANK"), tr("SELECTION_VETERAN")]
		),
		"single promoted selection should show veteran rank text"
	)

	_worker.find_child("Selection").select()
	await get_tree().process_frame
	_assert(
		_label_text("NameLabel") == tr("SELECTION_SELECTED").format([2]),
		"multi selection should show selected count"
	)
	_assert(
		_label_text("SummaryLabel").contains(tr("TANK"))
		and _label_text("SummaryLabel").contains(tr("WORKER")),
		"multi selection should summarize selected types"
	)
	_assert_rank_badge("V", "multi selection should show the highest promoted rank badge")
	_assert(
		_label_text("RankLabel") == "{0}: {1} x1".format(
			[tr("SELECTION_RANK"), tr("SELECTION_VETERAN")]
		),
		"multi selection should summarize promoted ranks"
	)
	_assert_selection_icon_visible("multi selection should keep a visible unit icon")
	_group_handler.set_group(3)
	await get_tree().process_frame
	_assert(
		_label_text("GroupLabel") == tr("SELECTION_CONTROL_GROUP").format([3]),
		"selection info should show an exact control group match"
	)

	MatchSignals.deselect_all_units.emit()
	await get_tree().process_frame
	_assert(not _selection_info.visible, "selection info panel should hide when nothing is selected")
	get_tree().quit()


func _label_text(label_name):
	return _selection_info.find_child(label_name, true, false).text


func _rank_badge():
	return _selection_info.find_child("RankBadge", true, false)


func _assert_rank_badge(expected_text, message):
	var badge = _rank_badge()
	_assert(badge != null, "{0}: missing RankBadge".format([message]))
	_assert(badge.visible, "{0}: rank badge should be visible".format([message]))
	_assert(badge.text == expected_text, "{0}: rank badge should show {1}".format([message, expected_text]))
	_assert(
		badge.get_theme_stylebox("normal") != null,
		"{0}: rank badge should have a visible frame".format([message])
	)


func _assert_selection_icon_visible(message):
	var icon = _selection_info.find_child("IconTextureRect", true, false)
	_assert(icon != null, "{0}: missing IconTextureRect".format([message]))
	_assert(icon.visible, "{0}: icon node should be visible".format([message]))
	_assert(icon.texture != null, "{0}: icon texture should be loaded".format([message]))
	_assert(
		icon.texture.get_image() != null,
		"{0}: icon texture should expose image data".format([message])
	)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
