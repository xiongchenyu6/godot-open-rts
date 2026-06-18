extends "res://tests/manual/Match.gd"

@onready var _test_camera = $IsometricCamera3D
@onready var _focus_controller = $Handlers/BattlefieldEventFocusController


func _ready():
	super()
	_test_camera.screen_margin_for_movement = -1
	await get_tree().process_frame

	_test_camera.set_position_safely(Vector3(6.0, 0.0, 6.0))
	await get_tree().process_frame

	var battle_position = Vector3(42.0, 0.0, 42.0)
	MatchSignals.battle_event_recorded.emit(battle_position)
	await get_tree().process_frame
	var event_position = _focus_controller.get_latest_event_position()
	_assert(event_position != null, "battle event signal should record a focusable position")
	var event_position_yless = event_position * Vector3(1, 0, 1)
	_assert(
		_camera_center_yless().distance_to(event_position_yless) > 4.0,
		"test setup should start camera away from the battle event"
	)

	var focus_event = _focus_event()
	_assert(InputMap.has_action("focus_latest_battle_event"), "focus action should exist")
	_assert(
		focus_event.is_action_pressed("focus_latest_battle_event"),
		"space key event should match the focus latest battle event action"
	)
	_focus_controller._unhandled_input(focus_event)
	await get_tree().process_frame
	var input_focus_center = _camera_center_yless()
	_assert(
		input_focus_center.distance_to(event_position_yless) < 0.75,
		"focus latest battle event should move the camera to the damaged unit: {0} vs {1}, distance {2}".format(
			[
				input_focus_center,
				event_position_yless,
				input_focus_center.distance_to(event_position_yless)
			]
		)
	)
	get_tree().quit()


func _camera_center_yless():
	var center = _test_camera.get_ray_intersection(get_viewport().size / 2.0)
	return center * Vector3(1, 0, 1)


func _focus_event():
	var event = InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	return event


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
