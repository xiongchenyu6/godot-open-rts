extends Node3D

const Unit = preload("res://source/match/units/Unit.gd")
const Structure = preload("res://source/match/units/Structure.gd")
const Player = preload("res://source/match/players/Player.gd")
const Human = preload("res://source/match/players/human/Human.gd")
const ActionQueueVisualizer = preload("res://source/match/handlers/ActionQueueVisualizer.gd")

const CommandCenter = preload("res://source/match/units/CommandCenter.tscn")
const Drone = preload("res://source/match/units/Drone.tscn")
const Worker = preload("res://source/match/units/Worker.tscn")
const WEB_DIAGNOSTIC_REFRESH_INTERVAL_SECONDS = 0.25

@export var settings: Resource = null

var map_path = ""
var map:
	set = _set_map,
	get = _get_map
var visible_player = null:
	set = _set_visible_player
var visible_players = null:
	set = _ignore,
	get = _get_visible_players
var _web_diagnostic_label = null
var _web_diagnostic_elapsed = WEB_DIAGNOSTIC_REFRESH_INTERVAL_SECONDS

@onready var navigation = $Navigation
@onready var fog_of_war = $FogOfWar

@onready var _camera = $IsometricCamera3D
@onready var _players = $Players
@onready var _terrain = $Terrain


func _enter_tree():
	assert(settings != null, "match cannot start without settings, see examples in tests/manual/")
	assert(map != null, "match cannot start without map, see examples in tests/manual/")


func _ready():
	MatchSignals.setup_and_spawn_unit.connect(_setup_and_spawn_unit)
	_setup_web_diagnostic_hud()
	_setup_subsystems_dependent_on_map()
	_apply_web_performance_profile()
	_setup_players()
	_setup_player_units()
	_setup_action_queue_visualizer()
	visible_player = _initial_visible_player()
	_move_camera_to_initial_position()
	_stabilize_web_startup_view()
	if settings.visibility == settings.Visibility.FULL:
		fog_of_war.reveal()
	MatchSignals.match_started.emit()


func _apply_web_performance_profile():
	if not OS.has_feature("web"):
		return
	var directional_light = get_node_or_null("DirectionalLight3D")
	if directional_light != null:
		directional_light.shadow_enabled = false
	var depth_fog = get_node_or_null("Fog")
	if depth_fog != null:
		depth_fog.hide()


func _stabilize_web_startup_view():
	if not OS.has_feature("web"):
		return
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.current = true
	_camera.make_current()
	_camera.set_size_safely(15.0)
	var player = _get_human_player()
	if player == null:
		var participants = _participant_players()
		if participants.is_empty():
			return
		player = participants[0]
	_focus_web_camera_on_player_directly(player)
	print(_web_startup_diagnostic_line(player))


func _setup_web_diagnostic_hud():
	if not OS.has_feature("web") or get_node_or_null("WebDiagnosticHUD") != null:
		return
	var layer = CanvasLayer.new()
	layer.name = "WebDiagnosticHUD"
	layer.layer = 100
	add_child(layer)

	var margin = MarginContainer.new()
	margin.anchor_left = 0.5
	margin.anchor_right = 0.5
	margin.anchor_top = 0.0
	margin.anchor_bottom = 0.0
	margin.offset_left = -260.0
	margin.offset_top = 48.0
	margin.offset_right = 260.0
	margin.offset_bottom = 118.0
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	layer.add_child(margin)

	var panel = PanelContainer.new()
	margin.add_child(panel)

	var inner_margin = MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", 10)
	inner_margin.add_theme_constant_override("margin_top", 8)
	inner_margin.add_theme_constant_override("margin_right", 10)
	inner_margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(inner_margin)

	_web_diagnostic_label = Label.new()
	_web_diagnostic_label.custom_minimum_size = Vector2(500.0, 58.0)
	_web_diagnostic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_web_diagnostic_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_web_diagnostic_label.text = "Web diagnostics starting"
	inner_margin.add_child(_web_diagnostic_label)


func _process(delta):
	if _web_diagnostic_label == null:
		return
	_web_diagnostic_elapsed += delta
	if _web_diagnostic_elapsed < WEB_DIAGNOSTIC_REFRESH_INTERVAL_SECONDS:
		return
	_web_diagnostic_elapsed = 0.0
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var frame_ms = 1000.0 / maxf(1.0, fps)
	_web_diagnostic_label.text = "{0} FPS  {1} ms  WebGL 2\n{2}".format(
		["%0.1f" % fps, "%0.1f" % frame_ms, get_web_diagnostic_status()]
	)


func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.is_action_pressed("shift_selecting"):
			return
		MatchSignals.deselect_all_units.emit()


func _set_map(a_map):
	assert(get_node_or_null("Map") == null, "map already set")
	a_map.name = "Map"
	add_child(a_map)
	a_map.owner = self


func _ignore(_value):
	pass


func _get_map():
	return get_node_or_null("Map")


func _set_visible_player(player):
	if visible_player == player:
		return
	var previous_player = visible_player
	if settings == null or settings.visibility == settings.Visibility.PER_PLAYER:
		_conceal_player_units(previous_player)
		_reveal_player_units(player)
	visible_player = player
	MatchSignals.visible_player_changed.emit(previous_player, visible_player)


func _get_visible_players():
	if settings.visibility == settings.Visibility.PER_PLAYER:
		return get_tree().get_nodes_in_group("players").filter(
			func(player): return visible_player != null and player.is_allied_with(visible_player)
		)
	return get_tree().get_nodes_in_group("players")


func _initial_visible_player():
	var players = _participant_players()
	if players.is_empty():
		return null
	if settings.visible_player >= 0 and settings.visible_player < players.size():
		return players[settings.visible_player]
	return players[0]


func _setup_subsystems_dependent_on_map():
	_terrain.update_shape(map.find_child("Terrain").mesh)
	fog_of_war.resize(map.size)
	_recalculate_camera_bounding_planes(map.size)
	navigation.setup(map)


func _recalculate_camera_bounding_planes(map_size: Vector2):
	_camera.bounding_planes[1] = Plane(-1, 0, 0, -map_size.x)
	_camera.bounding_planes[3] = Plane(0, 0, -1, -map_size.y)


func _setup_players():
	assert(
		_players.get_children().is_empty() or settings.players.is_empty(),
		"players can be defined either in settings or in scene tree, not in both"
	)
	if _players.get_children().is_empty():
		_create_players_from_settings()
	_adopt_map_players()
	for node in _players.get_children():
		if node is Player:
			node.add_to_group("players")


func _adopt_map_players():
	var map_players = map.get_node_or_null("NeutralPlayers")
	if map_players == null:
		return
	for player in map_players.get_children().duplicate():
		if not player is Player:
			continue
		var preserved_transform = player.global_transform
		map_players.remove_child(player)
		_players.add_child(player)
		player.global_transform = preserved_transform


func _create_players_from_settings():
	for player_settings in settings.players:
		var player_scene = Constants.Match.Player.CONTROLLER_SCENES[player_settings.controller]
		var player = player_scene.instantiate()
		player.color = player_settings.color
		player.team_id = player_settings.team_id
		player.resource_a = settings.starting_resource_a
		player.resource_b = settings.starting_resource_b
		if player.has_method("apply_player_settings"):
			player.apply_player_settings(player_settings)
		if player_settings.spawn_index_offset > 0:
			for _i in range(player_settings.spawn_index_offset):
				_players.add_child(Node.new())
		_players.add_child(player)


func _setup_player_units():
	for player in _players.get_children():
		if not player is Player:
			continue
		var player_index = player.get_index()
		var predefined_units = player.get_children().filter(func(child): return child is Unit)
		if not predefined_units.is_empty():
			predefined_units.map(func(unit): _setup_unit_groups(unit, unit.player))
		elif "participates_in_match" in player and not player.participates_in_match:
			continue
		else:
			_spawn_player_units(
				player, map.find_child("SpawnPoints").get_child(player_index).global_transform
			)


func _setup_action_queue_visualizer():
	if get_node_or_null("Handlers/ActionQueueVisualizer") != null:
		return
	var visualizer = ActionQueueVisualizer.new()
	visualizer.name = "ActionQueueVisualizer"
	var handlers = get_node_or_null("Handlers")
	if handlers == null:
		add_child(visualizer)
	else:
		handlers.add_child(visualizer)


func _spawn_player_units(player, spawn_transform):
	_setup_and_spawn_unit(CommandCenter.instantiate(), spawn_transform, player, false)
	_setup_and_spawn_unit(
		Drone.instantiate(), spawn_transform.translated(Vector3(-2, 0, -2)), player
	)
	_setup_and_spawn_unit(
		Worker.instantiate(), spawn_transform.translated(Vector3(-3, 0, 3)), player
	)
	_setup_and_spawn_unit(
		Worker.instantiate(), spawn_transform.translated(Vector3(3, 0, 3)), player
	)


func _setup_and_spawn_unit(unit, a_transform, player, mark_structure_under_construction = true):
	_setup_unit_groups(unit, player)
	player.add_child(unit)
	unit.global_transform = a_transform
	if unit is Structure and mark_structure_under_construction:
		unit.mark_as_under_construction()
	MatchSignals.unit_spawned.emit(unit)


func _setup_unit_groups(unit, player):
	unit.add_to_group("units")
	var human_player = _get_human_player()
	if player == human_player:
		unit.add_to_group("controlled_units")
	elif human_player != null and player.is_enemy_with(human_player):
		unit.add_to_group("adversary_units")
	if player in visible_players:
		unit.add_to_group("revealed_units")


func _get_human_player():
	var human_players = get_tree().get_nodes_in_group("players").filter(
		func(player): return player is Human
	)
	assert(human_players.size() <= 1, "more than one human player is not allowed")
	if not human_players.is_empty():
		return human_players[0]
	return null


func _move_camera_to_initial_position():
	var human_player = _get_human_player()
	if human_player != null:
		_move_camera_to_player_units_crowd_pivot(human_player)
	else:
		_move_camera_to_player_units_crowd_pivot(_participant_players()[0])


func focus_camera_on_player(player):
	if player == null:
		return
	_move_camera_to_player_units_crowd_pivot(player)


func _participant_players():
	return get_tree().get_nodes_in_group("players").filter(
		func(player):
			return not ("participates_in_match" in player) or player.participates_in_match
	)


func _move_camera_to_player_units_crowd_pivot(player):
	var player_units = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit.player == player
	)
	assert(not player_units.is_empty(), "player must have at least one initial unit")
	var crowd_pivot = Utils.Match.Unit.Movement.calculate_aabb_crowd_pivot_yless(player_units)
	_camera.set_position_safely(crowd_pivot)


func _focus_web_camera_on_player_directly(player):
	var target_position = _player_camera_focus_position(player)
	_set_web_camera_ground_target(target_position)


func _player_camera_focus_position(player) -> Vector3:
	var player_units = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit.player == player
	)
	if not player_units.is_empty():
		return Utils.Match.Unit.Movement.calculate_aabb_crowd_pivot_yless(player_units)
	var spawn_points = map.find_child("SpawnPoints", true, false)
	if spawn_points != null and spawn_points.get_child_count() > 0 and player != null:
		var spawn_index = clampi(player.get_index(), 0, spawn_points.get_child_count() - 1)
		return spawn_points.get_child(spawn_index).global_position * Vector3(1, 0, 1)
	if map != null:
		return Vector3(map.size.x * 0.5, 0.0, map.size.y * 0.5)
	return Vector3.ZERO


func _set_web_camera_ground_target(target_position: Vector3):
	target_position = _clamp_camera_target_to_map(target_position)
	var pitch_radians = deg_to_rad(-55.0)
	var yaw_radians = deg_to_rad(_camera.default_y_rotation_degrees)
	var basis = Basis.from_euler(Vector3(pitch_radians, yaw_radians, 0.0))
	var forward = -basis.z.normalized()
	var camera_height = maxf(18.0, _camera.size * 0.9 + 10.0)
	var distance = camera_height / maxf(0.1, -forward.y)
	_camera.global_transform = Transform3D(basis, target_position - forward * distance)
	_camera.near = 0.05
	_camera.far = 300.0


func _clamp_camera_target_to_map(target_position: Vector3) -> Vector3:
	if map == null:
		return target_position
	var margin = minf(6.0, minf(map.size.x, map.size.y) * 0.25)
	return Vector3(
		clampf(target_position.x, margin, maxf(margin, map.size.x - margin)),
		target_position.y,
		clampf(target_position.z, margin, maxf(margin, map.size.y - margin))
	)


func get_web_diagnostic_status() -> String:
	var camera = get_viewport().get_camera_3d()
	var unit_count = get_tree().get_nodes_in_group("units").size()
	var player_count = get_tree().get_nodes_in_group("players").size()
	var terrain = map.find_child("Terrain", true, false) if map != null else null
	var terrain_visible = terrain != null and terrain.visible
	var camera_name = str(camera.name) if camera != null else "none"
	var camera_pos = camera.global_position if camera != null else Vector3.ZERO
	var camera_rot = camera.rotation_degrees if camera != null else Vector3.ZERO
	return "U:{0} P:{1} Map:{2} Terrain:{3}\nCam:{4} pos:{5} rot:{6}".format(
		[
			unit_count,
			player_count,
			str(map.size) if map != null else "none",
			str(terrain_visible),
			camera_name,
			_format_vector3(camera_pos),
			_format_vector3(camera_rot),
		]
	)


func _web_startup_diagnostic_line(player) -> String:
	return "WEB_STARTUP {0}".format([get_web_diagnostic_status().replace("\n", " ")])


func _format_vector3(value: Vector3) -> String:
	return "(%0.1f,%0.1f,%0.1f)" % [value.x, value.y, value.z]


func _reveal_player_units(player):
	if player == null:
		return
	for unit in get_tree().get_nodes_in_group("units").filter(
		func(a_unit): return a_unit.player == player
	):
		unit.add_to_group("revealed_units")


func _conceal_player_units(player):
	if player == null:
		return
	for unit in get_tree().get_nodes_in_group("units").filter(
		func(a_unit): return a_unit.player == player
	):
		unit.remove_from_group("revealed_units")
