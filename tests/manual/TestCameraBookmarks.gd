extends "res://tests/manual/Match.gd"

@onready var _test_camera = $IsometricCamera3D
@onready var _bookmark_handler = $Handlers/CameraBookmarkHandler
@onready var _group_handler = $Handlers/UnitGroupSelectionHandler
@onready var _tank = $Players/Human/Tank


func _ready():
	super()
	_test_camera.screen_margin_for_movement = -1
	await get_tree().process_frame

	_assert(InputMap.has_action("camera_bookmarks_set_1"), "camera bookmark set action should exist")
	_assert(
		InputMap.has_action("camera_bookmarks_access_1"),
		"camera bookmark access action should exist"
	)
	_assert(
		_set_bookmark_event(1).is_action_pressed("camera_bookmarks_set_1", false, true),
		"Ctrl+Alt+1 should set camera bookmark 1"
	)
	_assert(
		_access_bookmark_event(1).is_action_pressed("camera_bookmarks_access_1", false, true),
		"Alt+1 should access camera bookmark 1"
	)

	_test_camera.set_size_safely(12.0)
	_test_camera.set_position_safely(Vector3(12.0, 0.0, 12.0))
	await get_tree().process_frame
	var saved_center = _camera_center_yless()
	var saved_size = _test_camera.size

	_bookmark_handler._input(_set_bookmark_event(1))
	await get_tree().process_frame
	_assert(_bookmark_handler.has_bookmark(1), "setting bookmark 1 should store a view")

	_test_camera.set_size_safely(24.0)
	_test_camera.set_position_safely(Vector3(42.0, 0.0, 42.0))
	await get_tree().process_frame
	var away_center = _camera_center_yless()
	_assert(
		away_center.distance_to(saved_center) > 4.0,
		"test setup should move camera away from the saved bookmark"
	)

	_bookmark_handler._input(_access_bookmark_event(1))
	await get_tree().process_frame
	_assert(
		_camera_center_yless().distance_to(saved_center) < 0.75,
		"Alt+1 should restore bookmark 1 camera center"
	)
	_assert(is_equal_approx(_test_camera.size, saved_size), "Alt+1 should restore bookmark zoom")

	_test_camera.set_position_safely(Vector3(42.0, 0.0, 42.0))
	await get_tree().process_frame
	var empty_access_center = _camera_center_yless()
	_assert(not _bookmark_handler.access_bookmark(2), "empty bookmark 2 should not restore a view")
	_assert(
		_camera_center_yless().distance_to(empty_access_center) < 0.25,
		"empty bookmark access should keep the current camera center"
	)

	_tank.find_child("Selection").select()
	await get_tree().process_frame
	_group_handler.set_group(1)
	MatchSignals.deselect_all_units.emit()
	await get_tree().process_frame
	_group_handler._input(_access_bookmark_event(1))
	await get_tree().process_frame
	_assert(
		_selected_controlled_units().is_empty(),
		"Alt+1 should not also access control group 1"
	)
	_group_handler._input(_plain_number_event(1))
	await get_tree().process_frame
	_assert(
		_selected_controlled_units().size() == 1 and _tank.is_in_group("selected_units"),
		"plain 1 should still access control group 1"
	)

	get_tree().quit()


func _camera_center_yless():
	var center = _test_camera.get_ray_intersection(get_viewport().size / 2.0)
	return center * Vector3(1, 0, 1)


func _selected_controlled_units():
	return get_tree().get_nodes_in_group("selected_units").filter(
		func(unit): return unit.is_in_group("controlled_units")
	)


func _set_bookmark_event(bookmark_id: int):
	return _key_event(KEY_0 + bookmark_id, true, true)


func _access_bookmark_event(bookmark_id: int):
	return _key_event(KEY_0 + bookmark_id, true, false)


func _plain_number_event(number: int):
	return _key_event(KEY_0 + number, false, false)


func _key_event(keycode: int, alt_pressed: bool, ctrl_pressed: bool):
	var event = InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	event.physical_keycode = keycode
	event.alt_pressed = alt_pressed
	event.ctrl_pressed = ctrl_pressed
	if not alt_pressed and not ctrl_pressed:
		event.unicode = keycode
	return event


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
