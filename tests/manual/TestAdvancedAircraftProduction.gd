extends "res://tests/manual/Match.gd"

const AircraftFactoryMenu = preload("res://source/match/hud/unit-menus/AircraftFactoryMenu.tscn")
const HelicopterUnit = preload("res://source/match/units/Helicopter.tscn")
const DroneUnit = preload("res://source/match/units/Drone.tscn")
const InterceptorVTOLUnit = preload("res://source/match/units/InterceptorVTOL.tscn")
const BomberVTOLUnit = preload("res://source/match/units/BomberVTOL.tscn")
const RocketGunshipUnit = preload("res://source/match/units/RocketGunship.tscn")
const HeavyBombardmentAirshipUnit = preload("res://source/match/units/HeavyBombardmentAirship.tscn")
const SiegeAirshipUnit = preload("res://source/match/units/SiegeAirship.tscn")
const COMMAND_BUTTON_SIZE = Vector2(112, 112)
const RA2_INSPIRED_ICON_SET = "imagegen-rts-ra2-inspired-20260616-01"
const LATE_TECH_ICON_SET = "imagegen-rts-late-tech-20260616-01"
const MENU_POLISH_ICON_SET = "imagegen-rts-menu-polish-20260616-01"
const ROSTER_ICON_SET = "imagegen-rts-roster-20260616-02"

const AIR_ROSTER = [
	HelicopterUnit,
	InterceptorVTOLUnit,
	DroneUnit,
	BomberVTOLUnit,
	RocketGunshipUnit,
	HeavyBombardmentAirshipUnit,
	SiegeAirshipUnit,
]

@onready var _aircraft_factory = $Players/Human/AircraftFactory


func _ready():
	super()
	await get_tree().process_frame
	assert(
		Utils.Match.Unit.Tech.can_construct(
			$Players/Human, "res://source/match/units/AircraftFactory.tscn"
		),
		"workers should be able to construct aircraft factory"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, InterceptorVTOLUnit.resource_path),
		"radar uplink should unlock interceptor VTOL production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, HeavyBombardmentAirshipUnit.resource_path),
		"tech lab should unlock heavy bombardment airship production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, SiegeAirshipUnit.resource_path),
		"tech lab should unlock siege airship production"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, RocketGunshipUnit.resource_path),
		"robotics bay should unlock rocket gunship production"
	)
	for aircraft_scene in AIR_ROSTER:
		_aircraft_factory.production_queue.produce(aircraft_scene, true)

	var queued_elements = _aircraft_factory.production_queue.get_elements()
	assert(queued_elements.size() == AIR_ROSTER.size(), "full aircraft roster should be queued")
	for index in range(AIR_ROSTER.size()):
		assert(
			queued_elements[index].unit_prototype.resource_path == AIR_ROSTER[index].resource_path,
			"aircraft roster should preserve requested production order"
		)

	_assert_aircraft_menu_layout()
	_spawn_and_check_unit(HelicopterUnit, Vector3(16.0, 0.0, 12.0))
	_spawn_and_check_unit(InterceptorVTOLUnit, Vector3(17.0, 0.0, 12.0))
	_spawn_and_check_unit(DroneUnit, Vector3(18.0, 0.0, 12.0))
	_spawn_and_check_unit(BomberVTOLUnit, Vector3(19.0, 0.0, 12.0))
	_spawn_and_check_unit(RocketGunshipUnit, Vector3(20.0, 0.0, 12.0))
	_spawn_and_check_unit(HeavyBombardmentAirshipUnit, Vector3(21.0, 0.0, 12.0))
	_spawn_and_check_unit(SiegeAirshipUnit, Vector3(22.0, 0.0, 12.0))
	await get_tree().process_frame
	assert($Players/Human/Helicopter.hp == $Players/Human/Helicopter.hp_max)
	assert(Constants.Match.Navigation.Domain.AIR in $Players/Human/Helicopter.attack_domains)
	assert(Constants.Match.Navigation.Domain.TERRAIN in $Players/Human/Helicopter.attack_domains)
	assert($Players/Human/Drone.movement_domain == Constants.Match.Navigation.Domain.AIR)
	assert($Players/Human/InterceptorVTOL.hp == $Players/Human/InterceptorVTOL.hp_max)
	assert(Constants.Match.Navigation.Domain.AIR in $Players/Human/InterceptorVTOL.attack_domains)
	assert(not Constants.Match.Navigation.Domain.TERRAIN in $Players/Human/InterceptorVTOL.attack_domains)
	assert($Players/Human/InterceptorVTOL.attack_range > $Players/Human/Helicopter.attack_range)
	assert($Players/Human/BomberVTOL.splash_radius > 0.0)
	assert(Constants.Match.Navigation.Domain.TERRAIN in $Players/Human/BomberVTOL.attack_domains)
	assert($Players/Human/RocketGunship.movement_speed > $Players/Human/BomberVTOL.movement_speed)
	assert(Constants.Match.Navigation.Domain.AIR in $Players/Human/RocketGunship.attack_domains)
	assert(Constants.Match.Navigation.Domain.TERRAIN in $Players/Human/RocketGunship.attack_domains)
	assert($Players/Human/RocketGunship.splash_radius > 0.0)
	assert($Players/Human/HeavyBombardmentAirship.hp > $Players/Human/BomberVTOL.hp)
	assert($Players/Human/HeavyBombardmentAirship.movement_speed < $Players/Human/BomberVTOL.movement_speed)
	assert($Players/Human/HeavyBombardmentAirship.attack_damage > $Players/Human/BomberVTOL.attack_damage)
	assert($Players/Human/HeavyBombardmentAirship.splash_radius > $Players/Human/BomberVTOL.splash_radius)
	assert($Players/Human/SiegeAirship.hp > $Players/Human/HeavyBombardmentAirship.hp)
	assert($Players/Human/SiegeAirship.movement_speed < $Players/Human/HeavyBombardmentAirship.movement_speed)
	assert($Players/Human/SiegeAirship.attack_damage > $Players/Human/HeavyBombardmentAirship.attack_damage)
	assert($Players/Human/SiegeAirship.splash_radius > $Players/Human/HeavyBombardmentAirship.splash_radius)
	assert(
		Constants.Match.Units.PROJECTILES.has(InterceptorVTOLUnit.resource_path),
		"interceptor should have a projectile mapping"
	)
	assert(
		Constants.Match.Units.PROJECTILES.has(HeavyBombardmentAirshipUnit.resource_path),
		"heavy bombardment airship should have a projectile mapping"
	)
	assert(
		Constants.Match.Units.PROJECTILES.has(RocketGunshipUnit.resource_path),
		"rocket gunship should have a projectile mapping"
	)
	assert(
		Constants.Match.Units.PROJECTILES.has(SiegeAirshipUnit.resource_path),
		"siege airship should have a projectile mapping"
	)
	get_tree().quit()


func _assert_aircraft_menu_layout():
	var menu = AircraftFactoryMenu.instantiate()
	add_child(menu)
	assert(menu.find_child("ProduceInterceptorVTOLButton") != null, "aircraft menu should expose interceptor")
	assert(menu.find_child("ProduceRocketGunshipButton") != null, "aircraft menu should expose rocket gunship")
	assert(
		menu.find_child("ProduceHeavyBombardmentAirshipButton") != null,
		"aircraft menu should expose heavy bombardment airship"
	)
	var siege_button = menu.find_child("ProduceSiegeAirshipButton")
	assert(siege_button != null, "aircraft menu should expose siege airship")
	var siege_icon = siege_button.find_child("TextureRect").texture
	assert(siege_icon != null, "siege airship button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(siege_icon, RA2_INSPIRED_ICON_SET),
		"siege airship should use a packaged root icon or generated RA2-inspired icon"
	)
	var helicopter_button = menu.find_child("ProduceHelicopterButton")
	var helicopter_icon = helicopter_button.find_child("TextureRect").texture
	assert(helicopter_icon != null, "helicopter should have an icon")
	assert(
		_icon_uses_canonical_or_marker(helicopter_icon, ROSTER_ICON_SET),
		"helicopter should use a packaged root icon or generated roster icon set"
	)
	for button_name in [
		"ProduceDroneButton",
		"ProduceBomberVTOLButton",
	]:
		var menu_polish_button = menu.find_child(button_name)
		var menu_polish_icon = menu_polish_button.find_child("TextureRect").texture
		assert(menu_polish_icon != null, "{0} should have an icon".format([button_name]))
		assert(
			_icon_uses_canonical_or_marker(menu_polish_icon, MENU_POLISH_ICON_SET),
			"{0} should use a packaged root icon or generated menu-polish icon set".format([button_name])
		)
	for button_name in [
		"ProduceInterceptorVTOLButton",
		"ProduceRocketGunshipButton",
	]:
		var ra2_button = menu.find_child(button_name)
		var ra2_icon = ra2_button.find_child("TextureRect").texture
		assert(ra2_icon != null, "{0} should have an icon".format([button_name]))
		assert(
			_icon_uses_canonical_or_marker(ra2_icon, RA2_INSPIRED_ICON_SET),
			"{0} should use a packaged root icon or generated RA2-inspired icon set".format([button_name])
		)
	var heavy_button = menu.find_child("ProduceHeavyBombardmentAirshipButton")
	var heavy_icon = heavy_button.find_child("TextureRect").texture
	assert(heavy_icon != null, "heavy bombardment airship should have an icon")
	assert(
		_icon_uses_canonical_or_marker(heavy_icon, LATE_TECH_ICON_SET),
		"heavy bombardment airship should use a packaged root icon or latest late-tech icon set"
	)
	for child in menu.get_children():
		assert(not child.name.begins_with("Padding"), "aircraft menu should not reserve padding cells")
		if child is Button:
			assert(child.custom_minimum_size == COMMAND_BUTTON_SIZE, "aircraft buttons should be large")
	menu.queue_free()


func _spawn_and_check_unit(unit_scene, position):
	var unit = unit_scene.instantiate()
	MatchSignals.setup_and_spawn_unit.emit(unit, Transform3D(Basis(), position), $Players/Human)


func _icon_uses_canonical_or_marker(icon, marker):
	return (
		icon.resource_path.begins_with("res://assets/ui/icons/")
		and not icon.resource_path.contains("/generated/")
	) or marker in icon.resource_path
