extends GridContainer

const WorkerUnit = preload("res://source/match/units/Worker.tscn")
const EngineerDroneUnit = preload("res://source/match/units/EngineerDrone.tscn")
const StructureMenuActions = preload("res://source/match/hud/unit-menus/StructureMenuActions.gd")
const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const ProductionMenuActions = preload("res://source/match/hud/unit-menus/ProductionMenuActions.gd")
const ProductionButtonTooltip = preload("res://source/match/hud/unit-menus/ProductionButtonTooltip.gd")

var unit = null
var units = []

@onready var _worker_button = find_child("ProduceWorkerButton")
@onready var _engineer_drone_button = find_child("ProduceEngineerDroneButton")
@onready var _sell_structure_button = find_child("SellStructureButton")
@onready var _rally_point_button = find_child("SetRallyPointButton")
var _repair_structure_button = null


func _ready():
	_repair_structure_button = StructureMenuActions.ensure_repair_button(self)
	CommandButtonHotkeys.assign_grid_hotkeys(self)
	_set_unit_tooltip(_worker_button, WorkerUnit, "WORKER", "WORKER_DESCRIPTION")
	_set_unit_tooltip(_engineer_drone_button, EngineerDroneUnit, "ENGINEER_DRONE", "ENGINEER_DRONE_DESCRIPTION")


func refresh():
	_refresh_unit_button(_worker_button, WorkerUnit, "WORKER", "WORKER_DESCRIPTION")
	_refresh_unit_button(
		_engineer_drone_button, EngineerDroneUnit, "ENGINEER_DRONE", "ENGINEER_DRONE_DESCRIPTION"
	)
	StructureMenuActions.refresh_sell_button(_sell_structure_button, _producer_units())
	StructureMenuActions.refresh_rally_point_button(_rally_point_button, _producer_units())
	StructureMenuActions.refresh_repair_button(_repair_structure_button, _producer_units())


func _refresh_unit_button(button, unit_scene, name_key, description_key):
	var missing_requirements = (
		Utils.Match.Unit.Tech.missing_production_requirements(unit.player, unit_scene.resource_path)
		if unit != null
		else []
	)
	button.disabled = (
		not missing_requirements.is_empty()
		or not ProductionMenuActions.has_available_queue(_producer_units())
	)
	_set_unit_tooltip(button, unit_scene, name_key, description_key, missing_requirements)


func _set_unit_tooltip(button, unit_scene, name_key, description_key, missing_requirements = []):
	ProductionButtonTooltip.apply(
		button,
		unit_scene,
		name_key,
		description_key,
		missing_requirements,
		unit.player if unit != null else null,
		ProductionMenuActions.primary_queue(_producer_units()),
		_producer_queues()
	)


func _on_produce_worker_button_pressed():
	_produce(WorkerUnit)


func _on_produce_engineer_drone_button_pressed():
	_produce(EngineerDroneUnit)


func _produce(unit_scene):
	ProductionMenuActions.produce_for_units(_producer_units(), unit_scene)


func _on_sell_structure_button_pressed():
	StructureMenuActions.sell(_producer_units())


func _on_set_rally_point_button_pressed():
	StructureMenuActions.request_rally_point(_producer_units())


func _on_repair_structure_button_pressed():
	StructureMenuActions.repair(_producer_units())
	refresh()


func _producer_units():
	if not units.is_empty():
		return units
	if unit != null:
		return [unit]
	return []


func _producer_queues():
	return _producer_units().map(func(producer_unit): return producer_unit.production_queue)
