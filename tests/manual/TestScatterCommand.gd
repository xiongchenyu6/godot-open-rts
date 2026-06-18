extends "res://tests/manual/Match.gd"

const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const Moving = preload("res://source/match/units/actions/Moving.gd")

@onready var _left_tank = $Players/Human/Tank
@onready var _right_tank = $Players/Human/Tank2
@onready var _generic_menu = $HUD/MarginContainer3/VBoxContainer/UnitMenus/MarginContainer/CommandPanelViewport/MenuScroll/MenuStack/GenericMenu


func _ready():
	super()
	await get_tree().process_frame
	await get_tree().process_frame

	_left_tank.position = Vector3(10.0, 0.0, 10.0)
	_right_tank.position = Vector3(12.0, 0.0, 10.0)

	_generic_menu.units = [_left_tank, _right_tank]
	_generic_menu.refresh()
	var scatter_button = _generic_menu.find_child("ScatterButton", true, false)
	_assert(InputMap.has_action("scatter"), "scatter input action should exist")
	_assert(scatter_button != null, "generic menu should expose scatter")
	_assert(
		scatter_button.get_meta(CommandButtonHotkeys.META_DISPLAY) == "X",
		"scatter should use the X command slot"
	)
	_assert(not scatter_button.disabled, "scatter should be available for mobile units")

	var initial_left_position = _left_tank.global_position_yless
	var initial_right_position = _right_tank.global_position_yless
	var initial_distance = initial_left_position.distance_to(initial_right_position)
	_generic_menu._on_scatter_button_pressed()

	_assert(_left_tank.action is Moving, "left tank should receive a moving scatter action")
	_assert(_right_tank.action is Moving, "right tank should receive a moving scatter action")

	var left_target = _left_tank.action._target_position
	var right_target = _right_tank.action._target_position
	_assert(left_target.x < initial_left_position.x, "left tank should scatter left")
	_assert(right_target.x > initial_right_position.x, "right tank should scatter right")
	_assert(
		left_target.distance_to(right_target) > initial_distance,
		"scatter targets should spread the group"
	)
	get_tree().quit()


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
