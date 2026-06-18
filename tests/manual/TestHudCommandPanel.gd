extends Node

const MatchScene = preload("res://source/match/Match.tscn")
const CommandButtonStatus = preload("res://source/match/hud/unit-menus/CommandButtonStatus.gd")
const RtsHudStylerScript = preload("res://source/match/hud/RtsHudStyler.gd")
const UnitMenusScene = preload("res://source/match/hud/UnitMenus.tscn")
const COMMAND_BUTTON_SIZE_MAX = Vector2(128, 128)
const COMMON_WEB_COMMAND_BUTTON_SIZE = Vector2(124, 124)
const SHORT_COMMAND_BUTTON_SIZE = Vector2(96, 96)
const COMMAND_PANEL_COLUMNS = 6
const COMMAND_PANEL_ROWS_MAX = 6
const COMMAND_PANEL_ROWS_MIN = 5
const COMMAND_PANEL_SLOT_COUNT_MAX = COMMAND_PANEL_COLUMNS * COMMAND_PANEL_ROWS_MAX
const COMMAND_PANEL_SIZE_MAX = (
	COMMAND_BUTTON_SIZE_MAX * Vector2(COMMAND_PANEL_COLUMNS, COMMAND_PANEL_ROWS_MAX)
)
const COMMON_WEB_COMMAND_PANEL_SIZE = (
	COMMON_WEB_COMMAND_BUTTON_SIZE * Vector2(COMMAND_PANEL_COLUMNS, COMMAND_PANEL_ROWS_MIN)
)
const SHORT_COMMAND_PANEL_SIZE = (
	SHORT_COMMAND_BUTTON_SIZE * Vector2(COMMAND_PANEL_COLUMNS, COMMAND_PANEL_ROWS_MIN)
)
const COMMON_WEB_VIEWPORT_SIZE = Vector2(1280, 720)
const SHORT_VIEWPORT_SIZE = Vector2(1024, 560)
const HUD_COMMAND_ANCHOR_MIN_WIDTH = 800.0
const HUD_COMMAND_ANCHOR_MIN_HEIGHT = 869.0
const CONSTRUCTION_ICON_SET = "imagegen-rts-construction-icons-20260615-01"
const RA2_PACK_ICON_SET = "imagegen-rts-ra2-pack-20260615-01"
const RA2_INSPIRED_ICON_SET = "imagegen-rts-ra2-inspired-20260616-01"
const RA2_INSPIRED_ROSTER_ICON_SET = "imagegen-rts-ra2-inspired-roster-20260616-01"
const LATE_TECH_ICON_SET = "imagegen-rts-late-tech-20260616-01"
const MENU_POLISH_ICON_SET = "imagegen-rts-menu-polish-20260616-01"
const NEW_ASSET_ICON_SET = "imagegen-rts-new-assets-20260616-01"
const ROCKET_ROBOT_ICON_SET = "imagegen-rts-rocket-robot-20260616-01"
const ROSTER_ICON_SET = "imagegen-rts-roster-20260616-02"
const CORE_COMMAND_ICON_SET = "rts-command-icons-20260616-01"
const QUEUE_LABEL_NAME = "QueueCountLabel"
const COST_LABEL_NAME = "CostLabel"
const TIME_LABEL_NAME = "TimeLabel"
const NAME_LABEL_NAME = "NameLabel"
const STATUS_STRIP_NAME = "CommandStatusStrip"
const ICON_BACKDROP_NAME = "CommandIconBackdrop"
const ICON_OVERLAY_NAME = "CommandIconOverlay"
const MOSAIC_ICON_NAME = "CommandIconMosaic"
const VISIBLE_ICON_NAME = "CommandVisibleIcon"
const SCREEN_ICON_LAYER_NAME = "CommandScreenIconLayer"
const SCREEN_ICON_PREFIX = "CommandScreenIcon_"
const COMMAND_DETAILS_PANEL_NAME = "CommandDetailsPanel"
const COMMAND_DETAILS_TITLE_NAME = "CommandDetailsTitle"
const COMMAND_DETAILS_BODY_NAME = "CommandDetailsBody"


class FakePlayer:
	extends Node

	signal changed

	var resource_a = 12
	var resource_b = 7

	func has_resources(_costs):
		return true

	func get_power_supply(_include_under_construction = false):
		return 14

	func get_power_drain(_include_under_construction = false):
		return 6


class FakeProductionQueue:
	extends RefCounted

	signal element_enqueued(element)
	signal element_removed(element)

	func size():
		return Constants.Match.Units.PRODUCTION_QUEUE_LIMIT

	func get_elements():
		return []


class FakeOpenProductionQueue:
	extends RefCounted

	signal element_enqueued(element)
	signal element_removed(element)

	func size():
		return 0

	func get_elements():
		return []


class FakeProductionStructure:
	extends Node

	var player = null
	var production_queue = null

	func _init(a_player, a_production_queue):
		player = a_player
		production_queue = a_production_queue


func _ready():
	var hud_styler = RtsHudStylerScript.new()
	add_child(hud_styler)
	var unit_menus = UnitMenusScene.instantiate()
	hud_styler.add_child(unit_menus)
	await get_tree().process_frame
	unit_menus.apply_command_panel_layout_for_viewport(Vector2(1920, 1080))
	await get_tree().process_frame

	var background_grid = unit_menus.find_child("BackgroundGrid", true, false)
	assert(background_grid != null, "unit command panel should keep a background slot grid")
	assert(
		background_grid.columns == COMMAND_PANEL_COLUMNS,
		"unit command panel should use the expanded command columns"
	)
	assert(
		background_grid.find_children("*", "Panel", true, false).size()
		== COMMAND_PANEL_SLOT_COUNT_MAX,
		"unit command panel should expose all visible command slots"
	)
	assert(
		_visible_background_slots(background_grid).size() == COMMAND_PANEL_SLOT_COUNT_MAX,
		"desktop command panel should show the full expanded command slot set"
	)
	var viewport = unit_menus.find_child("CommandPanelViewport", true, false)
	assert(viewport != null, "unit command panel should have a fixed viewport")
	assert(
		viewport.custom_minimum_size == COMMAND_PANEL_SIZE_MAX,
		"unit command panel should be large enough for all visible command slots"
	)
	assert(
		unit_menus.get_command_button_size() == COMMAND_BUTTON_SIZE_MAX,
		"1080p command panel should keep full-size command buttons"
	)
	assert(
		unit_menus.get_command_panel_size() == COMMAND_PANEL_SIZE_MAX,
		"1080p command panel should keep the full-size command panel"
	)
	assert(
		unit_menus.find_child("MenuScroll", true, false) is ScrollContainer,
		"unit command panel should scroll when future rosters exceed the visible slots"
	)
	_assert_controls_minimum_size(
		background_grid.find_children("*", "Panel", true, false), "command background slot"
	)
	_assert_controls_minimum_size(
		unit_menus.find_children("*", "Button", true, false), "command button"
	)
	_assert_command_menus_use_six_columns(unit_menus)
	_assert_command_menus_pack_primary_buttons_from_top_left(unit_menus)
	_assert_icon_buttons_do_not_use_text(unit_menus)
	_assert_all_command_buttons_have_loaded_icons(unit_menus)
	_assert_generic_menu_uses_core_command_icons(unit_menus)
	_assert_worker_construction_icons_use_generated_set(unit_menus)
	_assert_worker_core_roster_icons_use_generated_set(unit_menus)
	_assert_command_center_roster_icons_use_generated_set(unit_menus)
	_assert_aircraft_roster_icons_use_generated_set(unit_menus)
	_assert_menu_polish_icons_use_generated_set(unit_menus)
	_assert_rocket_robot_icon_uses_generated_set(unit_menus)
	_assert_new_asset_icons_use_generated_set(unit_menus)
	_assert_ra2_inspired_icons_use_generated_set(unit_menus)
	_assert_ra2_inspired_roster_icons_use_generated_set(unit_menus)
	_assert_command_icons_are_visible_on_dark_ui(unit_menus)
	_assert_worker_repair_pad_uses_defense_support_icon(unit_menus)
	_assert_worker_advanced_reactor_uses_defense_support_icon(unit_menus)
	_assert_worker_tesla_fence_uses_defense_support_icon(unit_menus)
	_assert_worker_prism_obelisk_uses_defense_support_icon(unit_menus)
	_assert_vehicle_shield_projector_uses_defense_support_icon(unit_menus)
	_assert_late_tech_icons_use_generated_set(unit_menus)
	_assert_production_queue_full_tooltip(unit_menus)
	_assert_production_role_tooltips(unit_menus)
	_assert_command_hover_details_panel(unit_menus)
	await _assert_command_buttons_have_visible_surface_names(unit_menus)
	await _assert_disabled_command_icons_remain_visible(unit_menus)
	_assert_match_hud_allocates_expanded_command_panel()
	_assert_match_hud_embeds_styled_unit_menus()
	await _assert_command_panel_keeps_full_size_for_common_web_viewport(unit_menus)
	await _assert_command_panel_keeps_full_size_for_short_viewport(unit_menus)
	get_tree().quit()


func _assert_controls_minimum_size(controls, label):
	for control in controls:
		assert(
			control.custom_minimum_size.x >= COMMAND_BUTTON_SIZE_MAX.x
			and control.custom_minimum_size.y >= COMMAND_BUTTON_SIZE_MAX.y,
			"{0} {1} should be at least {2}x{3}".format(
				[label, control.name, COMMAND_BUTTON_SIZE_MAX.x, COMMAND_BUTTON_SIZE_MAX.y]
			)
		)


func _assert_icon_buttons_do_not_use_text(root):
	for button in root.find_children("*", "Button", true, false):
		if button.find_child("TextureRect") == null:
			continue
		assert(button.text == "", "{0} should use its icon instead of overlay text".format([button.name]))


func _assert_all_command_buttons_have_loaded_icons(unit_menus):
	for menu_name in [
		"GenericMenu",
		"CommandCenterMenu",
		"VehicleFactoryMenu",
		"AircraftFactoryMenu",
		"BarracksMenu",
		"WorkerMenu",
	]:
		var menu = unit_menus.find_child(menu_name, true, false)
		for button in menu.find_children("*", "Button", true, false):
			var icon = button.find_child("TextureRect", true, false)
			assert(icon != null, "{0}/{1} should include a command icon node".format([menu_name, button.name]))
			assert(
				icon.texture != null,
				"{0}/{1} should load a real command icon texture".format([menu_name, button.name])
			)
			assert(
				icon.texture.resource_path != "",
				"{0}/{1} command icon should come from a packaged asset".format([menu_name, button.name])
			)


func _assert_command_menus_use_six_columns(unit_menus):
	for menu_name in [
		"GenericMenu",
		"CommandCenterMenu",
		"VehicleFactoryMenu",
		"AircraftFactoryMenu",
		"BarracksMenu",
		"WorkerMenu",
	]:
		var menu = unit_menus.find_child(menu_name, true, false)
		assert(
			menu.columns == COMMAND_PANEL_COLUMNS,
			"{0} should use the expanded command layout".format([menu_name])
		)


func _assert_command_menus_pack_primary_buttons_from_top_left(unit_menus):
	var expected_primary_buttons = {
		"CommandCenterMenu": [
			"ProduceWorkerButton",
			"ProduceEngineerDroneButton",
			"SellStructureButton",
			"SetRallyPointButton",
			"RepairStructureButton",
		],
		"GenericMenu": [
			"HoldPositionButton",
			"AttackMoveButton",
			"PatrolButton",
			"SellStructureButton",
			"DeployModeButton",
			"RepairStructureButton",
			"CancelActionButton",
			"GuardAreaButton",
			"ScatterButton",
		],
	}
	for menu_name in expected_primary_buttons:
		var menu = unit_menus.find_child(menu_name, true, false)
		var expected_buttons = expected_primary_buttons[menu_name]
		var children = menu.get_children()
		for index in range(expected_buttons.size()):
			assert(
				children[index] is Button,
				"{0} slot {1} should contain a command button instead of empty padding".format(
					[menu_name, index + 1]
				)
			)
			assert(
				children[index].name == expected_buttons[index],
				"{0} slot {1} should show {2} from the top-left compact layout".format(
					[menu_name, index + 1, expected_buttons[index]]
				)
			)


func _assert_generic_menu_uses_core_command_icons(unit_menus):
	var generic_menu = unit_menus.find_child("GenericMenu", true, false)
	_assert_button_icon_uses_set(generic_menu, "AttackMoveButton", CORE_COMMAND_ICON_SET)
	_assert_button_icon_uses_file(generic_menu, "AttackMoveButton", "13_attack_command.png")
	_assert_button_icon_uses_set(generic_menu, "PatrolButton", CORE_COMMAND_ICON_SET)
	_assert_button_icon_uses_file(generic_menu, "PatrolButton", "14_patrol_command.png")
	_assert_button_icon_uses_set(generic_menu, "GuardAreaButton", CORE_COMMAND_ICON_SET)
	_assert_button_icon_uses_file(generic_menu, "GuardAreaButton", "14_patrol_command.png")
	_assert_button_icon_uses_set(generic_menu, "ScatterButton", CORE_COMMAND_ICON_SET)
	_assert_button_icon_uses_file(generic_menu, "ScatterButton", "12_move_command.png")


func _assert_worker_construction_icons_use_generated_set(unit_menus):
	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	var generated_buttons = [
		"PlaceArcCoilDefenseTowerButton",
		"PlaceLanceBeamDefenseTowerButton",
		"PlaceCommandCenterButton",
		"PlaceAircraftFactoryButton",
	]
	for button_name in generated_buttons:
		var button = worker_menu.find_child(button_name)
		var icon = button.find_child("TextureRect").texture
		assert(icon != null, "{0} should load a construction icon".format([button_name]))
		assert(
			_is_canonical_icon_path(icon.resource_path) or CONSTRUCTION_ICON_SET in icon.resource_path,
			"{0} should use a canonical icon or the generated construction icon set".format(
				[button_name]
			)
		)


func _assert_worker_core_roster_icons_use_generated_set(unit_menus):
	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	for button_name in [
		"PlaceAntiGroundTurretButton",
		"PlaceVehicleFactoryButton",
		"PlacePowerReactorButton",
		"PlaceRefineryButton",
		"PlaceBarracksButton",
	]:
		_assert_button_icon_uses_set(worker_menu, button_name, RA2_INSPIRED_ROSTER_ICON_SET)
	for button_name in [
		"PlaceAntiAirTurretButton",
		"DeployMobileConstructionVehicleButton",
	]:
		_assert_button_icon_uses_set(worker_menu, button_name, ROSTER_ICON_SET)


func _assert_command_center_roster_icons_use_generated_set(unit_menus):
	var command_center_menu = unit_menus.find_child("CommandCenterMenu", true, false)
	_assert_button_icon_uses_set(
		command_center_menu, "ProduceEngineerDroneButton", RA2_INSPIRED_ROSTER_ICON_SET
	)


func _assert_aircraft_roster_icons_use_generated_set(unit_menus):
	var aircraft_menu = unit_menus.find_child("AircraftFactoryMenu", true, false)
	_assert_button_icon_uses_set(aircraft_menu, "ProduceHelicopterButton", ROSTER_ICON_SET)


func _assert_menu_polish_icons_use_generated_set(unit_menus):
	var command_center_menu = unit_menus.find_child("CommandCenterMenu", true, false)
	_assert_button_icon_uses_set(command_center_menu, "ProduceWorkerButton", MENU_POLISH_ICON_SET)
	_assert_button_icon_uses_file(
		command_center_menu, "ProduceWorkerButton", "ConstructionWorkerDrone.png"
	)

	var barracks_menu = unit_menus.find_child("BarracksMenu", true, false)
	var barracks_buttons = {
		"ProduceHeavyMachinegunTrooperButton": "HeavyMachinegunTrooper.png",
		"ProduceGrenadierTrooperButton": "GrenadierTrooper.png",
		"ProduceMortarTeamButton": "MortarTeam.png",
		"ProduceCryoSprayerButton": "CryoSprayer.png",
	}
	for button_name in barracks_buttons:
		_assert_button_icon_uses_set(barracks_menu, button_name, MENU_POLISH_ICON_SET)
		_assert_button_icon_uses_file(barracks_menu, button_name, barracks_buttons[button_name])

	var vehicle_menu = unit_menus.find_child("VehicleFactoryMenu", true, false)
	var vehicle_buttons = {
		"ProduceOreHarvesterButton": "OreHarvester.png",
		"ProduceMirageScoutTankButton": "MirageScoutTank.png",
		"ProduceLongbowMissileCrawlerButton": "LongbowMissileCrawler.png",
		"ProduceAntiAirWalkerButton": "AntiAirWalker.png",
	}
	for button_name in vehicle_buttons:
		_assert_button_icon_uses_set(vehicle_menu, button_name, MENU_POLISH_ICON_SET)
		_assert_button_icon_uses_file(vehicle_menu, button_name, vehicle_buttons[button_name])

	var aircraft_menu = unit_menus.find_child("AircraftFactoryMenu", true, false)
	var aircraft_buttons = {
		"ProduceDroneButton": "ScoutDrone.png",
		"ProduceBomberVTOLButton": "BomberVTOL.png",
	}
	for button_name in aircraft_buttons:
		_assert_button_icon_uses_set(aircraft_menu, button_name, MENU_POLISH_ICON_SET)
		_assert_button_icon_uses_file(aircraft_menu, button_name, aircraft_buttons[button_name])


func _assert_rocket_robot_icon_uses_generated_set(unit_menus):
	var vehicle_menu = unit_menus.find_child("VehicleFactoryMenu", true, false)
	_assert_button_icon_uses_set(vehicle_menu, "ProduceRocketTrooperRobotButton", ROCKET_ROBOT_ICON_SET)
	_assert_button_icon_uses_file(
		vehicle_menu, "ProduceRocketTrooperRobotButton", "RocketTrooperRobot.png"
	)


func _assert_new_asset_icons_use_generated_set(unit_menus):
	var barracks_menu = unit_menus.find_child("BarracksMenu", true, false)
	_assert_button_icon_uses_set(barracks_menu, "ProduceRocketInfantryButton", NEW_ASSET_ICON_SET)
	_assert_button_icon_uses_file(barracks_menu, "ProduceRocketInfantryButton", "RocketInfantry.png")
	_assert_button_icon_uses_set(
		barracks_menu, "ProduceSaboteurInfiltratorButton", NEW_ASSET_ICON_SET
	)
	_assert_button_icon_uses_file(
		barracks_menu, "ProduceSaboteurInfiltratorButton", "SaboteurEngineer.png"
	)

	var vehicle_menu = unit_menus.find_child("VehicleFactoryMenu", true, false)
	_assert_button_icon_uses_set(vehicle_menu, "ProduceRailgunTankButton", NEW_ASSET_ICON_SET)
	_assert_button_icon_uses_file(vehicle_menu, "ProduceRailgunTankButton", "RailgunTank.png")

	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	_assert_button_icon_uses_set(worker_menu, "PlaceAdvancedReactorPlantButton", NEW_ASSET_ICON_SET)
	_assert_button_icon_uses_file(worker_menu, "PlaceAdvancedReactorPlantButton", "AdvancedReactor.png")
	_assert_button_icon_uses_set(worker_menu, "PlacePrismDefenseObeliskButton", NEW_ASSET_ICON_SET)
	_assert_button_icon_uses_file(worker_menu, "PlacePrismDefenseObeliskButton", "PrismDefenseTower.png")


func _assert_ra2_inspired_icons_use_generated_set(unit_menus):
	var barracks_menu = unit_menus.find_child("BarracksMenu", true, false)
	for button_name in [
		"ProduceLightRifleInfantryButton",
		"ProduceFieldMedicButton",
	]:
		_assert_button_icon_uses_set(barracks_menu, button_name, RA2_INSPIRED_ROSTER_ICON_SET)
	for button_name in [
		"ProduceFlakRocketTeamButton",
		"ProduceShieldTrooperButton",
		"ProduceRailSniperTeamButton",
	]:
		_assert_button_icon_uses_set(barracks_menu, button_name, RA2_INSPIRED_ICON_SET)

	var vehicle_menu = unit_menus.find_child("VehicleFactoryMenu", true, false)
	for button_name in [
		"ProduceTankButton",
		"ProduceScoutRoverButton",
		"ProduceModularMissileCarrierButton",
		"ProduceSiegeArtilleryVehicleButton",
	]:
		_assert_button_icon_uses_set(vehicle_menu, button_name, RA2_INSPIRED_ROSTER_ICON_SET)
	for button_name in [
		"ProduceTeslaCrawlerMk2Button",
		"ProduceDroneMineLayerButton",
		"ProduceMobileShieldProjectorButton",
		"ProduceSiegeDrillTankButton",
	]:
		_assert_button_icon_uses_set(vehicle_menu, button_name, RA2_INSPIRED_ICON_SET)

	var aircraft_menu = unit_menus.find_child("AircraftFactoryMenu", true, false)
	for button_name in [
		"ProduceInterceptorVTOLButton",
		"ProduceRocketGunshipButton",
		"ProduceSiegeAirshipButton",
	]:
		_assert_button_icon_uses_set(aircraft_menu, button_name, RA2_INSPIRED_ICON_SET)

	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	for button_name in [
		"PlaceRepairPadButton",
		"PlaceOrePurifierButton",
		"PlaceWeatherControlSpireButton",
	]:
		_assert_button_icon_uses_set(worker_menu, button_name, RA2_INSPIRED_ICON_SET)


func _assert_ra2_inspired_roster_icons_use_generated_set(unit_menus):
	var command_center_menu = unit_menus.find_child("CommandCenterMenu", true, false)
	_assert_button_icon_uses_set(
		command_center_menu, "ProduceEngineerDroneButton", RA2_INSPIRED_ROSTER_ICON_SET
	)
	_assert_button_icon_uses_file(
		command_center_menu, "ProduceEngineerDroneButton", "02_combat_engineer.png"
	)

	var barracks_menu = unit_menus.find_child("BarracksMenu", true, false)
	var barracks_buttons = {
		"ProduceLightRifleInfantryButton": "00_rifle_infantry.png",
		"ProduceFieldMedicButton": "03_field_medic_drone.png",
	}
	for button_name in barracks_buttons:
		_assert_button_icon_uses_set(barracks_menu, button_name, RA2_INSPIRED_ROSTER_ICON_SET)
		_assert_button_icon_uses_file(barracks_menu, button_name, barracks_buttons[button_name])

	var vehicle_menu = unit_menus.find_child("VehicleFactoryMenu", true, false)
	var vehicle_buttons = {
		"ProduceTankButton": "05_light_tank.png",
		"ProduceScoutRoverButton": "04_scout_bike.png",
		"ProduceModularMissileCarrierButton": "06_missile_truck.png",
		"ProduceSiegeArtilleryVehicleButton": "07_self_propelled_artillery.png",
	}
	for button_name in vehicle_buttons:
		_assert_button_icon_uses_set(vehicle_menu, button_name, RA2_INSPIRED_ROSTER_ICON_SET)
		_assert_button_icon_uses_file(vehicle_menu, button_name, vehicle_buttons[button_name])

	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	var worker_buttons = {
		"PlaceAntiGroundTurretButton": "14_defense_turret.png",
		"PlaceVehicleFactoryButton": "10_vehicle_factory.png",
		"PlaceRadarUplinkButton": "11_radar_tower.png",
		"PlaceTechLabButton": "13_tech_lab.png",
		"PlacePowerReactorButton": "08_power_plant.png",
		"PlaceRefineryButton": "12_ore_refinery.png",
		"PlaceBarracksButton": "09_barracks.png",
	}
	for button_name in worker_buttons:
		_assert_button_icon_uses_set(worker_menu, button_name, RA2_INSPIRED_ROSTER_ICON_SET)
		_assert_button_icon_uses_file(worker_menu, button_name, worker_buttons[button_name])


func _assert_button_icon_uses_set(menu, button_name, icon_set):
	var button = menu.find_child(button_name)
	assert(button != null, "{0} should be present in {1}".format([button_name, menu.name]))
	var icon = button.find_child("TextureRect").texture
	assert(icon != null, "{0} should load a command icon".format([button_name]))
	assert(
		_is_canonical_icon_path(icon.resource_path) or icon_set in icon.resource_path,
		"{0} should use a canonical icon or icon set {1}".format([button_name, icon_set])
	)


func _assert_button_icon_uses_file(menu, button_name, file_name):
	var button = menu.find_child(button_name)
	assert(button != null, "{0} should be present in {1}".format([button_name, menu.name]))
	var icon = button.find_child("TextureRect").texture
	assert(icon != null, "{0} should load a command icon".format([button_name]))
	assert(
		_is_canonical_icon_path(icon.resource_path) or file_name in icon.resource_path,
		"{0} should use a canonical icon or icon file {1}".format([button_name, file_name])
	)


func _is_canonical_icon_path(icon_path):
	return icon_path.begins_with("res://assets/ui/icons/") and not icon_path.contains("/generated/")


func _assert_command_icons_are_visible_on_dark_ui(unit_menus):
	for button in unit_menus.find_children("*", "Button", true, false):
		var icon = button.find_child("TextureRect", true, false)
		if icon == null:
			continue
		assert(icon.texture != null, "{0} should keep a loaded command icon texture".format([button.name]))
		assert(button.icon == null, "{0} should avoid duplicate Button.icon drawing".format([button.name]))
		assert(not button.expand_icon, "{0} should not expand a hidden built-in icon".format([button.name]))
		assert(not icon.visible, "{0} source icon control should stay hidden".format([button.name]))
		assert(icon.material == null, "{0} icon should avoid Web-fragile shader materials".format([button.name]))
		var visible_icon = button.find_child(VISIBLE_ICON_NAME, false, false)
		assert(visible_icon != null, "{0} should include one dedicated visible icon layer".format([button.name]))
		assert(visible_icon.visible, "{0} visible icon layer should be visible".format([button.name]))
		assert(
			visible_icon.texture == icon.texture,
			"{0} visible icon layer should draw the command texture".format([button.name])
		)
		assert(visible_icon.z_index > 0, "{0} visible icon should draw above the button background".format([button.name]))
		assert(visible_icon.material == null, "{0} visible icon should avoid Web-fragile shader materials".format([button.name]))
		assert(
			visible_icon.size.x >= 48.0 and visible_icon.size.y >= 48.0,
			"{0} visible icon layer should keep a readable on-screen size".format([button.name])
		)
		var backdrop = button.find_child(ICON_BACKDROP_NAME, false, false)
		assert(backdrop != null, "{0} should include a command icon backdrop".format([button.name]))
		assert(backdrop.visible, "{0} command icon backdrop should be visible".format([button.name]))
		assert(
			backdrop.z_index < visible_icon.z_index,
			"{0} command icon should draw above its backdrop".format([button.name])
		)
		var overlay = button.find_child(ICON_OVERLAY_NAME, false, false)
		assert(overlay == null or not overlay.visible, "{0} direct overlay should stay hidden".format([button.name]))
		var mosaic = button.find_child(MOSAIC_ICON_NAME, false, false)
		assert(mosaic == null or not mosaic.visible, "{0} mosaic fallback should stay hidden".format([button.name]))
		_assert_no_screen_overlay_for_visible_button(unit_menus, button)
		_assert_texture_is_visible_on_dark_ui(visible_icon.texture, button.name)


func _assert_no_screen_overlay_for_visible_button(unit_menus, button):
	if not button.is_visible_in_tree():
		return
	var screen_overlay = _screen_overlay_for_button(unit_menus, button)
	assert(
		screen_overlay == null or not screen_overlay.visible,
		"{0} HUD-level screen icon should stay hidden".format([button.name])
	)


func _assert_texture_is_visible_on_dark_ui(texture, label):
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
		"{0} icon should have enough bright pixels to read on the dark command UI".format([label])
	)


func _assert_worker_repair_pad_uses_defense_support_icon(unit_menus):
	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	var button = worker_menu.find_child("PlaceRepairPadButton")
	assert(button != null, "worker menu should expose repair pad construction")
	var icon = button.find_child("TextureRect").texture
	assert(icon != null, "repair pad should load a generated icon")
	assert(
		_is_canonical_icon_path(icon.resource_path) or RA2_INSPIRED_ICON_SET in icon.resource_path,
		"repair pad should use a canonical icon or the generated defense-support icon set"
	)


func _assert_worker_advanced_reactor_uses_defense_support_icon(unit_menus):
	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	var button = worker_menu.find_child("PlaceAdvancedReactorPlantButton")
	assert(button != null, "worker menu should expose advanced reactor construction")
	var icon = button.find_child("TextureRect").texture
	assert(icon != null, "advanced reactor should load a generated icon")
	assert(
		_is_canonical_icon_path(icon.resource_path) or NEW_ASSET_ICON_SET in icon.resource_path,
		"advanced reactor should use a canonical icon or the generated new asset icon set"
	)


func _assert_worker_tesla_fence_uses_defense_support_icon(unit_menus):
	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	var button = worker_menu.find_child("PlaceTeslaFenceSegmentButton")
	assert(button != null, "worker menu should expose tesla fence construction")
	var icon = button.find_child("TextureRect").texture
	assert(icon != null, "tesla fence should load a generated icon")
	assert(
		_is_canonical_icon_path(icon.resource_path) or RA2_PACK_ICON_SET in icon.resource_path,
		"tesla fence should use a canonical icon or the generated defense-support icon set"
	)


func _assert_worker_prism_obelisk_uses_defense_support_icon(unit_menus):
	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	var button = worker_menu.find_child("PlacePrismDefenseObeliskButton")
	assert(button != null, "worker menu should expose prism defense obelisk construction")
	var icon = button.find_child("TextureRect").texture
	assert(icon != null, "prism defense obelisk should load a generated icon")
	assert(
		_is_canonical_icon_path(icon.resource_path) or NEW_ASSET_ICON_SET in icon.resource_path,
		"prism defense obelisk should use a canonical icon or the generated new asset icon set"
	)


func _assert_vehicle_shield_projector_uses_defense_support_icon(unit_menus):
	var vehicle_menu = unit_menus.find_child("VehicleFactoryMenu", true, false)
	var button = vehicle_menu.find_child("ProduceMobileShieldProjectorButton")
	assert(button != null, "vehicle menu should expose mobile shield projector")
	var icon = button.find_child("TextureRect").texture
	assert(icon != null, "mobile shield projector should load a generated icon")
	assert(
		_is_canonical_icon_path(icon.resource_path) or RA2_INSPIRED_ICON_SET in icon.resource_path,
		"mobile shield projector should use a canonical icon or the generated defense-support icon set"
	)


func _assert_late_tech_icons_use_generated_set(unit_menus):
	var barracks_menu = unit_menus.find_child("BarracksMenu", true, false)
	for button_name in [
		"ProduceFlakRocketTeamMk2Button",
		"ProduceShockTrooperButton",
		"ProducePhaseSaboteurButton",
	]:
		_assert_button_icon_uses_set(barracks_menu, button_name, LATE_TECH_ICON_SET)

	var vehicle_menu = unit_menus.find_child("VehicleFactoryMenu", true, false)
	for button_name in [
		"ProduceJammerVehicleButton",
		"ProduceLanceBeamTankButton",
		"ProduceHeavySiegeWalkerButton",
	]:
		_assert_button_icon_uses_set(vehicle_menu, button_name, LATE_TECH_ICON_SET)

	var aircraft_menu = unit_menus.find_child("AircraftFactoryMenu", true, false)
	for button_name in [
		"ProduceHeavyBombardmentAirshipButton",
	]:
		_assert_button_icon_uses_set(aircraft_menu, button_name, LATE_TECH_ICON_SET)

	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	for button_name in [
		"PlaceRailCannonBunkerButton",
	]:
		_assert_button_icon_uses_set(worker_menu, button_name, LATE_TECH_ICON_SET)


func _assert_production_queue_full_tooltip(unit_menus):
	var fake_player = FakePlayer.new()
	var fake_unit = FakeProductionStructure.new(fake_player, FakeProductionQueue.new())
	add_child(fake_player)
	add_child(fake_unit)

	var command_center_menu = unit_menus.find_child("CommandCenterMenu", true, false)
	command_center_menu.unit = fake_unit
	command_center_menu.refresh()

	var button = command_center_menu.find_child("ProduceWorkerButton")
	assert(button.disabled, "production button should be disabled when the queue is full")
	assert(
		button.tooltip_text.contains(tr("PRODUCTION_QUEUE_FULL")),
		"full production queues should explain why production buttons are disabled"
	)
	var cost_label = button.find_child(COST_LABEL_NAME, true, false)
	assert(cost_label != null and cost_label.text == "A 2", "production buttons should show cost")
	var time_label = button.find_child(TIME_LABEL_NAME, true, false)
	assert(
		time_label != null and time_label.visible and time_label.text == "3s",
		"production buttons should show production time"
	)
	var queue_label = button.find_child(QUEUE_LABEL_NAME, true, false)
	assert(
		queue_label != null and queue_label.text == tr("PRODUCTION_QUEUE_FULL_SHORT"),
		"full queue button should show translated full badge"
	)

	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	var barracks_button = worker_menu.find_child("PlaceBarracksButton")
	var construction_time_label = barracks_button.find_child(TIME_LABEL_NAME, true, false)
	assert(
		construction_time_label == null or not construction_time_label.visible,
		"construction buttons should not show invented build time"
	)

	remove_child(fake_unit)
	fake_unit.queue_free()
	remove_child(fake_player)
	fake_player.queue_free()


func _assert_production_role_tooltips(unit_menus):
	var fake_player = FakePlayer.new()
	var fake_unit = FakeProductionStructure.new(fake_player, FakeOpenProductionQueue.new())
	add_child(fake_player)
	add_child(fake_unit)

	var command_center_menu = unit_menus.find_child("CommandCenterMenu", true, false)
	command_center_menu.unit = fake_unit
	command_center_menu.refresh()
	_assert_tooltip_has_role_and_use(
		command_center_menu.find_child("ProduceWorkerButton"),
		tr("ROLE_ECONOMY"),
		tr("TACTIC_ECONOMY")
	)

	var barracks_menu = unit_menus.find_child("BarracksMenu", true, false)
	barracks_menu.unit = fake_unit
	barracks_menu.refresh()
	_assert_tooltip_has_role_and_use(
		barracks_menu.find_child("ProduceLightRifleInfantryButton"),
		tr("ROLE_INFANTRY"),
		tr("TACTIC_LINE_COMBAT")
	)

	var vehicle_menu = unit_menus.find_child("VehicleFactoryMenu", true, false)
	vehicle_menu.unit = fake_unit
	vehicle_menu.refresh()
	_assert_tooltip_has_role_and_use(
		vehicle_menu.find_child("ProduceTankButton"),
		tr("ROLE_ANTI_GROUND"),
		tr("TACTIC_LINE_COMBAT")
	)
	_assert_tooltip_has_role_and_use(
		vehicle_menu.find_child("ProduceMobileShieldProjectorButton"),
		tr("ROLE_SHIELD_SUPPORT"),
		tr("TACTIC_SHIELD_SUPPORT")
	)

	var aircraft_menu = unit_menus.find_child("AircraftFactoryMenu", true, false)
	aircraft_menu.unit = fake_unit
	aircraft_menu.refresh()
	_assert_tooltip_has_role_and_use(
		aircraft_menu.find_child("ProduceHelicopterButton"),
		tr("ROLE_AIR"),
		tr("TACTIC_FLEX_COMBAT")
	)

	remove_child(fake_unit)
	fake_unit.queue_free()
	remove_child(fake_player)
	fake_player.queue_free()


func _assert_tooltip_has_role_and_use(button, role_text, use_text):
	assert(button != null, "production button should exist for role tooltip coverage")
	assert(
		button.tooltip_text.contains(tr("PRODUCTION_ROLES")),
		"production tooltips should expose role labels"
	)
	assert(
		button.tooltip_text.contains(tr("PRODUCTION_USE")),
		"production tooltips should expose tactical use guidance"
	)
	assert(
		button.tooltip_text.contains(role_text),
		"production tooltip should include role {0}".format([role_text])
	)
	assert(
		button.tooltip_text.contains(use_text),
		"production tooltip should include tactical use {0}".format([use_text])
	)


func _assert_command_hover_details_panel(unit_menus):
	var details_panel = unit_menus.find_child(COMMAND_DETAILS_PANEL_NAME, true, false)
	assert(details_panel != null, "command panel should expose a hover details panel")
	assert(not details_panel.visible, "command details panel should stay hidden until a button is hovered")
	assert(
		details_panel.position.y < 0.0,
		"command details panel should sit above the command grid without covering command cells"
	)
	assert(
		details_panel.size.x == unit_menus.get_command_panel_size().x,
		"command details panel should match command grid width"
	)

	var fake_player = FakePlayer.new()
	var fake_unit = FakeProductionStructure.new(fake_player, FakeOpenProductionQueue.new())
	add_child(fake_player)
	add_child(fake_unit)

	var command_center_menu = unit_menus.find_child("CommandCenterMenu", true, false)
	command_center_menu.unit = fake_unit
	command_center_menu.refresh()
	unit_menus._track_player_resources(fake_player)
	unit_menus._track_production_queues([fake_unit.production_queue])
	unit_menus._show_menu(command_center_menu)

	var title = details_panel.find_child(COMMAND_DETAILS_TITLE_NAME, true, false)
	var body = details_panel.find_child(COMMAND_DETAILS_BODY_NAME, true, false)
	assert(title != null, "command details panel should include a title label")
	assert(body != null, "command details panel should include a body label")
	assert(
		not details_panel.visible,
		"showing a command menu should not leave a floating empty details panel on the battlefield"
	)

	var empty_button = Button.new()
	add_child(empty_button)
	unit_menus._show_command_details(empty_button)
	assert(not details_panel.visible, "empty command details should keep the panel hidden")
	remove_child(empty_button)
	empty_button.queue_free()

	var button = command_center_menu.find_child("ProduceWorkerButton")
	unit_menus._show_command_details(button)

	assert(details_panel.visible, "hovering a command button should reveal command details")
	assert(title != null and title.text.contains(tr("WORKER")), "command details should show the command name")
	assert(
		body != null and body.text.contains(tr("PRODUCTION_ROLES")),
		"command details should include the tactical role summary"
	)
	assert(
		body.text.contains(tr("PRODUCTION_USE")),
		"command details should include tactical use summary"
	)

	unit_menus._hide_command_details_for(button)
	assert(not details_panel.visible, "leaving the hovered command should hide command details")

	remove_child(fake_unit)
	fake_unit.queue_free()
	remove_child(fake_player)
	fake_player.queue_free()


func _assert_command_buttons_have_visible_surface_names(unit_menus):
	var fake_player = FakePlayer.new()
	var fake_unit = FakeProductionStructure.new(fake_player, FakeOpenProductionQueue.new())
	add_child(fake_player)
	add_child(fake_unit)

	var menus = [
		unit_menus.find_child("GenericMenu", true, false),
		unit_menus.find_child("CommandCenterMenu", true, false),
		unit_menus.find_child("VehicleFactoryMenu", true, false),
		unit_menus.find_child("AircraftFactoryMenu", true, false),
		unit_menus.find_child("BarracksMenu", true, false),
		unit_menus.find_child("WorkerMenu", true, false),
	]
	for menu in menus:
		if menu == null:
			continue
		if "unit" in menu:
			menu.unit = fake_unit
		if "units" in menu:
			menu.units = [fake_unit]
		if menu.has_method("refresh"):
			menu.refresh()
	await get_tree().process_frame

	for menu in menus:
		if menu == null:
			continue
		for button in menu.find_children("*", "Button", true, false):
			if not button.visible:
				continue
			var name_label = button.find_child(NAME_LABEL_NAME, false, false)
			assert(
				name_label != null,
				"{0}/{1} should expose a visible command surface name".format([menu.name, button.name])
			)
			assert(
				name_label.visible and name_label.text.strip_edges() != "",
				"{0}/{1} command surface name should be readable in the cell".format([menu.name, button.name])
			)
			assert(
				button.get_meta(CommandButtonStatus.META_NAME_TEXT, "").strip_edges() != "",
				"{0}/{1} should mirror its command surface name in metadata".format([menu.name, button.name])
			)
			var status_strip = button.find_child(STATUS_STRIP_NAME, false, false)
			assert(
				status_strip != null and status_strip.visible,
				"{0}/{1} should put command text on a readable bottom status strip".format(
					[menu.name, button.name]
				)
			)
			assert(
				status_strip.z_index < name_label.z_index,
				"{0}/{1} status strip should draw below command text".format([menu.name, button.name])
			)
			var visible_icon = button.find_child(VISIBLE_ICON_NAME, false, false)
			if visible_icon != null:
				assert(
					status_strip.z_index < visible_icon.z_index,
					"{0}/{1} status strip should not obscure the command icon".format(
						[menu.name, button.name]
					)
				)

	remove_child(fake_unit)
	fake_unit.queue_free()
	remove_child(fake_player)
	fake_player.queue_free()


func _assert_disabled_command_icons_remain_visible(unit_menus):
	var fake_player = FakePlayer.new()
	var fake_unit = FakeProductionStructure.new(fake_player, FakeOpenProductionQueue.new())
	add_child(fake_player)
	add_child(fake_unit)

	var barracks_menu = unit_menus.find_child("BarracksMenu", true, false)
	barracks_menu.unit = fake_unit
	barracks_menu.refresh()
	var vehicle_menu = unit_menus.find_child("VehicleFactoryMenu", true, false)
	vehicle_menu.unit = fake_unit
	vehicle_menu.refresh()
	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	worker_menu.unit = fake_unit
	worker_menu.refresh()

	await get_tree().process_frame

	var disabled_buttons = [
		barracks_menu.find_child("ProduceShieldTrooperButton"),
		vehicle_menu.find_child("ProduceTeslaCrawlerMk2Button"),
		worker_menu.find_child("PlaceWeatherControlSpireButton"),
		worker_menu.find_child("PlaceTechLabButton"),
	]
	for button in disabled_buttons:
		assert(button != null, "disabled command button should exist")
		assert(button.disabled, "{0} should be disabled for missing tech".format([button.name]))
		var icon = button.find_child("TextureRect", true, false)
		assert(icon != null, "{0} should keep its icon node".format([button.name]))
		assert(icon.texture != null, "{0} should keep a loaded icon texture".format([button.name]))
		assert(button.icon == null, "{0} disabled button should avoid duplicate Button.icon drawing".format([button.name]))
		assert(not button.expand_icon, "{0} disabled button should not expand a hidden built-in icon".format([button.name]))
		assert(not icon.visible, "{0} disabled source icon should stay hidden".format([button.name]))
		assert(icon.material == null, "{0} disabled icon should avoid Web-fragile shader materials".format([button.name]))
		var visible_icon = button.find_child(VISIBLE_ICON_NAME, false, false)
		assert(visible_icon != null, "{0} disabled button should keep one visible icon layer".format([button.name]))
		assert(visible_icon.visible, "{0} disabled visible icon should remain visible".format([button.name]))
		assert(visible_icon.texture == icon.texture, "{0} disabled visible icon should draw the command texture".format([button.name]))
		assert(
			visible_icon.modulate.a >= 0.80,
			"{0} disabled icon should stay readable instead of looking empty".format([button.name])
		)
		var backdrop = button.find_child(ICON_BACKDROP_NAME, false, false)
		assert(
			backdrop != null and backdrop.visible,
			"{0} disabled icon should keep a visible backdrop".format([button.name])
		)

	remove_child(fake_unit)
	fake_unit.queue_free()
	remove_child(fake_player)
	fake_player.queue_free()


func _assert_match_hud_allocates_expanded_command_panel():
	var match_node = MatchScene.instantiate()
	var command_anchor = match_node.get_node("HUD/MarginContainer3")
	var selection_anchor = match_node.get_node("HUD/SelectionInfoAnchor")
	var command_anchor_width = command_anchor.offset_right - command_anchor.offset_left
	var command_anchor_height = command_anchor.offset_bottom - command_anchor.offset_top
	assert(
		command_anchor_width >= HUD_COMMAND_ANCHOR_MIN_WIDTH,
		"match HUD should reserve enough width for the expanded command panel"
	)
	assert(
		command_anchor_height >= HUD_COMMAND_ANCHOR_MIN_HEIGHT,
		"match HUD should reserve enough height for the expanded command panel and queue"
	)
	assert(
		selection_anchor.offset_right <= command_anchor.offset_left - 10.0,
		"selection info should leave a gap before the expanded command panel"
	)
	match_node.queue_free()


func _assert_match_hud_embeds_styled_unit_menus():
	var match_node = MatchScene.instantiate()
	var hud = match_node.get_node("HUD")
	assert(hud.get_script() == RtsHudStylerScript, "real match HUD should use the RTS HUD styler")
	var unit_menus = hud.get_node_or_null("MarginContainer3/VBoxContainer/UnitMenus")
	assert(unit_menus != null, "real match HUD should embed unit command menus under the styled HUD")
	var command_center_menu = unit_menus.find_child("CommandCenterMenu", true, false)
	assert(command_center_menu != null, "real match HUD should include the command center menu")

	for button_name in ["ProduceWorkerButton", "ProduceEngineerDroneButton"]:
		var button = command_center_menu.find_child(button_name, true, false)
		var icon = button.find_child("TextureRect", true, false)
		assert(
			icon != null and icon.texture != null,
			"{0} real match HUD should ship with an initial icon texture".format([button_name])
		)

	match_node.queue_free()


func _assert_command_panel_keeps_full_size_for_common_web_viewport(unit_menus):
	unit_menus.apply_command_panel_layout_for_viewport(COMMON_WEB_VIEWPORT_SIZE)
	await get_tree().process_frame

	assert(
		unit_menus.get_command_panel_rows() == COMMAND_PANEL_ROWS_MIN,
		"720p web viewports should prefer five large command rows over six compressed rows"
	)
	assert(
		unit_menus.get_command_button_size() == COMMON_WEB_COMMAND_BUTTON_SIZE,
		"720p web viewports should keep command buttons large and readable"
	)
	assert(
		unit_menus.get_command_panel_size() == COMMON_WEB_COMMAND_PANEL_SIZE,
		"720p web viewports should keep the enlarged command panel"
	)
	assert(
		_visible_background_slots(unit_menus.find_child("BackgroundGrid", true, false)).size()
		== COMMAND_PANEL_COLUMNS * COMMAND_PANEL_ROWS_MIN,
		"720p web viewports should show five large rows and rely on menu scrolling for overflow"
	)


func _assert_command_panel_keeps_full_size_for_short_viewport(unit_menus):
	unit_menus.apply_command_panel_layout_for_viewport(SHORT_VIEWPORT_SIZE)
	await get_tree().process_frame

	assert(
		unit_menus.get_command_panel_rows() == COMMAND_PANEL_ROWS_MIN,
		"short web viewports should collapse to the five-row command panel"
	)
	assert(
		unit_menus.get_command_button_size() == SHORT_COMMAND_BUTTON_SIZE,
		"short web viewports should keep command buttons large enough to read and click"
	)
	assert(
		unit_menus.get_command_panel_size() == SHORT_COMMAND_PANEL_SIZE,
		"short web viewports should keep the expanded command panel fitting the viewport"
	)
	assert(
		unit_menus.find_child("CommandPanelViewport", true, false).custom_minimum_size
		== SHORT_COMMAND_PANEL_SIZE,
		"short command viewport should keep the responsive command panel size"
	)
	assert(
		_visible_background_slots(unit_menus.find_child("BackgroundGrid", true, false)).size()
		== COMMAND_PANEL_COLUMNS * COMMAND_PANEL_ROWS_MIN,
		"short command viewport should show five rows of command slots"
	)
	_assert_controls_exact_minimum_size(
		_visible_background_slots(unit_menus.find_child("BackgroundGrid", true, false)),
		SHORT_COMMAND_BUTTON_SIZE,
		"short viewport command background slot"
	)
	_assert_controls_exact_minimum_size(
		unit_menus.find_children("*", "Button", true, false),
		SHORT_COMMAND_BUTTON_SIZE,
		"short viewport command button"
	)


func _assert_controls_exact_minimum_size(controls, expected_size, label):
	for control in controls:
		assert(
			control.custom_minimum_size == expected_size,
			"{0} {1} should be exactly {2}x{3}".format(
				[label, control.name, expected_size.x, expected_size.y]
			)
		)


func _visible_background_slots(background_grid):
	return background_grid.find_children("*", "Panel", true, false).filter(
		func(slot): return slot.visible
	)


func _screen_overlay_for_button(root, button):
	var search_root = root
	var layer = null
	while search_root != null and layer == null:
		layer = search_root.find_child(SCREEN_ICON_LAYER_NAME, true, false)
		search_root = search_root.get_parent()
	if layer == null:
		return null
	return layer.find_child(
		"{0}{1}".format([SCREEN_ICON_PREFIX, button.get_instance_id()]), false, false
	)
