extends GridContainer

const TankUnit = preload("res://source/match/units/Tank.tscn")
const ScoutRoverUnit = preload("res://source/match/units/ScoutRover.tscn")
const OreHarvesterUnit = preload("res://source/match/units/OreHarvester.tscn")
const MobileConstructionVehicleUnit = preload(
	"res://source/match/units/MobileConstructionVehicle.tscn"
)
const MirageScoutTankUnit = preload("res://source/match/units/MirageScoutTank.tscn")
const FlameAssaultBuggyUnit = preload("res://source/match/units/FlameAssaultBuggy.tscn")
const DroneMineLayerUnit = preload("res://source/match/units/DroneMineLayer.tscn")
const TeslaCrawlerMk2Unit = preload("res://source/match/units/TeslaCrawlerMk2.tscn")
const RocketTrooperRobotUnit = preload("res://source/match/units/RocketTrooperRobot.tscn")
const ModularMissileCarrierUnit = preload("res://source/match/units/ModularMissileCarrier.tscn")
const JammerVehicleUnit = preload("res://source/match/units/JammerVehicle.tscn")
const AntiAirWalkerUnit = preload("res://source/match/units/AntiAirWalker.tscn")
const FlakHoverTankUnit = preload("res://source/match/units/FlakHoverTank.tscn")
const MobileRepairCrawlerUnit = preload("res://source/match/units/MobileRepairCrawler.tscn")
const MobileShieldProjectorUnit = preload("res://source/match/units/MobileShieldProjector.tscn")
const SiegeArtilleryVehicleUnit = preload("res://source/match/units/SiegeArtilleryVehicle.tscn")
const SiegeDrillTankUnit = preload("res://source/match/units/SiegeDrillTank.tscn")
const LongbowMissileCrawlerUnit = preload("res://source/match/units/LongbowMissileCrawler.tscn")
const LanceBeamTankUnit = preload("res://source/match/units/LanceBeamTank.tscn")
const RailgunTankUnit = preload("res://source/match/units/RailgunTank.tscn")
const HammerSiegeTankUnit = preload("res://source/match/units/HammerSiegeTank.tscn")
const HeavySiegeWalkerUnit = preload("res://source/match/units/HeavySiegeWalker.tscn")
const RailArtilleryWalkerUnit = preload("res://source/match/units/RailArtilleryWalker.tscn")
const StructureMenuActions = preload("res://source/match/hud/unit-menus/StructureMenuActions.gd")
const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const ProductionMenuActions = preload("res://source/match/hud/unit-menus/ProductionMenuActions.gd")
const ProductionButtonTooltip = preload("res://source/match/hud/unit-menus/ProductionButtonTooltip.gd")

var unit = null
var units = []

@onready var _tank_button = find_child("ProduceTankButton")
@onready var _scout_rover_button = find_child("ProduceScoutRoverButton")
@onready var _ore_harvester_button = find_child("ProduceOreHarvesterButton")
@onready var _mobile_construction_vehicle_button = find_child("ProduceMobileConstructionVehicleButton")
@onready var _mirage_scout_tank_button = find_child("ProduceMirageScoutTankButton")
@onready var _flame_assault_buggy_button = find_child("ProduceFlameAssaultBuggyButton")
@onready var _drone_mine_layer_button = find_child("ProduceDroneMineLayerButton")
@onready var _tesla_crawler_mk2_button = find_child("ProduceTeslaCrawlerMk2Button")
@onready var _rocket_trooper_robot_button = find_child("ProduceRocketTrooperRobotButton")
@onready var _modular_missile_carrier_button = find_child("ProduceModularMissileCarrierButton")
@onready var _jammer_vehicle_button = find_child("ProduceJammerVehicleButton")
@onready var _anti_air_walker_button = find_child("ProduceAntiAirWalkerButton")
@onready var _flak_hover_tank_button = find_child("ProduceFlakHoverTankButton")
@onready var _mobile_repair_crawler_button = find_child("ProduceMobileRepairCrawlerButton")
@onready var _mobile_shield_projector_button = find_child("ProduceMobileShieldProjectorButton")
@onready var _siege_artillery_vehicle_button = find_child("ProduceSiegeArtilleryVehicleButton")
@onready var _siege_drill_tank_button = find_child("ProduceSiegeDrillTankButton")
@onready var _longbow_missile_crawler_button = find_child("ProduceLongbowMissileCrawlerButton")
@onready var _lance_beam_tank_button = find_child("ProduceLanceBeamTankButton")
@onready var _railgun_tank_button = find_child("ProduceRailgunTankButton")
@onready var _hammer_siege_tank_button = find_child("ProduceHammerSiegeTankButton")
@onready var _heavy_siege_walker_button = find_child("ProduceHeavySiegeWalkerButton")
@onready var _rail_artillery_walker_button = find_child("ProduceRailArtilleryWalkerButton")
@onready var _sell_structure_button = find_child("SellStructureButton")
@onready var _rally_point_button = find_child("SetRallyPointButton")
var _repair_structure_button = null


func _ready():
	_repair_structure_button = StructureMenuActions.ensure_repair_button(self)
	CommandButtonHotkeys.assign_grid_hotkeys(self)
	_set_unit_tooltip(_tank_button, TankUnit, "TANK", "TANK_DESCRIPTION")
	_set_unit_tooltip(_scout_rover_button, ScoutRoverUnit, "SCOUT_ROVER", "SCOUT_ROVER_DESCRIPTION")
	_set_unit_tooltip(
		_ore_harvester_button,
		OreHarvesterUnit,
		"ORE_HARVESTER",
		"ORE_HARVESTER_DESCRIPTION"
	)
	_set_unit_tooltip(
		_mobile_construction_vehicle_button,
		MobileConstructionVehicleUnit,
		"MOBILE_CONSTRUCTION_VEHICLE",
		"MOBILE_CONSTRUCTION_VEHICLE_DESCRIPTION"
	)
	_set_unit_tooltip(
		_mirage_scout_tank_button,
		MirageScoutTankUnit,
		"MIRAGE_SCOUT_TANK",
		"MIRAGE_SCOUT_TANK_DESCRIPTION"
	)
	_set_unit_tooltip(
		_flame_assault_buggy_button,
		FlameAssaultBuggyUnit,
		"FLAME_ASSAULT_BUGGY",
		"FLAME_ASSAULT_BUGGY_DESCRIPTION"
	)
	_set_unit_tooltip(
		_drone_mine_layer_button,
		DroneMineLayerUnit,
		"DRONE_MINE_LAYER",
		"DRONE_MINE_LAYER_DESCRIPTION"
	)
	_set_unit_tooltip(
		_tesla_crawler_mk2_button,
		TeslaCrawlerMk2Unit,
		"TESLA_CRAWLER_MK2",
		"TESLA_CRAWLER_MK2_DESCRIPTION"
	)
	_set_unit_tooltip(
		_rocket_trooper_robot_button,
		RocketTrooperRobotUnit,
		"ROCKET_TROOPER_ROBOT",
		"ROCKET_TROOPER_ROBOT_DESCRIPTION"
	)
	_set_unit_tooltip(
		_modular_missile_carrier_button,
		ModularMissileCarrierUnit,
		"MODULAR_MISSILE_CARRIER",
		"MODULAR_MISSILE_CARRIER_DESCRIPTION"
	)
	_set_unit_tooltip(
		_jammer_vehicle_button,
		JammerVehicleUnit,
		"JAMMER_VEHICLE",
		"JAMMER_VEHICLE_DESCRIPTION"
	)
	_set_unit_tooltip(
		_anti_air_walker_button, AntiAirWalkerUnit, "ANTI_AIR_WALKER", "ANTI_AIR_WALKER_DESCRIPTION"
	)
	_set_unit_tooltip(
		_flak_hover_tank_button, FlakHoverTankUnit, "FLAK_HOVER_TANK", "FLAK_HOVER_TANK_DESCRIPTION"
	)
	_set_unit_tooltip(
		_mobile_repair_crawler_button,
		MobileRepairCrawlerUnit,
		"MOBILE_REPAIR_CRAWLER",
		"MOBILE_REPAIR_CRAWLER_DESCRIPTION"
	)
	_set_unit_tooltip(
		_mobile_shield_projector_button,
		MobileShieldProjectorUnit,
		"MOBILE_SHIELD_PROJECTOR",
		"MOBILE_SHIELD_PROJECTOR_DESCRIPTION"
	)
	_set_unit_tooltip(
		_siege_artillery_vehicle_button,
		SiegeArtilleryVehicleUnit,
		"SIEGE_ARTILLERY_VEHICLE",
		"SIEGE_ARTILLERY_VEHICLE_DESCRIPTION"
	)
	_set_unit_tooltip(
		_siege_drill_tank_button,
		SiegeDrillTankUnit,
		"SIEGE_DRILL_TANK",
		"SIEGE_DRILL_TANK_DESCRIPTION"
	)
	_set_unit_tooltip(
		_longbow_missile_crawler_button,
		LongbowMissileCrawlerUnit,
		"LONGBOW_MISSILE_CRAWLER",
		"LONGBOW_MISSILE_CRAWLER_DESCRIPTION"
	)
	_set_unit_tooltip(
		_lance_beam_tank_button,
		LanceBeamTankUnit,
		"LANCE_BEAM_TANK",
		"LANCE_BEAM_TANK_DESCRIPTION"
	)
	_set_unit_tooltip(
		_railgun_tank_button, RailgunTankUnit, "RAILGUN_TANK", "RAILGUN_TANK_DESCRIPTION"
	)
	_set_unit_tooltip(
		_hammer_siege_tank_button,
		HammerSiegeTankUnit,
		"HAMMER_SIEGE_TANK",
		"HAMMER_SIEGE_TANK_DESCRIPTION"
	)
	_set_unit_tooltip(
		_heavy_siege_walker_button,
		HeavySiegeWalkerUnit,
		"HEAVY_SIEGE_WALKER",
		"HEAVY_SIEGE_WALKER_DESCRIPTION"
	)
	_set_unit_tooltip(
		_rail_artillery_walker_button,
		RailArtilleryWalkerUnit,
		"RAIL_ARTILLERY_WALKER",
		"RAIL_ARTILLERY_WALKER_DESCRIPTION"
	)


func refresh():
	_refresh_unit_button(_tank_button, TankUnit, "TANK", "TANK_DESCRIPTION")
	_refresh_unit_button(_scout_rover_button, ScoutRoverUnit, "SCOUT_ROVER", "SCOUT_ROVER_DESCRIPTION")
	_refresh_unit_button(
		_ore_harvester_button,
		OreHarvesterUnit,
		"ORE_HARVESTER",
		"ORE_HARVESTER_DESCRIPTION"
	)
	_refresh_unit_button(
		_mobile_construction_vehicle_button,
		MobileConstructionVehicleUnit,
		"MOBILE_CONSTRUCTION_VEHICLE",
		"MOBILE_CONSTRUCTION_VEHICLE_DESCRIPTION"
	)
	_refresh_unit_button(
		_mirage_scout_tank_button,
		MirageScoutTankUnit,
		"MIRAGE_SCOUT_TANK",
		"MIRAGE_SCOUT_TANK_DESCRIPTION"
	)
	_refresh_unit_button(
		_flame_assault_buggy_button,
		FlameAssaultBuggyUnit,
		"FLAME_ASSAULT_BUGGY",
		"FLAME_ASSAULT_BUGGY_DESCRIPTION"
	)
	_refresh_unit_button(
		_drone_mine_layer_button,
		DroneMineLayerUnit,
		"DRONE_MINE_LAYER",
		"DRONE_MINE_LAYER_DESCRIPTION"
	)
	_refresh_unit_button(
		_tesla_crawler_mk2_button,
		TeslaCrawlerMk2Unit,
		"TESLA_CRAWLER_MK2",
		"TESLA_CRAWLER_MK2_DESCRIPTION"
	)
	_refresh_unit_button(
		_rocket_trooper_robot_button,
		RocketTrooperRobotUnit,
		"ROCKET_TROOPER_ROBOT",
		"ROCKET_TROOPER_ROBOT_DESCRIPTION"
	)
	_refresh_unit_button(
		_modular_missile_carrier_button,
		ModularMissileCarrierUnit,
		"MODULAR_MISSILE_CARRIER",
		"MODULAR_MISSILE_CARRIER_DESCRIPTION"
	)
	_refresh_unit_button(
		_jammer_vehicle_button,
		JammerVehicleUnit,
		"JAMMER_VEHICLE",
		"JAMMER_VEHICLE_DESCRIPTION"
	)
	_refresh_unit_button(
		_anti_air_walker_button, AntiAirWalkerUnit, "ANTI_AIR_WALKER", "ANTI_AIR_WALKER_DESCRIPTION"
	)
	_refresh_unit_button(
		_flak_hover_tank_button, FlakHoverTankUnit, "FLAK_HOVER_TANK", "FLAK_HOVER_TANK_DESCRIPTION"
	)
	_refresh_unit_button(
		_mobile_repair_crawler_button,
		MobileRepairCrawlerUnit,
		"MOBILE_REPAIR_CRAWLER",
		"MOBILE_REPAIR_CRAWLER_DESCRIPTION"
	)
	_refresh_unit_button(
		_mobile_shield_projector_button,
		MobileShieldProjectorUnit,
		"MOBILE_SHIELD_PROJECTOR",
		"MOBILE_SHIELD_PROJECTOR_DESCRIPTION"
	)
	_refresh_unit_button(
		_siege_artillery_vehicle_button,
		SiegeArtilleryVehicleUnit,
		"SIEGE_ARTILLERY_VEHICLE",
		"SIEGE_ARTILLERY_VEHICLE_DESCRIPTION"
	)
	_refresh_unit_button(
		_siege_drill_tank_button,
		SiegeDrillTankUnit,
		"SIEGE_DRILL_TANK",
		"SIEGE_DRILL_TANK_DESCRIPTION"
	)
	_refresh_unit_button(
		_longbow_missile_crawler_button,
		LongbowMissileCrawlerUnit,
		"LONGBOW_MISSILE_CRAWLER",
		"LONGBOW_MISSILE_CRAWLER_DESCRIPTION"
	)
	_refresh_unit_button(
		_lance_beam_tank_button,
		LanceBeamTankUnit,
		"LANCE_BEAM_TANK",
		"LANCE_BEAM_TANK_DESCRIPTION"
	)
	_refresh_unit_button(
		_railgun_tank_button, RailgunTankUnit, "RAILGUN_TANK", "RAILGUN_TANK_DESCRIPTION"
	)
	_refresh_unit_button(
		_hammer_siege_tank_button,
		HammerSiegeTankUnit,
		"HAMMER_SIEGE_TANK",
		"HAMMER_SIEGE_TANK_DESCRIPTION"
	)
	_refresh_unit_button(
		_heavy_siege_walker_button,
		HeavySiegeWalkerUnit,
		"HEAVY_SIEGE_WALKER",
		"HEAVY_SIEGE_WALKER_DESCRIPTION"
	)
	_refresh_unit_button(
		_rail_artillery_walker_button,
		RailArtilleryWalkerUnit,
		"RAIL_ARTILLERY_WALKER",
		"RAIL_ARTILLERY_WALKER_DESCRIPTION"
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


func _on_produce_tank_button_pressed():
	_produce(TankUnit)


func _on_produce_scout_rover_button_pressed():
	_produce(ScoutRoverUnit)


func _on_produce_ore_harvester_button_pressed():
	_produce(OreHarvesterUnit)


func _on_produce_mobile_construction_vehicle_button_pressed():
	_produce(MobileConstructionVehicleUnit)


func _on_produce_mirage_scout_tank_button_pressed():
	_produce(MirageScoutTankUnit)


func _on_produce_flame_assault_buggy_button_pressed():
	_produce(FlameAssaultBuggyUnit)


func _on_produce_drone_mine_layer_button_pressed():
	_produce(DroneMineLayerUnit)


func _on_produce_tesla_crawler_mk2_button_pressed():
	_produce(TeslaCrawlerMk2Unit)


func _on_produce_rocket_trooper_robot_button_pressed():
	_produce(RocketTrooperRobotUnit)


func _on_produce_modular_missile_carrier_button_pressed():
	_produce(ModularMissileCarrierUnit)


func _on_produce_jammer_vehicle_button_pressed():
	_produce(JammerVehicleUnit)


func _on_produce_anti_air_walker_button_pressed():
	_produce(AntiAirWalkerUnit)


func _on_produce_flak_hover_tank_button_pressed():
	_produce(FlakHoverTankUnit)


func _on_produce_mobile_repair_crawler_button_pressed():
	_produce(MobileRepairCrawlerUnit)


func _on_produce_mobile_shield_projector_button_pressed():
	_produce(MobileShieldProjectorUnit)


func _on_produce_longbow_missile_crawler_button_pressed():
	_produce(LongbowMissileCrawlerUnit)


func _on_produce_siege_artillery_vehicle_button_pressed():
	_produce(SiegeArtilleryVehicleUnit)


func _on_produce_siege_drill_tank_button_pressed():
	_produce(SiegeDrillTankUnit)


func _on_produce_heavy_siege_walker_button_pressed():
	_produce(HeavySiegeWalkerUnit)


func _on_produce_rail_artillery_walker_button_pressed():
	_produce(RailArtilleryWalkerUnit)


func _on_produce_lance_beam_tank_button_pressed():
	_produce(LanceBeamTankUnit)


func _on_produce_railgun_tank_button_pressed():
	_produce(RailgunTankUnit)


func _on_produce_hammer_siege_tank_button_pressed():
	_produce(HammerSiegeTankUnit)


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
