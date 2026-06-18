extends Control

const MatchSettings = preload("res://source/data-model/MatchSettings.gd")
const PlayerSettings = preload("res://source/data-model/PlayerSettings.gd")
const LoadingScene = preload("res://source/main-menu/Loading.tscn")

const PLAYER_CONTROLLER_OPTIONS = [
	{"key": "PLAYER_NONE", "id": Constants.PlayerType.NONE},
	{"key": "PLAYER_HUMAN", "id": Constants.PlayerType.HUMAN},
	{"key": "PLAYER_AI_BEGINNER", "id": Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_BEGINNER},
	{"key": "PLAYER_AI_EASY", "id": Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_EASY},
	{"key": "PLAYER_AI_NORMAL", "id": Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI},
	{"key": "PLAYER_AI_HARD", "id": Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_HARD},
]
const DEFAULT_PLAYER_CONTROLLERS = {
	0: Constants.PlayerType.HUMAN,
	2: Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI,
}
const STARTING_RESOURCE_OPTIONS = [
	{"key": "STARTING_RESOURCES_LOW", "resource_a": 4, "resource_b": 2},
	{"key": "STARTING_RESOURCES_STANDARD", "resource_a": 8, "resource_b": 4},
	{"key": "STARTING_RESOURCES_HIGH", "resource_a": 16, "resource_b": 8},
	{"key": "STARTING_RESOURCES_RICH", "resource_a": 32, "resource_b": 16},
]
const DEFAULT_STARTING_RESOURCE_OPTION = 1
const MAX_TEAM_OPTIONS = 8
const RANDOM_MAP_PATH = "__random_map__"
const RANDOM_MAP_KEY = "RANDOM_MAP"
const DEFAULT_PANEL_SIZE = Vector2(840, 858)
const DEFAULT_CONTENT_WIDTH = 800
const DEFAULT_MAP_PREVIEW_SIZE = Vector2(260, 260)
const DEFAULT_MAP_DETAILS_HEIGHT = 70
const DEFAULT_OPERATION_SUMMARY_HEIGHT = 132
const DEFAULT_PLAYER_GRID_HEIGHT = 556
const COMPACT_LAYOUT_HEIGHT = 820
const COMPACT_PANEL_MARGIN = 8
const COMPACT_PANEL_MAX_WIDTH = 840
const COMPACT_MAP_PREVIEW_SIZE = Vector2(210, 150)
const COMPACT_MAP_DETAILS_HEIGHT = 48
const COMPACT_OPERATION_SUMMARY_HEIGHT = 78
const COMPACT_BUTTON_HEIGHT = 38
const COMPACT_MIN_PLAYER_GRID_HEIGHT = 240

var _map_paths = []
var _random = RandomNumberGenerator.new()
var initial_match_settings = null
var initial_map_path = ""

@onready var _start_button = find_child("StartButton")
@onready var _back_button = find_child("BackButton")
@onready var _map_list = find_child("MapList")
@onready var _map_details = find_child("MapDetailsLabel")
@onready var _map_preview = find_child("MapPreview")
@onready var _starting_resources_option = find_child("StartingResourcesOptionButton")
@onready var _operation_summary = find_child("OperationSummaryLabel")
@onready var _map_header_label = find_child("MapHeaderLabel")
@onready var _players_header_label = find_child("PlayersHeaderLabel")


func _ready():
	_random.randomize()
	_apply_responsive_layout()
	if not get_viewport().size_changed.is_connected(_apply_responsive_layout):
		get_viewport().size_changed.connect(_apply_responsive_layout)
	_localize_static_text()
	_setup_map_list()
	_setup_starting_resource_option_button()
	_setup_player_color_option_buttons()
	_setup_player_team_option_buttons()
	_setup_player_option_buttons()
	_refresh_player_slot_colors()
	if not _starting_resources_option.item_selected.is_connected(_on_starting_resources_selected):
		_starting_resources_option.item_selected.connect(_on_starting_resources_selected)
	var option_nodes = _get_player_option_nodes()
	for option_node_id in range(option_nodes.size()):
		option_nodes[option_node_id].item_selected.connect(_on_player_selected.bind(option_node_id))
	_apply_initial_or_default_setup()


func _apply_responsive_layout():
	_apply_responsive_layout_for_viewport(get_viewport_rect().size)


func _apply_responsive_layout_for_viewport(viewport_size):
	var panel = get_node_or_null("PanelContainer")
	if panel == null:
		return
	if viewport_size.y < COMPACT_LAYOUT_HEIGHT:
		_apply_compact_layout(panel, viewport_size)
	else:
		_apply_default_layout(panel)


func _apply_compact_layout(panel, viewport_size):
	var available_width = maxf(320.0, viewport_size.x - COMPACT_PANEL_MARGIN * 2.0)
	var panel_width = minf(available_width, COMPACT_PANEL_MAX_WIDTH)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.0
	panel.anchor_right = 0.5
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_END
	panel.offset_left = -panel_width * 0.5
	panel.offset_top = COMPACT_PANEL_MARGIN
	panel.offset_right = panel_width * 0.5
	panel.offset_bottom = -COMPACT_PANEL_MARGIN
	panel.custom_minimum_size = Vector2(panel_width, 0)
	_set_content_width(maxf(280.0, panel_width - 40.0))
	_set_control_minimum_size("MapPreview", COMPACT_MAP_PREVIEW_SIZE)
	_set_control_minimum_size("MapDetailsLabel", Vector2(0, COMPACT_MAP_DETAILS_HEIGHT))
	_set_control_minimum_size(
		"OperationSummaryLabel", Vector2(0, COMPACT_OPERATION_SUMMARY_HEIGHT)
	)
	_set_rich_text_fit_content("OperationSummaryLabel", false)
	var grid_height = clampf(
		viewport_size.y - 430.0,
		COMPACT_MIN_PLAYER_GRID_HEIGHT,
		DEFAULT_PLAYER_GRID_HEIGHT
	)
	_set_control_minimum_size("GridContainer", Vector2(0, grid_height))
	_set_control_minimum_size("StartButton", Vector2(0, COMPACT_BUTTON_HEIGHT))
	_set_control_minimum_size("BackButton", Vector2(0, COMPACT_BUTTON_HEIGHT))


func _apply_default_layout(panel):
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = -DEFAULT_PANEL_SIZE.x * 0.5
	panel.offset_top = -DEFAULT_PANEL_SIZE.y * 0.5
	panel.offset_right = DEFAULT_PANEL_SIZE.x * 0.5
	panel.offset_bottom = DEFAULT_PANEL_SIZE.y * 0.5
	panel.custom_minimum_size = Vector2.ZERO
	_set_content_width(DEFAULT_CONTENT_WIDTH)
	_set_control_minimum_size("MapPreview", DEFAULT_MAP_PREVIEW_SIZE)
	_set_control_minimum_size("MapDetailsLabel", Vector2(0, DEFAULT_MAP_DETAILS_HEIGHT))
	_set_control_minimum_size(
		"OperationSummaryLabel", Vector2(0, DEFAULT_OPERATION_SUMMARY_HEIGHT)
	)
	_set_rich_text_fit_content("OperationSummaryLabel", true)
	_set_control_minimum_size("GridContainer", Vector2(0, DEFAULT_PLAYER_GRID_HEIGHT))
	_set_control_minimum_size("StartButton", Vector2.ZERO)
	_set_control_minimum_size("BackButton", Vector2.ZERO)


func _set_content_width(width):
	var content = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer")
	if content != null:
		content.custom_minimum_size.x = width


func _set_control_minimum_size(node_name, minimum_size):
	var control = find_child(node_name, true, false)
	if control != null and control is Control:
		control.custom_minimum_size = minimum_size


func _set_rich_text_fit_content(node_name, enabled):
	var rich_text = find_child(node_name, true, false)
	if rich_text != null and rich_text is RichTextLabel:
		rich_text.fit_content = enabled


func _setup_map_list():
	var maps = Utils.Dict.items(Constants.Match.MAPS)
	maps.sort_custom(_compare_maps_for_menu)
	_map_paths = maps.map(func(map): return map[0])
	_map_list.clear()
	for map_path in _map_paths:
		_map_list.add_item(_map_display_name(map_path))
	_map_paths.append(RANDOM_MAP_PATH)
	_map_list.add_item(tr(RANDOM_MAP_KEY))
	_map_list.select(0)


func _localize_static_text():
	if _map_header_label != null:
		_map_header_label.text = tr("MAP")
	if _players_header_label != null:
		_players_header_label.text = tr("PLAYERS")
	if _start_button != null:
		_start_button.text = tr("START")
	if _back_button != null:
		_back_button.text = tr("BACK")


func _setup_player_option_buttons():
	for option_node in _get_player_option_nodes():
		option_node.clear()
		for option in PLAYER_CONTROLLER_OPTIONS:
			option_node.add_item(tr(option["key"]), option["id"])
		_select_player_controller(
			option_node,
			DEFAULT_PLAYER_CONTROLLERS.get(
				_player_option_node_index(option_node), Constants.PlayerType.NONE
			)
		)


func _setup_starting_resource_option_button():
	var starting_resources_label = find_child("StartingResourcesLabel")
	if starting_resources_label != null:
		starting_resources_label.text = tr("STARTING_RESOURCES")
	_starting_resources_option.clear()
	for option_id in range(STARTING_RESOURCE_OPTIONS.size()):
		_starting_resources_option.add_item(tr(STARTING_RESOURCE_OPTIONS[option_id]["key"]), option_id)
	_starting_resources_option.select(DEFAULT_STARTING_RESOURCE_OPTION)
	_refresh_operation_summary()


func _create_match_settings():
	var match_settings = MatchSettings.new()
	var starting_resources = _selected_starting_resources()
	match_settings.starting_resource_a = starting_resources["resource_a"]
	match_settings.starting_resource_b = starting_resources["resource_b"]

	var option_nodes = _get_player_option_nodes().filter(func(option_node): return option_node.visible)
	var spawn_index_offset = 0
	for option_node_id in range(option_nodes.size()):
		var player_controller = _selected_player_controller(option_nodes[option_node_id])
		if player_controller != Constants.PlayerType.NONE:
			var player_settings = PlayerSettings.new()
			player_settings.controller = player_controller
			player_settings.color = _selected_player_color(
				_player_option_node_index(option_nodes[option_node_id])
			)
			player_settings.team_id = _selected_player_team(
				_player_option_node_index(option_nodes[option_node_id])
			)
			player_settings.spawn_index_offset = spawn_index_offset
			match_settings.players.append(player_settings)
			spawn_index_offset = 0
		else:
			spawn_index_offset += 1

	match_settings.visible_player = -1
	for player_id in range(match_settings.players.size()):
		var player = match_settings.players[player_id]
		if player.controller == Constants.PlayerType.HUMAN:
			match_settings.visible_player = player_id
	if match_settings.visible_player == -1:
		match_settings.visibility = match_settings.Visibility.ALL_PLAYERS

	return match_settings


func _get_selected_map_path():
	var selected_map_path = _selected_map_list_path()
	if _is_random_map_path(selected_map_path):
		return _pick_random_map_path_for_current_slots()
	return selected_map_path


func _selected_starting_resources():
	var selected_id = _starting_resources_option.get_selected_id()
	if selected_id < 0 or selected_id >= STARTING_RESOURCE_OPTIONS.size():
		selected_id = DEFAULT_STARTING_RESOURCE_OPTION
	return STARTING_RESOURCE_OPTIONS[selected_id]


func _apply_initial_or_default_setup():
	var map_index = _map_index_for_initial_map()
	_map_list.select(map_index)
	_on_map_list_item_selected(map_index)
	if initial_match_settings != null:
		_apply_match_settings(initial_match_settings)


func _map_index_for_initial_map():
	if initial_map_path == "":
		return 0
	for map_index in range(_map_paths.size()):
		if _map_paths[map_index] == initial_map_path:
			return map_index
	return 0


func _apply_match_settings(match_settings):
	_select_starting_resources_option(
		match_settings.starting_resource_a,
		match_settings.starting_resource_b
	)
	for option_node in _get_visible_player_option_nodes():
		_select_player_controller(option_node, Constants.PlayerType.NONE)
	var option_nodes = _get_player_option_nodes()
	var slot_index = 0
	for player_settings in match_settings.players:
		slot_index += int(player_settings.spawn_index_offset)
		if slot_index >= option_nodes.size():
			break
		var option_node = option_nodes[slot_index]
		if option_node.visible:
			_select_player_controller(option_node, player_settings.controller)
			_select_player_color_by_value(slot_index, player_settings.color)
			_select_player_team_by_id(slot_index, player_settings.team_id)
		slot_index += 1
	_enforce_restored_single_human()
	_ensure_minimum_visible_player_controllers()
	_update_start_button_state()
	_refresh_player_slot_colors()
	_refresh_operation_summary()


func _select_starting_resources_option(resource_a, resource_b):
	for option_id in range(STARTING_RESOURCE_OPTIONS.size()):
		var option = STARTING_RESOURCE_OPTIONS[option_id]
		if option["resource_a"] == resource_a and option["resource_b"] == resource_b:
			_starting_resources_option.select(option_id)
			_refresh_operation_summary()
			return
	_starting_resources_option.select(DEFAULT_STARTING_RESOURCE_OPTION)
	_refresh_operation_summary()


func _select_player_color_by_value(player_slot_id, color):
	var color_option_node = find_child("GridContainer").find_child(
		"ColorOptionButton{0}".format([player_slot_id]), false, false
	)
	if color_option_node != null:
		_select_player_color(
			color_option_node,
			_player_color_id_for_color(color, player_slot_id)
		)


func _select_player_team_by_id(player_slot_id, team_id):
	var team_option_node = find_child("GridContainer").find_child(
		"TeamOptionButton{0}".format([player_slot_id]), false, false
	)
	if team_option_node != null:
		_select_player_team(team_option_node, max(0, int(team_id)))


func _player_color_id_for_color(color, fallback_slot_id):
	for color_id in range(Constants.Player.COLORS.size()):
		if Constants.Player.COLORS[color_id].is_equal_approx(color):
			return color_id
	return fallback_slot_id % Constants.Player.COLORS.size()


func _enforce_restored_single_human():
	var first_human_slot_id = -1
	for option_node in _get_visible_player_option_nodes():
		if _selected_player_controller(option_node) != Constants.PlayerType.HUMAN:
			continue
		var player_slot_id = _player_option_node_index(option_node)
		if first_human_slot_id == -1:
			first_human_slot_id = player_slot_id
		else:
			_select_player_controller(option_node, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)


func _on_start_button_pressed():
	_update_start_button_state()
	if _start_button.disabled:
		return
	hide()
	var new_scene = LoadingScene.instantiate()
	new_scene.match_settings = _create_match_settings()
	new_scene.map_path = _get_selected_map_path()
	get_parent().add_child(new_scene)
	get_tree().current_scene = new_scene
	queue_free()


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://source/main-menu/Main.tscn")


func _align_player_controls_visibility_to_map(map):
	var option_nodes = _get_player_option_nodes()
	var label_nodes = _get_player_label_nodes()
	var color_option_nodes = _get_player_color_option_nodes()
	var team_option_nodes = _get_player_team_option_nodes()
	assert(option_nodes.size() == label_nodes.size())
	assert(option_nodes.size() == color_option_nodes.size())
	assert(option_nodes.size() == team_option_nodes.size())
	for node_id in range(option_nodes.size()):
		option_nodes[node_id].visible = node_id < map["players"]
		label_nodes[node_id].visible = node_id < map["players"]
		color_option_nodes[node_id].visible = node_id < map["players"]
		team_option_nodes[node_id].visible = node_id < map["players"]


func _on_player_selected(_selected_option_id, selected_player_id):
	var option_nodes = _get_player_option_nodes()
	var selected_player_controller = _selected_player_controller(option_nodes[selected_player_id])
	if selected_player_controller == Constants.PlayerType.HUMAN:
		_enforce_single_visible_human(selected_player_id)
	_update_start_button_state()
	_refresh_operation_summary()


func _on_map_list_item_selected(index):
	if _is_random_map_path(_map_paths[index]):
		_on_random_map_selected()
		return
	var map = Constants.Match.MAPS[_map_paths[index]]
	_set_map_details(str(map["players"]), "{0}x{1}".format([map["size"].x, map["size"].y]))
	if _map_preview != null:
		_map_preview.set_map(_map_paths[index], map)
	_align_player_controls_visibility_to_map(map)
	_ensure_minimum_visible_player_controllers()
	_update_start_button_state()
	_refresh_operation_summary()


func _on_random_map_selected():
	var preview_map_path = _largest_map_path()
	var preview_map = Constants.Match.MAPS[preview_map_path]
	var player_range = _map_player_range()
	_set_map_details(
		"{0}-{1}".format([player_range.x, player_range.y]),
		tr("MAP_DETAILS_RANDOM"),
		str(Constants.Match.MAPS.size())
	)
	if _map_preview != null:
		_map_preview.set_map(preview_map_path, preview_map)
	_align_player_controls_visibility_to_map({"players": player_range.y})
	_ensure_minimum_visible_player_controllers()
	_update_start_button_state()
	_refresh_operation_summary()


func _set_map_details(players_text, size_text, map_count_text = ""):
	var detail_lines = [
		"[u]{0}:[/u] {1}".format([tr("MAP_DETAILS_PLAYERS"), players_text])
	]
	if map_count_text != "":
		detail_lines.append("[u]{0}:[/u] {1}".format([tr("MAP_DETAILS_MAPS"), map_count_text]))
	detail_lines.append("[u]{0}:[/u] {1}".format([tr("MAP_DETAILS_SIZE"), size_text]))
	_map_details.text = "\n".join(detail_lines)


func _refresh_operation_summary():
	if _operation_summary == null or _map_list == null or _map_paths.is_empty():
		return
	var starting_resources = _selected_starting_resources()
	var active_player_count = _active_visible_player_controller_count()
	var active_team_count = _active_visible_team_count()
	var lines = [
		"[b]{0}[/b]".format([tr("OPERATION_SUMMARY_TITLE")]),
		"[u]{0}:[/u] {1}".format([tr("OPERATION_SUMMARY_MAP"), _selected_map_display_name()]),
		"[u]{0}:[/u] {1}    [u]{2}:[/u] {3}".format(
			[
				tr("OPERATION_SUMMARY_PLAYERS"),
				active_player_count,
				tr("OPERATION_SUMMARY_TEAMS"),
				active_team_count,
			]
		),
		"[u]{0}:[/u] A {1} / B {2}".format(
			[
				tr("OPERATION_SUMMARY_RESOURCES"),
				starting_resources["resource_a"],
				starting_resources["resource_b"],
			]
		),
		"[u]{0}:[/u] {1}".format(
			[tr("OPERATION_SUMMARY_OBJECTIVE"), tr("OPERATION_SUMMARY_OBJECTIVE_ELIMINATION")]
		),
		"[u]{0}:[/u] {1}".format([tr("OPERATION_SUMMARY_FORCES"), _active_force_summary()]),
	]
	if _start_button != null and _start_button.disabled:
		lines.append("[color=#ff705f]{0}[/color]".format([tr("OPERATION_SUMMARY_NOT_READY")]))
	else:
		lines.append("[color=#7cff89]{0}[/color]".format([tr("OPERATION_SUMMARY_READY")]))
	_operation_summary.text = "\n".join(lines)


func _selected_map_display_name():
	var selected_map_path = _selected_map_list_path()
	if _is_random_map_path(selected_map_path):
		return tr("RANDOM_MAP")
	return _map_display_name(selected_map_path)


func _map_display_name(map_path):
	var map_definition = Constants.Match.MAPS.get(map_path, {})
	var name_key = str(map_definition.get("name_key", ""))
	if name_key != "":
		return tr(name_key)
	return str(map_definition.get("name", map_path))


func _active_force_summary():
	var force_parts = []
	for option_node in _get_visible_player_option_nodes():
		var controller = _selected_player_controller(option_node)
		if controller == Constants.PlayerType.NONE:
			continue
		var player_slot_id = _player_option_node_index(option_node)
		force_parts.append(
			"{0} {1} {2}".format(
				[
					tr("OPERATION_SUMMARY_SLOT").format([player_slot_id + 1]),
					_controller_label(controller),
					tr("TEAM_SHORT").format([_selected_player_team(player_slot_id) + 1]),
				]
			)
		)
	if force_parts.is_empty():
		return tr("OPERATION_SUMMARY_EMPTY")
	return ", ".join(force_parts)


func _controller_label(controller):
	for option in PLAYER_CONTROLLER_OPTIONS:
		if option["id"] == controller:
			return tr(option["key"])
	return tr("PLAYER_NONE")


func _compare_maps_for_menu(map_a, map_b):
	if map_a[1]["players"] != map_b[1]["players"]:
		return map_a[1]["players"] < map_b[1]["players"]
	var area_a = map_a[1]["size"].x * map_a[1]["size"].y
	var area_b = map_b[1]["size"].x * map_b[1]["size"].y
	if area_a != area_b:
		return area_a < area_b
	var name_a = str(map_a[1].get("name_key", map_a[1]["name"]))
	var name_b = str(map_b[1].get("name_key", map_b[1]["name"]))
	return tr(name_a) < tr(name_b)


func _selected_map_list_path():
	var selected_items = _map_list.get_selected_items()
	if selected_items.is_empty():
		return _map_paths[0]
	return _map_paths[selected_items[0]]


func _is_random_map_path(map_path):
	return map_path == RANDOM_MAP_PATH


func _pick_random_map_path_for_current_slots():
	var candidates = _random_map_candidates_for_current_slots()
	if candidates.is_empty():
		return _largest_map_path()
	return candidates[_random.randi_range(0, candidates.size() - 1)]


func _random_map_candidates_for_current_slots():
	var required_player_slots = _required_player_slots_for_current_setup()
	return _actual_map_paths().filter(
		func(map_path): return Constants.Match.MAPS[map_path]["players"] >= required_player_slots
	)


func _required_player_slots_for_current_setup():
	var highest_active_slot = -1
	for option_node in _get_player_option_nodes():
		if _selected_player_controller(option_node) == Constants.PlayerType.NONE:
			continue
		highest_active_slot = maxi(highest_active_slot, _player_option_node_index(option_node))
	return max(2, highest_active_slot + 1)


func _actual_map_paths():
	return _map_paths.filter(func(map_path): return not _is_random_map_path(map_path))


func _largest_map_path():
	var largest_map_path = _actual_map_paths()[0]
	for map_path in _actual_map_paths():
		var player_count = Constants.Match.MAPS[map_path]["players"]
		var largest_player_count = Constants.Match.MAPS[largest_map_path]["players"]
		var map_size = Constants.Match.MAPS[map_path]["size"]
		var largest_size = Constants.Match.MAPS[largest_map_path]["size"]
		var map_area = map_size.x * map_size.y
		var largest_area = largest_size.x * largest_size.y
		if player_count > largest_player_count or (
			player_count == largest_player_count and map_area > largest_area
		):
			largest_map_path = map_path
	return largest_map_path


func _map_player_range():
	var min_players = Constants.Match.MAPS[_actual_map_paths()[0]]["players"]
	var max_players = min_players
	for map_path in _actual_map_paths():
		var player_count = Constants.Match.MAPS[map_path]["players"]
		min_players = mini(min_players, player_count)
		max_players = maxi(max_players, player_count)
	return Vector2i(min_players, max_players)



func _get_player_option_nodes():
	var option_nodes = _get_numbered_grid_children("OptionButton")
	option_nodes.sort_custom(
		func(option_a, option_b):
			return _player_option_node_index(option_a) < _player_option_node_index(option_b)
	)
	return option_nodes


func _get_player_label_nodes():
	var label_nodes = _get_numbered_grid_children("Label")
	label_nodes.sort_custom(
		func(label_a, label_b):
			return _player_label_node_index(label_a) < _player_label_node_index(label_b)
	)
	return label_nodes


func _get_player_color_option_nodes():
	var color_option_nodes = _get_numbered_grid_children("ColorOptionButton")
	color_option_nodes.sort_custom(
		func(option_a, option_b):
			return _player_color_option_node_index(option_a) < _player_color_option_node_index(option_b)
	)
	return color_option_nodes


func _get_player_team_option_nodes():
	var team_option_nodes = _get_numbered_grid_children("TeamOptionButton")
	team_option_nodes.sort_custom(
		func(option_a, option_b):
			return _player_team_option_node_index(option_a) < _player_team_option_node_index(option_b)
	)
	return team_option_nodes


func _setup_player_color_option_buttons():
	var grid = find_child("GridContainer")
	var option_nodes = _get_player_option_nodes()
	grid.columns = 4
	for option_node in option_nodes:
		var player_slot_id = _player_option_node_index(option_node)
		var color_option_node = grid.find_child(
			"ColorOptionButton{0}".format([player_slot_id]), false, false
		)
		if color_option_node == null:
			color_option_node = OptionButton.new()
			color_option_node.name = "ColorOptionButton{0}".format([player_slot_id])
			color_option_node.focus_mode = Control.FOCUS_NONE
			color_option_node.custom_minimum_size = Vector2(74, 0)
			color_option_node.size_flags_horizontal = Control.SIZE_SHRINK_END
			grid.add_child(color_option_node)
		grid.move_child(color_option_node, option_node.get_index() + 1)
		_setup_color_option_button(color_option_node, player_slot_id)


func _setup_player_team_option_buttons():
	var grid = find_child("GridContainer")
	var color_option_nodes = _get_player_color_option_nodes()
	grid.columns = 4
	for color_option_node in color_option_nodes:
		var player_slot_id = _player_color_option_node_index(color_option_node)
		var team_option_node = grid.find_child(
			"TeamOptionButton{0}".format([player_slot_id]), false, false
		)
		if team_option_node == null:
			team_option_node = OptionButton.new()
			team_option_node.name = "TeamOptionButton{0}".format([player_slot_id])
			team_option_node.focus_mode = Control.FOCUS_NONE
			team_option_node.custom_minimum_size = Vector2(72, 0)
			team_option_node.size_flags_horizontal = Control.SIZE_SHRINK_END
			grid.add_child(team_option_node)
		grid.move_child(team_option_node, color_option_node.get_index() + 1)
		_setup_team_option_button(team_option_node, player_slot_id)


func _setup_color_option_button(color_option_node, player_slot_id):
	color_option_node.clear()
	for color_id in range(Constants.Player.COLORS.size()):
		color_option_node.add_item(str(color_id + 1), color_id)
	_select_player_color(color_option_node, player_slot_id % Constants.Player.COLORS.size())
	color_option_node.item_selected.connect(_on_player_color_selected.bind(player_slot_id))


func _setup_team_option_button(team_option_node, player_slot_id):
	team_option_node.clear()
	for team_id in range(MAX_TEAM_OPTIONS):
		team_option_node.add_item(tr("TEAM_SHORT").format([team_id + 1]), team_id)
	_select_player_team(team_option_node, player_slot_id % MAX_TEAM_OPTIONS)
	if not team_option_node.item_selected.is_connected(_on_player_team_selected):
		team_option_node.item_selected.connect(_on_player_team_selected.bind(player_slot_id))


func _refresh_player_slot_colors():
	for label_node in _get_player_label_nodes():
		var player_slot_id = _player_label_node_index(label_node)
		var player_color = _selected_player_color(player_slot_id)
		label_node.add_theme_color_override("font_color", player_color)
		label_node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	for color_option_node in _get_player_color_option_nodes():
		_refresh_color_option_button(color_option_node)


func _get_visible_player_option_nodes():
	return _get_player_option_nodes().filter(func(option_node): return option_node.visible)


func _get_numbered_grid_children(prefix):
	var nodes = []
	for node in find_child("GridContainer").get_children():
		var node_name = str(node.name)
		if not node_name.begins_with(prefix):
			continue
		if not node_name.substr(prefix.length()).is_valid_int():
			continue
		nodes.append(node)
	return nodes


func _player_option_node_index(option_node):
	return _numbered_node_index(option_node, "OptionButton")


func _player_label_node_index(label_node):
	return _numbered_node_index(label_node, "Label")


func _player_color_option_node_index(color_option_node):
	return _numbered_node_index(color_option_node, "ColorOptionButton")


func _player_team_option_node_index(team_option_node):
	return _numbered_node_index(team_option_node, "TeamOptionButton")


func _numbered_node_index(node, prefix):
	return int(str(node.name).substr(prefix.length()))


func _selected_player_controller(option_node):
	var selected_id = option_node.get_selected_id()
	if selected_id == -1:
		return Constants.PlayerType.NONE
	return selected_id


func _select_player_controller(option_node, player_controller):
	for item_index in range(option_node.get_item_count()):
		if option_node.get_item_id(item_index) == player_controller:
			option_node.select(item_index)
			_refresh_operation_summary()
			return
	option_node.select(0)
	_refresh_operation_summary()


func _selected_player_color(player_slot_id):
	var color_option_node = find_child("GridContainer").find_child(
		"ColorOptionButton{0}".format([player_slot_id]), false, false
	)
	if color_option_node == null:
		return Constants.Player.COLORS[player_slot_id % Constants.Player.COLORS.size()]
	var selected_id = color_option_node.get_selected_id()
	if selected_id < 0 or selected_id >= Constants.Player.COLORS.size():
		selected_id = player_slot_id % Constants.Player.COLORS.size()
	return Constants.Player.COLORS[selected_id]


func _selected_player_team(player_slot_id):
	var team_option_node = find_child("GridContainer").find_child(
		"TeamOptionButton{0}".format([player_slot_id]), false, false
	)
	if team_option_node == null:
		return player_slot_id % MAX_TEAM_OPTIONS
	var selected_id = team_option_node.get_selected_id()
	if selected_id < 0 or selected_id >= MAX_TEAM_OPTIONS:
		selected_id = player_slot_id % MAX_TEAM_OPTIONS
	return selected_id


func _select_player_color(color_option_node, color_id):
	for item_index in range(color_option_node.get_item_count()):
		if color_option_node.get_item_id(item_index) == color_id:
			color_option_node.select(item_index)
			_refresh_color_option_button(color_option_node)
			_refresh_player_slot_colors()
			_refresh_operation_summary()
			return
	color_option_node.select(0)
	_refresh_color_option_button(color_option_node)
	_refresh_player_slot_colors()
	_refresh_operation_summary()


func _select_player_team(team_option_node, team_id):
	for item_index in range(team_option_node.get_item_count()):
		if team_option_node.get_item_id(item_index) == team_id:
			team_option_node.select(item_index)
			_refresh_operation_summary()
			return
	team_option_node.select(0)
	_refresh_operation_summary()


func _refresh_color_option_button(color_option_node):
	var color = _selected_player_color(_player_color_option_node_index(color_option_node))
	var normal_style = _color_button_style(color, 0.26)
	var hover_style = _color_button_style(color, 0.18)
	var pressed_style = _color_button_style(color, 0.08)
	color_option_node.add_theme_stylebox_override("normal", normal_style)
	color_option_node.add_theme_stylebox_override("hover", hover_style)
	color_option_node.add_theme_stylebox_override("pressed", pressed_style)
	color_option_node.add_theme_stylebox_override("focus", hover_style)
	color_option_node.add_theme_color_override("font_color", _contrast_text_color(color))
	color_option_node.add_theme_color_override("font_hover_color", _contrast_text_color(color))
	color_option_node.add_theme_color_override("font_pressed_color", _contrast_text_color(color))
	color_option_node.tooltip_text = tr("PLAYER_COLOR_TOOLTIP").format(
		[color_option_node.get_selected_id() + 1]
	)


func _color_button_style(color, darken_amount):
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(darken_amount)
	style.border_color = color.lightened(0.18)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _contrast_text_color(color):
	var luminance = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
	return Color(0.02, 0.03, 0.03, 1.0) if luminance > 0.55 else Color.WHITE


func _on_player_color_selected(_selected_option_id, _player_slot_id):
	_refresh_player_slot_colors()
	_refresh_operation_summary()


func _on_player_team_selected(_selected_option_id, _player_slot_id):
	_update_start_button_state()
	_refresh_operation_summary()


func _on_starting_resources_selected(_selected_option_id):
	_refresh_operation_summary()


func _ensure_minimum_visible_player_controllers():
	var visible_options = _get_visible_player_option_nodes()
	if visible_options.is_empty():
		return
	if _active_visible_player_controller_count() == 0:
		_select_player_controller(visible_options[0], Constants.PlayerType.HUMAN)
	if _active_visible_player_controller_count() < 2 and visible_options.size() >= 2:
		for option_node in visible_options:
			if _selected_player_controller(option_node) == Constants.PlayerType.NONE:
				_select_player_controller(option_node, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)
				return


func _active_visible_player_controller_count():
	return _get_visible_player_option_nodes().filter(
		func(option_node): return _selected_player_controller(option_node) != Constants.PlayerType.NONE
	).size()


func _enforce_single_visible_human(selected_player_id):
	var option_nodes = _get_visible_player_option_nodes()
	for option_node in option_nodes:
		if (
			_player_option_node_index(option_node) != selected_player_id
			and _selected_player_controller(option_node) == Constants.PlayerType.HUMAN
		):
			_select_player_controller(option_node, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)


func _update_start_button_state():
	var active_player_count = _active_visible_player_controller_count()
	var active_team_count = _active_visible_team_count()
	_start_button.disabled = active_player_count < 2 or active_team_count < 2
	if active_player_count < 2:
		_start_button.tooltip_text = tr("START_DISABLED_NEEDS_PLAYERS")
	elif active_team_count < 2:
		_start_button.tooltip_text = tr("START_DISABLED_NEEDS_OPPONENT")
	else:
		_start_button.tooltip_text = ""
	_refresh_operation_summary()


func _active_visible_team_count():
	var active_team_ids = {}
	for option_node in _get_visible_player_option_nodes():
		if _selected_player_controller(option_node) == Constants.PlayerType.NONE:
			continue
		active_team_ids[_selected_player_team(_player_option_node_index(option_node))] = true
	return active_team_ids.size()
