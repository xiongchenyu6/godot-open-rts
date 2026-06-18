extends "res://tests/manual/Match.gd"

const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const Moving = preload("res://source/match/units/actions/Moving.gd")
const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")

@onready var _tank = $Players/Human/Tank
@onready var _unit_actions_controller = $Players/Human/UnitActionsController
@onready var _generic_menu = get_node(
	"HUD/MarginContainer3/VBoxContainer/UnitMenus/MarginContainer"
	+ "/CommandPanelViewport/MenuScroll/MenuStack/GenericMenu"
)


func _ready():
	super()
	await get_tree().process_frame

	_tank.find_child("Selection").select()
	await get_tree().process_frame

	var cancel_button = _generic_menu.find_child("CancelActionButton", true, false)
	_assert(cancel_button != null, "generic command menu should expose cancel current action")
	_assert(
		cancel_button.get_meta(CommandButtonHotkeys.META_DISPLAY) == "S",
		"cancel current action should use the classic S stop hotkey"
	)
	_assert(cancel_button.disabled, "cancel should be disabled before a unit has active orders")
	_assert(
		cancel_button.tooltip_text.contains(tr("CANCEL_CURRENT_ACTION_DISABLED")),
		"disabled cancel tooltip should explain the missing active order"
	)

	_tank.action = Moving.new(_tank.global_position_yless + Vector3(5.0, 0.0, 0.0))
	await get_tree().process_frame
	_generic_menu.refresh()

	_assert(_tank.action != null, "test tank should have a movement order before pressing S")
	_assert(not cancel_button.disabled, "cancel should be enabled for a selected unit with active orders")
	_assert(
		cancel_button.tooltip_text.contains(tr("CANCEL_CURRENT_ACTION_DESCRIPTION")),
		"enabled cancel tooltip should describe stopping selected units"
	)

	_unit_actions_controller._unhandled_input(_key_event(KEY_S))
	await get_tree().process_frame
	_generic_menu.refresh()

	_assert(
		_tank.action is WaitingForTargets and _tank.action.is_idle(),
		"pressing S should return combat units to idle target-watching"
	)
	_assert(cancel_button.disabled, "cancel should disable again after the order is stopped")
	get_tree().quit()


func _key_event(keycode):
	var event = InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	event.physical_keycode = keycode
	return event


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
