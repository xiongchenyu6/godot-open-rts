extends Node3D

var _static_obstacles = []

@onready var air = find_child("Air")
@onready var terrain = find_child("Terrain")

@onready var _match = find_parent("Match")


func _ready():
	await _match.ready
	_setup_static_obstacles()


func get_navigation_map_rid_by_domain(domain):
	if domain == Constants.Match.Navigation.Domain.AIR:
		return air.navigation_map_rid if _air_navigation_map_is_usable() else terrain.navigation_map_rid
	return terrain.navigation_map_rid


func setup(map):
	assert(_static_obstacles.is_empty())
	air.bake(map)
	terrain.bake(map)
	_setup_static_obstacles()


func _setup_static_obstacles():
	if not _static_obstacles.is_empty():
		return
	for domain in [
		Constants.Match.Navigation.Domain.AIR, Constants.Match.Navigation.Domain.TERRAIN
	]:
		var obstacle = NavigationServer3D.obstacle_create()
		NavigationServer3D.obstacle_set_map(obstacle, get_navigation_map_rid_by_domain(domain))
		var obstacle_y = {
			Constants.Match.Navigation.Domain.AIR: Constants.Match.Air.Y,
			Constants.Match.Navigation.Domain.TERRAIN: 0,
		}[domain]
		NavigationServer3D.obstacle_set_position(obstacle, Vector3(0, obstacle_y, 0))
		var obstacle_vertices = [
			Vector3(0, 0, 0),
			Vector3(0, 0, _match.map.size.y),
			Vector3(_match.map.size.x, 0, _match.map.size.y),
			Vector3(_match.map.size.x, 0, 0),
		]
		NavigationServer3D.obstacle_set_vertices(obstacle, obstacle_vertices)
		NavigationServer3D.obstacle_set_avoidance_enabled(obstacle, true)
		_static_obstacles.append(obstacle)


func _air_navigation_map_is_usable():
	var probe = Vector3(_match.map.size.x * 0.5, Constants.Match.Air.Y, _match.map.size.y * 0.5)
	var closest = NavigationServer3D.map_get_closest_point(air.navigation_map_rid, probe)
	return not (closest * Vector3(1, 0, 1)).is_equal_approx(Vector3.ZERO)
