extends Node

const CommandCenterMenuScene = preload("res://source/match/hud/unit-menus/CommandCenterMenu.tscn")
const BarracksMenuScene = preload("res://source/match/hud/unit-menus/BarracksMenu.tscn")
const VehicleFactoryMenuScene = preload("res://source/match/hud/unit-menus/VehicleFactoryMenu.tscn")
const AircraftFactoryMenuScene = preload("res://source/match/hud/unit-menus/AircraftFactoryMenu.tscn")
const WorkerMenuScene = preload("res://source/match/hud/unit-menus/WorkerMenu.tscn")
const RtsHudStylerScript = preload("res://source/match/hud/RtsHudStyler.gd")
const CommandButtonIcons = preload("res://source/match/hud/unit-menus/CommandButtonIcons.gd")

const VISIBLE_ICON_NAME = "CommandVisibleIcon"

const SPECIAL_DEFAULT_PROPERTY_SCENES = [
	"res://source/match/units/LandMine.tscn",
	"res://source/match/units/TechOilDerrick.tscn",
	"res://source/match/units/TechAirport.tscn",
	"res://source/match/units/TechHospital.tscn",
	"res://source/match/units/TechRepairDepot.tscn",
	"res://source/match/units/TechBunker.tscn",
]

const COMMAND_CENTER_BUTTONS = [
	"ProduceWorkerButton",
	"ProduceEngineerDroneButton",
]

const BARRACKS_BUTTONS = [
	"ProduceLightRifleInfantryButton",
	"ProduceRocketInfantryButton",
	"ProduceFieldMedicButton",
	"ProduceShieldTrooperButton",
	"ProduceFlakRocketTeamButton",
	"ProduceFlakRocketTeamMk2Button",
	"ProduceHeavyMachinegunTrooperButton",
	"ProduceShockTrooperButton",
	"ProduceGrenadierTrooperButton",
	"ProduceMortarTeamButton",
	"ProduceCryoSprayerButton",
	"ProduceSniperScoutButton",
	"ProduceRailSniperTeamButton",
	"ProducePhaseSaboteurButton",
	"ProduceSaboteurInfiltratorButton",
	"ProducePulseRifleCommandoButton",
	"ProduceTacticalOfficerButton",
]

const VEHICLE_FACTORY_BUTTONS = [
	"ProduceTankButton",
	"ProduceScoutRoverButton",
	"ProduceOreHarvesterButton",
	"ProduceMobileConstructionVehicleButton",
	"ProduceMirageScoutTankButton",
	"ProduceFlameAssaultBuggyButton",
	"ProduceDroneMineLayerButton",
	"ProduceTeslaCrawlerMk2Button",
	"ProduceRocketTrooperRobotButton",
	"ProduceModularMissileCarrierButton",
	"ProduceLongbowMissileCrawlerButton",
	"ProduceJammerVehicleButton",
	"ProduceAntiAirWalkerButton",
	"ProduceFlakHoverTankButton",
	"ProduceMobileRepairCrawlerButton",
	"ProduceMobileShieldProjectorButton",
	"ProduceSiegeArtilleryVehicleButton",
	"ProduceSiegeDrillTankButton",
	"ProduceLanceBeamTankButton",
	"ProduceRailgunTankButton",
	"ProduceHammerSiegeTankButton",
	"ProduceHeavySiegeWalkerButton",
	"ProduceRailArtilleryWalkerButton",
]

const AIRCRAFT_FACTORY_BUTTONS = [
	"ProduceHelicopterButton",
	"ProduceInterceptorVTOLButton",
	"ProduceDroneButton",
	"ProduceBomberVTOLButton",
	"ProduceRocketGunshipButton",
	"ProduceHeavyBombardmentAirshipButton",
	"ProduceSiegeAirshipButton",
]

const WORKER_BUTTONS = [
	"PlaceAntiGroundTurretButton",
	"PlaceAntiAirTurretButton",
	"PlaceTeslaFenceSegmentButton",
	"PlaceArcCoilDefenseTowerButton",
	"PlaceLanceBeamDefenseTowerButton",
	"PlacePrismDefenseObeliskButton",
	"PlaceRailCannonBunkerButton",
	"PlaceRadarUplinkButton",
	"PlaceRoboticsBayButton",
	"PlaceTechLabButton",
	"PlaceWeatherControlSpireButton",
	"PlaceCommandCenterButton",
	"PlaceVehicleFactoryButton",
	"PlaceAircraftFactoryButton",
	"PlacePowerReactorButton",
	"PlaceAdvancedReactorPlantButton",
	"PlaceRefineryButton",
	"PlaceOrePurifierButton",
	"PlaceBarracksButton",
	"PlaceRepairPadButton",
]

const MAPPED_ICON_EXPECTATIONS = {
	"res://source/match/units/Tank.tscn": "imagegen-rts-ra2-inspired-roster-20260616-01/72/05_light_tank.png",
	"res://source/match/units/Worker.tscn": "imagegen-rts-menu-polish-20260616-01/72/ConstructionWorkerDrone.png",
	"res://source/match/units/RocketGunship.tscn": "imagegen-rts-ra2-inspired-20260616-01/72/RocketGunship.png",
	"res://source/match/units/FlakRocketTeamMk2.tscn": "imagegen-rts-late-tech-20260616-01/72/FlakRocketTeamMk2.png",
	"res://source/match/units/RailSniperTeam.tscn": "imagegen-rts-ra2-inspired-20260616-01/72/RailSniperTeam.png",
	"res://source/match/units/SaboteurInfiltrator.tscn": "imagegen-rts-new-assets-20260616-01/72/SaboteurEngineer.png",
	"res://source/match/units/MobileConstructionVehicle.tscn": "imagegen-rts-roster-20260616-02/72/07_mobile_construction_vehicle.png",
	"res://source/match/units/DroneMineLayer.tscn": "imagegen-rts-ra2-inspired-20260616-01/72/DroneMineLayer.png",
	"res://source/match/units/MobileShieldProjector.tscn": "imagegen-rts-ra2-inspired-20260616-01/72/MobileShieldProjector.png",
	"res://source/match/units/HammerSiegeTank.tscn": "rts-assault-tech-20260615-01/72/HammerSiegeTank.png",
	"res://source/match/units/SiegeAirship.tscn": "imagegen-rts-ra2-inspired-20260616-01/72/SiegeAirship.png",
	"res://source/match/units/Barracks.tscn": "imagegen-rts-ra2-inspired-roster-20260616-01/72/09_barracks.png",
	"res://source/match/units/RadarUplink.tscn": "imagegen-rts-ra2-inspired-roster-20260616-01/72/11_radar_tower.png",
	"res://source/match/units/TechLab.tscn": "imagegen-rts-ra2-inspired-roster-20260616-01/72/13_tech_lab.png",
	"res://source/match/units/AdvancedReactorPlant.tscn": "imagegen-rts-new-assets-20260616-01/72/AdvancedReactor.png",
	"res://source/match/units/OrePurifier.tscn": "imagegen-rts-ra2-inspired-20260616-01/72/OrePurifier.png",
	"res://source/match/units/RepairPad.tscn": "imagegen-rts-ra2-inspired-20260616-01/72/RepairPad.png",
	"res://source/match/units/TeslaFenceSegment.tscn": "imagegen-rts-ra2-pack-20260615-01/72/TeslaFenceSegment.png",
	"res://source/match/units/PrismDefenseObelisk.tscn": "imagegen-rts-new-assets-20260616-01/72/PrismDefenseTower.png",
	"res://source/match/units/RailCannonBunker.tscn": "imagegen-rts-late-tech-20260616-01/72/RailCannonBunker.png",
	"res://source/match/units/WeatherControlSpire.tscn": "imagegen-rts-ra2-inspired-20260616-01/72/WeatherControlSpire.png",
}


func _ready():
	_assert_production_registry()
	_assert_construction_registry()
	_assert_requirement_registry()
	_assert_power_registry()
	_assert_default_properties()
	_assert_projectiles()
	await _assert_command_menus()
	_assert_command_button_icon_fallback()
	_assert_command_button_uses_mapped_icons()
	_assert_playable_command_icons_are_packaged_and_visible()
	get_tree().quit()


func _assert_production_registry():
	var production_costs = Constants.Match.Units.PRODUCTION_COSTS
	var production_times = Constants.Match.Units.PRODUCTION_TIMES
	for unit_path in production_costs:
		_assert_scene_loads(unit_path, "production unit")
		_assert_resource_cost(production_costs[unit_path], unit_path)
		assert(production_times.has(unit_path), "{0} should have a production time".format([unit_path]))
		assert(
			Constants.Match.Units.DEFAULT_PROPERTIES.has(unit_path),
			"{0} should have default properties".format([unit_path])
		)
	for unit_path in production_times:
		assert(
			production_costs.has(unit_path),
			"{0} should have production costs if it has a production time".format([unit_path])
		)
		assert(production_times[unit_path] > 0.0, "{0} production time should be positive".format([unit_path]))


func _assert_construction_registry():
	var blueprints = Constants.Match.Units.STRUCTURE_BLUEPRINTS
	var construction_costs = Constants.Match.Units.CONSTRUCTION_COSTS
	var structure_name_keys = Constants.Match.Units.STRUCTURE_NAME_KEYS
	for structure_path in blueprints:
		var blueprint_path = blueprints[structure_path]
		_assert_scene_loads(structure_path, "constructable structure")
		_assert_scene_loads(blueprint_path, "structure blueprint")
		assert(
			construction_costs.has(structure_path),
			"{0} should have construction costs".format([structure_path])
		)
		_assert_resource_cost(construction_costs[structure_path], structure_path)
		assert(
			Constants.Match.Units.DEFAULT_PROPERTIES.has(structure_path),
			"{0} should have default properties".format([structure_path])
		)
		assert(structure_name_keys.has(structure_path), "{0} should have a structure name key".format([structure_path]))
	for structure_path in construction_costs:
		assert(
			blueprints.has(structure_path),
			"{0} should have a blueprint if it has construction costs".format([structure_path])
		)


func _assert_requirement_registry():
	for unit_path in Constants.Match.Units.PRODUCTION_REQUIREMENTS:
		assert(
			Constants.Match.Units.PRODUCTION_COSTS.has(unit_path),
			"{0} has requirements but is not producible".format([unit_path])
		)
		_assert_requirement_paths(Constants.Match.Units.PRODUCTION_REQUIREMENTS[unit_path], unit_path)

	for structure_path in Constants.Match.Units.CONSTRUCTION_REQUIREMENTS:
		assert(
			Constants.Match.Units.STRUCTURE_BLUEPRINTS.has(structure_path),
			"{0} has construction requirements but is not constructable".format([structure_path])
		)
		_assert_requirement_paths(Constants.Match.Units.CONSTRUCTION_REQUIREMENTS[structure_path], structure_path)


func _assert_power_registry():
	for structure_path in Constants.Match.Units.POWER_SUPPLY:
		assert(
			Constants.Match.Units.STRUCTURE_BLUEPRINTS.has(structure_path),
			"{0} supplies power but is not constructable".format([structure_path])
		)
	for structure_path in Constants.Match.Units.POWER_DRAIN:
		assert(
			Constants.Match.Units.STRUCTURE_BLUEPRINTS.has(structure_path),
			"{0} drains power but is not constructable".format([structure_path])
		)

	for power_id in Constants.Match.SupportPowers.DEFINITIONS:
		var definition = Constants.Match.SupportPowers.DEFINITIONS[power_id]
		assert(definition.has("name_key"), "{0} should have a name key".format([power_id]))
		assert(definition.has("description_key"), "{0} should have a description key".format([power_id]))
		assert(definition.has("requirements"), "{0} should have requirements".format([power_id]))
		assert(definition.has("cooldown"), "{0} should have a cooldown".format([power_id]))
		assert(definition["cooldown"] > 0.0, "{0} cooldown should be positive".format([power_id]))
		_assert_requirement_paths(definition["requirements"], power_id, true)


func _assert_default_properties():
	var valid_default_property_scenes = _known_playable_scene_paths()
	for special_path in SPECIAL_DEFAULT_PROPERTY_SCENES:
		valid_default_property_scenes[special_path] = true

	for scene_path in Constants.Match.Units.DEFAULT_PROPERTIES:
		assert(
			valid_default_property_scenes.has(scene_path),
			"{0} has default properties but is not producible, constructable, or special".format([scene_path])
		)
		_assert_scene_loads(scene_path, "default-property scene")
		var properties = Constants.Match.Units.DEFAULT_PROPERTIES[scene_path]
		assert(properties.has("hp"), "{0} should define hp".format([scene_path]))
		assert(properties.has("hp_max"), "{0} should define hp_max".format([scene_path]))
		assert(properties["hp"] > 0, "{0} hp should be positive".format([scene_path]))
		assert(properties["hp_max"] > 0, "{0} hp_max should be positive".format([scene_path]))
		assert(
			properties["hp"] <= properties["hp_max"],
			"{0} hp should not exceed hp_max".format([scene_path])
		)
		if properties.has("attack_damage"):
			assert(properties.has("attack_interval"), "{0} attacker should define attack interval".format([scene_path]))
			assert(properties.has("attack_range"), "{0} attacker should define attack range".format([scene_path]))
			assert(properties.has("attack_domains"), "{0} attacker should define attack domains".format([scene_path]))


func _assert_projectiles():
	var playable_scenes = _known_playable_scene_paths()
	for special_path in SPECIAL_DEFAULT_PROPERTY_SCENES:
		playable_scenes[special_path] = true
	for scene_path in Constants.Match.Units.PROJECTILES:
		assert(playable_scenes.has(scene_path), "{0} has a projectile but is not playable".format([scene_path]))
		assert(
			Constants.Match.Units.DEFAULT_PROPERTIES.has(scene_path),
			"{0} projectile owner should have default properties".format([scene_path])
		)
		assert(
			Constants.Match.Units.DEFAULT_PROPERTIES[scene_path].has("attack_damage"),
			"{0} projectile owner should define attack damage".format([scene_path])
		)
		_assert_scene_loads(Constants.Match.Units.PROJECTILES[scene_path], "projectile")


func _assert_command_menus():
	await _assert_menu_buttons(CommandCenterMenuScene, COMMAND_CENTER_BUTTONS, "command center menu")
	await _assert_menu_buttons(BarracksMenuScene, BARRACKS_BUTTONS, "barracks menu")
	await _assert_menu_buttons(VehicleFactoryMenuScene, VEHICLE_FACTORY_BUTTONS, "vehicle factory menu")
	await _assert_menu_buttons(AircraftFactoryMenuScene, AIRCRAFT_FACTORY_BUTTONS, "aircraft factory menu")
	await _assert_menu_buttons(WorkerMenuScene, WORKER_BUTTONS, "worker menu")
	await get_tree().process_frame


func _assert_menu_buttons(menu_scene, button_names, label):
	var hud_styler = RtsHudStylerScript.new()
	var unit_menus_root = Control.new()
	unit_menus_root.name = "UnitMenus"
	var menu = menu_scene.instantiate()
	add_child(hud_styler)
	hud_styler.add_child(unit_menus_root)
	unit_menus_root.add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	for button_name in button_names:
		var button = menu.find_child(button_name, true, false)
		assert(button != null, "{0} should expose {1}".format([label, button_name]))
		var icon = _source_icon_for_button(button)
		assert(icon != null, "{0} {1} should have an icon node".format([label, button_name]))
		assert(icon.texture != null, "{0} {1} should have an icon texture".format([label, button_name]))
		assert(button.icon == null, "{0} {1} should avoid duplicate Button.icon drawing".format([label, button_name]))
		assert(not button.expand_icon, "{0} {1} should not expand a hidden built-in icon".format([label, button_name]))
		var visible_icon = button.find_child(VISIBLE_ICON_NAME, false, false)
		assert(visible_icon != null, "{0} {1} should have one visible icon layer".format([label, button_name]))
		assert(visible_icon.visible, "{0} {1} visible icon layer should be visible".format([label, button_name]))
		assert(
			visible_icon.texture == icon.texture,
			"{0} {1} visible icon layer should draw the command texture".format([label, button_name])
		)
	hud_styler.queue_free()


func _source_icon_for_button(button):
	for icon in button.find_children("*", "TextureRect", true, false):
		if icon.name != VISIBLE_ICON_NAME:
			return icon
	return null


func _assert_command_button_icon_fallback():
	var button = Button.new()
	add_child(button)
	var unmapped_scene_path = "res://source/match/units/UnmappedPrototype.tscn"
	CommandButtonIcons.apply_for_scene(button, unmapped_scene_path)
	var icon = button.find_child("TextureRect", true, false)
	assert(icon != null, "unmapped command button should still create an icon node")
	assert(icon.texture != null, "unmapped command button should generate a fallback icon texture")
	assert(button.icon == null, "unmapped command button should avoid duplicate Button.icon drawing")
	assert(not button.expand_icon, "unmapped command button should not expand a hidden built-in icon")
	assert(button.get_meta(CommandButtonIcons.META_FALLBACK_ICON, false), "fallback icon meta should be true")
	var fallback_label = button.find_child(CommandButtonIcons.FALLBACK_LABEL_NAME, false, false)
	assert(fallback_label == null or not fallback_label.visible, "fallback command button should not stack a text code over the icon")
	button.queue_free()


func _assert_command_button_uses_mapped_icons():
	for scene_path in MAPPED_ICON_EXPECTATIONS:
		var button = Button.new()
		add_child(button)
		CommandButtonIcons.apply_for_scene(button, scene_path)
		var expected_icon_path = MAPPED_ICON_EXPECTATIONS[scene_path]
		var canonical_icon_path = CommandButtonIcons.canonical_icon_path_for_scene(scene_path)
		var expected_marker = canonical_icon_path if canonical_icon_path != "" else expected_icon_path
		var icon = button.find_child("TextureRect", true, false)
		assert(icon != null, "{0} should create an icon node".format([scene_path]))
		assert(icon.texture != null, "{0} should load its mapped icon texture".format([scene_path]))
		assert(
			expected_marker in icon.texture.resource_path,
			"{0} should prefer packaged root icon when present, then mapped generated icon {1}, got {2}".format(
				[scene_path, expected_marker, icon.texture.resource_path]
			)
		)
		assert(
			button.icon == null and not button.expand_icon,
			"{0} should avoid duplicate Button.icon drawing".format([scene_path])
		)
		assert(
			not button.get_meta(CommandButtonIcons.META_FALLBACK_ICON, true),
			"{0} should not be marked as a generated fallback icon".format([scene_path])
		)
		var code_label = button.find_child(CommandButtonIcons.FALLBACK_LABEL_NAME, false, false)
		assert(
			code_label == null or not code_label.visible,
			"{0} should not stack a center code label over packaged art".format([scene_path])
		)
		_assert_texture_is_visible_on_dark_ui(icon.texture, scene_path)
		button.queue_free()


func _assert_playable_command_icons_are_packaged_and_visible():
	var scene_paths = _known_playable_scene_paths().keys()
	scene_paths.sort()
	for scene_path in scene_paths:
		var button = Button.new()
		add_child(button)
		CommandButtonIcons.apply_for_scene(button, scene_path)
		var icon = button.find_child("TextureRect", true, false)
		assert(icon != null, "{0} should create a command icon node".format([scene_path]))
		assert(icon.texture != null, "{0} should load or generate a command icon".format([scene_path]))
		assert(
			button.icon == null and not button.expand_icon,
			"{0} should avoid duplicate Button.icon drawing".format([scene_path])
		)
		assert(
			not button.get_meta(CommandButtonIcons.META_FALLBACK_ICON, true),
			"{0} should use a packaged command icon instead of the emergency generated fallback".format([scene_path])
		)
		assert(
			icon.texture.resource_path != "",
			"{0} should come from a packaged command icon asset".format([scene_path])
		)
		var code_label = button.find_child(CommandButtonIcons.FALLBACK_LABEL_NAME, false, false)
		assert(
			code_label == null or not code_label.visible,
			"{0} should not stack a center code label over packaged art".format([scene_path])
		)
		_assert_texture_is_visible_on_dark_ui(icon.texture, scene_path)
		button.queue_free()


func _assert_requirement_paths(requirements, owner_label, allow_special = false):
	for structure_path in requirements:
		var is_constructable = Constants.Match.Units.STRUCTURE_BLUEPRINTS.has(structure_path)
		var is_special = allow_special and SPECIAL_DEFAULT_PROPERTY_SCENES.has(structure_path)
		assert(
			is_constructable or is_special,
			"{0} requires {1}, but it is not constructable or a special tech structure".format([owner_label, structure_path])
		)
		if is_constructable:
			assert(
				Constants.Match.Units.CONSTRUCTION_COSTS.has(structure_path),
				"{0} requires {1}, but it has no construction costs".format([owner_label, structure_path])
			)
		assert(
			Constants.Match.Units.STRUCTURE_NAME_KEYS.has(structure_path),
			"{0} requires {1}, but it has no display name key".format([owner_label, structure_path])
		)
		_assert_scene_loads(structure_path, "requirement")


func _assert_scene_loads(scene_path, label):
	assert(ResourceLoader.exists(scene_path), "{0} {1} should exist".format([label, scene_path]))
	assert(load(scene_path) != null, "{0} {1} should load".format([label, scene_path]))


func _assert_resource_cost(cost, label):
	assert(cost.has("resource_a"), "{0} should define resource_a cost".format([label]))
	assert(cost.has("resource_b"), "{0} should define resource_b cost".format([label]))
	assert(cost["resource_a"] >= 0, "{0} resource_a cost should be non-negative".format([label]))
	assert(cost["resource_b"] >= 0, "{0} resource_b cost should be non-negative".format([label]))


func _known_playable_scene_paths():
	var scenes = {}
	for unit_path in Constants.Match.Units.PRODUCTION_COSTS:
		scenes[unit_path] = true
	for structure_path in Constants.Match.Units.STRUCTURE_BLUEPRINTS:
		scenes[structure_path] = true
	return scenes


func _assert_texture_is_visible_on_dark_ui(texture, label):
	assert(texture != null, "{0} should have a texture".format([label]))
	var image = texture.get_image()
	assert(image != null, "{0} should expose image data".format([label]))
	var bright_pixels = 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.05 and max(pixel.r, max(pixel.g, pixel.b)) >= 0.35:
				bright_pixels += 1
	assert(
		bright_pixels >= 180,
		"{0} should have enough bright pixels to read on the dark command UI".format([label])
	)
