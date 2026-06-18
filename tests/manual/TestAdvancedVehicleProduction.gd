extends "res://tests/manual/Match.gd"

const CollectingResourcesSequentially = preload(
	"res://source/match/units/actions/CollectingResourcesSequentially.gd"
)
const CombatDamage = preload("res://source/match/utils/CombatDamageUtils.gd")
const Repairing = preload("res://source/match/units/actions/Repairing.gd")
const WorkerUnit = preload("res://source/match/units/Worker.tscn")
const OreHarvesterUnit = preload("res://source/match/units/OreHarvester.tscn")
const MobileConstructionVehicleUnit = preload(
	"res://source/match/units/MobileConstructionVehicle.tscn"
)
const MirageScoutTankUnit = preload("res://source/match/units/MirageScoutTank.tscn")
const FlameAssaultBuggyUnit = preload("res://source/match/units/FlameAssaultBuggy.tscn")
const DroneMineLayerUnit = preload("res://source/match/units/DroneMineLayer.tscn")
const TeslaCrawlerMk2Unit = preload("res://source/match/units/TeslaCrawlerMk2.tscn")
const ModularMissileCarrierUnit = preload("res://source/match/units/ModularMissileCarrier.tscn")
const JammerVehicleUnit = preload("res://source/match/units/JammerVehicle.tscn")
const FlakHoverTankUnit = preload("res://source/match/units/FlakHoverTank.tscn")
const MobileRepairCrawlerUnit = preload("res://source/match/units/MobileRepairCrawler.tscn")
const MobileShieldProjectorUnit = preload("res://source/match/units/MobileShieldProjector.tscn")
const LongbowMissileCrawlerUnit = preload("res://source/match/units/LongbowMissileCrawler.tscn")
const SiegeArtilleryVehicleUnit = preload("res://source/match/units/SiegeArtilleryVehicle.tscn")
const SiegeDrillTankUnit = preload("res://source/match/units/SiegeDrillTank.tscn")
const LanceBeamTankUnit = preload("res://source/match/units/LanceBeamTank.tscn")
const RailgunTankUnit = preload("res://source/match/units/RailgunTank.tscn")
const HammerSiegeTankUnit = preload("res://source/match/units/HammerSiegeTank.tscn")
const HeavySiegeWalkerUnit = preload("res://source/match/units/HeavySiegeWalker.tscn")
const RailArtilleryWalkerUnit = preload("res://source/match/units/RailArtilleryWalker.tscn")
const RA2_INSPIRED_ICON_SET = "imagegen-rts-ra2-inspired-20260616-01"
const LATE_TECH_ICON_SET = "imagegen-rts-late-tech-20260616-01"
const MENU_POLISH_ICON_SET = "imagegen-rts-menu-polish-20260616-01"
const ROCKET_ROBOT_ICON_SET = "imagegen-rts-rocket-robot-20260616-01"
const RA2_INSPIRED_ROSTER_ICON_SET = "imagegen-rts-ra2-inspired-roster-20260616-01"
const NEW_ASSET_ICON_SET = "imagegen-rts-new-assets-20260616-01"
const ROSTER_ICON_SET = "imagegen-rts-roster-20260616-02"

@onready var _vehicle_factory = $Players/Human/VehicleFactory


func _ready():
	super()
	await get_tree().process_frame
	assert(
		Utils.Match.Unit.Tech.can_construct($Players/Human, "res://source/match/units/TechLab.tscn"),
		"robotics bay should unlock tech lab construction"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, OreHarvesterUnit.resource_path),
		"vehicle factory should unlock ore harvester production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, MobileConstructionVehicleUnit.resource_path),
		"tech lab should unlock mobile construction vehicle production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, MirageScoutTankUnit.resource_path),
		"radar uplink should unlock mirage scout tank production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, ModularMissileCarrierUnit.resource_path),
		"robotics bay should unlock modular missile carrier production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, TeslaCrawlerMk2Unit.resource_path),
		"robotics bay should unlock tesla crawler production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, FlakHoverTankUnit.resource_path),
		"radar uplink should unlock flak hover tank production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, MobileRepairCrawlerUnit.resource_path),
		"robotics bay should unlock mobile repair crawler production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, MobileShieldProjectorUnit.resource_path),
		"robotics bay should unlock mobile shield projector production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, DroneMineLayerUnit.resource_path),
		"robotics bay should unlock drone mine layer production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, LongbowMissileCrawlerUnit.resource_path),
		"robotics bay should unlock longbow missile crawler production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, HeavySiegeWalkerUnit.resource_path),
		"tech lab should unlock heavy siege walker production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, SiegeDrillTankUnit.resource_path),
		"robotics bay should unlock siege drill tank production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, HammerSiegeTankUnit.resource_path),
		"tech lab should unlock hammer siege tank production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, RailArtilleryWalkerUnit.resource_path),
		"tech lab should unlock rail artillery walker production"
	)
	_vehicle_factory.production_queue.produce(MirageScoutTankUnit, true)
	_vehicle_factory.production_queue.produce(FlameAssaultBuggyUnit, true)
	_vehicle_factory.production_queue.produce(DroneMineLayerUnit, true)
	_vehicle_factory.production_queue.produce(TeslaCrawlerMk2Unit, true)
	_vehicle_factory.production_queue.produce(ModularMissileCarrierUnit, true)
	_vehicle_factory.production_queue.produce(JammerVehicleUnit, true)
	_vehicle_factory.production_queue.produce(FlakHoverTankUnit, true)
	_vehicle_factory.production_queue.produce(MobileRepairCrawlerUnit, true)
	_vehicle_factory.production_queue.produce(MobileShieldProjectorUnit, true)
	_vehicle_factory.production_queue.produce(LongbowMissileCrawlerUnit, true)
	_vehicle_factory.production_queue.produce(SiegeArtilleryVehicleUnit, true)
	_vehicle_factory.production_queue.produce(SiegeDrillTankUnit, true)
	_vehicle_factory.production_queue.produce(LanceBeamTankUnit, true)
	_vehicle_factory.production_queue.produce(RailgunTankUnit, true)
	_vehicle_factory.production_queue.produce(HammerSiegeTankUnit, true)
	_vehicle_factory.production_queue.produce(HeavySiegeWalkerUnit, true)
	_vehicle_factory.production_queue.produce(RailArtilleryWalkerUnit, true)
	_vehicle_factory.production_queue.produce(OreHarvesterUnit, true)
	_vehicle_factory.production_queue.produce(MobileConstructionVehicleUnit, true)

	var queued_elements = _vehicle_factory.production_queue.get_elements()
	assert(queued_elements.size() == 19, "advanced vehicle roster should be queued")
	assert(
		queued_elements[0].unit_prototype.resource_path == MirageScoutTankUnit.resource_path,
		"mirage scout tank should be produced by vehicle factory"
	)
	assert(
		queued_elements[1].unit_prototype.resource_path == FlameAssaultBuggyUnit.resource_path,
		"flame assault buggy should be produced by vehicle factory"
	)
	assert(
		queued_elements[2].unit_prototype.resource_path == DroneMineLayerUnit.resource_path,
		"drone mine layer should be produced by vehicle factory"
	)
	assert(
		queued_elements[3].unit_prototype.resource_path == TeslaCrawlerMk2Unit.resource_path,
		"tesla crawler should be produced by vehicle factory"
	)
	assert(
		queued_elements[4].unit_prototype.resource_path == ModularMissileCarrierUnit.resource_path,
		"modular missile carrier should be produced by vehicle factory"
	)
	assert(
		queued_elements[5].unit_prototype.resource_path == JammerVehicleUnit.resource_path,
		"jammer vehicle should be produced by vehicle factory"
	)
	assert(
		queued_elements[6].unit_prototype.resource_path == FlakHoverTankUnit.resource_path,
		"flak hover tank should be produced by vehicle factory"
	)
	assert(
		queued_elements[7].unit_prototype.resource_path == MobileRepairCrawlerUnit.resource_path,
		"mobile repair crawler should be produced by vehicle factory"
	)
	assert(
		queued_elements[8].unit_prototype.resource_path == MobileShieldProjectorUnit.resource_path,
		"mobile shield projector should be produced by vehicle factory"
	)
	assert(
		queued_elements[9].unit_prototype.resource_path == LongbowMissileCrawlerUnit.resource_path,
		"longbow missile crawler should be produced by vehicle factory"
	)
	assert(
		queued_elements[10].unit_prototype.resource_path == SiegeArtilleryVehicleUnit.resource_path,
		"siege artillery should be produced by vehicle factory"
	)
	assert(
		queued_elements[11].unit_prototype.resource_path == SiegeDrillTankUnit.resource_path,
		"siege drill tank should be produced by vehicle factory"
	)
	assert(
		queued_elements[12].unit_prototype.resource_path == LanceBeamTankUnit.resource_path,
		"lance beam tank should be produced by vehicle factory"
	)
	assert(
		queued_elements[13].unit_prototype.resource_path == RailgunTankUnit.resource_path,
		"railgun tank should be produced by vehicle factory"
	)
	assert(
		queued_elements[14].unit_prototype.resource_path == HammerSiegeTankUnit.resource_path,
		"hammer siege tank should be produced by vehicle factory"
	)
	assert(
		queued_elements[15].unit_prototype.resource_path == HeavySiegeWalkerUnit.resource_path,
		"heavy siege walker should be produced by vehicle factory"
	)
	assert(
		queued_elements[16].unit_prototype.resource_path == RailArtilleryWalkerUnit.resource_path,
		"rail artillery walker should be produced by vehicle factory"
	)
	assert(
		queued_elements[17].unit_prototype.resource_path == OreHarvesterUnit.resource_path,
		"ore harvester should be produced by vehicle factory"
	)
	assert(
		queued_elements[18].unit_prototype.resource_path == MobileConstructionVehicleUnit.resource_path,
		"mobile construction vehicle should be produced by vehicle factory"
	)
	_spawn_and_check_unit(MirageScoutTankUnit, Vector3(16.0, 0.0, 8.0))
	_spawn_and_check_unit(FlameAssaultBuggyUnit, Vector3(18.0, 0.0, 8.0))
	_spawn_and_check_unit(DroneMineLayerUnit, Vector3(34.0, 0.0, 8.0))
	_spawn_and_check_unit(TeslaCrawlerMk2Unit, Vector3(20.0, 0.0, 8.0))
	_spawn_and_check_unit(ModularMissileCarrierUnit, Vector3(22.0, 0.0, 8.0))
	_spawn_and_check_unit(JammerVehicleUnit, Vector3(24.0, 0.0, 8.0))
	_spawn_and_check_unit(FlakHoverTankUnit, Vector3(26.0, 0.0, 8.0))
	_spawn_and_check_unit(MobileRepairCrawlerUnit, Vector3(28.0, 0.0, 8.0))
	_spawn_and_check_unit(MobileShieldProjectorUnit, Vector3(30.0, 0.0, 8.0))
	_spawn_and_check_unit(LongbowMissileCrawlerUnit, Vector3(16.0, 0.0, 10.0))
	_spawn_and_check_unit(SiegeArtilleryVehicleUnit, Vector3(18.0, 0.0, 10.0))
	_spawn_and_check_unit(SiegeDrillTankUnit, Vector3(20.0, 0.0, 10.0))
	_spawn_and_check_unit(LanceBeamTankUnit, Vector3(22.0, 0.0, 10.0))
	_spawn_and_check_unit(RailgunTankUnit, Vector3(24.0, 0.0, 10.0))
	_spawn_and_check_unit(HammerSiegeTankUnit, Vector3(26.0, 0.0, 10.0))
	_spawn_and_check_unit(HeavySiegeWalkerUnit, Vector3(28.0, 0.0, 10.0))
	_spawn_and_check_unit(RailArtilleryWalkerUnit, Vector3(30.0, 0.0, 10.0))
	_spawn_and_check_unit(OreHarvesterUnit, Vector3(32.0, 0.0, 10.0))
	_spawn_and_check_unit(MobileConstructionVehicleUnit, Vector3(34.0, 0.0, 10.0))
	await get_tree().process_frame
	assert($Players/Human/MirageScoutTank.hp == $Players/Human/MirageScoutTank.hp_max)
	assert($Players/Human/MirageScoutTank.sight_range > $Players/Human/FlameAssaultBuggy.sight_range)
	assert($Players/Human/FlameAssaultBuggy.hp == $Players/Human/FlameAssaultBuggy.hp_max)
	assert($Players/Human/DroneMineLayer.hp == $Players/Human/DroneMineLayer.hp_max)
	assert($Players/Human/DroneMineLayer.mine_damage > 0.0)
	assert($Players/Human/DroneMineLayer.mine_limit > 0)
	assert($Players/Human/TeslaCrawlerMk2.hp == $Players/Human/TeslaCrawlerMk2.hp_max)
	assert($Players/Human/TeslaCrawlerMk2.splash_radius > 0.0)
	assert($Players/Human/TeslaCrawlerMk2.attack_range > $Players/Human/FlameAssaultBuggy.attack_range)
	assert(
		CombatDamage._get_damage_amount($Players/Human/TeslaCrawlerMk2, $Players/Human/CommandCenter)
		== $Players/Human/TeslaCrawlerMk2.attack_damage
		* $Players/Human/TeslaCrawlerMk2.structure_damage_multiplier,
		"tesla crawler structure damage multiplier should be applied by damage utility"
	)
	assert($Players/Human/ModularMissileCarrier.hp == $Players/Human/ModularMissileCarrier.hp_max)
	assert(Constants.Match.Navigation.Domain.AIR in $Players/Human/ModularMissileCarrier.attack_domains)
	assert(Constants.Match.Navigation.Domain.TERRAIN in $Players/Human/ModularMissileCarrier.attack_domains)
	assert($Players/Human/ModularMissileCarrier.splash_radius > 0.0)
	assert($Players/Human/JammerVehicle.hp == $Players/Human/JammerVehicle.hp_max)
	assert(Constants.Match.Navigation.Domain.AIR in $Players/Human/FlakHoverTank.attack_domains)
	assert(not Constants.Match.Navigation.Domain.TERRAIN in $Players/Human/FlakHoverTank.attack_domains)
	assert($Players/Human/FlakHoverTank.movement_speed > 3.0)
	assert($Players/Human/MobileRepairCrawler.repair_rate > Constants.Match.Repair.HITPOINTS_PER_SECOND)
	$Players/Human/MobileRepairCrawler.global_position = (
		$Players/Human/MirageScoutTank.global_position + Vector3(0.8, 0.0, 0.0)
	)
	$Players/Human/MirageScoutTank.hp -= 4
	var damaged_hp = $Players/Human/MirageScoutTank.hp
	assert(Repairing.is_applicable($Players/Human/MobileRepairCrawler, $Players/Human/MirageScoutTank))
	$Players/Human/MobileRepairCrawler.action = Repairing.new($Players/Human/MirageScoutTank)
	await get_tree().create_timer(0.4).timeout
	assert($Players/Human/MirageScoutTank.hp > damaged_hp, "mobile repair crawler should repair damaged units")
	assert($Players/Human/MobileShieldProjector.hp == $Players/Human/MobileShieldProjector.hp_max)
	$Players/Human/MobileShieldProjector.global_position = (
		$Players/Human/TeslaCrawlerMk2.global_position + Vector3(0.8, 0.0, 0.0)
	)
	await get_tree().create_timer(0.25).timeout
	assert(
		$Players/Human/TeslaCrawlerMk2.support_shielded,
		"mobile shield projector should shield nearby friendly units"
	)
	var shielded_hp_before = $Players/Human/TeslaCrawlerMk2.hp
	$Players/Human/TeslaCrawlerMk2.hp -= 4.0
	assert(
		$Players/Human/TeslaCrawlerMk2.hp > shielded_hp_before - 4.0,
		"mobile shield projector shield should reduce incoming damage"
	)
	assert($Players/Human/LongbowMissileCrawler.hp == $Players/Human/LongbowMissileCrawler.hp_max)
	assert(Constants.Match.Navigation.Domain.AIR in $Players/Human/LongbowMissileCrawler.attack_domains)
	assert(Constants.Match.Navigation.Domain.TERRAIN in $Players/Human/LongbowMissileCrawler.attack_domains)
	assert(
		$Players/Human/LongbowMissileCrawler.attack_range
		> $Players/Human/ModularMissileCarrier.attack_range
	)
	assert(Constants.Match.Units.PROJECTILES.has(LongbowMissileCrawlerUnit.resource_path))
	assert($Players/Human/SiegeDrillTank.hp == $Players/Human/SiegeDrillTank.hp_max)
	assert(
		$Players/Human/SiegeDrillTank.structure_damage_multiplier > 1.0,
		"siege drill tank should deal bonus structure damage"
	)
	assert(
		CombatDamage._get_damage_amount($Players/Human/SiegeDrillTank, $Players/Human/CommandCenter)
		== $Players/Human/SiegeDrillTank.attack_damage
		* $Players/Human/SiegeDrillTank.structure_damage_multiplier,
		"siege drill tank structure damage multiplier should be applied by damage utility"
	)
	assert($Players/Human/LanceBeamTank.hp == $Players/Human/LanceBeamTank.hp_max)
	assert(Constants.Match.Navigation.Domain.AIR in $Players/Human/LanceBeamTank.attack_domains)
	assert(Constants.Match.Navigation.Domain.TERRAIN in $Players/Human/LanceBeamTank.attack_domains)
	assert($Players/Human/RailgunTank.hp == $Players/Human/RailgunTank.hp_max)
	assert($Players/Human/HammerSiegeTank.hp == $Players/Human/HammerSiegeTank.hp_max)
	assert($Players/Human/HammerSiegeTank.hp_max > $Players/Human/SiegeArtilleryVehicle.hp_max)
	assert($Players/Human/HammerSiegeTank.splash_radius > 0.0)
	assert(not Constants.Match.Navigation.Domain.AIR in $Players/Human/HammerSiegeTank.attack_domains)
	assert(Constants.Match.Units.PROJECTILES.has(HammerSiegeTankUnit.resource_path))
	assert($Players/Human/HeavySiegeWalker.hp == $Players/Human/HeavySiegeWalker.hp_max)
	assert($Players/Human/HeavySiegeWalker.hp_max > $Players/Human/RailgunTank.hp_max)
	assert(
		$Players/Human/HeavySiegeWalker.splash_radius
		> $Players/Human/SiegeArtilleryVehicle.splash_radius
	)
	assert(Constants.Match.Units.PROJECTILES.has(HeavySiegeWalkerUnit.resource_path))
	assert($Players/Human/RailArtilleryWalker.hp == $Players/Human/RailArtilleryWalker.hp_max)
	assert(
		$Players/Human/RailArtilleryWalker.attack_range
		> $Players/Human/HeavySiegeWalker.attack_range
	)
	assert(
		$Players/Human/RailArtilleryWalker.splash_radius
		> $Players/Human/HeavySiegeWalker.splash_radius
	)
	assert(Constants.Match.Units.PROJECTILES.has(RailArtilleryWalkerUnit.resource_path))
	var worker_capacity = (
		Constants.Match.Units.DEFAULT_PROPERTIES[WorkerUnit.resource_path]["resources_max"]
	)
	assert($Players/Human/OreHarvester.hp == $Players/Human/OreHarvester.hp_max)
	assert($Players/Human/OreHarvester.resources_max > worker_capacity)
	assert($Players/Human/OreHarvester.attack_damage == null)
	assert($Players/Human/OreHarvester.can_collect_resources())
	assert(not $Players/Human/OreHarvester.can_construct_structures())
	assert(
		CollectingResourcesSequentially.is_applicable(
			$Players/Human/OreHarvester, $Players/Human/CommandCenter
		),
		"ore harvester should use the existing resource drop-off action"
	)
	assert($Players/Human/MobileConstructionVehicle.hp == $Players/Human/MobileConstructionVehicle.hp_max)
	assert(
		$Players/Human/MobileConstructionVehicle.hp_max
		> Constants.Match.Units.DEFAULT_PROPERTIES[WorkerUnit.resource_path]["hp_max"]
	)
	assert($Players/Human/MobileConstructionVehicle.can_construct_structures())
	assert(not $Players/Human/MobileConstructionVehicle.can_collect_resources())
	assert(
		not CollectingResourcesSequentially.is_applicable(
			$Players/Human/MobileConstructionVehicle, $Players/Human/CommandCenter
		),
		"mobile construction vehicle should not use resource drop-off actions"
	)
	_assert_vehicle_menu_uses_future_pack_icon()
	get_tree().quit()


func _spawn_and_check_unit(unit_scene, position):
	var unit = unit_scene.instantiate()
	MatchSignals.setup_and_spawn_unit.emit(unit, Transform3D(Basis(), position), $Players/Human)


func _assert_vehicle_menu_uses_future_pack_icon():
	var unit_menus = $HUD.find_child("UnitMenus", true, false)
	var menu = unit_menus.find_child("VehicleFactoryMenu", true, false)
	for button_name in [
		"ProduceTankButton",
		"ProduceScoutRoverButton",
		"ProduceSiegeArtilleryVehicleButton",
		"ProduceModularMissileCarrierButton",
	]:
		var roster_button = menu.find_child(button_name, true, false)
		assert(roster_button != null, "{0} should be exposed in vehicle menu".format([button_name]))
		var roster_icon = roster_button.find_child("TextureRect").texture
		assert(roster_icon != null, "{0} should have an icon".format([button_name]))
		assert(
			_icon_uses_canonical_or_marker(roster_icon, RA2_INSPIRED_ROSTER_ICON_SET),
			"{0} should use a packaged root icon or generated RA2-inspired roster icon set".format([button_name])
		)
	var button = menu.find_child("ProduceRailArtilleryWalkerButton", true, false)
	assert(button != null, "vehicle factory menu should expose rail artillery walker")
	var icon = button.find_child("TextureRect").texture
	assert(icon != null, "rail artillery walker button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(icon, "rts-future-pack-20260615"),
		"rail artillery walker should use a packaged root icon or generated future-pack icon"
	)
	var hammer_button = menu.find_child("ProduceHammerSiegeTankButton", true, false)
	assert(hammer_button != null, "vehicle factory menu should expose hammer siege tank")
	var hammer_icon = hammer_button.find_child("TextureRect").texture
	assert(hammer_icon != null, "hammer siege tank button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(hammer_icon, "rts-assault-tech-20260615-01"),
		"hammer siege tank should use a packaged root icon or generated assault-tech icon"
	)
	var rocket_robot_button = menu.find_child("ProduceRocketTrooperRobotButton", true, false)
	assert(rocket_robot_button != null, "vehicle factory menu should expose rocket trooper robot")
	var rocket_robot_icon = rocket_robot_button.find_child("TextureRect").texture
	assert(rocket_robot_icon != null, "rocket trooper robot button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(rocket_robot_icon, ROCKET_ROBOT_ICON_SET),
		"rocket trooper robot should use a packaged root icon or generated rocket-robot icon"
	)
	for button_name in [
		"ProduceOreHarvesterButton",
		"ProduceMirageScoutTankButton",
		"ProduceLongbowMissileCrawlerButton",
		"ProduceAntiAirWalkerButton",
	]:
		var menu_polish_button = menu.find_child(button_name, true, false)
		assert(menu_polish_button != null, "{0} should be exposed in vehicle menu".format([button_name]))
		var menu_polish_icon = menu_polish_button.find_child("TextureRect").texture
		assert(menu_polish_icon != null, "{0} should have an icon".format([button_name]))
		assert(
			_icon_uses_canonical_or_marker(menu_polish_icon, MENU_POLISH_ICON_SET),
			"{0} should use a packaged root icon or generated menu-polish icon set".format([button_name])
		)
	var mcv_button = menu.find_child("ProduceMobileConstructionVehicleButton", true, false)
	assert(mcv_button != null, "vehicle factory menu should expose mobile construction vehicle")
	var mcv_icon = mcv_button.find_child("TextureRect").texture
	assert(mcv_icon != null, "mobile construction vehicle button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(mcv_icon, ROSTER_ICON_SET),
		"mobile construction vehicle should use a packaged root icon or generated roster icon"
	)
	assert(
		mcv_button.tooltip_text.contains(tr("MOBILE_CONSTRUCTION_VEHICLE_DESCRIPTION")),
		"mobile construction vehicle tooltip should describe forward base expansion"
	)
	var railgun_button = menu.find_child("ProduceRailgunTankButton", true, false)
	assert(railgun_button != null, "vehicle factory menu should expose railgun tank")
	var railgun_icon = railgun_button.find_child("TextureRect").texture
	assert(railgun_icon != null, "railgun tank button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(railgun_icon, NEW_ASSET_ICON_SET),
		"railgun tank should use a packaged root icon or generated new asset icon"
	)
	var drill_button = menu.find_child("ProduceSiegeDrillTankButton", true, false)
	assert(drill_button != null, "vehicle factory menu should expose siege drill tank")
	var drill_icon = drill_button.find_child("TextureRect").texture
	assert(drill_icon != null, "siege drill tank button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(drill_icon, RA2_INSPIRED_ICON_SET),
		"siege drill tank should use a packaged root icon or generated RA2-inspired icon"
	)
	var tesla_button = menu.find_child("ProduceTeslaCrawlerMk2Button", true, false)
	assert(tesla_button != null, "vehicle factory menu should expose tesla crawler")
	var tesla_icon = tesla_button.find_child("TextureRect").texture
	assert(tesla_icon != null, "tesla crawler button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(tesla_icon, RA2_INSPIRED_ICON_SET),
		"tesla crawler should use a packaged root icon or generated RA2-inspired icon"
	)
	var mine_layer_button = menu.find_child("ProduceDroneMineLayerButton", true, false)
	assert(mine_layer_button != null, "vehicle factory menu should expose drone mine layer")
	var mine_layer_icon = mine_layer_button.find_child("TextureRect").texture
	assert(mine_layer_icon != null, "drone mine layer button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(mine_layer_icon, RA2_INSPIRED_ICON_SET),
		"drone mine layer should use a packaged root icon or generated RA2-inspired icon"
	)
	assert(
		mine_layer_button.tooltip_text.contains(tr("MINE_LIMIT")),
		"drone mine layer tooltip should expose mine capacity"
	)
	var shield_button = menu.find_child("ProduceMobileShieldProjectorButton", true, false)
	assert(shield_button != null, "vehicle factory menu should expose mobile shield projector")
	var shield_icon = shield_button.find_child("TextureRect").texture
	assert(shield_icon != null, "mobile shield projector button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(shield_icon, RA2_INSPIRED_ICON_SET),
		"mobile shield projector should use a packaged root icon or generated RA2-inspired icon"
	)
	assert(
		shield_button.tooltip_text.contains(tr("DAMAGE_TAKEN")),
		"mobile shield projector tooltip should expose shield damage reduction"
	)


func _icon_uses_canonical_or_marker(icon, marker):
	return (
		icon.resource_path.begins_with("res://assets/ui/icons/")
		and not icon.resource_path.contains("/generated/")
	) or marker in icon.resource_path
