extends Node

const Structure = preload("res://source/match/units/Structure.gd")
const Unit = preload("res://source/match/units/Unit.gd")
const Worker = preload("res://source/match/units/Worker.gd")

@export var camera_path: NodePath = NodePath("../../IsometricCamera3D")

@onready var _camera = get_node_or_null(camera_path)


func _input(event):
	if event.is_action_pressed("select_all_army", false, true):
		select_all_army()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("select_army_on_screen", false, true):
		select_army_on_screen()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("select_idle_workers", false, true):
		select_idle_workers()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("select_idle_harvesters", false, true):
		select_idle_harvesters()
		get_viewport().set_input_as_handled()
		return


func select_army_on_screen() -> int:
	var units_to_select = _army_units(true)
	Utils.Match.select_units(units_to_select)
	return units_to_select.size()


func select_all_army() -> int:
	var units_to_select = _army_units(false)
	Utils.Match.select_units(units_to_select)
	return units_to_select.size()


func select_idle_workers() -> int:
	var units_to_select = _idle_economy_units(Callable(self, "_is_builder_worker"))
	Utils.Match.select_units(units_to_select)
	return units_to_select.size()


func select_idle_harvesters() -> int:
	var units_to_select = _idle_economy_units(Callable(self, "_is_harvester_worker"))
	Utils.Match.select_units(units_to_select)
	return units_to_select.size()


func _army_units(only_on_screen: bool):
	var units_to_select = Utils.Set.new()
	for unit in get_tree().get_nodes_in_group("controlled_units"):
		if not _is_army_unit(unit):
			continue
		if not unit.visible:
			continue
		if only_on_screen and not _is_unit_on_screen(unit):
			continue
		units_to_select.add(unit)
	return units_to_select


func _idle_economy_units(predicate: Callable):
	var units_to_select = Utils.Set.new()
	for unit in get_tree().get_nodes_in_group("controlled_units"):
		if not unit is Worker:
			continue
		if not unit.visible:
			continue
		if not predicate.call(unit):
			continue
		if not _is_idle_unit(unit):
			continue
		units_to_select.add(unit)
	return units_to_select


func _is_army_unit(unit) -> bool:
	return unit is Unit and not unit is Structure and not unit is Worker


func _is_builder_worker(unit) -> bool:
	return unit.has_method("can_construct_structures") and unit.can_construct_structures()


func _is_harvester_worker(unit) -> bool:
	return (
		unit.has_method("can_collect_resources")
		and unit.can_collect_resources()
		and (not unit.has_method("can_construct_structures") or not unit.can_construct_structures())
	)


func _is_idle_unit(unit) -> bool:
	if unit.has_method("has_queued_actions") and unit.has_queued_actions():
		return false
	if unit.action == null:
		return true
	if unit.action.has_method("is_idle"):
		return unit.action.is_idle()
	return false


func _is_unit_on_screen(unit) -> bool:
	if _camera == null or _camera.is_position_behind(unit.global_position):
		return false
	var screen_position = _camera.unproject_position(unit.global_position)
	return Rect2(Vector2.ZERO, get_viewport().size).has_point(screen_position)
