extends Node

const AircraftFactory = preload("res://source/match/units/AircraftFactory.gd")
const Barracks = preload("res://source/match/units/Barracks.gd")
const CommandCenter = preload("res://source/match/units/CommandCenter.gd")
const VehicleFactory = preload("res://source/match/units/VehicleFactory.gd")

@export var camera_path: NodePath = NodePath("../../IsometricCamera3D")

@onready var _camera = get_node_or_null(camera_path)


func _input(event):
	if _is_production_structure_action(event, "select_command_center"):
		if _select_all_requested(event):
			select_all_command_centers()
		else:
			select_next_command_center()
		get_viewport().set_input_as_handled()
		return
	if _is_production_structure_action(event, "select_barracks"):
		if _select_all_requested(event):
			select_all_barracks()
		else:
			select_next_barracks()
		get_viewport().set_input_as_handled()
		return
	if _is_production_structure_action(event, "select_vehicle_factory"):
		if _select_all_requested(event):
			select_all_vehicle_factories()
		else:
			select_next_vehicle_factory()
		get_viewport().set_input_as_handled()
		return
	if _is_production_structure_action(event, "select_aircraft_factory"):
		if _select_all_requested(event):
			select_all_aircraft_factories()
		else:
			select_next_aircraft_factory()
		get_viewport().set_input_as_handled()
		return


func select_next_command_center() -> bool:
	return select_next_structure(CommandCenter)


func select_next_barracks() -> bool:
	return select_next_structure(Barracks)


func select_next_vehicle_factory() -> bool:
	return select_next_structure(VehicleFactory)


func select_next_aircraft_factory() -> bool:
	return select_next_structure(AircraftFactory)


func _is_production_structure_action(event, action_name) -> bool:
	if not event.is_action_pressed(action_name, false, false):
		return false
	if _event_modifier_pressed(event, "ctrl_pressed"):
		return false
	return true


func _select_all_requested(event) -> bool:
	return _event_modifier_pressed(event, "shift_pressed")


func _event_modifier_pressed(event, modifier_name) -> bool:
	return modifier_name in event and bool(event.get(modifier_name))


func select_all_command_centers() -> bool:
	return select_all_structures(CommandCenter)


func select_all_barracks() -> bool:
	return select_all_structures(Barracks)


func select_all_vehicle_factories() -> bool:
	return select_all_structures(VehicleFactory)


func select_all_aircraft_factories() -> bool:
	return select_all_structures(AircraftFactory)


func select_next_structure(structure_script) -> bool:
	var structures = _structures_of_type(structure_script)
	if structures.is_empty():
		return false

	var structure_to_select = _next_structure(structures, structure_script)
	var units_to_select = Utils.Set.new()
	units_to_select.add(structure_to_select)
	Utils.Match.select_units(units_to_select, true)
	_focus_structure(structure_to_select)
	return true


func select_all_structures(structure_script) -> bool:
	var structures = _structures_of_type(structure_script)
	if structures.is_empty():
		return false

	var units_to_select = Utils.Set.new()
	for structure in structures:
		units_to_select.add(structure)
	Utils.Match.select_units(units_to_select, true)
	_focus_structure(structures[0])
	return true


func _structures_of_type(structure_script) -> Array:
	var structures = []
	for unit in get_tree().get_nodes_in_group("controlled_units"):
		if _is_selectable_structure(unit, structure_script):
			structures.append(unit)
	structures.sort_custom(func(a, b): return str(a.get_path()) < str(b.get_path()))
	return structures


func _is_selectable_structure(unit, structure_script) -> bool:
	return (
		is_instance_valid(unit)
		and unit.is_inside_tree()
		and structure_script.instance_has(unit)
		and unit.visible
		and unit.is_in_group("controlled_units")
		and unit.is_constructed()
	)


func _next_structure(structures: Array, structure_script):
	var selected_structure = _selected_structure_of_type(structure_script)
	if selected_structure == null:
		return structures[0]
	var selected_index = structures.find(selected_structure)
	if selected_index == -1:
		return structures[0]
	return structures[(selected_index + 1) % structures.size()]


func _selected_structure_of_type(structure_script):
	var selected_units = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit): return is_instance_valid(unit) and unit.is_inside_tree()
	)
	if selected_units.size() != 1:
		return null
	var selected_unit = selected_units[0]
	if _is_selectable_structure(selected_unit, structure_script):
		return selected_unit
	return null


func _focus_structure(structure):
	if _camera == null:
		return
	_camera.set_position_safely(structure.global_position_yless)
