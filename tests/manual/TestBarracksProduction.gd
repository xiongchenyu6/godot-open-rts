extends "res://tests/manual/Match.gd"

const CombatDamage = preload("res://source/match/utils/CombatDamageUtils.gd")
const Repairing = preload("res://source/match/units/actions/Repairing.gd")
const LightRifleInfantryUnit = preload("res://source/match/units/LightRifleInfantry.tscn")
const RocketInfantryUnit = preload("res://source/match/units/RocketInfantry.tscn")
const FieldMedicUnit = preload("res://source/match/units/FieldMedic.tscn")
const ShieldTrooperUnit = preload("res://source/match/units/ShieldTrooper.tscn")
const FlakRocketTeamUnit = preload("res://source/match/units/FlakRocketTeam.tscn")
const FlakRocketTeamMk2Unit = preload("res://source/match/units/FlakRocketTeamMk2.tscn")
const HeavyMachinegunTrooperUnit = preload("res://source/match/units/HeavyMachinegunTrooper.tscn")
const ShockTrooperUnit = preload("res://source/match/units/ShockTrooper.tscn")
const GrenadierTrooperUnit = preload("res://source/match/units/GrenadierTrooper.tscn")
const MortarTeamUnit = preload("res://source/match/units/MortarTeam.tscn")
const CryoSprayerUnit = preload("res://source/match/units/CryoSprayer.tscn")
const SniperScoutUnit = preload("res://source/match/units/SniperScout.tscn")
const RailSniperTeamUnit = preload("res://source/match/units/RailSniperTeam.tscn")
const PhaseSaboteurUnit = preload("res://source/match/units/PhaseSaboteur.tscn")
const SaboteurInfiltratorUnit = preload("res://source/match/units/SaboteurInfiltrator.tscn")
const PulseRifleCommandoUnit = preload("res://source/match/units/PulseRifleCommando.tscn")
const TacticalOfficerUnit = preload("res://source/match/units/TacticalOfficer.tscn")
const REPAIR_TIMEOUT_S = 4.0
const RA2_INSPIRED_ICON_SET = "imagegen-rts-ra2-inspired-20260616-01"
const RA2_INSPIRED_ROSTER_ICON_SET = "imagegen-rts-ra2-inspired-roster-20260616-01"
const LATE_TECH_ICON_SET = "imagegen-rts-late-tech-20260616-01"
const MENU_POLISH_ICON_SET = "imagegen-rts-menu-polish-20260616-01"
const NEW_ASSET_ICON_SET = "imagegen-rts-new-assets-20260616-01"
const ROSTER_ICON_SET = "imagegen-rts-roster-20260616-02"

const INFANTRY_ROSTER = [
	LightRifleInfantryUnit,
	RocketInfantryUnit,
	FieldMedicUnit,
	ShieldTrooperUnit,
	FlakRocketTeamUnit,
	FlakRocketTeamMk2Unit,
	HeavyMachinegunTrooperUnit,
	ShockTrooperUnit,
	GrenadierTrooperUnit,
	MortarTeamUnit,
	CryoSprayerUnit,
	SniperScoutUnit,
	RailSniperTeamUnit,
	PhaseSaboteurUnit,
	SaboteurInfiltratorUnit,
	PulseRifleCommandoUnit,
	TacticalOfficerUnit,
]

@onready var _barracks = $Players/Human/Barracks


func _ready():
	super()
	await get_tree().process_frame
	assert(
		Utils.Match.Unit.Tech.can_construct($Players/Human, "res://source/match/units/Barracks.tscn"),
		"workers should be able to construct barracks without extra tech"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, LightRifleInfantryUnit.resource_path),
		"barracks should unlock basic rifle infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, RocketInfantryUnit.resource_path),
		"radar uplink should unlock rocket infantry for barracks"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, FieldMedicUnit.resource_path),
		"barracks should unlock field medic support infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, ShieldTrooperUnit.resource_path),
		"radar uplink should unlock shield trooper infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, FlakRocketTeamUnit.resource_path),
		"radar uplink should unlock flak rocket team infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, FlakRocketTeamMk2Unit.resource_path),
		"tech lab should unlock advanced flak rocket team infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, HeavyMachinegunTrooperUnit.resource_path),
		"barracks should unlock heavy machinegun infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, ShockTrooperUnit.resource_path),
		"radar uplink should unlock shock trooper infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, GrenadierTrooperUnit.resource_path),
		"radar uplink should unlock grenadier infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, MortarTeamUnit.resource_path),
		"radar uplink should unlock mortar team infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, CryoSprayerUnit.resource_path),
		"tech lab should unlock cryo sprayer infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, SniperScoutUnit.resource_path),
		"radar uplink should unlock sniper scout infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, RailSniperTeamUnit.resource_path),
		"tech lab should unlock rail sniper team infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, PhaseSaboteurUnit.resource_path),
		"tech lab should unlock phase saboteur infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, SaboteurInfiltratorUnit.resource_path),
		"tech lab should unlock saboteur infiltrator infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, PulseRifleCommandoUnit.resource_path),
		"tech lab should unlock pulse rifle commando infantry"
	)
	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, TacticalOfficerUnit.resource_path),
		"tech lab should unlock tactical officer infantry"
	)

	for infantry_scene in INFANTRY_ROSTER:
		_barracks.production_queue.produce(infantry_scene, true)

	var queued_elements = _barracks.production_queue.get_elements()
	assert(queued_elements.size() == INFANTRY_ROSTER.size(), "full barracks infantry roster should be queued")
	for index in range(INFANTRY_ROSTER.size()):
		assert(
			queued_elements[index].unit_prototype.resource_path == INFANTRY_ROSTER[index].resource_path,
			"barracks infantry roster should preserve requested production order"
		)

	_spawn_and_check_unit(LightRifleInfantryUnit, Vector3(16.0, 0.0, 10.0))
	_spawn_and_check_unit(RocketInfantryUnit, Vector3(17.0, 0.0, 10.0))
	_spawn_and_check_unit(FieldMedicUnit, Vector3(18.0, 0.0, 10.0))
	_spawn_and_check_unit(ShieldTrooperUnit, Vector3(19.0, 0.0, 10.0))
	_spawn_and_check_unit(FlakRocketTeamUnit, Vector3(20.0, 0.0, 10.0))
	_spawn_and_check_unit(FlakRocketTeamMk2Unit, Vector3(21.0, 0.0, 10.0))
	_spawn_and_check_unit(HeavyMachinegunTrooperUnit, Vector3(22.0, 0.0, 10.0))
	_spawn_and_check_unit(ShockTrooperUnit, Vector3(23.0, 0.0, 10.0))
	_spawn_and_check_unit(GrenadierTrooperUnit, Vector3(24.0, 0.0, 10.0))
	_spawn_and_check_unit(MortarTeamUnit, Vector3(25.0, 0.0, 10.0))
	_spawn_and_check_unit(CryoSprayerUnit, Vector3(26.0, 0.0, 10.0))
	_spawn_and_check_unit(SniperScoutUnit, Vector3(27.0, 0.0, 10.0))
	_spawn_and_check_unit(RailSniperTeamUnit, Vector3(28.0, 0.0, 10.0))
	_spawn_and_check_unit(PhaseSaboteurUnit, Vector3(29.0, 0.0, 10.0))
	_spawn_and_check_unit(SaboteurInfiltratorUnit, Vector3(30.0, 0.0, 10.0))
	_spawn_and_check_unit(PulseRifleCommandoUnit, Vector3(31.0, 0.0, 10.0))
	_spawn_and_check_unit(TacticalOfficerUnit, Vector3(32.0, 0.0, 10.0))
	await get_tree().process_frame
	assert($Players/Human/LightRifleInfantry.hp == $Players/Human/LightRifleInfantry.hp_max)
	assert($Players/Human/LightRifleInfantry.attack_damage > 0)
	assert($Players/Human/RocketInfantry.hp == $Players/Human/RocketInfantry.hp_max)
	assert($Players/Human/RocketInfantry.attack_damage > $Players/Human/LightRifleInfantry.attack_damage)
	assert($Players/Human/FieldMedic.hp == $Players/Human/FieldMedic.hp_max)
	assert($Players/Human/FieldMedic.attack_damage == null)
	assert($Players/Human/FieldMedic.repair_rate > 0.0)
	assert($Players/Human/ShieldTrooper.hp == $Players/Human/ShieldTrooper.hp_max)
	assert($Players/Human/ShieldTrooper.support_shielded)
	var shield_hp = $Players/Human/ShieldTrooper.hp
	$Players/Human/ShieldTrooper.hp -= 4.0
	assert(
		$Players/Human/ShieldTrooper.hp > shield_hp - 4.0,
		"shield trooper passive shield should reduce incoming damage"
	)
	$Players/Human/LightRifleInfantry.hp -= 1.0
	assert(
		Repairing.is_applicable($Players/Human/FieldMedic, $Players/Human/LightRifleInfantry),
		"field medic should be able to repair damaged friendly infantry"
	)
	var damaged_infantry_hp = $Players/Human/LightRifleInfantry.hp
	$Players/Human/FieldMedic.action = Repairing.new($Players/Human/LightRifleInfantry)
	await _wait_until(
		func(): return $Players/Human/LightRifleInfantry.hp > damaged_infantry_hp,
		REPAIR_TIMEOUT_S,
		"field medic should restore hit points after receiving a repair order"
	)
	assert($Players/Human/FlakRocketTeam.hp == $Players/Human/FlakRocketTeam.hp_max)
	assert(Constants.Match.Navigation.Domain.AIR in $Players/Human/FlakRocketTeam.attack_domains)
	assert(not Constants.Match.Navigation.Domain.TERRAIN in $Players/Human/FlakRocketTeam.attack_domains)
	assert($Players/Human/FlakRocketTeam.attack_range > $Players/Human/RocketInfantry.attack_range)
	assert($Players/Human/FlakRocketTeamMk2.hp == $Players/Human/FlakRocketTeamMk2.hp_max)
	assert(Constants.Match.Navigation.Domain.AIR in $Players/Human/FlakRocketTeamMk2.attack_domains)
	assert(Constants.Match.Navigation.Domain.TERRAIN in $Players/Human/FlakRocketTeamMk2.attack_domains)
	assert($Players/Human/FlakRocketTeamMk2.attack_range > $Players/Human/FlakRocketTeam.attack_range)
	assert($Players/Human/FlakRocketTeamMk2.splash_radius > $Players/Human/FlakRocketTeam.splash_radius)
	assert($Players/Human/HeavyMachinegunTrooper.attack_interval < $Players/Human/LightRifleInfantry.attack_interval)
	assert($Players/Human/ShockTrooper.attack_damage > $Players/Human/RocketInfantry.attack_damage)
	assert($Players/Human/GrenadierTrooper.splash_radius > 0.0)
	assert($Players/Human/MortarTeam.attack_range > $Players/Human/GrenadierTrooper.attack_range)
	assert($Players/Human/MortarTeam.splash_radius > $Players/Human/GrenadierTrooper.splash_radius)
	assert($Players/Human/CryoSprayer.splash_radius > $Players/Human/GrenadierTrooper.splash_radius)
	assert($Players/Human/CryoSprayer.attack_range < $Players/Human/GrenadierTrooper.attack_range)
	assert($Players/Human/SniperScout.attack_range > $Players/Human/RocketInfantry.attack_range)
	assert($Players/Human/RailSniperTeam.hp == $Players/Human/RailSniperTeam.hp_max)
	assert($Players/Human/RailSniperTeam.attack_range > $Players/Human/SniperScout.attack_range)
	assert($Players/Human/RailSniperTeam.attack_damage > $Players/Human/SniperScout.attack_damage)
	assert($Players/Human/PhaseSaboteur.hp == $Players/Human/PhaseSaboteur.hp_max)
	assert($Players/Human/PhaseSaboteur.structure_damage_multiplier > 1.0)
	assert($Players/Human/SaboteurInfiltrator.hp == $Players/Human/SaboteurInfiltrator.hp_max)
	assert($Players/Human/SaboteurInfiltrator.capture_time > 0.0)
	assert($Players/Human/SaboteurInfiltrator.infiltration_resource_steal_ratio > 0.0)
	assert($Players/Human/SaboteurInfiltrator.infiltration_resource_steal_cap > 0)
	assert(
		$Players/Human/SaboteurInfiltrator.structure_damage_multiplier
		> $Players/Human/PhaseSaboteur.structure_damage_multiplier
	)
	assert(
		$Players/Human/SaboteurInfiltrator.movement_speed
		> $Players/Human/PhaseSaboteur.movement_speed
	)
	assert($Players/Human/PulseRifleCommando.hp > $Players/Human/LightRifleInfantry.hp)
	assert(Constants.Match.Navigation.Domain.AIR in $Players/Human/PulseRifleCommando.attack_domains)
	assert(Constants.Match.Navigation.Domain.TERRAIN in $Players/Human/PulseRifleCommando.attack_domains)
	assert($Players/Human/TacticalOfficer.sight_range > $Players/Human/SniperScout.sight_range)
	assert(Constants.Match.Navigation.Domain.AIR in $Players/Human/TacticalOfficer.attack_domains)
	assert(Constants.Match.Navigation.Domain.TERRAIN in $Players/Human/TacticalOfficer.attack_domains)
	assert(
		CombatDamage._get_damage_amount($Players/Human/PhaseSaboteur, $Players/Human/CommandCenter)
		== $Players/Human/PhaseSaboteur.attack_damage
		* $Players/Human/PhaseSaboteur.structure_damage_multiplier,
		"phase saboteur structure damage multiplier should be applied by damage utility"
	)
	assert(
		CombatDamage._get_damage_amount($Players/Human/SaboteurInfiltrator, $Players/Human/CommandCenter)
		== $Players/Human/SaboteurInfiltrator.attack_damage
		* $Players/Human/SaboteurInfiltrator.structure_damage_multiplier,
		"saboteur infiltrator structure damage multiplier should be applied by damage utility"
	)
	_assert_barracks_menu_uses_roster_icons()
	_assert_barracks_menu_uses_menu_polish_icons()
	_assert_barracks_menu_uses_assault_tech_icon()
	_assert_barracks_menu_uses_ra2_icon_pack()
	_assert_barracks_menu_uses_generated_field_medic_icon()
	_assert_barracks_menu_uses_base_tech_icons()
	_assert_barracks_menu_uses_expansion_pack_icons()
	get_tree().quit()


func _spawn_and_check_unit(unit_scene, position):
	var unit = unit_scene.instantiate()
	MatchSignals.setup_and_spawn_unit.emit(unit, Transform3D(Basis(), position), $Players/Human)


func _wait_until(condition, timeout_s, message):
	var started_at_msec = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at_msec < timeout_s * 1000.0:
		if condition.call():
			return
		await get_tree().process_frame
	assert(false, message)


func _assert_barracks_menu_uses_assault_tech_icon():
	var unit_menus = $HUD.find_child("UnitMenus", true, false)
	var menu = unit_menus.find_child("BarracksMenu", true, false)
	var button = menu.find_child("ProduceFlakRocketTeamButton", true, false)
	assert(button != null, "barracks menu should expose flak rocket team")
	var icon = button.find_child("TextureRect").texture
	assert(icon != null, "flak rocket team button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(icon, RA2_INSPIRED_ICON_SET),
		"flak rocket team should use a packaged root icon or generated RA2-inspired icon"
	)


func _assert_barracks_menu_uses_roster_icons():
	var unit_menus = $HUD.find_child("UnitMenus", true, false)
	var menu = unit_menus.find_child("BarracksMenu", true, false)
	var rifle_button = menu.find_child("ProduceLightRifleInfantryButton", true, false)
	assert(rifle_button != null, "light rifle infantry should be exposed in barracks menu")
	var rifle_icon = rifle_button.find_child("TextureRect").texture
	assert(rifle_icon != null, "light rifle infantry should have an icon")
	assert(
		_icon_uses_canonical_or_marker(rifle_icon, RA2_INSPIRED_ROSTER_ICON_SET),
		"light rifle infantry should use a packaged root icon or generated RA2-inspired roster icon set"
	)
	var rocket_button = menu.find_child("ProduceRocketInfantryButton", true, false)
	assert(rocket_button != null, "rocket infantry should be exposed in barracks menu")
	var rocket_icon = rocket_button.find_child("TextureRect").texture
	assert(rocket_icon != null, "rocket infantry should have an icon")
	assert(
		_icon_uses_canonical_or_marker(rocket_icon, NEW_ASSET_ICON_SET),
		"rocket infantry should use a packaged root icon or generated new asset icon set"
	)
	for button_name in ["ProducePulseRifleCommandoButton"]:
		var button = menu.find_child(button_name, true, false)
		assert(button != null, "{0} should be exposed in barracks menu".format([button_name]))
		var icon = button.find_child("TextureRect").texture
		assert(icon != null, "{0} should have an icon".format([button_name]))
		assert(
			_icon_uses_canonical_or_marker(icon, ROSTER_ICON_SET),
			"{0} should use a packaged root icon or generated roster icon set".format([button_name])
		)


func _assert_barracks_menu_uses_menu_polish_icons():
	var unit_menus = $HUD.find_child("UnitMenus", true, false)
	var menu = unit_menus.find_child("BarracksMenu", true, false)
	for button_name in [
		"ProduceHeavyMachinegunTrooperButton",
		"ProduceGrenadierTrooperButton",
		"ProduceMortarTeamButton",
		"ProduceCryoSprayerButton",
	]:
		var button = menu.find_child(button_name, true, false)
		assert(button != null, "{0} should be exposed in barracks menu".format([button_name]))
		var icon = button.find_child("TextureRect").texture
		assert(icon != null, "{0} should have an icon".format([button_name]))
		assert(
			_icon_uses_canonical_or_marker(icon, MENU_POLISH_ICON_SET),
			"{0} should use a packaged root icon or generated menu-polish icon set".format([button_name])
		)


func _assert_barracks_menu_uses_ra2_icon_pack():
	var unit_menus = $HUD.find_child("UnitMenus", true, false)
	var menu = unit_menus.find_child("BarracksMenu", true, false)
	var flak_button = menu.find_child("ProduceFlakRocketTeamMk2Button", true, false)
	assert(flak_button != null, "flak rocket team mk2 should be exposed in barracks menu")
	var flak_icon = flak_button.find_child("TextureRect").texture
	assert(flak_icon != null, "flak rocket team mk2 should have an icon")
	assert(
		_icon_uses_canonical_or_marker(flak_icon, LATE_TECH_ICON_SET),
		"flak rocket team mk2 should use a packaged root icon or latest late-tech icon pack"
	)
	var saboteur_button = menu.find_child("ProduceSaboteurInfiltratorButton", true, false)
	assert(saboteur_button != null, "saboteur infiltrator should be exposed in barracks menu")
	var saboteur_icon = saboteur_button.find_child("TextureRect").texture
	assert(saboteur_icon != null, "saboteur infiltrator should have an icon")
	assert(
		_icon_uses_canonical_or_marker(saboteur_icon, NEW_ASSET_ICON_SET),
		"saboteur infiltrator should use a packaged root icon or generated new asset icon set"
	)
	assert(
		saboteur_button.tooltip_text.contains(tr("RESOURCE_STEAL")),
		"saboteur infiltrator tooltip should show its infiltration resource steal"
	)


func _assert_barracks_menu_uses_generated_field_medic_icon():
	var unit_menus = $HUD.find_child("UnitMenus", true, false)
	var menu = unit_menus.find_child("BarracksMenu", true, false)
	var button = menu.find_child("ProduceFieldMedicButton", true, false)
	assert(button != null, "barracks menu should expose field medic")
	var icon = button.find_child("TextureRect").texture
	assert(icon != null, "field medic button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(icon, RA2_INSPIRED_ROSTER_ICON_SET),
		"field medic should use a packaged root icon or generated RA2-inspired roster medic icon"
	)


func _assert_barracks_menu_uses_base_tech_icons():
	var unit_menus = $HUD.find_child("UnitMenus", true, false)
	var menu = unit_menus.find_child("BarracksMenu", true, false)
	for button_name in ["ProduceTacticalOfficerButton"]:
		var button = menu.find_child(button_name, true, false)
		assert(button != null, "{0} should be exposed in barracks menu".format([button_name]))
		var icon = button.find_child("TextureRect").texture
		assert(icon != null, "{0} should have an icon".format([button_name]))
		assert(
			_icon_uses_canonical_or_marker(icon, "rts-base-tech-20260615"),
			"{0} should use a packaged root icon or generated base-tech icon set".format([button_name])
		)


func _assert_barracks_menu_uses_expansion_pack_icons():
	var unit_menus = $HUD.find_child("UnitMenus", true, false)
	var menu = unit_menus.find_child("BarracksMenu", true, false)
	var button = menu.find_child("ProduceRailSniperTeamButton", true, false)
	assert(button != null, "barracks menu should expose rail sniper team")
	var icon = button.find_child("TextureRect").texture
	assert(icon != null, "rail sniper team button should have an icon")
	assert(
		_icon_uses_canonical_or_marker(icon, RA2_INSPIRED_ICON_SET),
		"rail sniper team should use a packaged root icon or generated RA2-inspired icon"
	)


func _icon_uses_canonical_or_marker(icon, marker):
	return (
		icon.resource_path.begins_with("res://assets/ui/icons/")
		and not icon.resource_path.contains("/generated/")
	) or marker in icon.resource_path
