extends "res://tests/manual/Match.gd"

const VehicleFactoryUnit = preload("res://source/match/units/VehicleFactory.tscn")
const BarracksUnit = preload("res://source/match/units/Barracks.tscn")
const AircraftFactoryUnit = preload("res://source/match/units/AircraftFactory.tscn")
const TankUnit = preload("res://source/match/units/Tank.tscn")
const LightRifleInfantryUnit = preload("res://source/match/units/LightRifleInfantry.tscn")
const FieldMedicUnit = preload("res://source/match/units/FieldMedic.tscn")
const ShieldTrooperUnit = preload("res://source/match/units/ShieldTrooper.tscn")
const TacticalOfficerUnit = preload("res://source/match/units/TacticalOfficer.tscn")
const RailSniperTeamUnit = preload("res://source/match/units/RailSniperTeam.tscn")
const DroneMineLayerUnit = preload("res://source/match/units/DroneMineLayer.tscn")
const TeslaCrawlerMk2Unit = preload("res://source/match/units/TeslaCrawlerMk2.tscn")
const HelicopterUnit = preload("res://source/match/units/Helicopter.tscn")
const FlakRocketTeamUnit = preload("res://source/match/units/FlakRocketTeam.tscn")
const FlakRocketTeamMk2Unit = preload("res://source/match/units/FlakRocketTeamMk2.tscn")
const SaboteurInfiltratorUnit = preload("res://source/match/units/SaboteurInfiltrator.tscn")
const HammerSiegeTankUnit = preload("res://source/match/units/HammerSiegeTank.tscn")
const SiegeAirshipUnit = preload("res://source/match/units/SiegeAirship.tscn")
const MobileRepairCrawlerUnit = preload("res://source/match/units/MobileRepairCrawler.tscn")
const RailArtilleryWalkerUnit = preload("res://source/match/units/RailArtilleryWalker.tscn")
const SiegeDrillTankUnit = preload("res://source/match/units/SiegeDrillTank.tscn")
const OreHarvesterUnit = preload("res://source/match/units/OreHarvester.tscn")
const AdvancedReactorPlantUnit = preload("res://source/match/units/AdvancedReactorPlant.tscn")
const REPLACEMENT_TIMEOUT_S = 1.0

@onready var _ai = $Players/SimpleClairvoyantAI
@onready var _human = $Players/Human
@onready var _offense_controller = $Players/SimpleClairvoyantAI/OffenseController
@onready var _vehicle_factory = $Players/SimpleClairvoyantAI/VehicleFactory
@onready var _barracks = $Players/SimpleClairvoyantAI/Barracks
@onready var _aircraft_factory = $Players/SimpleClairvoyantAI/AircraftFactory


func _ready():
	super()
	for _i in range(8):
		await get_tree().process_frame
	assert(
		_ai.tertiary_offensive_structure == _ai.OffensiveStructure.AIRCRAFT_FACTORY,
		"default AI tertiary offense should be aircraft"
	)
	assert(
		_vehicle_factory.production_queue.get_elements().size() > 0,
		"AI should queue vehicle production for mixed offense"
	)
	assert(
		_barracks.production_queue.get_elements().size() > 0,
		"AI should queue infantry production for mixed offense"
	)
	assert(
		_aircraft_factory.production_queue.get_elements().size() > 0,
		"AI should queue aircraft production for mixed offense"
	)
	var opening_vehicle_queue_path = (
		_vehicle_factory.production_queue.get_elements()[0].unit_prototype.resource_path
	)
	var opening_vehicle_unit = load(opening_vehicle_queue_path).instantiate()
	assert(
		opening_vehicle_queue_path == OreHarvesterUnit.resource_path
		or _offense_controller._is_battle_unit(opening_vehicle_unit),
		"AI vehicle factory should open with economy support or a battle vehicle, got {0}".format(
			[opening_vehicle_queue_path]
		)
	)
	opening_vehicle_unit.free()
	var initial_vehicle_combat_scene = _offense_controller._pick_next_available_unit_scene(
		_offense_controller._unit_scenes_for_structure(_ai.OffensiveStructure.VEHICLE_FACTORY),
		"test_initial_vehicle_combat_unit"
	)
	assert(
		initial_vehicle_combat_scene.resource_path == TankUnit.resource_path,
		"AI vehicle combat lane should start with tank"
	)
	assert(
		_barracks.production_queue.get_elements()[0].unit_prototype.resource_path
		== LightRifleInfantryUnit.resource_path,
		"AI infantry lane should start with rifle infantry"
	)
	assert(
		_aircraft_factory.production_queue.get_elements()[0].unit_prototype.resource_path
		== HelicopterUnit.resource_path,
		"AI aircraft lane should start with helicopter"
	)
	assert(
		Constants.Match.Units.CONSTRUCTION_COSTS.has(AircraftFactoryUnit.resource_path),
		"aircraft factory should remain a normal AI-buildable production structure"
	)
	assert(
		_offense_controller._power_supply_scene_for_capacity().resource_path
		== AdvancedReactorPlantUnit.resource_path,
		"fully teched AI should prefer advanced reactor plants for new power capacity"
	)
	_assert_ai_offense_falls_back_from_unknown_structure()
	var vehicle_scenes = _offense_controller._unit_scenes_for_structure(
		_ai.OffensiveStructure.VEHICLE_FACTORY
	)
	var sampled_vehicle_scene_paths = []
	for _i in range(vehicle_scenes.size()):
		var vehicle_scene = _offense_controller._pick_next_available_unit_scene(
			vehicle_scenes, "test_vehicle_unit"
		)
		assert(vehicle_scene != null, "fully teched AI should have available vehicle units")
		sampled_vehicle_scene_paths.append(vehicle_scene.resource_path)
	assert(
		MobileRepairCrawlerUnit.resource_path in sampled_vehicle_scene_paths,
		"AI vehicle roster should include mobile repair crawler"
	)
	assert(
		RailArtilleryWalkerUnit.resource_path in sampled_vehicle_scene_paths,
		"AI vehicle roster should include rail artillery walker"
	)
	assert(
		HammerSiegeTankUnit.resource_path in sampled_vehicle_scene_paths,
		"AI vehicle roster should include hammer siege tank"
	)
	assert(
		SiegeDrillTankUnit.resource_path in sampled_vehicle_scene_paths,
		"AI vehicle roster should include siege drill tank"
	)
	assert(
		TeslaCrawlerMk2Unit.resource_path in sampled_vehicle_scene_paths,
		"AI vehicle roster should include tesla crawler"
	)
	assert(
		DroneMineLayerUnit.resource_path in sampled_vehicle_scene_paths,
		"AI vehicle roster should include drone mine layer"
	)
	var infantry_scenes = _offense_controller._unit_scenes_for_structure(
		_ai.OffensiveStructure.BARRACKS
	)
	var sampled_infantry_scene_paths = []
	for _i in range(infantry_scenes.size()):
		var infantry_scene = _offense_controller._pick_next_available_unit_scene(
			infantry_scenes, "test_infantry_unit"
		)
		assert(infantry_scene != null, "fully teched AI should have available infantry units")
		sampled_infantry_scene_paths.append(infantry_scene.resource_path)
	assert(
		FlakRocketTeamUnit.resource_path in sampled_infantry_scene_paths,
		"AI infantry roster should include flak rocket team"
	)
	assert(
		FlakRocketTeamMk2Unit.resource_path in sampled_infantry_scene_paths,
		"AI infantry roster should include advanced flak rocket team"
	)
	assert(
		not (SaboteurInfiltratorUnit.resource_path in sampled_infantry_scene_paths),
		"saboteur infiltrator should be reserved for the AI infiltration controller"
	)
	assert(
		FieldMedicUnit.resource_path in sampled_infantry_scene_paths,
		"AI infantry roster should include field medic support"
	)
	assert(
		ShieldTrooperUnit.resource_path in sampled_infantry_scene_paths,
		"AI infantry roster should include shield trooper"
	)
	assert(
		TacticalOfficerUnit.resource_path in sampled_infantry_scene_paths,
		"AI infantry roster should include tactical officer"
	)
	assert(
		RailSniperTeamUnit.resource_path in sampled_infantry_scene_paths,
		"AI infantry roster should include rail sniper team"
	)
	var air_scenes = _offense_controller._unit_scenes_for_structure(
		_ai.OffensiveStructure.AIRCRAFT_FACTORY
	)
	var sampled_air_scene_paths = []
	for _i in range(air_scenes.size()):
		var air_scene = _offense_controller._pick_next_available_unit_scene(
			air_scenes, "test_air_unit"
		)
		assert(air_scene != null, "fully teched AI should have available aircraft units")
		sampled_air_scene_paths.append(air_scene.resource_path)
	assert(
		SiegeAirshipUnit.resource_path in sampled_air_scene_paths,
		"AI aircraft roster should include siege airship"
	)
	await _assert_ai_prioritizes_anti_air_against_enemy_air()
	await _assert_ai_replaces_lost_full_battlegroup()
	var mobile_repair_crawler = MobileRepairCrawlerUnit.instantiate()
	var field_medic = FieldMedicUnit.instantiate()
	var rail_artillery_walker = RailArtilleryWalkerUnit.instantiate()
	var flak_rocket_team = FlakRocketTeamUnit.instantiate()
	var flak_rocket_team_mk2 = FlakRocketTeamMk2Unit.instantiate()
	var saboteur_infiltrator = SaboteurInfiltratorUnit.instantiate()
	var hammer_siege_tank = HammerSiegeTankUnit.instantiate()
	var shield_trooper = ShieldTrooperUnit.instantiate()
	var tactical_officer = TacticalOfficerUnit.instantiate()
	var rail_sniper_team = RailSniperTeamUnit.instantiate()
	var drone_mine_layer = DroneMineLayerUnit.instantiate()
	var tesla_crawler = TeslaCrawlerMk2Unit.instantiate()
	var siege_drill_tank = SiegeDrillTankUnit.instantiate()
	var siege_airship = SiegeAirshipUnit.instantiate()
	var ore_harvester = OreHarvesterUnit.instantiate()
	assert(
		_offense_controller._is_battle_unit(mobile_repair_crawler),
		"mobile repair crawler should attach to AI battlegroups"
	)
	assert(
		_offense_controller._is_battle_unit(field_medic),
		"field medic should attach to AI battlegroups"
	)
	assert(
		_offense_controller._is_battle_unit(rail_artillery_walker),
		"rail artillery walker should attach to AI battlegroups"
	)
	assert(
		_offense_controller._is_battle_unit(flak_rocket_team),
		"flak rocket team should attach to AI battlegroups"
	)
	assert(
		_offense_controller._is_battle_unit(flak_rocket_team_mk2),
		"advanced flak rocket team should attach to AI battlegroups"
	)
	assert(
		not _offense_controller._is_battle_unit(saboteur_infiltrator),
		"saboteur infiltrator should not be consumed by ordinary AI battlegroups"
	)
	assert(
		_offense_controller._is_battle_unit(hammer_siege_tank),
		"hammer siege tank should attach to AI battlegroups"
	)
	assert(
		_offense_controller._is_battle_unit(shield_trooper),
		"shield trooper should attach to AI battlegroups"
	)
	assert(
		_offense_controller._is_battle_unit(tactical_officer),
		"tactical officer should attach to AI battlegroups"
	)
	assert(
		_offense_controller._is_battle_unit(rail_sniper_team),
		"rail sniper team should attach to AI battlegroups"
	)
	assert(
		_offense_controller._is_battle_unit(drone_mine_layer),
		"drone mine layer should attach to AI battlegroups"
	)
	assert(
		_offense_controller._is_battle_unit(tesla_crawler),
		"tesla crawler should attach to AI battlegroups"
	)
	assert(
		_offense_controller._is_battle_unit(siege_drill_tank),
		"siege drill tank should attach to AI battlegroups"
	)
	assert(
		_offense_controller._is_battle_unit(siege_airship),
		"siege airship should attach to AI battlegroups"
	)
	assert(
		not _offense_controller._is_battle_unit(ore_harvester),
		"ore harvester should stay in the economy layer instead of battlegroups"
	)
	mobile_repair_crawler.free()
	field_medic.free()
	rail_artillery_walker.free()
	flak_rocket_team.free()
	flak_rocket_team_mk2.free()
	saboteur_infiltrator.free()
	hammer_siege_tank.free()
	shield_trooper.free()
	tactical_officer.free()
	rail_sniper_team.free()
	drone_mine_layer.free()
	tesla_crawler.free()
	siege_drill_tank.free()
	siege_airship.free()
	ore_harvester.free()
	get_tree().quit()


func _assert_ai_prioritizes_anti_air_against_enemy_air():
	for structure in [_vehicle_factory, _barracks, _aircraft_factory]:
		structure.production_queue.cancel_all()
	_offense_controller._pending_unit_scene_by_metadata.clear()
	_offense_controller._number_of_pending_unit_resource_requests.clear()
	assert(
		_offense_controller._anti_air_response_count() == 0,
		"AI test should start without an anti-air response"
	)

	var enemy_helicopter = HelicopterUnit.instantiate()
	_setup_and_spawn_unit(
		enemy_helicopter, Transform3D(Basis(), Vector3(22.0, 0.0, 35.0)), _human, false
	)

	assert(
		_offense_controller._enemy_air_units_count() >= 1,
		"AI test should have enemy air pressure"
	)

	var vehicle_scenes = _offense_controller._unit_scenes_for_structure(
		_ai.OffensiveStructure.VEHICLE_FACTORY
	)
	_offense_controller._unit_scene_cursor_by_metadata["test_air_counter_vehicle"] = 0
	var counter_scene = _offense_controller._pick_next_available_unit_scene(
		vehicle_scenes, "test_air_counter_vehicle"
	)
	assert(counter_scene != null, "AI should find a vehicle counter to enemy air")
	assert(
		counter_scene.resource_path != TankUnit.resource_path,
		"AI should skip the default tank when it needs anti-air coverage"
	)
	assert(
		_offense_controller._unit_scene_can_attack_domain(
			counter_scene, Constants.Match.Navigation.Domain.AIR
		),
		"AI should prioritize an anti-air-capable vehicle against enemy aircraft"
	)

	enemy_helicopter.queue_free()
	await get_tree().process_frame


func _assert_ai_offense_falls_back_from_unknown_structure():
	var unknown_structure = 999
	assert(
		_offense_controller._normalized_offensive_structure(unknown_structure)
		== _ai.OffensiveStructure.VEHICLE_FACTORY,
		"AI offense should normalize unknown structure slots to the vehicle factory"
	)
	assert(
		_offense_controller._structure_scene_for_offensive_structure(unknown_structure).resource_path
		== VehicleFactoryUnit.resource_path,
		"AI offense should build vehicle factories for unknown offensive structure slots"
	)
	var fallback_unit_scenes = _offense_controller._unit_scenes_for_structure(unknown_structure)
	assert(
		not fallback_unit_scenes.is_empty()
		and fallback_unit_scenes[0].resource_path == TankUnit.resource_path,
		"AI offense should use the vehicle combat roster for unknown offensive structure slots"
	)
	assert(
		_offense_controller._is_offensive_structure(_vehicle_factory, unknown_structure),
		"AI offense should treat vehicle factories as the unknown-slot fallback"
	)
	assert(
		not _offense_controller._is_offensive_structure(_barracks, unknown_structure),
		"AI offense should not match infantry production as the unknown-slot fallback"
	)
	_offense_controller.provision({}, "unknown_test_metadata")
	var vehicle_queue_size_before_bad_provision = _vehicle_factory.production_queue.size()
	_offense_controller._pending_unit_scene_by_metadata["primary_unit"] = TankUnit
	_offense_controller._number_of_pending_unit_resource_requests["primary_unit"] = 1
	_offense_controller.provision({"resource_a": 999, "resource_b": 999}, "primary_unit")
	assert(
		_vehicle_factory.production_queue.size() == vehicle_queue_size_before_bad_provision,
		"AI offense should ignore mismatched unit resources instead of queueing production"
	)
	assert(
		_offense_controller._number_of_pending_unit_resource_requests["primary_unit"] == 0,
		"AI offense mismatched resource provision should clear the consumed pending unit request"
	)
	assert(
		not _offense_controller._pending_unit_scene_by_metadata.has("primary_unit"),
		"AI offense mismatched resource provision should clear stale unit metadata"
	)


func _assert_ai_replaces_lost_full_battlegroup():
	await _fill_current_forming_battlegroup()
	await _wait_until(
		func():
			return (
				_offense_controller._battlegroups.size() == _ai.expected_number_of_battlegroups
				and _offense_controller._battlegroup_under_forming == null
			),
		REPLACEMENT_TIMEOUT_S,
		"AI should stop forming once all expected battlegroups are full"
	)
	var lost_battlegroup = _offense_controller._battlegroups[0]
	lost_battlegroup.queue_free()
	await _wait_until(
		func():
			return (
				_offense_controller._battlegroups.size() == _ai.expected_number_of_battlegroups
				and _offense_controller._battlegroup_under_forming != null
			),
		REPLACEMENT_TIMEOUT_S,
		"AI should create a replacement battlegroup after losing a full attack group"
	)
	assert(
		_offense_controller._number_of_additional_units_required() > 0,
		"replacement battlegroup should reopen AI unit production demand"
	)


func _fill_current_forming_battlegroup():
	var forming_battlegroup = _offense_controller._battlegroup_under_forming
	assert(forming_battlegroup != null, "AI should have a battlegroup under formation")
	var spawned_units = 0
	while (
		is_instance_valid(forming_battlegroup)
		and forming_battlegroup.size() < _ai.expected_number_of_units_in_battlegroup
	):
		var reinforcement = TankUnit.instantiate()
		_setup_and_spawn_unit(
			reinforcement,
			Transform3D(Basis(), Vector3(30.0 + spawned_units, 0.0, 43.0)),
			_ai,
			false
		)
		spawned_units += 1
		await get_tree().process_frame


func _wait_until(condition, timeout_s, message):
	var started_at_msec = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at_msec < timeout_s * 1000.0:
		if condition.call():
			return
		await get_tree().process_frame
	assert(false, message)
