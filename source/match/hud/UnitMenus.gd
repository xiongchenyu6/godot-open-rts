extends PanelContainer

const VehicleFactory = preload("res://source/match/units/VehicleFactory.gd")
const AircraftFactory = preload("res://source/match/units/AircraftFactory.gd")
const Barracks = preload("res://source/match/units/Barracks.gd")
const CommandCenter = preload("res://source/match/units/CommandCenter.gd")
const Worker = preload("res://source/match/units/Worker.gd")
const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const CommandButtonStatus = preload("res://source/match/hud/unit-menus/CommandButtonStatus.gd")

const COMMAND_BUTTON_SIZE_MAX = Vector2(128, 128)
const COMMAND_BUTTON_SIZE_MIN = Vector2(96, 96)
const COMMAND_PANEL_COLUMNS = 6
const COMMAND_PANEL_ROWS_MAX = 6
const COMMAND_PANEL_ROWS_MIN = 5
const COMMAND_PANEL_VERTICAL_RESERVED_SPACE = 100.0
const COMMAND_PANEL_HORIZONTAL_RESERVED_SPACE = 160.0
const COMMAND_PANEL_SLOT_COUNT_MAX = COMMAND_PANEL_COLUMNS * COMMAND_PANEL_ROWS_MAX
const COMMAND_DETAILS_PANEL_NAME = "CommandDetailsPanel"
const COMMAND_DETAILS_TITLE_NAME = "CommandDetailsTitle"
const COMMAND_DETAILS_BODY_NAME = "CommandDetailsBody"
const COMMAND_DETAILS_META_CONNECTED = "command_details_connected"
const COMMAND_DETAILS_HEIGHT = 74.0
const COMMAND_DETAILS_MARGIN = 8.0
const COMMAND_DETAILS_BG = Color(0.025, 0.045, 0.055, 0.96)
const COMMAND_DETAILS_BORDER = Color(0.34, 0.52, 0.58, 1.0)
const COMMAND_DETAILS_TITLE_COLOR = Color(0.84, 0.97, 0.93, 1.0)
const COMMAND_DETAILS_BODY_COLOR = Color(0.58, 0.73, 0.72, 1.0)

@onready var _command_panel_viewport = find_child("CommandPanelViewport")
@onready var _background_grid = find_child("BackgroundGrid")
@onready var _menu_scroll = find_child("MenuScroll")
@onready var _menu_stack = find_child("MenuStack")
@onready var _generic_menu = find_child("GenericMenu")
@onready var _command_center_menu = find_child("CommandCenterMenu")
@onready var _vehicle_factory_menu = find_child("VehicleFactoryMenu")
@onready var _aircraft_factory_menu = find_child("AircraftFactoryMenu")
@onready var _barracks_menu = find_child("BarracksMenu")
@onready var _worker_menu = find_child("WorkerMenu")

var _tracked_player = null
var _tracked_production_queues = []
var _command_button_size = COMMAND_BUTTON_SIZE_MAX
var _command_panel_rows = COMMAND_PANEL_ROWS_MAX
var _command_panel_size = COMMAND_BUTTON_SIZE_MAX * Vector2(
	COMMAND_PANEL_COLUMNS, COMMAND_PANEL_ROWS_MAX
)
var _active_menu = null
var _layout_initialized = false
var _details_panel = null
var _details_title = null
var _details_body = null
var _details_button = null


func _ready():
	_ensure_command_details_panel()
	_setup_command_panel_draw_order()
	apply_command_panel_layout_for_viewport(get_viewport().get_visible_rect().size)
	get_viewport().size_changed.connect(
		func(): apply_command_panel_layout_for_viewport(get_viewport().get_visible_rect().size)
	)
	_reset_menus()
	MatchSignals.unit_selected.connect(func(_unit): _reset_menus())
	MatchSignals.unit_deselected.connect(func(_unit): _reset_menus())
	MatchSignals.unit_spawned.connect(func(_unit): _reset_menus())
	MatchSignals.unit_construction_finished.connect(func(_unit): _reset_menus())
	MatchSignals.unit_died.connect(func(_unit): _reset_menus())
	MatchSignals.unit_sold.connect(func(_unit): _reset_menus())
	MatchSignals.unit_captured.connect(func(_unit, _previous_player, _new_player): _reset_menus())


func _setup_command_panel_draw_order():
	_background_grid.z_index = 0
	_menu_scroll.z_index = 20
	_menu_stack.z_index = 20


func apply_command_panel_layout_for_viewport(viewport_size):
	var next_panel_rows = _command_panel_rows_for_viewport(viewport_size)
	var next_button_size = _command_button_size_for_viewport(viewport_size, next_panel_rows)
	if (
		_layout_initialized
		and next_button_size == _command_button_size
		and next_panel_rows == _command_panel_rows
	):
		return
	_command_button_size = next_button_size
	_command_panel_rows = next_panel_rows
	_command_panel_size = _command_button_size * Vector2(
		COMMAND_PANEL_COLUMNS, _command_panel_rows
	)
	_setup_command_panel_slots()
	_layout_command_details_panel()
	_layout_initialized = true
	if _active_menu != null:
		_sync_menu_scroll(_active_menu)


func get_command_button_size():
	return _command_button_size


func get_command_panel_size():
	return _command_panel_size


func get_command_panel_rows():
	return _command_panel_rows


func _command_panel_rows_for_viewport(viewport_size):
	if viewport_size.y <= 0.0:
		return COMMAND_PANEL_ROWS_MAX
	var height_needed_for_full_panel = (
		COMMAND_BUTTON_SIZE_MAX.y * COMMAND_PANEL_ROWS_MAX
		+ COMMAND_PANEL_VERTICAL_RESERVED_SPACE
	)
	if viewport_size.y >= height_needed_for_full_panel:
		return COMMAND_PANEL_ROWS_MAX
	return COMMAND_PANEL_ROWS_MIN


func _command_button_size_for_viewport(viewport_size, panel_rows):
	if viewport_size == Vector2.ZERO:
		return COMMAND_BUTTON_SIZE_MAX
	var width_limited_size = floorf(
		(viewport_size.x - COMMAND_PANEL_HORIZONTAL_RESERVED_SPACE) / COMMAND_PANEL_COLUMNS
	)
	var height_limited_size = floorf(
		(viewport_size.y - COMMAND_PANEL_VERTICAL_RESERVED_SPACE) / panel_rows
	)
	var next_button_size = minf(
		COMMAND_BUTTON_SIZE_MAX.x,
		minf(width_limited_size, height_limited_size)
	)
	next_button_size = maxf(COMMAND_BUTTON_SIZE_MIN.x, next_button_size)
	return Vector2(next_button_size, next_button_size)


func _setup_command_panel_slots():
	_command_panel_viewport.custom_minimum_size = _command_panel_size
	_background_grid.columns = COMMAND_PANEL_COLUMNS
	for menu in [
		_command_center_menu,
		_vehicle_factory_menu,
		_aircraft_factory_menu,
		_barracks_menu,
		_worker_menu,
		_generic_menu
	]:
		menu.columns = COMMAND_PANEL_COLUMNS
		_apply_menu_button_size(menu)
	var slots = _background_grid.find_children("*", "Panel", true, false)
	while slots.size() < COMMAND_PANEL_SLOT_COUNT_MAX:
		var slot = Panel.new()
		slot.custom_minimum_size = _command_button_size
		_background_grid.add_child(slot)
		slots.append(slot)
	var visible_slot_count = COMMAND_PANEL_COLUMNS * _command_panel_rows
	for index in range(slots.size()):
		var slot = slots[index]
		slot.visible = index < visible_slot_count
		slot.custom_minimum_size = _command_button_size


func _unhandled_key_input(event):
	for menu in [
		_command_center_menu,
		_vehicle_factory_menu,
		_aircraft_factory_menu,
		_barracks_menu,
		_worker_menu,
		_generic_menu
	]:
		if CommandButtonHotkeys.try_activate(menu, event):
			get_viewport().set_input_as_handled()
			return


func _reset_menus():
	_hide_all_menus()
	if _try_showing_any_menu():
		show()
	else:
		_track_player_resources(null)
		_track_production_queue(null)
		hide()


func _hide_all_menus():
	_active_menu = null
	_hide_command_details()
	_generic_menu.hide()
	_command_center_menu.hide()
	_vehicle_factory_menu.hide()
	_aircraft_factory_menu.hide()
	_barracks_menu.hide()
	_worker_menu.hide()
	_command_center_menu.units = []
	_vehicle_factory_menu.units = []
	_aircraft_factory_menu.units = []
	_barracks_menu.units = []


func _try_showing_any_menu():
	var selected_controlled_units = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit): return unit.is_in_group("controlled_units")
	)
	if _try_show_production_menu_for_selection(
		selected_controlled_units, CommandCenter, _command_center_menu
	):
		return true
	if _try_show_production_menu_for_selection(
		selected_controlled_units, VehicleFactory, _vehicle_factory_menu
	):
		return true
	if _try_show_production_menu_for_selection(
		selected_controlled_units, AircraftFactory, _aircraft_factory_menu
	):
		return true
	if _try_show_production_menu_for_selection(
		selected_controlled_units, Barracks, _barracks_menu
	):
		return true
	if (
		selected_controlled_units.size() == 1
		and selected_controlled_units[0] is Worker
		and selected_controlled_units[0].can_construct_structures()
	):
		_track_player_resources(selected_controlled_units[0].player)
		_track_production_queues([])
		_worker_menu.unit = selected_controlled_units[0]
		_worker_menu.refresh()
		_show_menu(_worker_menu)
		return true
	if selected_controlled_units.size() > 0:
		_track_player_resources(selected_controlled_units[0].player)
		_track_production_queues([])
		_generic_menu.units = selected_controlled_units
		_generic_menu.refresh()
		_show_menu(_generic_menu)
		return true
	return false


func _try_show_production_menu_for_selection(selected_controlled_units, structure_script, menu):
	var production_units = _selected_constructed_units_of_type(
		selected_controlled_units, structure_script
	)
	if production_units.is_empty():
		return false
	_track_player_resources(production_units[0].player)
	_track_production_queues(
		production_units.map(func(production_unit): return production_unit.production_queue)
	)
	menu.unit = production_units[0]
	menu.units = production_units
	menu.refresh()
	_show_menu(menu)
	return true


func _selected_constructed_units_of_type(selected_controlled_units, structure_script):
	if selected_controlled_units.is_empty():
		return []
	var production_units = []
	for selected_unit in selected_controlled_units:
		if (
			not is_instance_valid(selected_unit)
			or not selected_unit.is_inside_tree()
			or not structure_script.instance_has(selected_unit)
			or not selected_unit.is_constructed()
		):
			return []
		production_units.append(selected_unit)
	production_units.sort_custom(func(a, b): return str(a.get_path()) < str(b.get_path()))
	return production_units


func _show_menu(menu):
	_active_menu = menu
	_apply_menu_button_size(menu)
	_sync_menu_scroll(menu)
	menu.show()
	_hide_command_details()


func _sync_menu_scroll(menu):
	var menu_minimum_size = menu.get_combined_minimum_size()
	var content_size = Vector2(
		max(_command_panel_size.x, menu_minimum_size.x),
		max(_command_panel_size.y, menu_minimum_size.y)
	)
	_menu_stack.custom_minimum_size = content_size
	_menu_stack.size = content_size
	menu.position = Vector2.ZERO
	menu.custom_minimum_size = content_size
	menu.size = content_size
	_menu_scroll.scroll_horizontal = 0
	_menu_scroll.scroll_vertical = 0


func _apply_menu_button_size(menu):
	for child in menu.get_children():
		if child is Control:
			child.custom_minimum_size = _command_button_size
		if child is Button:
			_connect_command_button_details(child)


func _ensure_command_details_panel():
	if _details_panel != null and is_instance_valid(_details_panel):
		return
	_details_panel = PanelContainer.new()
	_details_panel.name = COMMAND_DETAILS_PANEL_NAME
	_details_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_details_panel.visible = false
	_details_panel.z_index = 150
	_details_panel.add_theme_stylebox_override(
		"panel", _details_stylebox(COMMAND_DETAILS_BG, COMMAND_DETAILS_BORDER)
	)
	_command_panel_viewport.add_child(_details_panel)

	var margin_container = MarginContainer.new()
	margin_container.name = "CommandDetailsMargin"
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_top", 7)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_bottom", 7)
	_details_panel.add_child(margin_container)

	var detail_stack = VBoxContainer.new()
	detail_stack.name = "CommandDetailsStack"
	detail_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_stack.add_theme_constant_override("separation", 2)
	margin_container.add_child(detail_stack)

	_details_title = Label.new()
	_details_title.name = COMMAND_DETAILS_TITLE_NAME
	_details_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_details_title.clip_text = true
	_details_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_details_title.add_theme_font_size_override("font_size", 16)
	_details_title.add_theme_color_override("font_color", COMMAND_DETAILS_TITLE_COLOR)
	_details_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_details_title.add_theme_constant_override("shadow_offset_x", 1)
	_details_title.add_theme_constant_override("shadow_offset_y", 1)
	detail_stack.add_child(_details_title)

	_details_body = Label.new()
	_details_body.name = COMMAND_DETAILS_BODY_NAME
	_details_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_details_body.clip_text = true
	_details_body.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_details_body.add_theme_font_size_override("font_size", 11)
	_details_body.add_theme_color_override("font_color", COMMAND_DETAILS_BODY_COLOR)
	_details_body.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_details_body.add_theme_constant_override("shadow_offset_x", 1)
	_details_body.add_theme_constant_override("shadow_offset_y", 1)
	detail_stack.add_child(_details_body)
	_layout_command_details_panel()


func _layout_command_details_panel():
	if _details_panel == null:
		return
	_details_panel.anchor_left = 0.0
	_details_panel.anchor_top = 0.0
	_details_panel.anchor_right = 0.0
	_details_panel.anchor_bottom = 0.0
	_details_panel.position = Vector2(0, -COMMAND_DETAILS_HEIGHT - COMMAND_DETAILS_MARGIN)
	_details_panel.size = Vector2(_command_panel_size.x, COMMAND_DETAILS_HEIGHT)
	_details_panel.custom_minimum_size = Vector2(_command_panel_size.x, COMMAND_DETAILS_HEIGHT)
	_details_panel.offset_left = 0.0
	_details_panel.offset_top = -COMMAND_DETAILS_HEIGHT - COMMAND_DETAILS_MARGIN
	_details_panel.offset_right = _command_panel_size.x
	_details_panel.offset_bottom = -COMMAND_DETAILS_MARGIN


func _connect_command_button_details(button):
	if button.get_meta(COMMAND_DETAILS_META_CONNECTED, false):
		return
	button.mouse_entered.connect(func(): _show_command_details(button))
	button.focus_entered.connect(func(): _show_command_details(button))
	button.mouse_exited.connect(func(): _hide_command_details_for(button))
	button.focus_exited.connect(func(): _hide_command_details_for(button))
	button.set_meta(COMMAND_DETAILS_META_CONNECTED, true)


func _show_command_details(button):
	if button == null:
		return
	_ensure_command_details_panel()
	var tooltip_text = button.tooltip_text.strip_edges()
	if tooltip_text == "":
		_hide_command_details()
		return
	var lines = _non_empty_lines(tooltip_text)
	if lines.is_empty():
		_hide_command_details()
		return
	_details_button = button
	_details_title.text = _command_detail_title(button, lines[0])
	_details_body.text = _command_detail_body(lines)
	_details_panel.visible = (
		_details_title.text.strip_edges() != "" or _details_body.text.strip_edges() != ""
	)
	_layout_command_details_panel()


func _hide_command_details_for(button):
	if _details_button == button:
		_hide_command_details()


func _hide_command_details():
	_details_button = null
	if _details_panel != null:
		_details_panel.visible = false


func _show_menu_summary():
	if _active_menu == null:
		_hide_command_details()
		return
	_ensure_command_details_panel()
	_details_button = null
	_details_title.text = _menu_summary_title(_active_menu)
	_details_body.text = _menu_summary_body(_active_menu)
	_details_panel.visible = true
	_layout_command_details_panel()


func _menu_summary_title(menu):
	if menu == _command_center_menu:
		return tr("CC")
	if menu == _vehicle_factory_menu:
		return tr("VEHICLE_FACTORY")
	if menu == _aircraft_factory_menu:
		return tr("AIRCRAFT_FACTORY")
	if menu == _barracks_menu:
		return tr("BARRACKS")
	if menu == _worker_menu:
		return tr("WORKER")
	return tr("COMMAND_PANEL_ORDERS")


func _menu_summary_body(menu):
	var parts = [_resource_summary(), _power_summary()]
	var producer_count = _menu_producer_count(menu)
	if producer_count > 0:
		parts.append("{0} {1}".format([tr("COMMAND_PANEL_PRODUCERS"), producer_count]))
	var queue_summary = _queue_summary()
	if queue_summary != "":
		parts.append(queue_summary)
	parts.append("{0} {1}".format([tr("COMMAND_PANEL_COMMANDS"), _menu_command_count(menu)]))
	return " | ".join(parts)


func _resource_summary():
	var resource_a = 0
	var resource_b = 0
	if _tracked_player != null and is_instance_valid(_tracked_player):
		if "resource_a" in _tracked_player:
			resource_a = int(_tracked_player.resource_a)
		if "resource_b" in _tracked_player:
			resource_b = int(_tracked_player.resource_b)
	return "A {0}  B {1}".format([resource_a, resource_b])


func _power_summary():
	var supply = 0
	var drain = 0
	if _tracked_player != null and is_instance_valid(_tracked_player):
		if _tracked_player.has_method("get_power_supply"):
			supply = int(_tracked_player.get_power_supply())
		if _tracked_player.has_method("get_power_drain"):
			drain = int(_tracked_player.get_power_drain())
	return "{0} {1}/{2}".format([tr("POWER"), supply, drain])


func _queue_summary():
	var queue_used = 0
	var queue_capacity = 0
	for queue in _tracked_production_queues:
		if queue == null or not is_instance_valid(queue) or not queue.has_method("size"):
			continue
		queue_used += int(queue.size())
		queue_capacity += Constants.Match.Units.PRODUCTION_QUEUE_LIMIT
	if queue_capacity <= 0:
		return ""
	return "{0} {1}/{2}".format([tr("COMMAND_PANEL_QUEUE"), queue_used, queue_capacity])


func _menu_producer_count(menu):
	if "units" in menu:
		return menu.units.size()
	if "unit" in menu and menu.unit != null:
		return 1
	return 0


func _menu_command_count(menu):
	var count = 0
	for child in menu.get_children():
		if child is Button and child.visible:
			count += 1
	return count


func _command_detail_title(button, first_line):
	if first_line.contains(" - "):
		return first_line
	var command_name = str(button.get_meta(CommandButtonStatus.META_NAME_TEXT, "")).strip_edges()
	if command_name != "":
		return "{0}: {1}".format([command_name, first_line])
	return first_line


func _command_detail_body(lines):
	var detail_lines = []
	for index in range(1, lines.size()):
		var line = lines[index]
		if line.begins_with(tr("COMMAND_HOTKEY")):
			continue
		detail_lines.append(line)
		if detail_lines.size() >= 2:
			break
	return " | ".join(detail_lines)


func _non_empty_lines(value):
	var lines = []
	for line in value.split("\n", false):
		var clean_line = str(line).strip_edges()
		if clean_line != "":
			lines.append(clean_line)
	return lines


func _details_stylebox(bg_color, border_color):
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	return style


func _track_player_resources(player):
	if _tracked_player == player:
		return
	if (
		_tracked_player != null
		and _tracked_player.changed.is_connected(_on_tracked_player_changed)
	):
		_tracked_player.changed.disconnect(_on_tracked_player_changed)
	_tracked_player = player
	if (
		_tracked_player != null
		and not _tracked_player.changed.is_connected(_on_tracked_player_changed)
	):
		_tracked_player.changed.connect(_on_tracked_player_changed)


func _on_tracked_player_changed():
	_reset_menus()


func _track_production_queue(production_queue):
	_track_production_queues([production_queue] if production_queue != null else [])


func _track_production_queues(production_queues):
	var next_queues = _deduplicate_valid_production_queues(production_queues)
	if _same_tracked_queues(next_queues):
		return
	for tracked_queue in _tracked_production_queues:
		if tracked_queue == null or not is_instance_valid(tracked_queue):
			continue
		if tracked_queue.element_enqueued.is_connected(_on_tracked_queue_changed):
			tracked_queue.element_enqueued.disconnect(_on_tracked_queue_changed)
		if tracked_queue.element_removed.is_connected(_on_tracked_queue_changed):
			tracked_queue.element_removed.disconnect(_on_tracked_queue_changed)
	_tracked_production_queues = next_queues
	for tracked_queue in _tracked_production_queues:
		if not tracked_queue.element_enqueued.is_connected(_on_tracked_queue_changed):
			tracked_queue.element_enqueued.connect(_on_tracked_queue_changed)
		if not tracked_queue.element_removed.is_connected(_on_tracked_queue_changed):
			tracked_queue.element_removed.connect(_on_tracked_queue_changed)


func _deduplicate_valid_production_queues(production_queues):
	var valid_queues = []
	for production_queue in production_queues:
		if production_queue == null or not is_instance_valid(production_queue):
			continue
		if production_queue in valid_queues:
			continue
		valid_queues.append(production_queue)
	return valid_queues


func _same_tracked_queues(next_queues):
	if _tracked_production_queues.size() != next_queues.size():
		return false
	for index in range(next_queues.size()):
		if _tracked_production_queues[index] != next_queues[index]:
			return false
	return true


func _on_tracked_queue_changed(_element):
	_reset_menus()
