extends GridContainer

const CommandCenterUnit = preload("res://source/match/units/CommandCenter.tscn")
const VehicleFactoryUnit = preload("res://source/match/units/VehicleFactory.tscn")
const AircraftFactoryUnit = preload("res://source/match/units/AircraftFactory.tscn")
const AntiGroundTurretUnit = preload("res://source/match/units/AntiGroundTurret.tscn")
const AntiAirTurretUnit = preload("res://source/match/units/AntiAirTurret.tscn")
const TeslaFenceSegmentUnit = preload("res://source/match/units/TeslaFenceSegment.tscn")
const ArcCoilDefenseTowerUnit = preload("res://source/match/units/ArcCoilDefenseTower.tscn")
const LanceBeamDefenseTowerUnit = preload("res://source/match/units/LanceBeamDefenseTower.tscn")
const PrismDefenseObeliskUnit = preload("res://source/match/units/PrismDefenseObelisk.tscn")
const RailCannonBunkerUnit = preload("res://source/match/units/RailCannonBunker.tscn")
const PowerReactorUnit = preload("res://source/match/units/PowerReactor.tscn")
const AdvancedReactorPlantUnit = preload("res://source/match/units/AdvancedReactorPlant.tscn")
const RefineryUnit = preload("res://source/match/units/Refinery.tscn")
const OrePurifierUnit = preload("res://source/match/units/OrePurifier.tscn")
const BarracksUnit = preload("res://source/match/units/Barracks.tscn")
const RadarUplinkUnit = preload("res://source/match/units/RadarUplink.tscn")
const RoboticsBayUnit = preload("res://source/match/units/RoboticsBay.tscn")
const RepairPadUnit = preload("res://source/match/units/RepairPad.tscn")
const TechLabUnit = preload("res://source/match/units/TechLab.tscn")
const WeatherControlSpireUnit = preload("res://source/match/units/WeatherControlSpire.tscn")
const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const CommandButtonStatus = preload("res://source/match/hud/unit-menus/CommandButtonStatus.gd")

var unit = null

@onready var _ag_turret_button = find_child("PlaceAntiGroundTurretButton")
@onready var _aa_turret_button = find_child("PlaceAntiAirTurretButton")
@onready var _tesla_fence_button = find_child("PlaceTeslaFenceSegmentButton")
@onready var _arc_coil_tower_button = find_child("PlaceArcCoilDefenseTowerButton")
@onready var _lance_beam_tower_button = find_child("PlaceLanceBeamDefenseTowerButton")
@onready var _prism_defense_obelisk_button = find_child("PlacePrismDefenseObeliskButton")
@onready var _rail_cannon_bunker_button = find_child("PlaceRailCannonBunkerButton")
@onready var _power_reactor_button = find_child("PlacePowerReactorButton")
@onready var _advanced_reactor_button = find_child("PlaceAdvancedReactorPlantButton")
@onready var _refinery_button = find_child("PlaceRefineryButton")
@onready var _ore_purifier_button = find_child("PlaceOrePurifierButton")
@onready var _barracks_button = find_child("PlaceBarracksButton")
@onready var _radar_uplink_button = find_child("PlaceRadarUplinkButton")
@onready var _robotics_bay_button = find_child("PlaceRoboticsBayButton")
@onready var _repair_pad_button = find_child("PlaceRepairPadButton")
@onready var _tech_lab_button = find_child("PlaceTechLabButton")
@onready var _weather_control_spire_button = find_child("PlaceWeatherControlSpireButton")
@onready var _cc_button = find_child("PlaceCommandCenterButton")
@onready var _vehicle_factory_button = find_child("PlaceVehicleFactoryButton")
@onready var _aircraft_factory_button = find_child("PlaceAircraftFactoryButton")
@onready var _deploy_mcv_button = find_child("DeployMobileConstructionVehicleButton")


func _ready():
	CommandButtonHotkeys.assign_grid_hotkeys(self)
	_set_structure_tooltip(_ag_turret_button, AntiGroundTurretUnit, "AG_TURRET", "AG_TURRET_DESCRIPTION")
	_set_structure_tooltip(_aa_turret_button, AntiAirTurretUnit, "AA_TURRET", "AA_TURRET_DESCRIPTION")
	_set_structure_tooltip(
		_tesla_fence_button,
		TeslaFenceSegmentUnit,
		"TESLA_FENCE_SEGMENT",
		"TESLA_FENCE_SEGMENT_DESCRIPTION"
	)
	_set_structure_tooltip(
		_arc_coil_tower_button,
		ArcCoilDefenseTowerUnit,
		"ARC_COIL_DEFENSE_TOWER",
		"ARC_COIL_DEFENSE_TOWER_DESCRIPTION"
	)
	_set_structure_tooltip(
		_lance_beam_tower_button,
		LanceBeamDefenseTowerUnit,
		"LANCE_BEAM_DEFENSE_TOWER",
		"LANCE_BEAM_DEFENSE_TOWER_DESCRIPTION"
	)
	_set_structure_tooltip(
		_prism_defense_obelisk_button,
		PrismDefenseObeliskUnit,
		"PRISM_DEFENSE_OBELISK",
		"PRISM_DEFENSE_OBELISK_DESCRIPTION"
	)
	_set_structure_tooltip(
		_rail_cannon_bunker_button,
		RailCannonBunkerUnit,
		"RAIL_CANNON_BUNKER",
		"RAIL_CANNON_BUNKER_DESCRIPTION"
	)
	_set_structure_tooltip(
		_power_reactor_button, PowerReactorUnit, "POWER_REACTOR", "POWER_REACTOR_DESCRIPTION"
	)
	_set_structure_tooltip(
		_advanced_reactor_button,
		AdvancedReactorPlantUnit,
		"ADVANCED_REACTOR_PLANT",
		"ADVANCED_REACTOR_PLANT_DESCRIPTION"
	)
	_set_structure_tooltip(_refinery_button, RefineryUnit, "REFINERY", "REFINERY_DESCRIPTION")
	_set_structure_tooltip(
		_ore_purifier_button, OrePurifierUnit, "ORE_PURIFIER", "ORE_PURIFIER_DESCRIPTION"
	)
	_set_structure_tooltip(_barracks_button, BarracksUnit, "BARRACKS", "BARRACKS_DESCRIPTION")
	_set_structure_tooltip(_radar_uplink_button, RadarUplinkUnit, "RADAR_UPLINK", "RADAR_UPLINK_DESCRIPTION")
	_set_structure_tooltip(
		_robotics_bay_button, RoboticsBayUnit, "ROBOTICS_BAY", "ROBOTICS_BAY_DESCRIPTION"
	)
	_set_structure_tooltip(_repair_pad_button, RepairPadUnit, "REPAIR_PAD", "REPAIR_PAD_DESCRIPTION")
	_set_structure_tooltip(_tech_lab_button, TechLabUnit, "TECH_LAB", "TECH_LAB_DESCRIPTION")
	_set_structure_tooltip(
		_weather_control_spire_button,
		WeatherControlSpireUnit,
		"WEATHER_CONTROL_SPIRE",
		"WEATHER_CONTROL_SPIRE_DESCRIPTION"
	)
	_set_structure_tooltip(_cc_button, CommandCenterUnit, "CC", "CC_DESCRIPTION")
	_set_structure_tooltip(
		_vehicle_factory_button, VehicleFactoryUnit, "VEHICLE_FACTORY", "VEHICLE_FACTORY_DESCRIPTION"
	)
	_set_structure_tooltip(
		_aircraft_factory_button,
		AircraftFactoryUnit,
		"AIRCRAFT_FACTORY",
		"AIRCRAFT_FACTORY_DESCRIPTION"
	)
	_refresh_deploy_mcv_button()


func refresh():
	_refresh_structure_button(
		_ag_turret_button, AntiGroundTurretUnit, "AG_TURRET", "AG_TURRET_DESCRIPTION"
	)
	_refresh_structure_button(
		_aa_turret_button, AntiAirTurretUnit, "AA_TURRET", "AA_TURRET_DESCRIPTION"
	)
	_refresh_structure_button(
		_tesla_fence_button,
		TeslaFenceSegmentUnit,
		"TESLA_FENCE_SEGMENT",
		"TESLA_FENCE_SEGMENT_DESCRIPTION"
	)
	_refresh_structure_button(
		_arc_coil_tower_button,
		ArcCoilDefenseTowerUnit,
		"ARC_COIL_DEFENSE_TOWER",
		"ARC_COIL_DEFENSE_TOWER_DESCRIPTION"
	)
	_refresh_structure_button(
		_lance_beam_tower_button,
		LanceBeamDefenseTowerUnit,
		"LANCE_BEAM_DEFENSE_TOWER",
		"LANCE_BEAM_DEFENSE_TOWER_DESCRIPTION"
	)
	_refresh_structure_button(
		_prism_defense_obelisk_button,
		PrismDefenseObeliskUnit,
		"PRISM_DEFENSE_OBELISK",
		"PRISM_DEFENSE_OBELISK_DESCRIPTION"
	)
	_refresh_structure_button(
		_rail_cannon_bunker_button,
		RailCannonBunkerUnit,
		"RAIL_CANNON_BUNKER",
		"RAIL_CANNON_BUNKER_DESCRIPTION"
	)
	_refresh_structure_button(
		_power_reactor_button, PowerReactorUnit, "POWER_REACTOR", "POWER_REACTOR_DESCRIPTION"
	)
	_refresh_structure_button(
		_advanced_reactor_button,
		AdvancedReactorPlantUnit,
		"ADVANCED_REACTOR_PLANT",
		"ADVANCED_REACTOR_PLANT_DESCRIPTION"
	)
	_refresh_structure_button(_refinery_button, RefineryUnit, "REFINERY", "REFINERY_DESCRIPTION")
	_refresh_structure_button(
		_ore_purifier_button, OrePurifierUnit, "ORE_PURIFIER", "ORE_PURIFIER_DESCRIPTION"
	)
	_refresh_structure_button(_barracks_button, BarracksUnit, "BARRACKS", "BARRACKS_DESCRIPTION")
	_refresh_structure_button(
		_radar_uplink_button, RadarUplinkUnit, "RADAR_UPLINK", "RADAR_UPLINK_DESCRIPTION"
	)
	_refresh_structure_button(
		_robotics_bay_button, RoboticsBayUnit, "ROBOTICS_BAY", "ROBOTICS_BAY_DESCRIPTION"
	)
	_refresh_structure_button(_repair_pad_button, RepairPadUnit, "REPAIR_PAD", "REPAIR_PAD_DESCRIPTION")
	_refresh_structure_button(_tech_lab_button, TechLabUnit, "TECH_LAB", "TECH_LAB_DESCRIPTION")
	_refresh_structure_button(
		_weather_control_spire_button,
		WeatherControlSpireUnit,
		"WEATHER_CONTROL_SPIRE",
		"WEATHER_CONTROL_SPIRE_DESCRIPTION"
	)
	_refresh_structure_button(_cc_button, CommandCenterUnit, "CC", "CC_DESCRIPTION")
	_refresh_structure_button(
		_vehicle_factory_button, VehicleFactoryUnit, "VEHICLE_FACTORY", "VEHICLE_FACTORY_DESCRIPTION"
	)
	_refresh_structure_button(
		_aircraft_factory_button,
		AircraftFactoryUnit,
		"AIRCRAFT_FACTORY",
		"AIRCRAFT_FACTORY_DESCRIPTION"
	)
	_refresh_deploy_mcv_button()


func _refresh_structure_button(button, structure_scene, name_key, description_key):
	var missing_requirements = (
		Utils.Match.Unit.Tech.missing_construction_requirements(
			unit.player, structure_scene.resource_path
		)
		if unit != null
		else []
	)
	button.disabled = not missing_requirements.is_empty()
	_set_structure_tooltip(button, structure_scene, name_key, description_key, missing_requirements)


func _set_structure_tooltip(button, structure_scene, name_key, description_key, missing_requirements = []):
	var properties = Constants.Match.Units.DEFAULT_PROPERTIES[structure_scene.resource_path]
	var costs = Constants.Match.Units.CONSTRUCTION_COSTS[structure_scene.resource_path]
	var stats = "{0} HP".format([properties["hp_max"]])
	if properties.has("attack_damage"):
		var dps = float(properties["attack_damage"]) / float(properties["attack_interval"])
		stats += ", {0} DPS, {1} range".format([snappedf(dps, 0.1), properties["attack_range"]])
	if properties.has("repair_rate"):
		stats += ", {0} {1}".format([snappedf(properties["repair_rate"], 0.1), tr("REPAIR_RATE")])
	if properties.has("resource_bonus_ratio"):
		stats += ", +{0}% {1}".format(
			[roundi(properties["resource_bonus_ratio"] * 100.0), tr("RESOURCE_BONUS")]
		)
	stats += _format_power_stats(structure_scene.resource_path)
	var tooltip_text = (
		"{0} - {1}\n{2}\n{3}: {4}, {5}: {6}".format(
			[
				tr(name_key),
				tr(description_key),
				stats,
				tr("RESOURCE_A"),
				costs["resource_a"],
				tr("RESOURCE_B"),
				costs["resource_b"]
			]
		)
	)
	tooltip_text += _format_construction_requirements(structure_scene, missing_requirements)
	button.tooltip_text = CommandButtonHotkeys.tooltip(button, tooltip_text)
	CommandButtonStatus.apply_construction(
		button,
		structure_scene,
		missing_requirements,
		unit.player if unit != null else null,
		name_key
	)


func _format_construction_requirements(structure_scene, missing_requirements):
	var requirements = Constants.Match.Units.CONSTRUCTION_REQUIREMENTS.get(
		structure_scene.resource_path, []
	)
	if requirements.is_empty():
		return ""
	var text = "\n{0}: {1}".format(
		[tr("REQUIRES"), Utils.Match.Unit.Tech.requirement_names(requirements)]
	)
	if not missing_requirements.is_empty():
		text += "\n{0}: {1}".format(
			[tr("MISSING_TECH"), Utils.Match.Unit.Tech.requirement_names(missing_requirements)]
		)
	return text


func _format_power_stats(structure_path):
	var supply = Constants.Match.Units.POWER_SUPPLY.get(structure_path, 0)
	var drain = Constants.Match.Units.POWER_DRAIN.get(structure_path, 0)
	if supply > 0:
		return ", +{0} {1}".format([supply, tr("POWER")])
	if drain > 0:
		return ", -{0} {1}".format([drain, tr("POWER")])
	return ""


func _refresh_deploy_mcv_button():
	var can_deploy = (
		unit != null
		and unit.has_method("can_deploy_as_command_center")
		and unit.can_deploy_as_command_center()
	)
	_deploy_mcv_button.visible = can_deploy
	_deploy_mcv_button.disabled = not can_deploy
	CommandButtonStatus.apply_action(_deploy_mcv_button, "DEPLOY_MCV")
	_deploy_mcv_button.tooltip_text = CommandButtonHotkeys.tooltip(
		_deploy_mcv_button,
		"{0} - {1}".format([tr("DEPLOY_MCV"), tr("DEPLOY_MCV_DESCRIPTION")])
	)


func _try_place_structure(structure_scene):
	if unit == null:
		return
	if not Utils.Match.Unit.Tech.can_construct(unit.player, structure_scene.resource_path):
		return
	MatchSignals.place_structure.emit(structure_scene)


func _on_place_command_center_button_pressed():
	_try_place_structure(CommandCenterUnit)


func _on_place_vehicle_factory_button_pressed():
	_try_place_structure(VehicleFactoryUnit)


func _on_place_aircraft_factory_button_pressed():
	_try_place_structure(AircraftFactoryUnit)


func _on_place_anti_ground_turret_button_pressed():
	_try_place_structure(AntiGroundTurretUnit)


func _on_place_anti_air_turret_button_pressed():
	_try_place_structure(AntiAirTurretUnit)


func _on_place_tesla_fence_segment_button_pressed():
	_try_place_structure(TeslaFenceSegmentUnit)


func _on_place_arc_coil_defense_tower_button_pressed():
	_try_place_structure(ArcCoilDefenseTowerUnit)


func _on_place_lance_beam_defense_tower_button_pressed():
	_try_place_structure(LanceBeamDefenseTowerUnit)


func _on_place_prism_defense_obelisk_button_pressed():
	_try_place_structure(PrismDefenseObeliskUnit)


func _on_place_rail_cannon_bunker_button_pressed():
	_try_place_structure(RailCannonBunkerUnit)


func _on_place_power_reactor_button_pressed():
	_try_place_structure(PowerReactorUnit)


func _on_place_advanced_reactor_plant_button_pressed():
	_try_place_structure(AdvancedReactorPlantUnit)


func _on_place_refinery_button_pressed():
	_try_place_structure(RefineryUnit)


func _on_place_ore_purifier_button_pressed():
	_try_place_structure(OrePurifierUnit)


func _on_place_barracks_button_pressed():
	_try_place_structure(BarracksUnit)


func _on_place_radar_uplink_button_pressed():
	_try_place_structure(RadarUplinkUnit)


func _on_place_robotics_bay_button_pressed():
	_try_place_structure(RoboticsBayUnit)


func _on_place_repair_pad_button_pressed():
	_try_place_structure(RepairPadUnit)


func _on_place_tech_lab_button_pressed():
	_try_place_structure(TechLabUnit)


func _on_place_weather_control_spire_button_pressed():
	_try_place_structure(WeatherControlSpireUnit)


func _on_deploy_mobile_construction_vehicle_button_pressed():
	if (
		unit != null
		and unit.has_method("can_deploy_as_command_center")
		and unit.can_deploy_as_command_center()
	):
		unit.deploy_as_command_center()
