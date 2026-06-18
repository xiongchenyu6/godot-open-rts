extends "res://tests/manual/Match.gd"

const LightRifleInfantryUnit = preload("res://source/match/units/LightRifleInfantry.tscn")

const FOCUS_EPSILON = 0.75

@onready var _test_camera = $IsometricCamera3D
@onready var _production_structure_handler = $Handlers/ProductionStructureHotkeysHandler
@onready var _unit_menus = $HUD/MarginContainer3/VBoxContainer/UnitMenus
@onready var _command_center = $Players/Human/CommandCenter
@onready var _barracks_a = $Players/Human/BarracksA
@onready var _barracks_b = $Players/Human/BarracksB
@onready var _vehicle_factory = $Players/Human/VehicleFactory
@onready var _aircraft_factory = $Players/Human/AircraftFactory


func _ready():
	super()
	_test_camera.screen_margin_for_movement = -1
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_place_structures()

	_assert(InputMap.has_action("select_command_center"), "command center hotkey action should exist")
	_assert(InputMap.has_action("select_barracks"), "barracks hotkey action should exist")
	_assert(InputMap.has_action("select_vehicle_factory"), "vehicle factory hotkey action should exist")
	_assert(InputMap.has_action("select_aircraft_factory"), "aircraft factory hotkey action should exist")

	var command_center_event = _select_command_center_event()
	var barracks_event = _select_barracks_event()
	var all_barracks_event = _select_all_barracks_event()
	var vehicle_factory_event = _select_vehicle_factory_event()
	var all_vehicle_factories_event = _select_all_vehicle_factories_event()
	var aircraft_factory_event = _select_aircraft_factory_event()
	var all_aircraft_factories_event = _select_all_aircraft_factories_event()
	var all_command_centers_event = _select_all_command_centers_event()

	_assert(
		command_center_event.is_action_pressed("select_command_center", false, true),
		"Alt+C should select command centers"
	)
	_assert(
		barracks_event.is_action_pressed("select_barracks", false, true),
		"Alt+B should select barracks"
	)
	_assert(
		all_barracks_event.is_action_pressed("select_barracks", false, false),
		"Shift+Alt+B should reuse the barracks selection action"
	)
	_assert(
		vehicle_factory_event.is_action_pressed("select_vehicle_factory", false, true),
		"Alt+V should select vehicle factories"
	)
	_assert(
		aircraft_factory_event.is_action_pressed("select_aircraft_factory", false, true),
		"Alt+F should select aircraft factories"
	)
	_assert(
		not _key_event(KEY_B, true, true).is_action_pressed("select_barracks", false, true),
		"Ctrl+Alt+B should not also match barracks selection"
	)

	_test_camera.set_size_safely(10.0)
	_test_camera.set_position_safely(Vector3(8.0, 0.0, 8.0))
	await get_tree().process_frame

	_production_structure_handler._input(barracks_event)
	await get_tree().process_frame
	_assert(_is_only_selected(_barracks_a), "first Alt+B should select the first barracks")
	_assert(_is_camera_focused_on(_barracks_a), "first Alt+B should focus the first barracks")

	_production_structure_handler._input(barracks_event)
	await get_tree().process_frame
	_assert(_is_only_selected(_barracks_b), "second Alt+B should select the next barracks")
	_assert(_is_camera_focused_on(_barracks_b), "second Alt+B should focus the next barracks")

	_assert(
		_production_structure_handler._is_production_structure_action(
			all_barracks_event, "select_barracks"
		),
		"Shift+Alt+B should be handled as a barracks selection hotkey"
	)
	_assert(
		_production_structure_handler._select_all_requested(all_barracks_event),
		"Shift+Alt+B should request selecting all barracks"
	)
	_production_structure_handler._input(all_barracks_event)
	await get_tree().process_frame
	var selected_barracks = _selected_controlled_units()
	_assert(
		selected_barracks == [_barracks_a, _barracks_b],
		"Shift+Alt+B should select all constructed barracks, got {0}".format(
			[str(_unit_names(selected_barracks))]
		)
	)
	_assert(_is_camera_focused_on(_barracks_a), "Shift+Alt+B should focus the first barracks")
	await _assert_multi_barracks_menu_queues_all_selected_barracks()

	var ctrl_barracks_event = _key_event(KEY_B, true, true)
	_production_structure_handler._input(ctrl_barracks_event)
	await get_tree().process_frame
	_assert(
		_selected_controlled_units() == [_barracks_a, _barracks_b],
		"Ctrl+Alt+B should not change production structure selection"
	)

	_production_structure_handler._input(command_center_event)
	await get_tree().process_frame
	_assert(_is_only_selected(_command_center), "Alt+C should select command center")
	_assert(_is_camera_focused_on(_command_center), "Alt+C should focus command center")

	_production_structure_handler._input(all_command_centers_event)
	await get_tree().process_frame
	_assert(
		_selected_controlled_units() == [_command_center],
		"Shift+Alt+C should select all constructed command centers"
	)

	_production_structure_handler._input(vehicle_factory_event)
	await get_tree().process_frame
	_assert(_is_only_selected(_vehicle_factory), "Alt+V should select vehicle factory")
	_assert(_is_camera_focused_on(_vehicle_factory), "Alt+V should focus vehicle factory")

	_production_structure_handler._input(all_vehicle_factories_event)
	await get_tree().process_frame
	_assert(
		_selected_controlled_units() == [_vehicle_factory],
		"Shift+Alt+V should select all constructed vehicle factories"
	)

	_production_structure_handler._input(aircraft_factory_event)
	await get_tree().process_frame
	_assert(_is_only_selected(_aircraft_factory), "Alt+F should select aircraft factory")
	_assert(_is_camera_focused_on(_aircraft_factory), "Alt+F should focus aircraft factory")

	_production_structure_handler._input(all_aircraft_factories_event)
	await get_tree().process_frame
	_assert(
		_selected_controlled_units() == [_aircraft_factory],
		"Shift+Alt+F should select all constructed aircraft factories"
	)

	get_tree().quit()


func _place_structures():
	_place_structure(_command_center, Vector3(12.0, 0.0, 12.0))
	_place_structure(_barracks_a, Vector3(18.0, 0.0, 12.0))
	_place_structure(_barracks_b, Vector3(26.0, 0.0, 12.0))
	_place_structure(_vehicle_factory, Vector3(18.0, 0.0, 22.0))
	_place_structure(_aircraft_factory, Vector3(26.0, 0.0, 22.0))


func _place_structure(structure, position: Vector3):
	structure.global_position = position


func _is_only_selected(unit) -> bool:
	var selected_units = _selected_controlled_units()
	return selected_units.size() == 1 and selected_units[0] == unit


func _selected_controlled_units():
	var selected_units = get_tree().get_nodes_in_group("selected_units").filter(
		func(selected_unit): return selected_unit.is_in_group("controlled_units")
	)
	selected_units.sort_custom(func(a, b): return str(a.get_path()) < str(b.get_path()))
	return selected_units


func _unit_names(units):
	return units.map(func(unit): return unit.name)


func _is_camera_focused_on(unit) -> bool:
	return _camera_center_yless().distance_to(unit.global_position_yless) <= FOCUS_EPSILON


func _assert_multi_barracks_menu_queues_all_selected_barracks():
	var barracks_menu = _unit_menus.find_child("BarracksMenu", true, false)
	_assert(barracks_menu.visible, "all selected barracks should show the barracks production menu")
	_assert(barracks_menu.unit == _barracks_a, "multi-barracks menu should keep the first barracks as primary")
	_assert(
		barracks_menu.units == [_barracks_a, _barracks_b],
		"multi-barracks menu should retain all selected barracks"
	)

	var rifle_button = barracks_menu.find_child("ProduceLightRifleInfantryButton", true, false)
	_assert(rifle_button != null, "multi-barracks menu should expose the infantry production button")
	_assert(not rifle_button.disabled, "multi-barracks infantry button should be enabled")
	rifle_button.pressed.emit()
	await get_tree().process_frame
	_assert(
		_barracks_a.production_queue.size() == 1,
		"multi-barracks production should queue the infantry in the first barracks"
	)
	_assert(
		_barracks_b.production_queue.size() == 1,
		"multi-barracks production should queue the infantry in the second barracks"
	)
	_assert(
		_barracks_a.production_queue.get_elements()[0].unit_prototype.resource_path
		== LightRifleInfantryUnit.resource_path,
		"first barracks should queue light rifle infantry"
	)
	_assert(
		_barracks_b.production_queue.get_elements()[0].unit_prototype.resource_path
		== LightRifleInfantryUnit.resource_path,
		"second barracks should queue light rifle infantry"
	)
	var refreshed_rifle_button = barracks_menu.find_child("ProduceLightRifleInfantryButton", true, false)
	var queue_label = refreshed_rifle_button.find_child("QueueCountLabel", true, false)
	_assert(queue_label != null and queue_label.visible, "multi-barracks button should show queued count")
	_assert(queue_label.text == "x2", "multi-barracks button should aggregate queued infantry count")


func _camera_center_yless():
	var center = _test_camera.get_ray_intersection(get_viewport().size / 2.0)
	return center * Vector3(1, 0, 1)


func _select_command_center_event():
	return _key_event(KEY_C, true, false)


func _select_all_command_centers_event():
	return _key_event(KEY_C, true, false, true)


func _select_barracks_event():
	return _key_event(KEY_B, true, false)


func _select_all_barracks_event():
	return _key_event(KEY_B, true, false, true)


func _select_vehicle_factory_event():
	return _key_event(KEY_V, true, false)


func _select_all_vehicle_factories_event():
	return _key_event(KEY_V, true, false, true)


func _select_aircraft_factory_event():
	return _key_event(KEY_F, true, false)


func _select_all_aircraft_factories_event():
	return _key_event(KEY_F, true, false, true)


func _key_event(keycode: int, alt_pressed: bool, ctrl_pressed: bool, shift_pressed: bool = false):
	var event = InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	event.physical_keycode = keycode
	event.alt_pressed = alt_pressed
	event.ctrl_pressed = ctrl_pressed
	event.shift_pressed = shift_pressed
	if not ctrl_pressed:
		event.unicode = keycode + 32
	return event


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
