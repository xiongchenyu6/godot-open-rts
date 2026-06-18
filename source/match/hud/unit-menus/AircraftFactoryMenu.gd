extends GridContainer

const HelicopterUnit = preload("res://source/match/units/Helicopter.tscn")
const DroneUnit = preload("res://source/match/units/Drone.tscn")
const InterceptorVTOLUnit = preload("res://source/match/units/InterceptorVTOL.tscn")
const BomberVTOLUnit = preload("res://source/match/units/BomberVTOL.tscn")
const RocketGunshipUnit = preload("res://source/match/units/RocketGunship.tscn")
const HeavyBombardmentAirshipUnit = preload(
	"res://source/match/units/HeavyBombardmentAirship.tscn"
)
const SiegeAirshipUnit = preload("res://source/match/units/SiegeAirship.tscn")
const StructureMenuActions = preload("res://source/match/hud/unit-menus/StructureMenuActions.gd")
const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const ProductionMenuActions = preload("res://source/match/hud/unit-menus/ProductionMenuActions.gd")
const ProductionButtonTooltip = preload("res://source/match/hud/unit-menus/ProductionButtonTooltip.gd")

var unit = null
var units = []

@onready var _helicopter_button = find_child("ProduceHelicopterButton")
@onready var _drone_button = find_child("ProduceDroneButton")
@onready var _interceptor_vtol_button = find_child("ProduceInterceptorVTOLButton")
@onready var _bomber_vtol_button = find_child("ProduceBomberVTOLButton")
@onready var _rocket_gunship_button = find_child("ProduceRocketGunshipButton")
@onready var _heavy_bombardment_airship_button = find_child(
	"ProduceHeavyBombardmentAirshipButton"
)
@onready var _siege_airship_button = find_child("ProduceSiegeAirshipButton")
@onready var _sell_structure_button = find_child("SellStructureButton")
@onready var _rally_point_button = find_child("SetRallyPointButton")
var _repair_structure_button = null


func _ready():
	_repair_structure_button = StructureMenuActions.ensure_repair_button(self)
	CommandButtonHotkeys.assign_grid_hotkeys(self)
	_set_unit_tooltip(_helicopter_button, HelicopterUnit, "HELICOPTER", "HELICOPTER_DESCRIPTION")
	_set_unit_tooltip(_drone_button, DroneUnit, "DRONE", "DRONE_DESCRIPTION")
	_set_unit_tooltip(
		_interceptor_vtol_button,
		InterceptorVTOLUnit,
		"INTERCEPTOR_VTOL",
		"INTERCEPTOR_VTOL_DESCRIPTION"
	)
	_set_unit_tooltip(_bomber_vtol_button, BomberVTOLUnit, "BOMBER_VTOL", "BOMBER_VTOL_DESCRIPTION")
	_set_unit_tooltip(
		_rocket_gunship_button, RocketGunshipUnit, "ROCKET_GUNSHIP", "ROCKET_GUNSHIP_DESCRIPTION"
	)
	_set_unit_tooltip(
		_heavy_bombardment_airship_button,
		HeavyBombardmentAirshipUnit,
		"HEAVY_BOMBARDMENT_AIRSHIP",
		"HEAVY_BOMBARDMENT_AIRSHIP_DESCRIPTION"
	)
	_set_unit_tooltip(
		_siege_airship_button,
		SiegeAirshipUnit,
		"SIEGE_AIRSHIP",
		"SIEGE_AIRSHIP_DESCRIPTION"
	)


func refresh():
	_refresh_unit_button(_helicopter_button, HelicopterUnit, "HELICOPTER", "HELICOPTER_DESCRIPTION")
	_refresh_unit_button(_drone_button, DroneUnit, "DRONE", "DRONE_DESCRIPTION")
	_refresh_unit_button(
		_interceptor_vtol_button,
		InterceptorVTOLUnit,
		"INTERCEPTOR_VTOL",
		"INTERCEPTOR_VTOL_DESCRIPTION"
	)
	_refresh_unit_button(
		_bomber_vtol_button, BomberVTOLUnit, "BOMBER_VTOL", "BOMBER_VTOL_DESCRIPTION"
	)
	_refresh_unit_button(
		_rocket_gunship_button, RocketGunshipUnit, "ROCKET_GUNSHIP", "ROCKET_GUNSHIP_DESCRIPTION"
	)
	_refresh_unit_button(
		_heavy_bombardment_airship_button,
		HeavyBombardmentAirshipUnit,
		"HEAVY_BOMBARDMENT_AIRSHIP",
		"HEAVY_BOMBARDMENT_AIRSHIP_DESCRIPTION"
	)
	_refresh_unit_button(
		_siege_airship_button,
		SiegeAirshipUnit,
		"SIEGE_AIRSHIP",
		"SIEGE_AIRSHIP_DESCRIPTION"
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


func _on_produce_helicopter_button_pressed():
	_produce(HelicopterUnit)


func _on_produce_drone_button_pressed():
	_produce(DroneUnit)


func _on_produce_interceptor_vtol_button_pressed():
	_produce(InterceptorVTOLUnit)


func _on_produce_bomber_vtol_button_pressed():
	_produce(BomberVTOLUnit)


func _on_produce_rocket_gunship_button_pressed():
	_produce(RocketGunshipUnit)


func _on_produce_heavy_bombardment_airship_button_pressed():
	_produce(HeavyBombardmentAirshipUnit)


func _on_produce_siege_airship_button_pressed():
	_produce(SiegeAirshipUnit)


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
