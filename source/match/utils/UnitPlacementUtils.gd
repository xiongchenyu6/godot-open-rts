enum { VALID, COLLIDES_WITH_AGENT, NOT_NAVIGABLE }

const MAX_RADIAL_PLACEMENT_RINGS = 256


static func find_valid_position_radially(
	starting_position: Vector3, radius: float, navigation_map_rid: RID, scene_tree
):
	return find_valid_position_radially_yet_skip_starting_radius(
		starting_position, 0.0, radius, 0.0, Vector3(0, 0, 1), true, navigation_map_rid, scene_tree
	)


static func find_valid_position_radially_yet_skip_starting_radius(
	starting_position: Vector3,
	starting_radius: float,
	radius: float,
	spacing: float,
	starting_direction: Vector3,
	shuffle: bool,
	navigation_map_rid: RID,
	scene_tree
):
	var starting_position_yless = starting_position * Vector3(1, 0, 1)
	var units = (
		scene_tree.get_nodes_in_group("units") + scene_tree.get_nodes_in_group("resource_units")
	)
	var starting_distance = (
		0 if is_zero_approx(starting_radius) else starting_radius + radius + spacing
	)
	var starting_offset = 1 if is_zero_approx(starting_radius) else 0
	if (
		is_zero_approx(starting_radius)
		and _is_agent_placement_position_valid(
			starting_position_yless, radius, units, navigation_map_rid
		)
	):
		return starting_position_yless
	for ring_number in range(starting_offset, MAX_RADIAL_PLACEMENT_RINGS):
		var ring_distance_from_starting_position: float = (
			starting_distance + radius * 0.5 * ring_number
		)
		if is_zero_approx(ring_distance_from_starting_position):
			continue
		var rotation_angle_rad = asin(
			clampf((radius + spacing) / ring_distance_from_starting_position, -1.0, 1.0)
		)
		if is_zero_approx(rotation_angle_rad):
			continue
		var radial_positions = _radial_positions_for_ring(
			starting_position_yless,
			starting_direction,
			ring_distance_from_starting_position,
			rotation_angle_rad,
			shuffle
		)
		for radial_position in radial_positions:
			if _is_agent_placement_position_valid(
				radial_position, radius, units, navigation_map_rid
			):
				return radial_position
	return Vector3.INF


static func _radial_positions_for_ring(
	starting_position_yless,
	starting_direction,
	ring_distance_from_starting_position,
	rotation_angle_rad,
	shuffle
):
	var rotation_angles = []
	var next_rotation_angle_rad = 0.0
	while next_rotation_angle_rad <= PI * 2.0 - rotation_angle_rad:
		rotation_angles.append(next_rotation_angle_rad)
		next_rotation_angle_rad += rotation_angle_rad
	if shuffle:
		rotation_angles.shuffle()
	else:
		rotation_angles.sort_custom(
			func(a, b):
				var a_distance = _absolute_wrapped_angle(a)
				var b_distance = _absolute_wrapped_angle(b)
				if not is_equal_approx(a_distance, b_distance):
					return a_distance < b_distance
				return a < b
		)
	var radial_positions = []
	for rotation_angle in rotation_angles:
		radial_positions.append(
			(
				starting_position_yless
				+ (
					starting_direction.normalized().rotated(Vector3.UP, rotation_angle)
					* ring_distance_from_starting_position
				)
			)
		)
	return radial_positions


static func _absolute_wrapped_angle(angle):
	return minf(absf(angle), absf(PI * 2.0 - angle))


static func validate_agent_placement_position(position, radius, existing_units, navigation_map_rid):
	for existing_unit in existing_units:
		if (
			(existing_unit.global_position * Vector3(1, 0, 1)).distance_to(
				position * Vector3(1, 0, 1)
			)
			<= existing_unit.radius + radius
		):
			return COLLIDES_WITH_AGENT
	var points_expected_to_be_navigable = []
	for x in [-1, 0, 1]:
		for z in [-1, 0, 1]:
			points_expected_to_be_navigable.append(
				position + Vector3(x, 0, z).normalized() * radius
			)
	for point_expected_to_be_navigable in points_expected_to_be_navigable:
		var point_yless = point_expected_to_be_navigable * Vector3(1, 0, 1)
		var closest_point_yless = (
			NavigationServer3D.map_get_closest_point(
				navigation_map_rid, point_expected_to_be_navigable
			)
			* Vector3(1, 0, 1)
		)
		if (
			point_yless.distance_to(closest_point_yless)
			> Constants.Match.Terrain.Navmesh.CELL_SIZE
		):
			return NOT_NAVIGABLE
	return VALID


static func is_within_base_construction_radius(player, position, structure_radius):
	return nearest_base_construction_anchor(player, position, structure_radius) != null


static func nearest_base_construction_anchor(player, position, structure_radius):
	var anchors = _base_construction_anchors(player)
	if anchors.is_empty():
		return null
	var best_anchor = null
	var best_distance = INF
	var position_yless = position * Vector3(1, 0, 1)
	for anchor in anchors:
		var anchor_position_yless = anchor.global_position * Vector3(1, 0, 1)
		var distance = anchor_position_yless.distance_to(position_yless)
		var allowed_distance = (
			anchor.radius
			+ structure_radius
			+ Constants.Match.Units.BASE_CONSTRUCTION_RADIUS_M
		)
		if distance > allowed_distance:
			continue
		if distance < best_distance:
			best_distance = distance
			best_anchor = anchor
	return best_anchor


static func _is_agent_placement_position_valid(
	position, radius, existing_units, navigation_map_rid
):
	return (
		validate_agent_placement_position(position, radius, existing_units, navigation_map_rid)
		== VALID
	)


static func _base_construction_anchors(player):
	if player == null:
		return []
	var anchors = []
	for child in player.get_children():
		if not child.has_method("is_constructed"):
			continue
		if not "radius" in child:
			continue
		if not child.is_inside_tree() or not child.is_constructed():
			continue
		anchors.append(child)
	return anchors
