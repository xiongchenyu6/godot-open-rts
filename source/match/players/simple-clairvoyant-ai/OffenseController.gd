extends Node

signal resources_required(resources, metadata)

const Worker = preload("res://source/match/units/Worker.gd")
const CommandCenter = preload("res://source/match/units/CommandCenter.gd")
const PowerReactorScene = preload("res://source/match/units/PowerReactor.tscn")
const AdvancedReactorPlantScene = preload("res://source/match/units/AdvancedReactorPlant.tscn")
const RadarUplink = preload("res://source/match/units/RadarUplink.gd")
const RadarUplinkScene = preload("res://source/match/units/RadarUplink.tscn")
const RoboticsBay = preload("res://source/match/units/RoboticsBay.gd")
const RoboticsBayScene = preload("res://source/match/units/RoboticsBay.tscn")
const TechLab = preload("res://source/match/units/TechLab.gd")
const TechLabScene = preload("res://source/match/units/TechLab.tscn")
const WeatherControlSpire = preload("res://source/match/units/WeatherControlSpire.gd")
const WeatherControlSpireScene = preload("res://source/match/units/WeatherControlSpire.tscn")
const Barracks = preload("res://source/match/units/Barracks.gd")
const BarracksScene = preload("res://source/match/units/Barracks.tscn")
const VehicleFactory = preload("res://source/match/units/VehicleFactory.gd")
const VehicleFactoryScene = preload("res://source/match/units/VehicleFactory.tscn")
const Tank = preload("res://source/match/units/Tank.gd")
const TankScene = preload("res://source/match/units/Tank.tscn")
const LightRifleInfantry = preload("res://source/match/units/LightRifleInfantry.gd")
const LightRifleInfantryScene = preload("res://source/match/units/LightRifleInfantry.tscn")
const RocketInfantry = preload("res://source/match/units/RocketInfantry.gd")
const RocketInfantryScene = preload("res://source/match/units/RocketInfantry.tscn")
const FieldMedic = preload("res://source/match/units/FieldMedic.gd")
const FieldMedicScene = preload("res://source/match/units/FieldMedic.tscn")
const ShieldTrooper = preload("res://source/match/units/ShieldTrooper.gd")
const ShieldTrooperScene = preload("res://source/match/units/ShieldTrooper.tscn")
const FlakRocketTeam = preload("res://source/match/units/FlakRocketTeam.gd")
const FlakRocketTeamScene = preload("res://source/match/units/FlakRocketTeam.tscn")
const FlakRocketTeamMk2 = preload("res://source/match/units/FlakRocketTeamMk2.gd")
const FlakRocketTeamMk2Scene = preload("res://source/match/units/FlakRocketTeamMk2.tscn")
const HeavyMachinegunTrooper = preload("res://source/match/units/HeavyMachinegunTrooper.gd")
const HeavyMachinegunTrooperScene = preload("res://source/match/units/HeavyMachinegunTrooper.tscn")
const ShockTrooper = preload("res://source/match/units/ShockTrooper.gd")
const ShockTrooperScene = preload("res://source/match/units/ShockTrooper.tscn")
const GrenadierTrooper = preload("res://source/match/units/GrenadierTrooper.gd")
const GrenadierTrooperScene = preload("res://source/match/units/GrenadierTrooper.tscn")
const MortarTeam = preload("res://source/match/units/MortarTeam.gd")
const MortarTeamScene = preload("res://source/match/units/MortarTeam.tscn")
const CryoSprayer = preload("res://source/match/units/CryoSprayer.gd")
const CryoSprayerScene = preload("res://source/match/units/CryoSprayer.tscn")
const SniperScout = preload("res://source/match/units/SniperScout.gd")
const SniperScoutScene = preload("res://source/match/units/SniperScout.tscn")
const RailSniperTeam = preload("res://source/match/units/RailSniperTeam.gd")
const RailSniperTeamScene = preload("res://source/match/units/RailSniperTeam.tscn")
const PhaseSaboteur = preload("res://source/match/units/PhaseSaboteur.gd")
const PhaseSaboteurScene = preload("res://source/match/units/PhaseSaboteur.tscn")
const PulseRifleCommando = preload("res://source/match/units/PulseRifleCommando.gd")
const PulseRifleCommandoScene = preload("res://source/match/units/PulseRifleCommando.tscn")
const TacticalOfficer = preload("res://source/match/units/TacticalOfficer.gd")
const TacticalOfficerScene = preload("res://source/match/units/TacticalOfficer.tscn")
const ScoutRover = preload("res://source/match/units/ScoutRover.gd")
const ScoutRoverScene = preload("res://source/match/units/ScoutRover.tscn")
const MirageScoutTank = preload("res://source/match/units/MirageScoutTank.gd")
const MirageScoutTankScene = preload("res://source/match/units/MirageScoutTank.tscn")
const FlameAssaultBuggy = preload("res://source/match/units/FlameAssaultBuggy.gd")
const FlameAssaultBuggyScene = preload("res://source/match/units/FlameAssaultBuggy.tscn")
const DroneMineLayer = preload("res://source/match/units/DroneMineLayer.gd")
const DroneMineLayerScene = preload("res://source/match/units/DroneMineLayer.tscn")
const TeslaCrawlerMk2 = preload("res://source/match/units/TeslaCrawlerMk2.gd")
const TeslaCrawlerMk2Scene = preload("res://source/match/units/TeslaCrawlerMk2.tscn")
const RocketTrooperRobot = preload("res://source/match/units/RocketTrooperRobot.gd")
const RocketTrooperRobotScene = preload("res://source/match/units/RocketTrooperRobot.tscn")
const JammerVehicle = preload("res://source/match/units/JammerVehicle.gd")
const JammerVehicleScene = preload("res://source/match/units/JammerVehicle.tscn")
const AntiAirWalker = preload("res://source/match/units/AntiAirWalker.gd")
const AntiAirWalkerScene = preload("res://source/match/units/AntiAirWalker.tscn")
const FlakHoverTank = preload("res://source/match/units/FlakHoverTank.gd")
const FlakHoverTankScene = preload("res://source/match/units/FlakHoverTank.tscn")
const MobileRepairCrawler = preload("res://source/match/units/MobileRepairCrawler.gd")
const MobileRepairCrawlerScene = preload("res://source/match/units/MobileRepairCrawler.tscn")
const MobileShieldProjector = preload("res://source/match/units/MobileShieldProjector.gd")
const MobileShieldProjectorScene = preload("res://source/match/units/MobileShieldProjector.tscn")
const ModularMissileCarrier = preload("res://source/match/units/ModularMissileCarrier.gd")
const ModularMissileCarrierScene = preload("res://source/match/units/ModularMissileCarrier.tscn")
const LongbowMissileCrawler = preload("res://source/match/units/LongbowMissileCrawler.gd")
const LongbowMissileCrawlerScene = preload("res://source/match/units/LongbowMissileCrawler.tscn")
const SiegeArtilleryVehicle = preload("res://source/match/units/SiegeArtilleryVehicle.gd")
const SiegeArtilleryVehicleScene = preload("res://source/match/units/SiegeArtilleryVehicle.tscn")
const SiegeDrillTank = preload("res://source/match/units/SiegeDrillTank.gd")
const SiegeDrillTankScene = preload("res://source/match/units/SiegeDrillTank.tscn")
const LanceBeamTank = preload("res://source/match/units/LanceBeamTank.gd")
const LanceBeamTankScene = preload("res://source/match/units/LanceBeamTank.tscn")
const RailgunTank = preload("res://source/match/units/RailgunTank.gd")
const RailgunTankScene = preload("res://source/match/units/RailgunTank.tscn")
const HammerSiegeTank = preload("res://source/match/units/HammerSiegeTank.gd")
const HammerSiegeTankScene = preload("res://source/match/units/HammerSiegeTank.tscn")
const HeavySiegeWalker = preload("res://source/match/units/HeavySiegeWalker.gd")
const HeavySiegeWalkerScene = preload("res://source/match/units/HeavySiegeWalker.tscn")
const RailArtilleryWalker = preload("res://source/match/units/RailArtilleryWalker.gd")
const RailArtilleryWalkerScene = preload("res://source/match/units/RailArtilleryWalker.tscn")
const AircraftFactory = preload("res://source/match/units/AircraftFactory.gd")
const AircraftFactoryScene = preload("res://source/match/units/AircraftFactory.tscn")
const Helicopter = preload("res://source/match/units/Helicopter.gd")
const HelicopterScene = preload("res://source/match/units/Helicopter.tscn")
const InterceptorVTOL = preload("res://source/match/units/InterceptorVTOL.gd")
const InterceptorVTOLScene = preload("res://source/match/units/InterceptorVTOL.tscn")
const BomberVTOL = preload("res://source/match/units/BomberVTOL.gd")
const BomberVTOLScene = preload("res://source/match/units/BomberVTOL.tscn")
const RocketGunship = preload("res://source/match/units/RocketGunship.gd")
const RocketGunshipScene = preload("res://source/match/units/RocketGunship.tscn")
const HeavyBombardmentAirship = preload("res://source/match/units/HeavyBombardmentAirship.gd")
const HeavyBombardmentAirshipScene = preload(
	"res://source/match/units/HeavyBombardmentAirship.tscn"
)
const SiegeAirship = preload("res://source/match/units/SiegeAirship.gd")
const SiegeAirshipScene = preload("res://source/match/units/SiegeAirship.tscn")
const AutoAttackingBattlegroup = preload(
	"res://source/match/players/simple-clairvoyant-ai/AutoAttackingBattlegroup.gd"
)

const REFRESH_INTERVAL_S = 1.0 / 60.0 * 30.0

var _player = null
var _primary_structure_scene = null
var _secondary_structure_scene = null
var _tertiary_structure_scene = null
var _number_of_pending_structure_resource_requests = {}
var _primary_unit_scenes = []
var _secondary_unit_scenes = []
var _tertiary_unit_scenes = []
var _number_of_pending_unit_resource_requests = {}
var _pending_unit_scene_by_metadata = {}
var _unit_scene_cursor_by_metadata = {}
var _battlegroup_under_forming = null
var _battlegroups = []

@onready var _ai = get_parent()


func setup(player):
	_player = player
	_primary_structure_scene = _structure_scene_for_offensive_structure(
		_ai.primary_offensive_structure
	)
	_secondary_structure_scene = _structure_scene_for_offensive_structure(
		_ai.secondary_offensive_structure
	)
	_tertiary_structure_scene = _structure_scene_for_offensive_structure(
		_ai.tertiary_offensive_structure
	)
	_primary_unit_scenes = _unit_scenes_for_structure(_ai.primary_offensive_structure)
	_secondary_unit_scenes = _unit_scenes_for_structure(_ai.secondary_offensive_structure)
	_tertiary_unit_scenes = _unit_scenes_for_structure(_ai.tertiary_offensive_structure)
	_setup_refresh_timer()
	_try_creating_new_battlegroup()
	_attach_current_battle_units()
	MatchSignals.unit_spawned.connect(_on_unit_spawned)
	MatchSignals.unit_construction_finished.connect(_on_unit_construction_finished)
	MatchSignals.unit_captured.connect(_on_unit_captured)
	_enforce_primary_structure_existence()
	_enforce_power_capacity()
	_enforce_tech_structure_existence()


func provision(resources, metadata):
	if metadata == "primary_structure":
		_provision_structure(_primary_structure_scene, resources, metadata)
	elif metadata == "secondary_structure":
		_provision_structure(_secondary_structure_scene, resources, metadata)
	elif metadata == "tertiary_structure":
		_provision_structure(_tertiary_structure_scene, resources, metadata)
	elif metadata == "power_reactor":
		_provision_structure(PowerReactorScene, resources, metadata)
	elif metadata == "advanced_reactor_plant":
		_provision_structure(AdvancedReactorPlantScene, resources, metadata)
	elif metadata == "radar_uplink":
		_provision_structure(RadarUplinkScene, resources, metadata)
	elif metadata == "robotics_bay":
		_provision_structure(RoboticsBayScene, resources, metadata)
	elif metadata == "tech_lab":
		_provision_structure(TechLabScene, resources, metadata)
	elif metadata == "weather_control_spire":
		_provision_structure(WeatherControlSpireScene, resources, metadata)
	elif metadata == "primary_unit":
		_provision_unit(
			_pending_unit_scene_by_metadata.get(metadata, null),
			_primary_structure(),
			resources,
			metadata
		)
	elif metadata == "secondary_unit":
		_provision_unit(
			_pending_unit_scene_by_metadata.get(metadata, null),
			_secondary_structure(),
			resources,
			metadata
		)
	elif metadata == "tertiary_unit":
		_provision_unit(
			_pending_unit_scene_by_metadata.get(metadata, null),
			_tertiary_structure(),
			resources,
			metadata
		)
	else:
		push_warning("Ignoring unknown AI offense resource request metadata: {0}".format([metadata]))


func _setup_refresh_timer():
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_refresh_timer_timeout)
	timer.start(REFRESH_INTERVAL_S)


func _provision_structure(structure_scene, resources, metadata):
	_decrement_pending_request(_number_of_pending_structure_resource_requests, metadata)
	if structure_scene == null:
		push_warning("Ignoring AI offense structure provision with no scene for {0}".format([metadata]))
		return
	if not _resources_match(
		resources,
		Constants.Match.Units.CONSTRUCTION_COSTS[structure_scene.resource_path],
		metadata
	):
		return
	var workers = get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return unit is Worker and unit.can_construct_structures() and unit.player == _player
	)
	if workers.is_empty():
		return
	_construct_structure(structure_scene)


func _provision_unit(unit_scene, structure_producing_unit, resources, metadata):
	_decrement_pending_request(_number_of_pending_unit_resource_requests, metadata)
	_pending_unit_scene_by_metadata.erase(metadata)
	if unit_scene == null:
		push_warning("Ignoring AI offense unit provision with no scene for {0}".format([metadata]))
		return
	if not _resources_match(
		resources,
		Constants.Match.Units.PRODUCTION_COSTS[unit_scene.resource_path],
		metadata
	):
		return
	if structure_producing_unit == null:
		return
	structure_producing_unit.production_queue.produce(unit_scene, true)


func _resources_match(resources, expected_resources, metadata):
	if resources == expected_resources:
		return true
	push_warning(
		"Ignoring AI offense resource provision for {0}: expected {1}, got {2}".format(
			[metadata, expected_resources, resources]
		)
	)
	return false


func _decrement_pending_request(pending_counts, metadata):
	pending_counts[metadata] = max(0, int(pending_counts.get(metadata, 0)) - 1)


func _try_creating_new_battlegroup():
	if _battlegroup_under_forming != null:
		return false
	if not _battlegroups.is_empty():
		_enforce_secondary_structure_existence()
		_enforce_tertiary_structure_existence()
	if _battlegroups.size() >= _ai.expected_number_of_battlegroups:
		for structure in _offensive_structures():
			if structure != null:
				structure.production_queue.cancel_all()
		_battlegroup_under_forming = null
		return false
	var adversary_players = get_tree().get_nodes_in_group("players").filter(
		func(player): return _player.is_enemy_with(player)
	)
	if adversary_players.is_empty():
		return false
	adversary_players.shuffle()
	var battlegroup = AutoAttackingBattlegroup.new(
		_ai.expected_number_of_units_in_battlegroup, adversary_players
	)
	_battlegroups.append(battlegroup)
	battlegroup.tree_exited.connect(_on_battlegroup_died.bind(battlegroup))
	add_child(battlegroup)
	_battlegroup_under_forming = battlegroup
	return true


func _attach_current_battle_units():
	var battle_units = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit.player == _player and _is_battle_unit(unit)
	)
	for battle_unit in battle_units:
		_on_unit_spawned(battle_unit)


func _construct_structure(structure_scene):
	var construction_cost = Constants.Match.Units.CONSTRUCTION_COSTS[structure_scene.resource_path]
	assert(
		_player.has_resources(construction_cost),
		"player should have enough resources at this point"
	)
	var ccs = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is CommandCenter and unit.player == _player
	)
	var workers = get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return unit is Worker and unit.can_construct_structures() and unit.player == _player
	)
	var unit_to_spawn = structure_scene.instantiate()
	var reference_unit_for_placement = _frontline_build_anchor(ccs, workers)
	if reference_unit_for_placement == null:
		unit_to_spawn.free()
		return
	var offense_direction = _offense_direction_from(reference_unit_for_placement.global_position)
	var placement_position = Utils.Match.Unit.Placement.find_valid_position_radially_yet_skip_starting_radius(
		reference_unit_for_placement.global_position,
		reference_unit_for_placement.radius,
		unit_to_spawn.radius + Constants.Match.Units.EMPTY_SPACE_RADIUS_SURROUNDING_STRUCTURE_M,
		0.1,
		offense_direction,
		false,
		find_parent("Match").navigation.get_navigation_map_rid_by_domain(
			unit_to_spawn.movement_domain
		),
		get_tree()
	)
	if placement_position == Vector3.INF:
		unit_to_spawn.free()
		return
	var target_transform = Transform3D(Basis(), placement_position).looking_at(
		placement_position + offense_direction, Vector3.UP
	)
	_player.subtract_resources(construction_cost)
	MatchSignals.setup_and_spawn_unit.emit(unit_to_spawn, target_transform, _player)
	_enforce_primary_units_production.call_deferred()
	_enforce_secondary_units_production.call_deferred()
	_enforce_tertiary_units_production.call_deferred()


func _frontline_build_anchor(command_centers, workers):
	var candidates = command_centers if not command_centers.is_empty() else workers
	if candidates.is_empty():
		return null
	var enemies = _enemy_units()
	if enemies.is_empty():
		return candidates[0]
	var best_candidate = candidates[0]
	var best_distance = INF
	for candidate in candidates:
		var distance = _distance_to_nearest_enemy(candidate.global_position_yless, enemies)
		if distance < best_distance:
			best_distance = distance
			best_candidate = candidate
	return best_candidate


func _offense_direction_from(origin):
	var nearest_enemy = _nearest_enemy_to(origin)
	if nearest_enemy == null:
		return Vector3(0, 0, 1)
	var direction = nearest_enemy.global_position_yless - (origin * Vector3(1, 0, 1))
	if direction.is_zero_approx():
		return Vector3(0, 0, 1)
	return direction.normalized()


func _nearest_enemy_to(origin):
	var enemies = _enemy_units()
	if enemies.is_empty():
		return null
	var origin_yless = origin * Vector3(1, 0, 1)
	var best_enemy = enemies[0]
	var best_distance = INF
	for enemy in enemies:
		var distance = enemy.global_position_yless.distance_to(origin_yless)
		if distance < best_distance:
			best_distance = distance
			best_enemy = enemy
	return best_enemy


func _distance_to_nearest_enemy(origin_yless, enemies):
	var best_distance = INF
	for enemy in enemies:
		best_distance = minf(best_distance, enemy.global_position_yless.distance_to(origin_yless))
	return best_distance


func _enemy_units():
	return get_tree().get_nodes_in_group("units").filter(
		func(unit): return _is_living_enemy_unit(unit)
	)


func _enforce_primary_structure_existence():
	_enforce_structure_existence(
		_primary_structure(), _primary_structure_scene, "primary_structure"
	)


func _enforce_secondary_structure_existence():
	_enforce_structure_existence(
		_secondary_structure(), _secondary_structure_scene, "secondary_structure"
	)


func _enforce_tertiary_structure_existence():
	if _is_tertiary_offensive_structure_duplicate():
		return
	_enforce_structure_existence(
		_tertiary_structure(), _tertiary_structure_scene, "tertiary_structure"
	)


func _enforce_power_capacity():
	if _number_of_pending_structure_resource_requests.get("power_reactor", 0) > 0:
		return
	if _number_of_pending_structure_resource_requests.get("advanced_reactor_plant", 0) > 0:
		return
	if _player.get_power_margin(true) >= Constants.Match.Power.AI_TARGET_RESERVE:
		return
	var power_scene = _power_supply_scene_for_capacity()
	var metadata = _power_supply_metadata(power_scene)
	_number_of_pending_structure_resource_requests[metadata] = 1
	resources_required.emit(
		Constants.Match.Units.CONSTRUCTION_COSTS[power_scene.resource_path], metadata
	)


func _enforce_tech_structure_existence():
	_enforce_structure_existence(_radar_uplink(), RadarUplinkScene, "radar_uplink")
	if Utils.Match.Unit.Tech.player_has_constructed_structure(_player, RadarUplinkScene.resource_path):
		_enforce_structure_existence(_robotics_bay(), RoboticsBayScene, "robotics_bay")
	if Utils.Match.Unit.Tech.player_has_constructed_structure(_player, RoboticsBayScene.resource_path):
		_enforce_structure_existence(_tech_lab(), TechLabScene, "tech_lab")
	if Utils.Match.Unit.Tech.player_has_constructed_structure(_player, TechLabScene.resource_path):
		_enforce_structure_existence(
			_weather_control_spire(), WeatherControlSpireScene, "weather_control_spire"
		)


func _enforce_structure_existence(structure, structure_scene, type):
	if structure == null and _number_of_pending_structure_resource_requests.get(type, 0) == 0:
		_number_of_pending_structure_resource_requests[type] = (
			_number_of_pending_structure_resource_requests.get(type, 0) + 1
		)
		resources_required.emit(
			Constants.Match.Units.CONSTRUCTION_COSTS[structure_scene.resource_path], type
		)


func _enforce_primary_units_production():
	_enforce_units_production(_primary_structure(), _primary_unit_scenes, "primary_unit")


func _enforce_secondary_units_production():
	_enforce_units_production(_secondary_structure(), _secondary_unit_scenes, "secondary_unit")


func _enforce_tertiary_units_production():
	if _is_tertiary_offensive_structure_duplicate():
		return
	_enforce_units_production(_tertiary_structure(), _tertiary_unit_scenes, "tertiary_unit")


func _enforce_units_production(structure, unit_scenes, type):
	if structure == null or not structure.is_constructed() or not _is_units_production_allowed():
		return
	var number_of_pending_units = structure.production_queue.size()
	if number_of_pending_units + _number_of_pending_unit_resource_requests.get(type, 0) == 0:
		var unit_scene = _pick_next_available_unit_scene(unit_scenes, type)
		if unit_scene == null:
			return
		_number_of_pending_unit_resource_requests[type] = (
			_number_of_pending_unit_resource_requests.get(type, 0) + 1
		)
		_pending_unit_scene_by_metadata[type] = unit_scene
		resources_required.emit(
			Constants.Match.Units.PRODUCTION_COSTS[unit_scene.resource_path], type
		)


func _primary_structure():
	return _offensive_structure_for(_ai.primary_offensive_structure)


func _secondary_structure():
	return _offensive_structure_for(_ai.secondary_offensive_structure)


func _tertiary_structure():
	return _offensive_structure_for(_ai.tertiary_offensive_structure)


func _offensive_structures():
	var structures = []
	for structure in [_primary_structure(), _secondary_structure(), _tertiary_structure()]:
		if structure != null and not structure in structures:
			structures.append(structure)
	return structures


func _is_tertiary_offensive_structure_duplicate():
	return (
		_ai.tertiary_offensive_structure == _ai.primary_offensive_structure
		or _ai.tertiary_offensive_structure == _ai.secondary_offensive_structure
	)


func _offensive_structure_for(offensive_structure):
	var structures = get_tree().get_nodes_in_group("units").filter(
		func(unit): return _is_offensive_structure(unit, offensive_structure) and unit.player == _player
	)
	return structures[0] if not structures.is_empty() else null


func _is_offensive_structure(unit, offensive_structure):
	match _normalized_offensive_structure(offensive_structure):
		_ai.OffensiveStructure.VEHICLE_FACTORY:
			return unit is VehicleFactory
		_ai.OffensiveStructure.AIRCRAFT_FACTORY:
			return unit is AircraftFactory
		_ai.OffensiveStructure.BARRACKS:
			return unit is Barracks


func _radar_uplink():
	var radar_uplinks = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is RadarUplink and unit.player == _player
	)
	return radar_uplinks[0] if not radar_uplinks.is_empty() else null


func _tech_lab():
	var tech_labs = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is TechLab and unit.player == _player
	)
	return tech_labs[0] if not tech_labs.is_empty() else null


func _weather_control_spire():
	var weather_control_spires = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is WeatherControlSpire and unit.player == _player
	)
	return weather_control_spires[0] if not weather_control_spires.is_empty() else null


func _robotics_bay():
	var robotics_bays = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is RoboticsBay and unit.player == _player
	)
	return robotics_bays[0] if not robotics_bays.is_empty() else null


func _power_supply_scene_for_capacity():
	if Utils.Match.Unit.Tech.player_has_constructed_structure(_player, TechLabScene.resource_path):
		return AdvancedReactorPlantScene
	return PowerReactorScene


func _power_supply_metadata(power_scene):
	if power_scene == AdvancedReactorPlantScene:
		return "advanced_reactor_plant"
	return "power_reactor"


func _is_units_production_allowed():
	var pending_or_queued_units = Utils.Arr.sum(_number_of_pending_unit_resource_requests.values())
	for structure in _offensive_structures():
		if structure == null or not structure.is_constructed():
			continue
		pending_or_queued_units += structure.production_queue.size()
	return (
		_number_of_additional_units_required()
		> pending_or_queued_units
	)


func _number_of_additional_units_required():
	if _battlegroup_under_forming == null:
		return 0
	return (
		_ai.expected_number_of_battlegroups * _ai.expected_number_of_units_in_battlegroup
		- (_battlegroups.size() - 1) * _ai.expected_number_of_units_in_battlegroup
		- _battlegroup_under_forming.size()
	)


func _on_unit_spawned(unit):
	if unit.player != _player:
		return
	if _is_battle_unit(unit):
		# TODO: check if this still happens after ensuring only own players should match
		# assert(_battlegroup_under_forming != null) # TODO: investigate how do we get here
		if _battlegroup_under_forming == null:
			return
		_battlegroup_under_forming.attach_unit(unit)
		if _battlegroup_under_forming.size() == _ai.expected_number_of_units_in_battlegroup:
			_battlegroup_under_forming = null
			_try_creating_new_battlegroup()
		_enforce_primary_units_production()
		_enforce_secondary_units_production()
		_enforce_tertiary_units_production()


func _on_unit_construction_finished(unit):
	if unit.player != _player:
		return
	_enforce_power_capacity()
	_enforce_tech_structure_existence()
	_enforce_primary_units_production()
	_enforce_secondary_units_production()
	_enforce_tertiary_units_production()


func _on_unit_captured(_unit, previous_player, new_player):
	if previous_player != _player and new_player != _player:
		return
	_enforce_primary_structure_existence()
	_enforce_power_capacity()
	_enforce_tech_structure_existence()
	_enforce_primary_units_production()
	_enforce_secondary_units_production()
	_enforce_tertiary_units_production()


func _on_battlegroup_died(battlegroup):
	if not is_inside_tree():
		return
	_battlegroups.erase(battlegroup)
	if _battlegroup_under_forming == battlegroup:
		_battlegroup_under_forming = null
	call_deferred("_replace_lost_battlegroup")


func _replace_lost_battlegroup():
	if not is_inside_tree():
		return
	if _battlegroup_under_forming == null:
		_try_creating_new_battlegroup()
	_enforce_primary_units_production()
	_enforce_secondary_units_production()
	_enforce_tertiary_units_production()


func _on_refresh_timer_timeout():
	_enforce_primary_structure_existence()
	_enforce_power_capacity()
	_enforce_tech_structure_existence()
	# secondary structure existence is enforced only when a battlegroup is formed
	_enforce_primary_units_production()
	_enforce_secondary_units_production()
	_enforce_tertiary_units_production()


func _unit_scenes_for_structure(offensive_structure):
	match _normalized_offensive_structure(offensive_structure):
		_ai.OffensiveStructure.VEHICLE_FACTORY:
			return [
				TankScene,
				ScoutRoverScene,
				MirageScoutTankScene,
				FlameAssaultBuggyScene,
				DroneMineLayerScene,
				TeslaCrawlerMk2Scene,
				RocketTrooperRobotScene,
				ModularMissileCarrierScene,
				JammerVehicleScene,
				AntiAirWalkerScene,
				FlakHoverTankScene,
				MobileRepairCrawlerScene,
				MobileShieldProjectorScene,
				LongbowMissileCrawlerScene,
				SiegeArtilleryVehicleScene,
				SiegeDrillTankScene,
				LanceBeamTankScene,
				RailgunTankScene,
				HammerSiegeTankScene,
				HeavySiegeWalkerScene,
				RailArtilleryWalkerScene,
			]
		_ai.OffensiveStructure.AIRCRAFT_FACTORY:
			return [
				HelicopterScene,
				InterceptorVTOLScene,
				BomberVTOLScene,
				RocketGunshipScene,
				HeavyBombardmentAirshipScene,
				SiegeAirshipScene,
			]
		_ai.OffensiveStructure.BARRACKS:
			return [
				LightRifleInfantryScene,
				HeavyMachinegunTrooperScene,
				FieldMedicScene,
				ShieldTrooperScene,
					ShockTrooperScene,
					RocketInfantryScene,
					FlakRocketTeamScene,
					FlakRocketTeamMk2Scene,
					GrenadierTrooperScene,
					MortarTeamScene,
					CryoSprayerScene,
					SniperScoutScene,
					RailSniperTeamScene,
					PhaseSaboteurScene,
					PulseRifleCommandoScene,
					TacticalOfficerScene,
			]


func _structure_scene_for_offensive_structure(offensive_structure):
	match _normalized_offensive_structure(offensive_structure):
		_ai.OffensiveStructure.VEHICLE_FACTORY:
			return VehicleFactoryScene
		_ai.OffensiveStructure.AIRCRAFT_FACTORY:
			return AircraftFactoryScene
		_ai.OffensiveStructure.BARRACKS:
			return BarracksScene


func _normalized_offensive_structure(offensive_structure):
	match offensive_structure:
		_ai.OffensiveStructure.VEHICLE_FACTORY:
			return offensive_structure
		_ai.OffensiveStructure.AIRCRAFT_FACTORY:
			return offensive_structure
		_ai.OffensiveStructure.BARRACKS:
			return offensive_structure
		_:
			push_warning(
				"Unknown AI offensive structure {0}; falling back to vehicle factory".format(
					[offensive_structure]
				)
			)
			return _ai.OffensiveStructure.VEHICLE_FACTORY


func _pick_next_unit_scene(unit_scenes, metadata):
	var cursor = _unit_scene_cursor_by_metadata.get(metadata, 0)
	_unit_scene_cursor_by_metadata[metadata] = cursor + 1
	return unit_scenes[cursor % unit_scenes.size()]


func _pick_next_available_unit_scene(unit_scenes, metadata):
	var counter_unit_scene = _pick_next_counter_unit_scene(unit_scenes, metadata)
	if counter_unit_scene != null:
		return counter_unit_scene
	for _i in range(unit_scenes.size()):
		var unit_scene = _pick_next_unit_scene(unit_scenes, metadata)
		if Utils.Match.Unit.Tech.can_produce(_player, unit_scene.resource_path):
			return unit_scene
	return null


func _pick_next_counter_unit_scene(unit_scenes, metadata):
	if not _needs_more_anti_air_units():
		return null
	for _i in range(unit_scenes.size()):
		var unit_scene = _pick_next_unit_scene(unit_scenes, metadata)
		if not Utils.Match.Unit.Tech.can_produce(_player, unit_scene.resource_path):
			continue
		if _unit_scene_can_attack_domain(unit_scene, Constants.Match.Navigation.Domain.AIR):
			return unit_scene
	return null


func _needs_more_anti_air_units():
	var enemy_air_units_count = _enemy_air_units_count()
	if enemy_air_units_count == 0:
		return false
	return _anti_air_response_count() < enemy_air_units_count


func _enemy_air_units_count():
	var count = 0
	for unit in get_tree().get_nodes_in_group("units"):
		if (
			_is_living_enemy_unit(unit)
			and "movement_domain" in unit
			and unit.movement_domain == Constants.Match.Navigation.Domain.AIR
		):
			count += 1
	return count


func _anti_air_response_count():
	var count = 0
	for unit in get_tree().get_nodes_in_group("units"):
		if _is_own_living_anti_air_unit(unit):
			count += 1
	for structure in _offensive_structures():
		if structure == null or structure.production_queue == null:
			continue
		for queue_element in structure.production_queue.get_elements():
			if _unit_scene_can_attack_domain(
				queue_element.unit_prototype, Constants.Match.Navigation.Domain.AIR
			):
				count += 1
	for pending_unit_scene in _pending_unit_scene_by_metadata.values():
		if _unit_scene_can_attack_domain(pending_unit_scene, Constants.Match.Navigation.Domain.AIR):
			count += 1
	return count


func _is_living_enemy_unit(unit):
	return (
		"player" in unit
		and _player.is_enemy_with(unit.player)
		and "hp" in unit
		and unit.hp != null
		and unit.hp > 0
	)


func _is_own_living_anti_air_unit(unit):
	return (
		"player" in unit
		and unit.player == _player
		and "hp" in unit
		and unit.hp != null
		and unit.hp > 0
		and "attack_damage" in unit
		and unit.attack_damage != null
		and unit.attack_damage > 0
		and "attack_domains" in unit
		and Constants.Match.Navigation.Domain.AIR in unit.attack_domains
	)


func _unit_scene_can_attack_domain(unit_scene, domain):
	if unit_scene == null:
		return false
	var unit_properties = Constants.Match.Units.DEFAULT_PROPERTIES.get(unit_scene.resource_path, {})
	if unit_properties.get("attack_damage", 0) <= 0:
		return false
	return domain in unit_properties.get("attack_domains", [])


func _is_battle_unit(unit):
	return (
		unit is Tank
		or unit is LightRifleInfantry
		or unit is RocketInfantry
		or unit is FieldMedic
			or unit is ShieldTrooper
			or unit is FlakRocketTeam
			or unit is FlakRocketTeamMk2
			or unit is HeavyMachinegunTrooper
		or unit is ShockTrooper
		or unit is GrenadierTrooper
		or unit is MortarTeam
		or unit is CryoSprayer
		or unit is SniperScout
			or unit is RailSniperTeam
			or unit is PhaseSaboteur
			or unit is PulseRifleCommando
		or unit is TacticalOfficer
		or unit is ScoutRover
		or unit is MirageScoutTank
		or unit is FlameAssaultBuggy
		or unit is DroneMineLayer
		or unit is TeslaCrawlerMk2
		or unit is RocketTrooperRobot
		or unit is JammerVehicle
		or unit is AntiAirWalker
		or unit is FlakHoverTank
		or unit is MobileRepairCrawler
		or unit is MobileShieldProjector
		or unit is ModularMissileCarrier
		or unit is LongbowMissileCrawler
		or unit is SiegeArtilleryVehicle
		or unit is SiegeDrillTank
		or unit is LanceBeamTank
		or unit is RailgunTank
		or unit is HammerSiegeTank
		or unit is HeavySiegeWalker
		or unit is RailArtilleryWalker
		or unit is Helicopter
		or unit is InterceptorVTOL
		or unit is BomberVTOL
		or unit is RocketGunship
		or unit is HeavyBombardmentAirship
		or unit is SiegeAirship
	)
