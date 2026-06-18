extends Control

const ResourceA = preload("res://source/match/units/non-player/ResourceA.gd")
const ResourceB = preload("res://source/match/units/non-player/ResourceB.gd")

const SUPPLY_CRATE_PATH = "res://source/match/units/non-player/SupplyCrate.tscn"
const NEUTRAL_TECH_SCENE_PATHS = {
	"res://source/match/units/TechAirport.tscn": true,
	"res://source/match/units/TechBunker.tscn": true,
	"res://source/match/units/TechHospital.tscn": true,
	"res://source/match/units/TechOilDerrick.tscn": true,
	"res://source/match/units/TechRepairDepot.tscn": true,
}

const BACKGROUND_COLOR = Color(0.035, 0.055, 0.052, 1.0)
const GRID_COLOR = Color(0.17, 0.26, 0.23, 0.65)
const BORDER_COLOR = Color(0.48, 0.62, 0.54, 1.0)
const RESOURCE_A_COLOR = Color(0.25, 0.66, 1.0, 1.0)
const RESOURCE_B_COLOR = Color(1.0, 0.45, 0.24, 1.0)
const NEUTRAL_TECH_COLOR = Color(1.0, 0.86, 0.28, 1.0)
const SUPPLY_CRATE_COLOR = Color(0.42, 1.0, 0.52, 1.0)
const ROCK_COLOR = Color(0.34, 0.37, 0.34, 0.9)
const SPAWN_OUTLINE_COLOR = Color(0.02, 0.025, 0.02, 1.0)
const MAP_PADDING = 12.0
const GRID_DIVISIONS = 4

var _map_size = Vector2(1, 1)
var _spawn_points = []
var _resource_a_points = []
var _resource_b_points = []
var _decoration_points = []
var _neutral_tech_points = []
var _supply_crate_points = []


func set_map(map_path, map_definition):
	_map_size = Vector2(map_definition["size"])
	_spawn_points.clear()
	_resource_a_points.clear()
	_resource_b_points.clear()
	_decoration_points.clear()
	_neutral_tech_points.clear()
	_supply_crate_points.clear()

	var packed_map = load(map_path)
	if packed_map == null:
		queue_redraw()
		return

	var map = packed_map.instantiate()
	_extract_map_preview_data(map)
	map.free()
	queue_redraw()


func _draw():
	var map_rect = _map_rect()
	draw_rect(map_rect, BACKGROUND_COLOR, true)
	_draw_grid(map_rect)
	_draw_points(map_rect, _decoration_points, ROCK_COLOR, 4.0, false)
	_draw_points(map_rect, _resource_a_points, RESOURCE_A_COLOR, 3.5, false)
	_draw_points(map_rect, _resource_b_points, RESOURCE_B_COLOR, 4.5, false)
	_draw_squares(map_rect, _supply_crate_points, SUPPLY_CRATE_COLOR, 4.5)
	_draw_diamonds(map_rect, _neutral_tech_points, NEUTRAL_TECH_COLOR, 5.5)
	_draw_spawn_points(map_rect)
	draw_rect(map_rect, BORDER_COLOR, false, 2.0)


func _extract_map_preview_data(map):
	var spawn_points_parent = map.find_child("SpawnPoints")
	if spawn_points_parent != null:
		for spawn_point in spawn_points_parent.get_children():
			if spawn_point is Node3D:
				_spawn_points.append(_position_relative_to_map(spawn_point, map))

	var resources_parent = map.find_child("Resources")
	if resources_parent != null:
		var resources = resources_parent.find_children("*", "Area3D", true, false).filter(
			func(node): return node.is_in_group("resource_units")
		)
		for resource in resources:
			var point = _position_relative_to_map(resource, map)
			if resource is ResourceB:
				_resource_b_points.append(point)
			elif resource is ResourceA:
				_resource_a_points.append(point)

	var decorations_parent = map.find_child("Decorations")
	if decorations_parent != null:
		var decorations = decorations_parent.find_children("*", "StaticBody3D", true, false)
		for decoration in decorations:
			if decoration.is_in_group("terrain_navigation_input"):
				_decoration_points.append(_position_relative_to_map(decoration, map))

	for node in map.find_children("*", "Node", true, false):
		var scene_path = _scene_path_for_node(node)
		if scene_path == SUPPLY_CRATE_PATH:
			_supply_crate_points.append(_position_relative_to_map(node, map))
		elif NEUTRAL_TECH_SCENE_PATHS.has(scene_path):
			_neutral_tech_points.append(_position_relative_to_map(node, map))


func _map_rect():
	var available = Rect2(Vector2.ZERO, size).grow(-MAP_PADDING)
	var map_aspect = _map_size.x / maxf(_map_size.y, 1.0)
	var rect_size = available.size
	if rect_size.x / maxf(rect_size.y, 1.0) > map_aspect:
		rect_size.x = rect_size.y * map_aspect
	else:
		rect_size.y = rect_size.x / map_aspect
	var rect_position = available.position + (available.size - rect_size) * 0.5
	return Rect2(rect_position, rect_size)


func _draw_grid(map_rect):
	for line_index in range(1, GRID_DIVISIONS):
		var x = map_rect.position.x + map_rect.size.x * float(line_index) / GRID_DIVISIONS
		var y = map_rect.position.y + map_rect.size.y * float(line_index) / GRID_DIVISIONS
		draw_line(Vector2(x, map_rect.position.y), Vector2(x, map_rect.end.y), GRID_COLOR, 1.0)
		draw_line(Vector2(map_rect.position.x, y), Vector2(map_rect.end.x, y), GRID_COLOR, 1.0)


func _draw_points(map_rect, points, color, radius, outline):
	for point in points:
		var preview_point = _map_to_preview(map_rect, point)
		if outline:
			draw_circle(preview_point, radius + 2.0, SPAWN_OUTLINE_COLOR)
		draw_circle(preview_point, radius, color)


func _draw_squares(map_rect, points, color, half_size):
	for point in points:
		var preview_point = _map_to_preview(map_rect, point)
		var outline_rect = Rect2(
			preview_point - Vector2(half_size + 1.5, half_size + 1.5),
			Vector2((half_size + 1.5) * 2.0, (half_size + 1.5) * 2.0)
		)
		var rect = Rect2(
			preview_point - Vector2(half_size, half_size),
			Vector2(half_size * 2.0, half_size * 2.0)
		)
		draw_rect(outline_rect, SPAWN_OUTLINE_COLOR, true)
		draw_rect(rect, color, true)


func _draw_diamonds(map_rect, points, color, radius):
	for point in points:
		var preview_point = _map_to_preview(map_rect, point)
		var outline = PackedVector2Array([
			preview_point + Vector2(0.0, -(radius + 2.0)),
			preview_point + Vector2(radius + 2.0, 0.0),
			preview_point + Vector2(0.0, radius + 2.0),
			preview_point + Vector2(-(radius + 2.0), 0.0),
		])
		var diamond = PackedVector2Array([
			preview_point + Vector2(0.0, -radius),
			preview_point + Vector2(radius, 0.0),
			preview_point + Vector2(0.0, radius),
			preview_point + Vector2(-radius, 0.0),
		])
		draw_colored_polygon(outline, SPAWN_OUTLINE_COLOR)
		draw_colored_polygon(diamond, color)


func _draw_spawn_points(map_rect):
	for point_id in range(_spawn_points.size()):
		var color = Constants.Player.COLORS[point_id % Constants.Player.COLORS.size()]
		var preview_point = _map_to_preview(map_rect, _spawn_points[point_id])
		draw_circle(preview_point, 8.0, SPAWN_OUTLINE_COLOR)
		draw_circle(preview_point, 5.5, color)


func _map_to_preview(map_rect, map_point):
	return Vector2(
		map_rect.position.x + map_rect.size.x * map_point.x / maxf(_map_size.x, 1.0),
		map_rect.position.y + map_rect.size.y * map_point.y / maxf(_map_size.y, 1.0)
	)


func _position_relative_to_map(node, map):
	var transform = Transform3D.IDENTITY
	var current = node
	while current != null and current != map:
		if current is Node3D:
			transform = current.transform * transform
		current = current.get_parent()
	return Vector2(transform.origin.x, transform.origin.z)


func _scene_path_for_node(node):
	var script = node.get_script()
	if script == null:
		return ""
	return script.resource_path.replace(".gd", ".tscn")
