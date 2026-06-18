extends Node3D

@export var camera_path: NodePath = NodePath("../../IsometricCamera3D")

var _set_action_names = [null]
var _get_action_names = [null]
var _unit_group_names = [null]
var _last_accessed_group_id = 0

@onready var _camera = get_node_or_null(camera_path)


func _ready():
	for group_id in range(1, 10):
		_set_action_names.append("unit_groups_set_{0}".format([group_id]))
		_get_action_names.append("unit_groups_access_{0}".format([group_id]))
		_unit_group_names.append("unit_group_{0}".format([group_id]))


func _input(event):
	for group_id in range(1, 10):
		if event.is_action_pressed(_set_action_names[group_id], false, true):
			set_group(group_id)
			return
		if event.is_action_pressed(_get_action_names[group_id], false, true):
			access_group(group_id)
			return


func access_group(group_id: int):
	var units_in_group = _units_in_group(group_id)
	var should_focus_group = (
		_last_accessed_group_id == group_id and _is_exact_current_selection(units_in_group)
	)
	Utils.Match.select_units(units_in_group)
	_last_accessed_group_id = group_id if not units_in_group.empty() else 0
	if should_focus_group:
		_focus_group(units_in_group)


func set_group(group_id: int):
	_last_accessed_group_id = 0
	var group_name = _unit_group_names[group_id]
	var previous_units = get_tree().get_nodes_in_group(group_name)
	for unit in previous_units:
		unit.remove_from_group(_unit_group_names[group_id])

	var assigned_units = []
	for unit in get_tree().get_nodes_in_group("selected_units"):
		if unit.is_in_group("controlled_units"):
			unit.add_to_group(group_name)
			assigned_units.append(unit)
	if assigned_units.is_empty():
		if not previous_units.is_empty():
			MatchSignals.unit_group_cleared.emit(group_id)
		return
	MatchSignals.unit_group_assigned.emit(group_id, assigned_units)


func _units_in_group(group_id: int):
	return Utils.Set.from_array(
		get_tree().get_nodes_in_group(_unit_group_names[group_id]).filter(
			func(unit): return _is_focusable_unit(unit)
		)
	)


func _is_focusable_unit(unit):
	return is_instance_valid(unit) and unit.is_inside_tree() and unit.is_in_group("controlled_units")


func _is_exact_current_selection(units):
	if units.empty():
		return false
	var selected_units = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit): return _is_focusable_unit(unit)
	)
	if selected_units.size() != units.size():
		return false
	for unit in selected_units:
		if not units.has(unit):
			return false
	return true


func _focus_group(units):
	if _camera == null or units.empty():
		return
	var pivot = Utils.Match.Unit.Movement.calculate_aabb_crowd_pivot_yless(units.to_array())
	_camera.set_position_safely(pivot)
