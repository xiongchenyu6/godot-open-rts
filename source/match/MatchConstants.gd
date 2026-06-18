const OWNED_PLAYER_CIRCLE_COLOR = Color.GREEN
const ADVERSARY_PLAYER_CIRCLE_COLOR = Color.RED
const RESOURCE_CIRCLE_COLOR = Color.YELLOW
const DEFAULT_CIRCLE_COLOR = Color.WHITE
const MAPS = {
	"res://source/match/maps/PlainAndSimple.tscn":
	{
		"name": "Plain & Simple",
		"name_key": "MAP_NAME_PLAIN_AND_SIMPLE",
		"players": 4,
		"size": Vector2i(50, 50),
	},
	"res://source/match/maps/FourCorners.tscn":
	{
		"name": "Four Corners",
		"name_key": "MAP_NAME_FOUR_CORNERS",
		"players": 4,
		"size": Vector2i(72, 72),
	},
	"res://source/match/maps/TechDivide.tscn":
	{
		"name": "Tech Divide",
		"name_key": "MAP_NAME_TECH_DIVIDE",
		"players": 6,
		"size": Vector2i(84, 84),
	},
	"res://source/match/maps/BigArena.tscn":
	{
		"name": "Big Arena",
		"name_key": "MAP_NAME_BIG_ARENA",
		"players": 8,
		"size": Vector2i(100, 100),
	},
}


class Navigation:
	enum Domain { AIR, TERRAIN }

	const DOMAIN_TO_GROUP_MAPPING = {
		Domain.AIR: "air_navigation_input",
		Domain.TERRAIN: "terrain_navigation_input",
	}


class Air:
	const Y = 1.5
	const PLANE = Plane(Vector3.UP, Y)

	class Navmesh:
		const CELL_SIZE = 0.4
		const CELL_HEIGHT = 0.4
		const MAX_AGENT_RADIUS = 0.8


class Terrain:
	const PLANE = Plane(Vector3.UP, 0)

	class Navmesh:
		const CELL_SIZE = 0.3
		const CELL_HEIGHT = 0.3
		const MAX_AGENT_RADIUS = 0.9  # max radius of movable units


class Resources:
	const ORE_PURIFIER_STRUCTURE_PATH = "res://source/match/units/OrePurifier.tscn"
	const ORE_PURIFIER_BONUS_RATIO = 0.25

	class A:
		const COLOR = Color.BLUE
		const MATERIAL_PATH = "res://source/match/resources/materials/resource_a.material.tres"
		const COLLECTING_TIME_S = 1.0

	class B:
		const COLOR = Color.RED
		const MATERIAL_PATH = "res://source/match/resources/materials/resource_b.material.tres"
		const COLLECTING_TIME_S = 2.0


class Power:
	const LOW_POWER_PRODUCTION_SPEED_MULTIPLIER = 0.5
	const AI_TARGET_RESERVE = 8


class Repair:
	const HITPOINTS_PER_SECOND = 2.0


class Capture:
	const ENGINEER_CAPTURE_TIME_SECONDS = 1.2
	const SABOTEUR_RESOURCE_STEAL_RATIO = 0.35
	const SABOTEUR_RESOURCE_STEAL_CAP = 8
	const SABOTEUR_PRODUCTION_VETERANCY_RANK = 1
	const SABOTEUR_POWER_SABOTAGE_DURATION_SECONDS = 10.0
	const INFILTRATION_RESOURCE_TARGETS = [
		"res://source/match/units/CommandCenter.tscn",
		"res://source/match/units/Refinery.tscn",
		"res://source/match/units/OrePurifier.tscn",
	]
	const INFILTRATION_POWER_SABOTAGE_TARGETS = [
		"res://source/match/units/PowerReactor.tscn",
		"res://source/match/units/AdvancedReactorPlant.tscn",
	]
	const INFILTRATION_PRODUCTION_VETERANCY_TARGETS = {
		"res://source/match/units/Barracks.tscn": "res://source/match/units/Barracks.tscn",
		"res://source/match/units/VehicleFactory.tscn": "res://source/match/units/VehicleFactory.tscn",
		"res://source/match/units/AircraftFactory.tscn": "res://source/match/units/AircraftFactory.tscn",
	}


class Structure:
	const SELL_REFUND_RATIO = 0.5
	const MANUAL_REPAIR_COST_RATIO = 0.5
	const MANUAL_REPAIR_HITPOINTS_PER_SECOND = 3.0
	const MANUAL_REPAIR_TICK_SECONDS = 0.2
	const AI_REPAIR_MIN_MISSING_HITPOINT_RATIO = 0.25
	const AI_REPAIR_MAX_STARTS_PER_REFRESH = 2


class SupportPowers:
	const RADAR_SWEEP = "radar_sweep"
	const ORBITAL_STRIKE = "orbital_strike"
	const EMP_PULSE = "emp_pulse"
	const CHRONO_RELAY = "chrono_relay"
	const SHIELD_OVERDRIVE = "shield_overdrive"
	const NANITE_REPAIR_SWARM = "nanite_repair_swarm"
	const WEATHER_STORM = "weather_storm"
	const STRATEGIC_MISSILE = "strategic_missile"
	const PARADROP = "paradrop"
	const DEFINITIONS = {
		"radar_sweep":
		{
			"name_key": "RADAR_SWEEP",
			"description_key": "RADAR_SWEEP_DESCRIPTION",
			"requirements": ["res://source/match/units/RadarUplink.tscn"],
			"requires_power": true,
			"cooldown": 18.0,
			"radius": 12.0,
			"duration": 8.0,
		},
		"orbital_strike":
		{
			"name_key": "ORBITAL_STRIKE",
			"description_key": "ORBITAL_STRIKE_DESCRIPTION",
			"requirements": ["res://source/match/units/TechLab.tscn"],
			"requires_power": true,
			"cooldown": 45.0,
			"impact_delay": 0.7,
			"radius": 3.4,
			"damage": 8.0,
		},
		"emp_pulse":
		{
			"name_key": "EMP_PULSE",
			"description_key": "EMP_PULSE_DESCRIPTION",
			"requirements": ["res://source/match/units/RoboticsBay.tscn"],
			"requires_power": true,
			"cooldown": 36.0,
			"radius": 4.8,
			"duration": 5.0,
		},
		"chrono_relay":
		{
			"name_key": "CHRONO_RELAY",
			"description_key": "CHRONO_RELAY_DESCRIPTION",
			"requirements": ["res://source/match/units/TechLab.tscn"],
			"requires_power": true,
			"cooldown": 38.0,
			"radius": 4.6,
			"duration": 7.0,
			"speed_multiplier": 1.75,
		},
		"shield_overdrive":
		{
			"name_key": "SHIELD_OVERDRIVE",
			"description_key": "SHIELD_OVERDRIVE_DESCRIPTION",
			"requirements": ["res://source/match/units/TechLab.tscn"],
			"requires_power": true,
			"cooldown": 55.0,
			"radius": 4.8,
			"duration": 8.0,
			"damage_multiplier": 0.25,
		},
		"nanite_repair_swarm":
		{
			"name_key": "NANITE_REPAIR_SWARM",
			"description_key": "NANITE_REPAIR_SWARM_DESCRIPTION",
			"requirements": ["res://source/match/units/RoboticsBay.tscn"],
			"requires_power": true,
			"cooldown": 42.0,
			"radius": 5.2,
			"healing": 10.0,
		},
		"weather_storm":
			{
				"name_key": "WEATHER_STORM",
				"description_key": "WEATHER_STORM_DESCRIPTION",
				"requirements": ["res://source/match/units/WeatherControlSpire.tscn"],
				"requires_power": true,
				"superweapon": true,
				"initial_cooldown": 90.0,
				"cooldown": 90.0,
				"impact_delay": 1.8,
				"radius": 6.4,
				"damage": 12.0,
			},
		"strategic_missile":
		{
			"name_key": "STRATEGIC_MISSILE",
			"description_key": "STRATEGIC_MISSILE_DESCRIPTION",
			"requirements": ["res://source/match/units/WeatherControlSpire.tscn"],
			"requires_power": true,
			"superweapon": true,
			"initial_cooldown": 105.0,
			"cooldown": 105.0,
			"impact_delay": 1.4,
			"radius": 4.8,
			"damage": 20.0,
		},
		"paradrop":
		{
			"name_key": "PARADROP",
			"description_key": "PARADROP_DESCRIPTION",
			"requirements": ["res://source/match/units/TechAirport.tscn"],
			"requires_power": false,
			"cooldown": 52.0,
			"impact_delay": 1.1,
			"radius": 2.4,
			"unit_paths":
			[
				"res://source/match/units/LightRifleInfantry.tscn",
				"res://source/match/units/LightRifleInfantry.tscn",
				"res://source/match/units/RocketInfantry.tscn",
			],
		},
	}


class BattleEventPing:
	const GENERIC = "generic"
	const SUPPORT_POWER = "support_power"
	const ENEMY_SUPPORT_POWER = "enemy_support_power"
	const ENEMY_SUPERWEAPON = "enemy_superweapon"


class Veterancy:
	const MAX_RANK = 2
	const KILLS_BY_RANK = [0, 2, 5]
	const DAMAGE_MULTIPLIER_BY_RANK = [1.0, 1.25, 1.5]
	const HP_MULTIPLIER_BY_RANK = [1.0, 1.2, 1.5]
	const RANGE_BONUS_BY_RANK = [0.0, 0.5, 1.0]
	const SIGHT_BONUS_BY_RANK = [0.0, 1.0, 2.0]
	const ELITE_REGEN_HITPOINTS_PER_SECOND = 1.0
	const ELITE_REGEN_TICK_SECONDS = 0.5


class Units:
	const PRODUCTION_COSTS = {
		"res://source/match/units/Worker.tscn":
		{
			"resource_a": 2,
			"resource_b": 0,
		},
		"res://source/match/units/Helicopter.tscn":
		{
			"resource_a": 1,
			"resource_b": 3,
		},
		"res://source/match/units/Drone.tscn":
		{
			"resource_a": 2,
			"resource_b": 0,
		},
		"res://source/match/units/InterceptorVTOL.tscn":
		{
			"resource_a": 3,
			"resource_b": 4,
		},
		"res://source/match/units/Tank.tscn":
		{
			"resource_a": 3,
			"resource_b": 1,
		},
		"res://source/match/units/LightRifleInfantry.tscn":
		{
			"resource_a": 1,
			"resource_b": 0,
		},
		"res://source/match/units/RocketInfantry.tscn":
		{
			"resource_a": 2,
			"resource_b": 1,
		},
		"res://source/match/units/FieldMedic.tscn":
		{
			"resource_a": 2,
			"resource_b": 1,
		},
		"res://source/match/units/ShieldTrooper.tscn":
		{
			"resource_a": 3,
			"resource_b": 2,
		},
		"res://source/match/units/TacticalOfficer.tscn":
		{
			"resource_a": 4,
			"resource_b": 3,
		},
		"res://source/match/units/FlakRocketTeam.tscn":
		{
			"resource_a": 3,
			"resource_b": 2,
		},
		"res://source/match/units/FlakRocketTeamMk2.tscn":
		{
			"resource_a": 4,
			"resource_b": 4,
		},
		"res://source/match/units/HeavyMachinegunTrooper.tscn":
		{
			"resource_a": 2,
			"resource_b": 1,
		},
		"res://source/match/units/ShockTrooper.tscn":
		{
			"resource_a": 3,
			"resource_b": 2,
		},
		"res://source/match/units/GrenadierTrooper.tscn":
		{
			"resource_a": 2,
			"resource_b": 2,
		},
		"res://source/match/units/MortarTeam.tscn":
		{
			"resource_a": 3,
			"resource_b": 2,
		},
		"res://source/match/units/CryoSprayer.tscn":
		{
			"resource_a": 3,
			"resource_b": 3,
		},
		"res://source/match/units/SniperScout.tscn":
		{
			"resource_a": 3,
			"resource_b": 2,
		},
		"res://source/match/units/RailSniperTeam.tscn":
		{
			"resource_a": 4,
			"resource_b": 4,
		},
		"res://source/match/units/PhaseSaboteur.tscn":
		{
			"resource_a": 4,
			"resource_b": 4,
		},
		"res://source/match/units/SaboteurInfiltrator.tscn":
		{
			"resource_a": 5,
			"resource_b": 5,
		},
		"res://source/match/units/PulseRifleCommando.tscn":
		{
			"resource_a": 4,
			"resource_b": 3,
		},
		"res://source/match/units/ScoutRover.tscn":
		{
			"resource_a": 2,
			"resource_b": 0,
		},
		"res://source/match/units/OreHarvester.tscn":
		{
			"resource_a": 4,
			"resource_b": 1,
		},
		"res://source/match/units/MobileConstructionVehicle.tscn":
		{
			"resource_a": 7,
			"resource_b": 6,
		},
		"res://source/match/units/MirageScoutTank.tscn":
		{
			"resource_a": 3,
			"resource_b": 2,
		},
		"res://source/match/units/FlameAssaultBuggy.tscn":
		{
			"resource_a": 2,
			"resource_b": 2,
		},
		"res://source/match/units/DroneMineLayer.tscn":
		{
			"resource_a": 4,
			"resource_b": 3,
		},
		"res://source/match/units/TeslaCrawlerMk2.tscn":
		{
			"resource_a": 4,
			"resource_b": 4,
		},
		"res://source/match/units/RocketTrooperRobot.tscn":
		{
			"resource_a": 2,
			"resource_b": 1,
		},
		"res://source/match/units/JammerVehicle.tscn":
		{
			"resource_a": 3,
			"resource_b": 3,
		},
		"res://source/match/units/AntiAirWalker.tscn":
		{
			"resource_a": 3,
			"resource_b": 2,
		},
		"res://source/match/units/FlakHoverTank.tscn":
		{
			"resource_a": 4,
			"resource_b": 3,
		},
		"res://source/match/units/MobileRepairCrawler.tscn":
		{
			"resource_a": 4,
			"resource_b": 4,
		},
		"res://source/match/units/MobileShieldProjector.tscn":
		{
			"resource_a": 5,
			"resource_b": 4,
		},
		"res://source/match/units/ModularMissileCarrier.tscn":
		{
			"resource_a": 4,
			"resource_b": 4,
		},
		"res://source/match/units/LongbowMissileCrawler.tscn":
		{
			"resource_a": 5,
			"resource_b": 5,
		},
		"res://source/match/units/SiegeArtilleryVehicle.tscn":
		{
			"resource_a": 5,
			"resource_b": 3,
		},
		"res://source/match/units/SiegeDrillTank.tscn":
		{
			"resource_a": 5,
			"resource_b": 4,
		},
		"res://source/match/units/LanceBeamTank.tscn":
		{
			"resource_a": 5,
			"resource_b": 5,
		},
		"res://source/match/units/RailgunTank.tscn":
		{
			"resource_a": 6,
			"resource_b": 5,
		},
		"res://source/match/units/HammerSiegeTank.tscn":
		{
			"resource_a": 6,
			"resource_b": 4,
		},
		"res://source/match/units/HeavySiegeWalker.tscn":
		{
			"resource_a": 7,
			"resource_b": 6,
		},
		"res://source/match/units/RailArtilleryWalker.tscn":
		{
			"resource_a": 8,
			"resource_b": 7,
		},
		"res://source/match/units/EngineerDrone.tscn":
		{
			"resource_a": 2,
			"resource_b": 2,
		},
		"res://source/match/units/BomberVTOL.tscn":
		{
			"resource_a": 4,
			"resource_b": 5,
		},
		"res://source/match/units/RocketGunship.tscn":
		{
			"resource_a": 5,
			"resource_b": 5,
		},
		"res://source/match/units/HeavyBombardmentAirship.tscn":
		{
			"resource_a": 7,
			"resource_b": 8,
		},
		"res://source/match/units/SiegeAirship.tscn":
		{
			"resource_a": 8,
			"resource_b": 8,
		},
	}
	const PRODUCTION_TIMES = {
		"res://source/match/units/Worker.tscn": 3.0,
		"res://source/match/units/Helicopter.tscn": 6.0,
		"res://source/match/units/Drone.tscn": 3.0,
		"res://source/match/units/InterceptorVTOL.tscn": 7.5,
		"res://source/match/units/Tank.tscn": 6.0,
		"res://source/match/units/LightRifleInfantry.tscn": 3.0,
		"res://source/match/units/RocketInfantry.tscn": 5.0,
		"res://source/match/units/FieldMedic.tscn": 4.5,
		"res://source/match/units/ShieldTrooper.tscn": 5.5,
		"res://source/match/units/TacticalOfficer.tscn": 6.0,
		"res://source/match/units/FlakRocketTeam.tscn": 5.8,
		"res://source/match/units/FlakRocketTeamMk2.tscn": 7.2,
		"res://source/match/units/HeavyMachinegunTrooper.tscn": 4.5,
		"res://source/match/units/ShockTrooper.tscn": 5.5,
		"res://source/match/units/GrenadierTrooper.tscn": 5.0,
		"res://source/match/units/MortarTeam.tscn": 6.0,
		"res://source/match/units/CryoSprayer.tscn": 6.5,
		"res://source/match/units/SniperScout.tscn": 6.5,
		"res://source/match/units/RailSniperTeam.tscn": 8.0,
		"res://source/match/units/PhaseSaboteur.tscn": 7.0,
		"res://source/match/units/SaboteurInfiltrator.tscn": 8.0,
		"res://source/match/units/PulseRifleCommando.tscn": 7.5,
		"res://source/match/units/ScoutRover.tscn": 4.0,
		"res://source/match/units/OreHarvester.tscn": 7.0,
		"res://source/match/units/MobileConstructionVehicle.tscn": 10.5,
		"res://source/match/units/MirageScoutTank.tscn": 5.5,
		"res://source/match/units/FlameAssaultBuggy.tscn": 5.0,
		"res://source/match/units/DroneMineLayer.tscn": 7.0,
		"res://source/match/units/TeslaCrawlerMk2.tscn": 7.5,
		"res://source/match/units/RocketTrooperRobot.tscn": 5.0,
		"res://source/match/units/JammerVehicle.tscn": 6.5,
		"res://source/match/units/AntiAirWalker.tscn": 7.0,
		"res://source/match/units/FlakHoverTank.tscn": 7.0,
		"res://source/match/units/MobileRepairCrawler.tscn": 7.5,
		"res://source/match/units/MobileShieldProjector.tscn": 8.0,
		"res://source/match/units/ModularMissileCarrier.tscn": 8.0,
		"res://source/match/units/LongbowMissileCrawler.tscn": 9.5,
		"res://source/match/units/SiegeArtilleryVehicle.tscn": 9.0,
		"res://source/match/units/SiegeDrillTank.tscn": 8.5,
		"res://source/match/units/LanceBeamTank.tscn": 9.5,
		"res://source/match/units/RailgunTank.tscn": 11.0,
		"res://source/match/units/HammerSiegeTank.tscn": 11.5,
		"res://source/match/units/HeavySiegeWalker.tscn": 12.0,
		"res://source/match/units/RailArtilleryWalker.tscn": 13.5,
		"res://source/match/units/EngineerDrone.tscn": 5.0,
		"res://source/match/units/BomberVTOL.tscn": 10.0,
		"res://source/match/units/RocketGunship.tscn": 9.0,
		"res://source/match/units/HeavyBombardmentAirship.tscn": 13.0,
		"res://source/match/units/SiegeAirship.tscn": 14.0,
	}
	const PRODUCTION_REQUIREMENTS = {
		"res://source/match/units/RocketInfantry.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/FlakRocketTeam.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/FlakRocketTeamMk2.tscn":
		["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/GrenadierTrooper.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/MortarTeam.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/ShockTrooper.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/ShieldTrooper.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/TacticalOfficer.tscn":
		["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/CryoSprayer.tscn": ["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/SniperScout.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/RailSniperTeam.tscn": ["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/PhaseSaboteur.tscn": ["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/SaboteurInfiltrator.tscn":
		["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/PulseRifleCommando.tscn":
		["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/MirageScoutTank.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/RocketTrooperRobot.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/DroneMineLayer.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/TeslaCrawlerMk2.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/AntiAirWalker.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/FlakHoverTank.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/MobileRepairCrawler.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/MobileShieldProjector.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/MobileConstructionVehicle.tscn":
		["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/ModularMissileCarrier.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/LongbowMissileCrawler.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/JammerVehicle.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/EngineerDrone.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/InterceptorVTOL.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/SiegeArtilleryVehicle.tscn":
		["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/SiegeDrillTank.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/LanceBeamTank.tscn": ["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/RailgunTank.tscn": ["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/HammerSiegeTank.tscn": ["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/HeavySiegeWalker.tscn":
		["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/RailArtilleryWalker.tscn":
		["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/BomberVTOL.tscn": ["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/RocketGunship.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/HeavyBombardmentAirship.tscn":
		["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/SiegeAirship.tscn": ["res://source/match/units/TechLab.tscn"],
	}
	const PRODUCTION_QUEUE_LIMIT = 5
	const CRUSH_DAMAGE = 999.0
	const CRUSH_RADIUS_MARGIN_M = 0.15
	const CRUSH_MIN_FRAME_DISPLACEMENT_M = 0.005
	const CRUSHER_UNIT_PATHS = [
		"res://source/match/units/Tank.tscn",
		"res://source/match/units/OreHarvester.tscn",
		"res://source/match/units/MobileConstructionVehicle.tscn",
		"res://source/match/units/TeslaCrawlerMk2.tscn",
		"res://source/match/units/AntiAirWalker.tscn",
		"res://source/match/units/MobileRepairCrawler.tscn",
		"res://source/match/units/MobileShieldProjector.tscn",
		"res://source/match/units/ModularMissileCarrier.tscn",
		"res://source/match/units/LongbowMissileCrawler.tscn",
		"res://source/match/units/SiegeArtilleryVehicle.tscn",
		"res://source/match/units/SiegeDrillTank.tscn",
		"res://source/match/units/LanceBeamTank.tscn",
		"res://source/match/units/RailgunTank.tscn",
		"res://source/match/units/HammerSiegeTank.tscn",
		"res://source/match/units/HeavySiegeWalker.tscn",
		"res://source/match/units/RailArtilleryWalker.tscn",
	]
	const CRUSHABLE_UNIT_PATHS = [
		"res://source/match/units/Worker.tscn",
		"res://source/match/units/EngineerDrone.tscn",
		"res://source/match/units/LightRifleInfantry.tscn",
		"res://source/match/units/RocketInfantry.tscn",
		"res://source/match/units/FieldMedic.tscn",
		"res://source/match/units/ShieldTrooper.tscn",
		"res://source/match/units/FlakRocketTeam.tscn",
		"res://source/match/units/FlakRocketTeamMk2.tscn",
		"res://source/match/units/HeavyMachinegunTrooper.tscn",
		"res://source/match/units/ShockTrooper.tscn",
		"res://source/match/units/GrenadierTrooper.tscn",
		"res://source/match/units/MortarTeam.tscn",
		"res://source/match/units/CryoSprayer.tscn",
		"res://source/match/units/SniperScout.tscn",
		"res://source/match/units/RailSniperTeam.tscn",
		"res://source/match/units/PhaseSaboteur.tscn",
		"res://source/match/units/SaboteurInfiltrator.tscn",
		"res://source/match/units/PulseRifleCommando.tscn",
		"res://source/match/units/TacticalOfficer.tscn",
		"res://source/match/units/RocketTrooperRobot.tscn",
	]
	const STRUCTURE_BLUEPRINTS = {
		"res://source/match/units/CommandCenter.tscn":
		"res://source/match/units/structure-geometries/CommandCenter.tscn",
		"res://source/match/units/PowerReactor.tscn":
		"res://source/match/units/structure-geometries/PowerReactor.tscn",
		"res://source/match/units/AdvancedReactorPlant.tscn":
		"res://source/match/units/structure-geometries/AdvancedReactorPlant.tscn",
		"res://source/match/units/Refinery.tscn":
		"res://source/match/units/structure-geometries/Refinery.tscn",
		"res://source/match/units/OrePurifier.tscn":
		"res://source/match/units/structure-geometries/OrePurifier.tscn",
		"res://source/match/units/Barracks.tscn":
		"res://source/match/units/structure-geometries/Barracks.tscn",
		"res://source/match/units/RadarUplink.tscn":
		"res://source/match/units/structure-geometries/RadarUplink.tscn",
		"res://source/match/units/RoboticsBay.tscn":
		"res://source/match/units/structure-geometries/RoboticsBay.tscn",
		"res://source/match/units/RepairPad.tscn":
		"res://source/match/units/structure-geometries/RepairPad.tscn",
		"res://source/match/units/TechLab.tscn":
		"res://source/match/units/structure-geometries/TechLab.tscn",
		"res://source/match/units/VehicleFactory.tscn":
		"res://source/match/units/structure-geometries/VehicleFactory.tscn",
		"res://source/match/units/AircraftFactory.tscn":
		"res://source/match/units/structure-geometries/AircraftFactory.tscn",
		"res://source/match/units/AntiGroundTurret.tscn":
		"res://source/match/units/structure-geometries/AntiGroundTurret.tscn",
		"res://source/match/units/AntiAirTurret.tscn":
		"res://source/match/units/structure-geometries/AntiAirTurret.tscn",
		"res://source/match/units/TeslaFenceSegment.tscn":
		"res://source/match/units/structure-geometries/TeslaFenceSegment.tscn",
		"res://source/match/units/ArcCoilDefenseTower.tscn":
		"res://source/match/units/structure-geometries/ArcCoilDefenseTower.tscn",
			"res://source/match/units/LanceBeamDefenseTower.tscn":
			"res://source/match/units/structure-geometries/LanceBeamDefenseTower.tscn",
			"res://source/match/units/PrismDefenseObelisk.tscn":
			"res://source/match/units/structure-geometries/PrismDefenseObelisk.tscn",
			"res://source/match/units/RailCannonBunker.tscn":
			"res://source/match/units/structure-geometries/RailCannonBunker.tscn",
		"res://source/match/units/WeatherControlSpire.tscn":
		"res://source/match/units/structure-geometries/WeatherControlSpire.tscn",
	}
	const CONSTRUCTION_REQUIREMENTS = {
		"res://source/match/units/RoboticsBay.tscn":
		["res://source/match/units/RadarUplink.tscn"],
		"res://source/match/units/TechLab.tscn": ["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/AdvancedReactorPlant.tscn":
		["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/OrePurifier.tscn":
		["res://source/match/units/TechLab.tscn", "res://source/match/units/Refinery.tscn"],
		"res://source/match/units/ArcCoilDefenseTower.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/TeslaFenceSegment.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
		"res://source/match/units/RepairPad.tscn":
		["res://source/match/units/RoboticsBay.tscn"],
			"res://source/match/units/LanceBeamDefenseTower.tscn":
			["res://source/match/units/TechLab.tscn"],
			"res://source/match/units/PrismDefenseObelisk.tscn":
			["res://source/match/units/TechLab.tscn"],
			"res://source/match/units/RailCannonBunker.tscn":
			["res://source/match/units/TechLab.tscn"],
		"res://source/match/units/WeatherControlSpire.tscn":
		["res://source/match/units/TechLab.tscn"],
	}
	const STRUCTURE_NAME_KEYS = {
		"res://source/match/units/CommandCenter.tscn": "CC",
		"res://source/match/units/PowerReactor.tscn": "POWER_REACTOR",
		"res://source/match/units/AdvancedReactorPlant.tscn": "ADVANCED_REACTOR_PLANT",
		"res://source/match/units/Refinery.tscn": "REFINERY",
		"res://source/match/units/OrePurifier.tscn": "ORE_PURIFIER",
		"res://source/match/units/TechOilDerrick.tscn": "TECH_OIL_DERRICK",
		"res://source/match/units/TechAirport.tscn": "TECH_AIRPORT",
		"res://source/match/units/TechHospital.tscn": "TECH_HOSPITAL",
		"res://source/match/units/TechRepairDepot.tscn": "TECH_REPAIR_DEPOT",
		"res://source/match/units/TechBunker.tscn": "TECH_BUNKER",
		"res://source/match/units/Barracks.tscn": "BARRACKS",
		"res://source/match/units/RadarUplink.tscn": "RADAR_UPLINK",
		"res://source/match/units/RoboticsBay.tscn": "ROBOTICS_BAY",
		"res://source/match/units/RepairPad.tscn": "REPAIR_PAD",
		"res://source/match/units/TechLab.tscn": "TECH_LAB",
		"res://source/match/units/VehicleFactory.tscn": "VEHICLE_FACTORY",
		"res://source/match/units/AircraftFactory.tscn": "AIRCRAFT_FACTORY",
		"res://source/match/units/AntiGroundTurret.tscn": "AG_TURRET",
		"res://source/match/units/AntiAirTurret.tscn": "AA_TURRET",
		"res://source/match/units/TeslaFenceSegment.tscn": "TESLA_FENCE_SEGMENT",
			"res://source/match/units/ArcCoilDefenseTower.tscn": "ARC_COIL_DEFENSE_TOWER",
			"res://source/match/units/LanceBeamDefenseTower.tscn": "LANCE_BEAM_DEFENSE_TOWER",
			"res://source/match/units/PrismDefenseObelisk.tscn": "PRISM_DEFENSE_OBELISK",
			"res://source/match/units/RailCannonBunker.tscn": "RAIL_CANNON_BUNKER",
		"res://source/match/units/WeatherControlSpire.tscn": "WEATHER_CONTROL_SPIRE",
	}
	const CONSTRUCTION_COSTS = {
		"res://source/match/units/CommandCenter.tscn":
		{
			"resource_a": 8,
			"resource_b": 8,
		},
		"res://source/match/units/PowerReactor.tscn":
		{
			"resource_a": 3,
			"resource_b": 1,
		},
		"res://source/match/units/AdvancedReactorPlant.tscn":
		{
			"resource_a": 8,
			"resource_b": 8,
		},
		"res://source/match/units/Refinery.tscn":
		{
			"resource_a": 4,
			"resource_b": 2,
		},
		"res://source/match/units/OrePurifier.tscn":
		{
			"resource_a": 6,
			"resource_b": 6,
		},
		"res://source/match/units/Barracks.tscn":
		{
			"resource_a": 3,
			"resource_b": 1,
		},
		"res://source/match/units/RadarUplink.tscn":
		{
			"resource_a": 4,
			"resource_b": 3,
		},
		"res://source/match/units/RoboticsBay.tscn":
		{
			"resource_a": 5,
			"resource_b": 5,
		},
		"res://source/match/units/RepairPad.tscn":
		{
			"resource_a": 4,
			"resource_b": 3,
		},
		"res://source/match/units/TechLab.tscn":
		{
			"resource_a": 7,
			"resource_b": 7,
		},
		"res://source/match/units/VehicleFactory.tscn":
		{
			"resource_a": 6,
			"resource_b": 0,
		},
		"res://source/match/units/AircraftFactory.tscn":
		{
			"resource_a": 4,
			"resource_b": 4,
		},
		"res://source/match/units/AntiGroundTurret.tscn":
		{
			"resource_a": 2,
			"resource_b": 2,
		},
		"res://source/match/units/AntiAirTurret.tscn":
		{
			"resource_a": 2,
			"resource_b": 2,
		},
		"res://source/match/units/TeslaFenceSegment.tscn":
		{
			"resource_a": 3,
			"resource_b": 3,
		},
		"res://source/match/units/ArcCoilDefenseTower.tscn":
		{
			"resource_a": 4,
			"resource_b": 5,
		},
			"res://source/match/units/LanceBeamDefenseTower.tscn":
			{
				"resource_a": 5,
				"resource_b": 6,
			},
			"res://source/match/units/PrismDefenseObelisk.tscn":
			{
				"resource_a": 7,
				"resource_b": 8,
			},
			"res://source/match/units/RailCannonBunker.tscn":
			{
			"resource_a": 6,
			"resource_b": 7,
		},
		"res://source/match/units/WeatherControlSpire.tscn":
		{
			"resource_a": 8,
			"resource_b": 9,
		},
	}
	const POWER_SUPPLY = {
		"res://source/match/units/CommandCenter.tscn": 8,
		"res://source/match/units/PowerReactor.tscn": 18,
		"res://source/match/units/AdvancedReactorPlant.tscn": 48,
	}
	const POWER_DRAIN = {
		"res://source/match/units/Refinery.tscn": 4,
		"res://source/match/units/OrePurifier.tscn": 6,
		"res://source/match/units/Barracks.tscn": 4,
		"res://source/match/units/RadarUplink.tscn": 5,
		"res://source/match/units/RoboticsBay.tscn": 6,
		"res://source/match/units/RepairPad.tscn": 5,
		"res://source/match/units/TechLab.tscn": 8,
		"res://source/match/units/VehicleFactory.tscn": 6,
		"res://source/match/units/AircraftFactory.tscn": 7,
		"res://source/match/units/AntiGroundTurret.tscn": 4,
		"res://source/match/units/AntiAirTurret.tscn": 4,
		"res://source/match/units/TeslaFenceSegment.tscn": 3,
			"res://source/match/units/ArcCoilDefenseTower.tscn": 8,
			"res://source/match/units/LanceBeamDefenseTower.tscn": 10,
			"res://source/match/units/PrismDefenseObelisk.tscn": 13,
			"res://source/match/units/RailCannonBunker.tscn": 12,
		"res://source/match/units/WeatherControlSpire.tscn": 14,
	}
	const DEFAULT_PROPERTIES = {
		"res://source/match/units/Drone.tscn":
		{
			"sight_range": 10.0,
			"hp": 6,
			"hp_max": 6,
		},
		"res://source/match/units/Worker.tscn":
		{
			"sight_range": 5.0,
			"hp": 6,
			"hp_max": 6,
			"resources_max": 2,
		},
		"res://source/match/units/LandMine.tscn":
		{
			"sight_range": 1.0,
			"hp": 1,
			"hp_max": 1,
			"mine_damage": 4.0,
			"trigger_radius": 0.9,
			"blast_radius": 1.5,
			"arming_delay": 0.25,
		},
		"res://source/match/units/OreHarvester.tscn":
		{
			"sight_range": 7.0,
			"hp": 12,
			"hp_max": 12,
			"resources_max": 6,
		},
		"res://source/match/units/MobileConstructionVehicle.tscn":
		{
			"sight_range": 8.5,
			"hp": 16,
			"hp_max": 16,
		},
		"res://source/match/units/Helicopter.tscn":
		{
			"sight_range": 8.0,
			"hp": 10,
			"hp_max": 10,
			"attack_damage": 1,
			"attack_interval": 1.0,
			"attack_range": 5.0,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
		},
		"res://source/match/units/InterceptorVTOL.tscn":
		{
			"sight_range": 12.0,
			"hp": 9,
			"hp_max": 9,
			"attack_damage": 2,
			"attack_interval": 0.45,
			"attack_range": 7.5,
			"attack_domains": [Navigation.Domain.AIR],
		},
		"res://source/match/units/Tank.tscn":
		{
			"sight_range": 8.0,
			"hp": 10,
			"hp_max": 10,
			"attack_damage": 2,
			"attack_interval": 0.75,
			"attack_range": 5.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/LightRifleInfantry.tscn":
		{
			"sight_range": 7.0,
			"hp": 4,
			"hp_max": 4,
			"attack_damage": 1,
			"attack_interval": 0.9,
			"attack_range": 4.5,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/RocketInfantry.tscn":
		{
			"sight_range": 8.0,
			"hp": 5,
			"hp_max": 5,
			"attack_damage": 2,
			"attack_interval": 1.6,
			"attack_range": 6.0,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
		},
		"res://source/match/units/FieldMedic.tscn":
			{
				"sight_range": 7.0,
				"hp": 5,
				"hp_max": 5,
				"repair_rate": Repair.HITPOINTS_PER_SECOND * 0.85,
				"repair_radius": 3.75,
			},
		"res://source/match/units/ShieldTrooper.tscn":
		{
			"sight_range": 7.0,
			"hp": 9,
			"hp_max": 9,
			"attack_damage": 1,
			"attack_interval": 0.85,
			"attack_range": 4.2,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/FlakRocketTeam.tscn":
		{
			"sight_range": 9.0,
			"hp": 6,
			"hp_max": 6,
			"attack_damage": 3,
			"attack_interval": 1.25,
			"attack_range": 7.0,
			"attack_domains": [Navigation.Domain.AIR],
			"splash_radius": 1.2,
			"splash_damage_multiplier": 0.45,
		},
		"res://source/match/units/FlakRocketTeamMk2.tscn":
		{
			"sight_range": 10.5,
			"hp": 7,
			"hp_max": 7,
			"attack_damage": 4,
			"attack_interval": 1.35,
			"attack_range": 8.2,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
			"splash_radius": 1.5,
			"splash_damage_multiplier": 0.55,
		},
		"res://source/match/units/HeavyMachinegunTrooper.tscn":
		{
			"sight_range": 7.5,
			"hp": 7,
			"hp_max": 7,
			"attack_damage": 1,
			"attack_interval": 0.35,
			"attack_range": 4.5,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/ShockTrooper.tscn":
		{
			"sight_range": 8.0,
			"hp": 6,
			"hp_max": 6,
			"attack_damage": 3,
			"attack_interval": 1.0,
			"attack_range": 4.8,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/GrenadierTrooper.tscn":
		{
			"sight_range": 7.5,
			"hp": 5,
			"hp_max": 5,
			"attack_damage": 2,
			"attack_interval": 1.7,
			"attack_range": 5.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"splash_radius": 1.4,
			"splash_damage_multiplier": 0.55,
		},
		"res://source/match/units/MortarTeam.tscn":
		{
			"sight_range": 8.5,
			"hp": 5,
			"hp_max": 5,
			"attack_damage": 3,
			"attack_interval": 2.2,
			"attack_range": 7.2,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"splash_radius": 1.8,
			"splash_damage_multiplier": 0.6,
		},
		"res://source/match/units/CryoSprayer.tscn":
		{
			"sight_range": 7.5,
			"hp": 6,
			"hp_max": 6,
			"attack_damage": 1,
			"attack_interval": 0.45,
			"attack_range": 3.2,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"splash_radius": 1.8,
			"splash_damage_multiplier": 0.45,
		},
		"res://source/match/units/SniperScout.tscn":
		{
			"sight_range": 11.0,
			"hp": 4,
			"hp_max": 4,
			"attack_damage": 4,
			"attack_interval": 2.3,
			"attack_range": 8.5,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/RailSniperTeam.tscn":
		{
			"sight_range": 12.5,
			"hp": 6,
			"hp_max": 6,
			"attack_damage": 6,
			"attack_interval": 2.8,
			"attack_range": 10.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/PhaseSaboteur.tscn":
		{
			"sight_range": 9.0,
			"hp": 5,
			"hp_max": 5,
			"attack_damage": 2,
			"attack_interval": 1.2,
			"attack_range": 4.2,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"structure_damage_multiplier": 3.0,
		},
		"res://source/match/units/SaboteurInfiltrator.tscn":
		{
			"sight_range": 10.0,
			"hp": 6,
			"hp_max": 6,
			"attack_damage": 2,
			"attack_interval": 0.9,
			"attack_range": 4.5,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"structure_damage_multiplier": 4.0,
			"capture_time": Capture.ENGINEER_CAPTURE_TIME_SECONDS * 2.0,
			"infiltration_resource_steal_ratio": Capture.SABOTEUR_RESOURCE_STEAL_RATIO,
			"infiltration_resource_steal_cap": Capture.SABOTEUR_RESOURCE_STEAL_CAP,
			"infiltration_production_veterancy_rank":
			Capture.SABOTEUR_PRODUCTION_VETERANCY_RANK,
			"infiltration_power_sabotage_duration":
			Capture.SABOTEUR_POWER_SABOTAGE_DURATION_SECONDS,
		},
		"res://source/match/units/PulseRifleCommando.tscn":
		{
			"sight_range": 9.0,
			"hp": 8,
			"hp_max": 8,
			"attack_damage": 2,
			"attack_interval": 0.55,
			"attack_range": 5.5,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
		},
		"res://source/match/units/TacticalOfficer.tscn":
		{
			"sight_range": 12.0,
			"hp": 6,
			"hp_max": 6,
			"attack_damage": 2,
			"attack_interval": 0.8,
			"attack_range": 6.2,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
		},
		"res://source/match/units/ScoutRover.tscn":
		{
			"sight_range": 12.0,
			"hp": 5,
			"hp_max": 5,
			"attack_damage": 1,
			"attack_interval": 0.8,
			"attack_range": 4.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/MirageScoutTank.tscn":
		{
			"sight_range": 14.0,
			"hp": 8,
			"hp_max": 8,
			"attack_damage": 1,
			"attack_interval": 0.6,
			"attack_range": 4.8,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/FlameAssaultBuggy.tscn":
		{
			"sight_range": 8.0,
			"hp": 7,
			"hp_max": 7,
			"attack_damage": 1,
			"attack_interval": 0.35,
			"attack_range": 3.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/DroneMineLayer.tscn":
		{
			"sight_range": 9.0,
			"hp": 8,
			"hp_max": 8,
			"mine_damage": 4.0,
			"mine_deploy_interval": 2.2,
			"mine_deploy_radius": 1.1,
			"mine_spacing": 1.15,
			"mine_limit": 4,
		},
		"res://source/match/units/TeslaCrawlerMk2.tscn":
		{
			"sight_range": 8.5,
			"hp": 12,
			"hp_max": 12,
			"attack_damage": 2,
			"attack_interval": 0.65,
			"attack_range": 3.8,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"splash_radius": 1.5,
			"splash_damage_multiplier": 0.5,
			"structure_damage_multiplier": 1.2,
		},
		"res://source/match/units/RocketTrooperRobot.tscn":
		{
			"sight_range": 8.0,
			"hp": 7,
			"hp_max": 7,
			"attack_damage": 2,
			"attack_interval": 1.4,
			"attack_range": 5.5,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
		},
		"res://source/match/units/JammerVehicle.tscn":
		{
			"sight_range": 14.0,
			"hp": 8,
			"hp_max": 8,
			"attack_damage": 1,
			"attack_interval": 1.0,
			"attack_range": 6.0,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
		},
		"res://source/match/units/AntiAirWalker.tscn":
		{
			"sight_range": 9.0,
			"hp": 9,
			"hp_max": 9,
			"attack_damage": 2,
			"attack_interval": 0.8,
			"attack_range": 7.5,
			"attack_domains": [Navigation.Domain.AIR],
		},
		"res://source/match/units/FlakHoverTank.tscn":
		{
			"sight_range": 10.0,
			"hp": 10,
			"hp_max": 10,
			"attack_damage": 2,
			"attack_interval": 0.55,
			"attack_range": 7.5,
			"attack_domains": [Navigation.Domain.AIR],
		},
		"res://source/match/units/MobileRepairCrawler.tscn":
			{
				"sight_range": 9.0,
				"hp": 9,
				"hp_max": 9,
				"repair_rate": Repair.HITPOINTS_PER_SECOND * 1.25,
				"repair_radius": 4.0,
			},
		"res://source/match/units/MobileShieldProjector.tscn":
		{
			"sight_range": 9.5,
			"hp": 10,
			"hp_max": 10,
			"support_shield_radius": 4.0,
			"support_shield_duration": 0.7,
			"support_shield_damage_multiplier": 0.55,
		},
		"res://source/match/units/ModularMissileCarrier.tscn":
		{
			"sight_range": 10.0,
			"hp": 10,
			"hp_max": 10,
			"attack_damage": 3,
			"attack_interval": 1.6,
			"attack_range": 8.0,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
			"splash_radius": 1.6,
			"splash_damage_multiplier": 0.45,
		},
		"res://source/match/units/LongbowMissileCrawler.tscn":
		{
			"sight_range": 11.0,
			"hp": 12,
			"hp_max": 12,
			"attack_damage": 4,
			"attack_interval": 1.8,
			"attack_range": 9.0,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
			"splash_radius": 1.7,
			"splash_damage_multiplier": 0.5,
		},
		"res://source/match/units/SiegeArtilleryVehicle.tscn":
		{
			"sight_range": 9.0,
			"hp": 12,
			"hp_max": 12,
			"attack_damage": 4,
			"attack_interval": 2.5,
			"attack_range": 9.5,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"splash_radius": 2.2,
			"splash_damage_multiplier": 0.6,
		},
		"res://source/match/units/SiegeDrillTank.tscn":
		{
			"sight_range": 8.5,
			"hp": 16,
			"hp_max": 16,
			"attack_damage": 4,
			"attack_interval": 1.4,
			"attack_range": 3.6,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"structure_damage_multiplier": 2.4,
		},
		"res://source/match/units/LanceBeamTank.tscn":
		{
			"sight_range": 10.0,
			"hp": 14,
			"hp_max": 14,
			"attack_damage": 3,
			"attack_interval": 0.9,
			"attack_range": 7.0,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
		},
		"res://source/match/units/RailgunTank.tscn":
		{
			"sight_range": 10.0,
			"hp": 16,
			"hp_max": 16,
			"attack_damage": 7,
			"attack_interval": 2.4,
			"attack_range": 8.5,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/HammerSiegeTank.tscn":
		{
			"sight_range": 9.5,
			"hp": 17,
			"hp_max": 17,
			"attack_damage": 6,
			"attack_interval": 2.6,
			"attack_range": 9.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"splash_radius": 2.4,
			"splash_damage_multiplier": 0.65,
		},
		"res://source/match/units/HeavySiegeWalker.tscn":
		{
			"sight_range": 10.0,
			"hp": 20,
			"hp_max": 20,
			"attack_damage": 8,
			"attack_interval": 3.2,
			"attack_range": 10.5,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"splash_radius": 2.8,
			"splash_damage_multiplier": 0.7,
		},
		"res://source/match/units/RailArtilleryWalker.tscn":
		{
			"sight_range": 11.0,
			"hp": 18,
			"hp_max": 18,
			"attack_damage": 10,
			"attack_interval": 3.6,
			"attack_range": 12.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"splash_radius": 3.2,
			"splash_damage_multiplier": 0.65,
		},
		"res://source/match/units/EngineerDrone.tscn":
		{
			"sight_range": 9.0,
			"hp": 5,
			"hp_max": 5,
			"repair_rate": Repair.HITPOINTS_PER_SECOND,
			"capture_time": Capture.ENGINEER_CAPTURE_TIME_SECONDS,
		},
		"res://source/match/units/BomberVTOL.tscn":
		{
			"sight_range": 9.0,
			"hp": 12,
			"hp_max": 12,
			"attack_damage": 4,
			"attack_interval": 2.0,
			"attack_range": 6.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"splash_radius": 2.0,
			"splash_damage_multiplier": 0.7,
		},
		"res://source/match/units/RocketGunship.tscn":
		{
			"sight_range": 10.0,
			"hp": 11,
			"hp_max": 11,
			"attack_damage": 3,
			"attack_interval": 1.2,
			"attack_range": 6.5,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
			"splash_radius": 1.2,
			"splash_damage_multiplier": 0.45,
		},
		"res://source/match/units/HeavyBombardmentAirship.tscn":
		{
			"sight_range": 10.0,
			"hp": 18,
			"hp_max": 18,
			"attack_damage": 7,
			"attack_interval": 3.0,
			"attack_range": 8.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"splash_radius": 2.8,
			"splash_damage_multiplier": 0.75,
		},
		"res://source/match/units/SiegeAirship.tscn":
		{
			"sight_range": 10.5,
			"hp": 20,
			"hp_max": 20,
			"attack_damage": 8,
			"attack_interval": 3.4,
			"attack_range": 8.5,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"splash_radius": 3.1,
			"splash_damage_multiplier": 0.8,
		},
		"res://source/match/units/CommandCenter.tscn":
		{
			"sight_range": 10.0,
			"hp": 20,
			"hp_max": 20,
		},
		"res://source/match/units/PowerReactor.tscn":
		{
			"sight_range": 8.0,
			"hp": 12,
			"hp_max": 12,
		},
		"res://source/match/units/AdvancedReactorPlant.tscn":
		{
			"sight_range": 9.0,
			"hp": 18,
			"hp_max": 18,
		},
		"res://source/match/units/Refinery.tscn":
		{
			"sight_range": 8.0,
			"hp": 14,
			"hp_max": 14,
		},
		"res://source/match/units/OrePurifier.tscn":
		{
			"sight_range": 8.5,
			"hp": 16,
			"hp_max": 16,
			"resource_bonus_ratio": 0.25,
		},
		"res://source/match/units/TechOilDerrick.tscn":
		{
			"sight_range": 7.5,
			"hp": 14,
			"hp_max": 14,
			"resource_income_a": 1,
			"resource_income_b": 0,
			"income_interval_s": 6.0,
			"capture_bonus_a": 4,
			"capture_bonus_b": 0,
		},
		"res://source/match/units/TechAirport.tscn":
		{
			"sight_range": 10.0,
			"hp": 18,
			"hp_max": 18,
		},
		"res://source/match/units/TechHospital.tscn":
		{
			"sight_range": 8.5,
			"hp": 16,
			"hp_max": 16,
			"healing_rate": 1.5,
			"healing_radius": 4.5,
		},
		"res://source/match/units/TechRepairDepot.tscn":
		{
			"sight_range": 8.5,
			"hp": 16,
			"hp_max": 16,
			"repair_rate": 3.0,
			"repair_radius": 4.75,
		},
		"res://source/match/units/TechBunker.tscn":
		{
			"sight_range": 9.5,
			"hp": 18,
			"hp_max": 18,
			"attack_damage": 0.0,
			"attack_interval": 0.85,
			"attack_range": 7.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"garrison_capacity": 4,
			"garrison_attack_damage_per_unit": 1.25,
		},
		"res://source/match/units/Barracks.tscn":
		{
			"sight_range": 8.0,
			"hp": 13,
			"hp_max": 13,
		},
		"res://source/match/units/RadarUplink.tscn":
		{
			"sight_range": 14.0,
			"hp": 12,
			"hp_max": 12,
		},
		"res://source/match/units/RoboticsBay.tscn":
		{
			"sight_range": 10.0,
			"hp": 14,
			"hp_max": 14,
		},
		"res://source/match/units/RepairPad.tscn":
		{
			"sight_range": 8.5,
			"hp": 13,
			"hp_max": 13,
			"repair_rate": 4.5,
		},
		"res://source/match/units/TechLab.tscn":
		{
			"sight_range": 10.0,
			"hp": 16,
			"hp_max": 16,
		},
		"res://source/match/units/WeatherControlSpire.tscn":
		{
			"sight_range": 12.0,
			"hp": 18,
			"hp_max": 18,
		},
		"res://source/match/units/VehicleFactory.tscn":
		{
			"sight_range": 8.0,
			"hp": 16,
			"hp_max": 16,
		},
		"res://source/match/units/AircraftFactory.tscn":
		{
			"sight_range": 8.0,
			"hp": 16,
			"hp_max": 16,
		},
		"res://source/match/units/AntiGroundTurret.tscn":
		{
			"sight_range": 8.0,
			"hp": 8,
			"hp_max": 8,
			"attack_damage": 2,
			"attack_interval": 1.0,
			"attack_range": 8.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/AntiAirTurret.tscn":
		{
			"sight_range": 8.0,
			"hp": 8,
			"hp_max": 8,
			"attack_damage": 2,
			"attack_interval": 0.75,
			"attack_range": 8.0,
			"attack_domains": [Navigation.Domain.AIR],
		},
		"res://source/match/units/TeslaFenceSegment.tscn":
		{
			"sight_range": 6.0,
			"hp": 16,
			"hp_max": 16,
			"attack_damage": 1.5,
			"attack_interval": 0.35,
			"attack_range": 2.6,
			"attack_domains": [Navigation.Domain.TERRAIN],
		},
		"res://source/match/units/ArcCoilDefenseTower.tscn":
		{
			"sight_range": 9.0,
			"hp": 10,
			"hp_max": 10,
			"attack_damage": 2,
			"attack_interval": 0.55,
			"attack_range": 7.5,
			"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
			"splash_radius": 1.4,
			"splash_damage_multiplier": 0.45,
		},
			"res://source/match/units/LanceBeamDefenseTower.tscn":
			{
				"sight_range": 10.0,
			"hp": 12,
			"hp_max": 12,
			"attack_damage": 5,
			"attack_interval": 1.5,
				"attack_range": 9.5,
				"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
			},
			"res://source/match/units/PrismDefenseObelisk.tscn":
			{
				"sight_range": 12.0,
				"hp": 13,
				"hp_max": 13,
				"attack_damage": 7,
				"attack_interval": 2.0,
				"attack_range": 11.0,
				"attack_domains": [Navigation.Domain.TERRAIN, Navigation.Domain.AIR],
				"structure_damage_multiplier": 1.5,
			},
			"res://source/match/units/RailCannonBunker.tscn":
			{
			"sight_range": 12.0,
			"hp": 14,
			"hp_max": 14,
			"attack_damage": 9,
			"attack_interval": 3.2,
			"attack_range": 12.0,
			"attack_domains": [Navigation.Domain.TERRAIN],
			"splash_radius": 3.0,
			"splash_damage_multiplier": 0.7,
			"structure_damage_multiplier": 1.35,
		},
	}
	const PROJECTILES = {
		"res://source/match/units/Helicopter.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/Tank.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/LightRifleInfantry.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/RocketInfantry.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/FlakRocketTeam.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/FlakRocketTeamMk2.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/InterceptorVTOL.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/HeavyMachinegunTrooper.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/ShockTrooper.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/ShieldTrooper.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/GrenadierTrooper.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/MortarTeam.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/CryoSprayer.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/SniperScout.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/RailSniperTeam.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/PhaseSaboteur.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/SaboteurInfiltrator.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/PulseRifleCommando.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/TacticalOfficer.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/ScoutRover.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/MirageScoutTank.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/FlameAssaultBuggy.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/TeslaCrawlerMk2.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/RocketTrooperRobot.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/JammerVehicle.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/AntiAirWalker.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/FlakHoverTank.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/ModularMissileCarrier.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/LongbowMissileCrawler.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/SiegeArtilleryVehicle.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/SiegeDrillTank.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/LanceBeamTank.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/RailgunTank.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/HammerSiegeTank.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/HeavySiegeWalker.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/RailArtilleryWalker.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/BomberVTOL.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/RocketGunship.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/HeavyBombardmentAirship.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/SiegeAirship.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/AntiGroundTurret.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/AntiAirTurret.tscn":
		"res://source/match/units/projectiles/Rocket.tscn",
		"res://source/match/units/ArcCoilDefenseTower.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
			"res://source/match/units/LanceBeamDefenseTower.tscn":
			"res://source/match/units/projectiles/CannonShell.tscn",
			"res://source/match/units/PrismDefenseObelisk.tscn":
			"res://source/match/units/projectiles/CannonShell.tscn",
			"res://source/match/units/RailCannonBunker.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn",
		"res://source/match/units/TechBunker.tscn":
		"res://source/match/units/projectiles/CannonShell.tscn"
	}
	const ADHERENCE_MARGIN_M = 0.3  # TODO: try lowering while fixing a 'push' problem
	const NEW_RESOURCE_SEARCH_RADIUS_M = 30
	const MOVING_UNIT_RADIUS_MAX_M = 1.0
	const EMPTY_SPACE_RADIUS_SURROUNDING_STRUCTURE_M = MOVING_UNIT_RADIUS_MAX_M * 2.5
	const BASE_CONSTRUCTION_RADIUS_M = 9.0
	const STRUCTURE_CONSTRUCTING_SPEED = 0.3  # progress [0.0..1.0] per second


class VoiceNarrator:
	enum Events {
		MATCH_STARTED,
		MATCH_ABORTED,
		MATCH_FINISHED_WITH_VICTORY,
		MATCH_FINISHED_WITH_DEFEAT,
		BASE_UNDER_ATTACK,
		UNIT_UNDER_ATTACK,
		UNIT_LOST,
		UNIT_PRODUCTION_STARTED,
		UNIT_PRODUCTION_FINISHED,
		UNIT_CONSTRUCTION_FINISHED,
		UNIT_HELLO,
		UNIT_ACK_1,
		UNIT_ACK_2,
		NOT_ENOUGH_RESOURCES,
		SUPPORT_POWER_READY,
		SUPPORT_POWER_FIRED,
		ENEMY_SUPPORT_POWER_FIRED,
		ENEMY_SUPERWEAPON_READY,
		ENEMY_SUPERWEAPON_LAUNCHED,
	}

	const EVENT_TO_ASSET_MAPPING = {
		Events.MATCH_STARTED:
		preload("res://assets/voice/english/ttsmaker-com-148-alayna-us/battle_control_online.ogg"),
		Events.MATCH_ABORTED:
		preload("res://assets/voice/english/ttsmaker-com-148-alayna-us/battle_control_offline.ogg"),
		Events.MATCH_FINISHED_WITH_VICTORY:
		preload("res://assets/voice/english/ttsmaker-com-148-alayna-us/you_are_victorious.ogg"),
		Events.MATCH_FINISHED_WITH_DEFEAT:
		preload("res://assets/voice/english/ttsmaker-com-148-alayna-us/you_have_lost.ogg"),
		Events.BASE_UNDER_ATTACK:
		preload(
			"res://assets/voice/english/ttsmaker-com-148-alayna-us/your_base_is_under_attack.ogg"
		),
		Events.UNIT_UNDER_ATTACK:
		preload("res://assets/voice/english/ttsmaker-com-148-alayna-us/unit_under_attack.ogg"),
		Events.UNIT_LOST:
		preload("res://assets/voice/english/ttsmaker-com-148-alayna-us/unit_lost.ogg"),
		Events.UNIT_PRODUCTION_STARTED:
		preload("res://assets/voice/english/ttsmaker-com-148-alayna-us/training.ogg"),
		Events.UNIT_PRODUCTION_FINISHED:
		preload("res://assets/voice/english/ttsmaker-com-148-alayna-us/unit_ready.ogg"),
		Events.UNIT_CONSTRUCTION_FINISHED:
		preload("res://assets/voice/english/ttsmaker-com-148-alayna-us/construction_complete.ogg"),
		Events.UNIT_HELLO:
		preload("res://assets/voice/english/ttsmaker-com-2704-jackson-us/sir.ogg"),
		Events.UNIT_ACK_1:
		preload("res://assets/voice/english/ttsmaker-com-2704-jackson-us/yes_sir.ogg"),
		Events.UNIT_ACK_2:
		preload("res://assets/voice/english/ttsmaker-com-2704-jackson-us/acknowledged.ogg"),
		Events.NOT_ENOUGH_RESOURCES:
		preload("res://assets/voice/english/ttsmaker-com-148-alayna-us/not_enough_resources.ogg"),
		Events.SUPPORT_POWER_READY:
		preload("res://assets/voice/english/ttsmaker-com-148-alayna-us/unit_ready.ogg"),
		Events.SUPPORT_POWER_FIRED:
		preload("res://assets/voice/english/ttsmaker-com-2704-jackson-us/acknowledged.ogg"),
		Events.ENEMY_SUPPORT_POWER_FIRED:
		preload("res://assets/voice/english/ttsmaker-com-148-alayna-us/unit_under_attack.ogg"),
		Events.ENEMY_SUPERWEAPON_READY:
		preload(
			"res://assets/voice/english/ttsmaker-com-148-alayna-us/your_base_is_under_attack.ogg"
		),
		Events.ENEMY_SUPERWEAPON_LAUNCHED:
		preload(
			"res://assets/voice/english/ttsmaker-com-148-alayna-us/your_base_is_under_attack.ogg"
		),
	}
