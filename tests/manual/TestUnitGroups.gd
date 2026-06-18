extends "res://tests/manual/Match.gd"

@onready var _tank = $Players/Human/Tank
@onready var _worker = $Players/Human/Worker
@onready var _test_camera = $IsometricCamera3D
@onready var _group_handler = $Handlers/UnitGroupSelectionHandler


func _ready():
	super()
	await get_tree().process_frame
	_test_camera.screen_margin_for_movement = -1

	var assigned_events = []
	var cleared_events = []
	var record_assigned = func(group_id, units):
		assigned_events.append({"group_id": group_id, "unit_count": units.size()})
	var record_cleared = func(group_id): cleared_events.append(group_id)
	MatchSignals.unit_group_assigned.connect(record_assigned)
	MatchSignals.unit_group_cleared.connect(record_cleared)

	_tank.find_child("Selection").select()
	_worker.find_child("Selection").select()
	_group_handler.set_group(1)
	await get_tree().process_frame
	_assert(assigned_events.size() == 1, "setting a group should emit one assignment event")
	_assert(assigned_events[0]["group_id"] == 1, "assignment event should include the group id")
	_assert(assigned_events[0]["unit_count"] == 2, "assignment event should include grouped units")
	MatchSignals.deselect_all_units.emit()
	await get_tree().process_frame

	var group_pivot = Utils.Match.Unit.Movement.calculate_aabb_crowd_pivot_yless([_tank, _worker])
	_test_camera.set_position_safely(Vector3(6.0, 0.0, 6.0))
	await get_tree().process_frame
	var away_center = _camera_center_yless()

	_group_handler.access_group(1)
	await get_tree().process_frame
	_assert(_selected_controlled_units().size() == 2, "accessing group should select all grouped units")
	_assert(_tank.is_in_group("selected_units"), "accessing group should select the grouped tank")
	_assert(_worker.is_in_group("selected_units"), "accessing group should select the grouped worker")
	_assert(
		_camera_center_yless().distance_to(away_center) < 0.25,
		"first group access should preserve camera position"
	)

	_group_handler.access_group(1)
	await get_tree().process_frame
	_assert(
		_camera_center_yless().distance_to(group_pivot) < 0.75,
		"second group access should focus the camera on the selected group"
	)

	MatchSignals.deselect_all_units.emit()
	await get_tree().process_frame
	_group_handler.set_group(1)
	await get_tree().process_frame
	_assert(cleared_events == [1], "setting an empty selection should clear an existing group")
	_assert(_selected_controlled_units().is_empty(), "clearing a group should not change selection")

	MatchSignals.unit_group_assigned.disconnect(record_assigned)
	MatchSignals.unit_group_cleared.disconnect(record_cleared)
	get_tree().quit()


func _camera_center_yless():
	var center = _test_camera.get_ray_intersection(get_viewport().size / 2.0)
	return center * Vector3(1, 0, 1)


func _selected_controlled_units():
	return get_tree().get_nodes_in_group("selected_units").filter(
		func(unit): return unit.is_in_group("controlled_units")
	)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
