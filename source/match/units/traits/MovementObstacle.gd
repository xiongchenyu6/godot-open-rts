extends NavigationObstacle3D

@export var domain = Constants.Match.Navigation.Domain.TERRAIN
@export var path_height_offset = 0.0

@onready var _match = find_parent("Match")
@onready var _unit = get_parent()


func _ready():
	await get_tree().process_frame  # wait for navigation to be operational
	set_navigation_map(_match.navigation.get_navigation_map_rid_by_domain(domain))
	_align_unit_position_to_navigation()
	_affect_navigation_if_needed()


func _exit_tree():
	if affect_navigation_mesh:
		remove_from_group(Constants.Match.Navigation.DOMAIN_TO_GROUP_MAPPING[domain])
		MatchSignals.schedule_navigation_rebake.emit(domain)


func _align_unit_position_to_navigation():
	var initial_position = get_parent().global_transform.origin
	var closest_point = NavigationServer3D.map_get_closest_point(
		get_navigation_map(), initial_position
	)
	if _is_navigation_point_valid(initial_position, closest_point):
		_unit.global_transform.origin = closest_point - Vector3(0, path_height_offset, 0)
	else:
		_unit.global_transform.origin = initial_position


func _affect_navigation_if_needed():
	if affect_navigation_mesh:
		add_to_group(Constants.Match.Navigation.DOMAIN_TO_GROUP_MAPPING[domain])
		MatchSignals.schedule_navigation_rebake.emit(domain)


func _is_navigation_point_valid(query_position, closest_point):
	if not (
		is_finite(closest_point.x) and is_finite(closest_point.y) and is_finite(closest_point.z)
	):
		return false
	var query_position_yless = query_position * Vector3(1, 0, 1)
	var closest_point_yless = closest_point * Vector3(1, 0, 1)
	return not (
		closest_point_yless.is_equal_approx(Vector3.ZERO)
		and not query_position_yless.is_equal_approx(Vector3.ZERO)
	)
