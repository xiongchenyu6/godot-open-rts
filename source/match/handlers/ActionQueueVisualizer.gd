extends Node3D

const Moving = preload("res://source/match/units/actions/Moving.gd")
const AttackMoving = preload("res://source/match/units/actions/AttackMoving.gd")
const Patrolling = preload("res://source/match/units/actions/Patrolling.gd")

const HEIGHT_OFFSET = 0.14
const MARKER_SIZE = 0.36
const QUEUED_COLOR = Color(1.0, 0.75, 0.18, 0.9)
const CURRENT_COLOR = Color(0.47, 0.98, 1.0, 0.92)

var _mesh = ImmediateMesh.new()
var _mesh_instance = MeshInstance3D.new()


func _ready():
	_mesh_instance.name = "QueuePathMesh"
	_mesh_instance.mesh = _mesh
	_mesh_instance.material_override = _make_material()
	add_child(_mesh_instance)


func _process(_delta):
	_redraw()


func get_path_points_for_unit(unit):
	if not _should_show_unit(unit):
		return []
	var targets = []
	var current_target = _target_position_for_action(unit.action)
	if current_target != null:
		targets.append(current_target)
	for queued_action in unit.action_queue:
		var queued_target = _target_position_for_action(queued_action)
		if queued_target != null:
			targets.append(queued_target)
	if targets.is_empty():
		return []
	var points = [unit.global_position_yless]
	points.append_array(targets)
	return points


func _redraw():
	_mesh.clear_surfaces()
	var paths = []
	for unit in get_tree().get_nodes_in_group("selected_units"):
		var points = get_path_points_for_unit(unit)
		if points.size() >= 2:
			paths.append(points)
	if paths.is_empty():
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for points in paths:
		_draw_path(points)
	_mesh.surface_end()


func _draw_path(points):
	for index in range(1, points.size()):
		var color = CURRENT_COLOR if index == 1 else QUEUED_COLOR
		_draw_line(_raised(points[index - 1]), _raised(points[index]), color)
		_draw_marker(points[index], color)


func _draw_marker(point, color):
	var center = _raised(point)
	var left = center + Vector3(-MARKER_SIZE, 0.0, 0.0)
	var right = center + Vector3(MARKER_SIZE, 0.0, 0.0)
	var top = center + Vector3(0.0, 0.0, -MARKER_SIZE)
	var bottom = center + Vector3(0.0, 0.0, MARKER_SIZE)
	_draw_line(left, top, color)
	_draw_line(top, right, color)
	_draw_line(right, bottom, color)
	_draw_line(bottom, left, color)


func _draw_line(from, to, color):
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(from)
	_mesh.surface_add_vertex(to)


func _target_position_for_action(action):
	if action is Moving or action is AttackMoving:
		return action._target_position * Vector3(1, 0, 1)
	if action is Patrolling:
		if action.has_method("get_current_target_position"):
			var current_target_position = action.get_current_target_position()
			if current_target_position != null:
				return current_target_position * Vector3(1, 0, 1)
		return action._patrol_position * Vector3(1, 0, 1)
	return null


func _should_show_unit(unit):
	return (
		unit != null
		and is_instance_valid(unit)
		and unit.is_in_group("controlled_units")
		and unit.is_in_group("selected_units")
		and "action_queue" in unit
	)


func _raised(point):
	return point * Vector3(1, 0, 1) + Vector3(0.0, HEIGHT_OFFSET, 0.0)


func _make_material():
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.no_depth_test = true
	return material
