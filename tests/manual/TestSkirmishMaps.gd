extends Node

const MatchScene = preload("res://source/match/Match.tscn")

const FOUR_CORNERS_MAP_PATH = "res://source/match/maps/FourCorners.tscn"
const TECH_DIVIDE_MAP_PATH = "res://source/match/maps/TechDivide.tscn"
const BIG_ARENA_MAP_PATH = "res://source/match/maps/BigArena.tscn"
const SUPPLY_CRATE_PATH = "res://source/match/units/non-player/SupplyCrate.tscn"
const TECH_AIRPORT_PATH = "res://source/match/units/TechAirport.tscn"
const TECH_BUNKER_PATH = "res://source/match/units/TechBunker.tscn"
const TECH_HOSPITAL_PATH = "res://source/match/units/TechHospital.tscn"
const TECH_OIL_DERRICK_PATH = "res://source/match/units/TechOilDerrick.tscn"
const TECH_REPAIR_DEPOT_PATH = "res://source/match/units/TechRepairDepot.tscn"

const STRATEGIC_MAP_FEATURES = {
	FOUR_CORNERS_MAP_PATH:
	{
		"crates": 4,
		"neutral_tech":
		{
			TECH_AIRPORT_PATH: 2,
			TECH_BUNKER_PATH: 2,
			TECH_HOSPITAL_PATH: 2,
			TECH_OIL_DERRICK_PATH: 2,
			TECH_REPAIR_DEPOT_PATH: 2,
		},
	},
	TECH_DIVIDE_MAP_PATH:
	{
		"crates": 6,
		"neutral_tech":
		{
			TECH_AIRPORT_PATH: 2,
			TECH_BUNKER_PATH: 4,
			TECH_HOSPITAL_PATH: 2,
			TECH_OIL_DERRICK_PATH: 4,
			TECH_REPAIR_DEPOT_PATH: 2,
		},
	},
	BIG_ARENA_MAP_PATH:
	{
		"crates": 5,
		"neutral_tech":
		{
			TECH_AIRPORT_PATH: 2,
			TECH_BUNKER_PATH: 4,
			TECH_HOSPITAL_PATH: 2,
			TECH_OIL_DERRICK_PATH: 4,
			TECH_REPAIR_DEPOT_PATH: 2,
		},
	},
}


func _ready():
	assert(Constants.Match.MAPS.size() >= 4, "skirmish should expose multiple strategic maps")
	_assert_navigation_inputs_are_collision_based()
	for map_path in Constants.Match.MAPS.keys():
		_assert_map_definition(map_path, Constants.Match.MAPS[map_path])
	get_tree().quit()


func _assert_navigation_inputs_are_collision_based():
	var match_scene = MatchScene.instantiate()
	var terrain_body = match_scene.get_node("Terrain")
	assert(
		terrain_body is StaticBody3D,
		"match terrain navigation input should come from a collision body"
	)
	assert(
		terrain_body.is_in_group("terrain_navigation_input"),
		"match terrain collision body should feed terrain navmesh baking"
	)
	assert(
		terrain_body.collision_layer & 2 != 0,
		"match terrain collision body should be visible to the terrain navmesh collision mask"
	)
	var terrain_navigation_region = match_scene.get_node("Navigation/Terrain/NavigationRegion3D")
	assert(
		terrain_navigation_region.navigation_mesh.geometry_source_group_name
		== &"terrain_navigation_input",
		"terrain navmesh should read the collision-backed terrain input group"
	)
	match_scene.free()


func _assert_map_definition(map_path, map_definition):
	var packed_map = load(map_path)
	assert(packed_map != null, "{0} should load".format([map_path]))
	var map = packed_map.instantiate()
	var visual_terrain = map.get_node("Geometry/Terrain")
	assert(
		not visual_terrain.is_in_group("terrain_navigation_input"),
		"{0} visual terrain should not force runtime RenderingServer mesh parsing".format([map_path])
	)

	var expected_size = map_definition["size"]
	assert(
		int(map.size.x) == expected_size.x and int(map.size.y) == expected_size.y,
		"{0} should advertise its actual map size".format([map_path])
	)
	var spawn_points = map.find_child("SpawnPoints").get_children()
	assert(
		spawn_points.size() == map_definition["players"],
		"{0} should have one spawn point per player slot".format([map_path])
	)
	for spawn_point in spawn_points:
		_assert_position_inside_map(map_path, map, _position_relative_to_map(spawn_point, map))

	var resources = map.find_child("Resources").find_children("*", "Area3D", true, false).filter(
		func(node): return node.is_in_group("resource_units")
	)
	assert(
		resources.size() >= map_definition["players"] * 3,
		"{0} should provide enough starting resources for all player slots".format([map_path])
	)
	for resource in resources:
		_assert_position_inside_map(map_path, map, _position_relative_to_map(resource, map))

	if STRATEGIC_MAP_FEATURES.has(map_path):
		_assert_strategic_map_features(map_path, map, STRATEGIC_MAP_FEATURES[map_path])

	map.free()


func _assert_strategic_map_features(map_path, map, expected):
	var neutral_players = map.find_child("NeutralPlayers", true, false)
	assert(neutral_players != null, "{0} should expose neutral tech ownership".format([map_path]))
	var neutral_tech = neutral_players.find_child("NeutralTech", true, false)
	assert(neutral_tech != null, "{0} should include a neutral tech player".format([map_path]))
	assert(
		"participates_in_match" in neutral_tech and not neutral_tech.participates_in_match,
		"{0} neutral tech player should not count toward victory".format([map_path])
	)

	for scene_path in expected["neutral_tech"]:
		var matching_nodes = _nodes_with_scene_path(neutral_tech, scene_path)
		assert(
			matching_nodes.size() == expected["neutral_tech"][scene_path],
			"{0} should include {1} neutral {2} nodes".format(
				[map_path, expected["neutral_tech"][scene_path], scene_path]
			)
		)
		for node in matching_nodes:
			_assert_position_inside_map(map_path, map, _position_relative_to_map(node, map))

	var crates = _nodes_with_scene_path(map.find_child("SupplyCrates", true, false), SUPPLY_CRATE_PATH)
	assert(
		crates.size() == expected["crates"],
		"{0} should include {1} strategic supply crates".format([map_path, expected["crates"]])
	)
	for crate in crates:
		_assert_position_inside_map(map_path, map, _position_relative_to_map(crate, map))


func _nodes_with_scene_path(root, scene_path):
	if root == null:
		return []
	var nodes = []
	for node in root.find_children("*", "Node", true, false):
		var script = node.get_script()
		if script != null and script.resource_path.replace(".gd", ".tscn") == scene_path:
			nodes.append(node)
	return nodes


func _assert_position_inside_map(map_path, map, position):
	assert(
		position.x >= 0.0
		and position.z >= 0.0
		and position.x <= map.size.x
		and position.z <= map.size.y,
		"{0} has a map object outside the playable bounds".format([map_path])
	)


func _position_relative_to_map(node, map):
	var transform = Transform3D.IDENTITY
	var current = node
	while current != null and current != map:
		if current is Node3D:
			transform = current.transform * transform
		current = current.get_parent()
	return transform.origin
