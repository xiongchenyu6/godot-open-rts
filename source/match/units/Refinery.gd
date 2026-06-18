extends "res://source/match/units/Structure.gd"

const OreHarvesterScene = preload("res://source/match/units/OreHarvester.tscn")

var _free_harvester_spawned = false


func _ready():
	constructed.connect(_on_constructed)
	await super()


func _on_constructed():
	if _free_harvester_spawned:
		return
	_free_harvester_spawned = true
	call_deferred("_spawn_free_harvester")


func _spawn_free_harvester():
	if not is_inside_tree():
		return
	var match = find_parent("Match")
	if match == null:
		return
	var harvester = OreHarvesterScene.instantiate()
	var spawn_direction = global_transform.basis.z * Vector3(1, 0, 1)
	if spawn_direction.length_squared() == 0.0:
		spawn_direction = Vector3(0, 0, 1)
	spawn_direction = spawn_direction.normalized()
	var placement_position = _find_harvester_spawn_position(harvester, spawn_direction, match)
	var target_transform = Transform3D(Basis(), placement_position).looking_at(
		placement_position + spawn_direction, Vector3.UP
	)
	MatchSignals.setup_and_spawn_unit.emit(harvester, target_transform, player)


func _find_harvester_spawn_position(harvester, spawn_direction, match):
	var navigation_map_rid = match.navigation.get_navigation_map_rid_by_domain(
		harvester.movement_domain
	)
	var base_position = global_position * Vector3(1, 0, 1)
	var right_direction = spawn_direction.rotated(Vector3.UP, PI * 0.5).normalized()
	var candidate_directions = [
		spawn_direction,
		-spawn_direction,
		right_direction,
		-right_direction,
		(spawn_direction + right_direction).normalized(),
		(spawn_direction - right_direction).normalized(),
		(-spawn_direction + right_direction).normalized(),
		(-spawn_direction - right_direction).normalized(),
	]
	var spacing = 0.35
	var start_distance = radius + harvester.radius + spacing
	var existing_units = get_tree().get_nodes_in_group("units") + get_tree().get_nodes_in_group(
		"resource_units"
	)
	for ring in range(4):
		var distance = start_distance + (harvester.radius + spacing) * ring
		for direction in candidate_directions:
			var candidate_position = base_position + direction * distance
			if (
				Utils.Match.Unit.Placement.validate_agent_placement_position(
					candidate_position, harvester.radius, existing_units, navigation_map_rid
				)
				== Utils.Match.Unit.Placement.VALID
			):
				return candidate_position
	return base_position + spawn_direction * start_distance
