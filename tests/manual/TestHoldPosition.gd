extends "res://tests/manual/Match.gd"

const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")
const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")

@onready var _tank = $Players/Human/Tank
@onready var _target_worker = $Players/Player/Worker
@onready var _generic_menu = get_node(
	"HUD/MarginContainer3/VBoxContainer/UnitMenus/MarginContainer"
	+ "/CommandPanelViewport/MenuScroll/MenuStack/GenericMenu"
)
@onready var _selection_info = $HUD/SelectionInfoAnchor/SelectionInfo


func _ready():
	super()
	await get_tree().process_frame

	_tank.find_child("Selection").select()
	await get_tree().process_frame
	var hold_button = _generic_menu.find_child("HoldPositionButton", true, false)
	var guard_button = _generic_menu.find_child("GuardAreaButton", true, false)
	_assert(hold_button != null, "generic command menu should expose hold position")
	_assert(guard_button != null, "generic command menu should expose guard area")
	_assert(not hold_button.disabled, "hold position should be available for combat units")
	_assert(not guard_button.disabled, "guard area should be available for combat units")
	_assert(
		guard_button.get_meta(CommandButtonHotkeys.META_DISPLAY) == "G",
		"guard area should use the G command slot"
	)

	_generic_menu._on_hold_position_button_toggled(true)
	await get_tree().process_frame
	_target_worker.global_position = _tank.global_position + Vector3(4.0, 0.0, 0.0)
	var initial_target_hp = _target_worker.hp
	await get_tree().create_timer(0.55).timeout
	_assert(_tank.hold_position, "hold position should be enabled on the selected tank")
	_assert(hold_button.button_pressed, "hold position button should show the active stance")
	_assert(
		_selection_info.find_child("StatsLabel", true, false).text.contains(
			tr("SELECTION_HOLD_POSITION")
		),
		"selection info should show hold-position state"
	)
	_assert(
		_tank.action is WaitingForTargets and _tank.action.is_idle(),
		"holding units should keep waiting without auto-chasing"
	)
	_assert(
		is_instance_valid(_target_worker) and _target_worker.hp == initial_target_hp,
		"holding units should not damage visible nearby enemies automatically"
	)

	_generic_menu._on_guard_area_button_pressed()
	await get_tree().process_frame
	_assert(not _tank.hold_position, "guard area should clear hold-position stance")
	_assert(not hold_button.button_pressed, "hold button should clear after guard area is issued")
	await _wait_until(
		func(): return not is_instance_valid(_target_worker) or _target_worker.hp < initial_target_hp,
		2.0,
		"units should resume automatic target acquisition after hold position is disabled"
	)
	get_tree().quit()


func _wait_until(condition, timeout_s, message):
	var started_at_msec = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at_msec < timeout_s * 1000.0:
		if condition.call():
			return
		await get_tree().process_frame
	_assert(false, message)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
