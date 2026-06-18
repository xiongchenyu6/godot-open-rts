extends GridContainer

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
const StructureMenuActions = preload("res://source/match/hud/unit-menus/StructureMenuActions.gd")
const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const ProductionMenuActions = preload("res://source/match/hud/unit-menus/ProductionMenuActions.gd")
const ProductionButtonTooltip = preload("res://source/match/hud/unit-menus/ProductionButtonTooltip.gd")

var unit = null
var units = []

@onready var _light_rifle_infantry_button = find_child("ProduceLightRifleInfantryButton")
@onready var _rocket_infantry_button = find_child("ProduceRocketInfantryButton")
@onready var _field_medic_button = find_child("ProduceFieldMedicButton")
@onready var _shield_trooper_button = find_child("ProduceShieldTrooperButton")
@onready var _flak_rocket_team_button = find_child("ProduceFlakRocketTeamButton")
@onready var _flak_rocket_team_mk2_button = find_child("ProduceFlakRocketTeamMk2Button")
@onready var _heavy_machinegun_trooper_button = find_child("ProduceHeavyMachinegunTrooperButton")
@onready var _shock_trooper_button = find_child("ProduceShockTrooperButton")
@onready var _grenadier_trooper_button = find_child("ProduceGrenadierTrooperButton")
@onready var _mortar_team_button = find_child("ProduceMortarTeamButton")
@onready var _cryo_sprayer_button = find_child("ProduceCryoSprayerButton")
@onready var _sniper_scout_button = find_child("ProduceSniperScoutButton")
@onready var _rail_sniper_team_button = find_child("ProduceRailSniperTeamButton")
@onready var _phase_saboteur_button = find_child("ProducePhaseSaboteurButton")
@onready var _saboteur_infiltrator_button = find_child("ProduceSaboteurInfiltratorButton")
@onready var _pulse_rifle_commando_button = find_child("ProducePulseRifleCommandoButton")
@onready var _tactical_officer_button = find_child("ProduceTacticalOfficerButton")
@onready var _sell_structure_button = find_child("SellStructureButton")
@onready var _rally_point_button = find_child("SetRallyPointButton")
var _repair_structure_button = null


func _ready():
	_repair_structure_button = StructureMenuActions.ensure_repair_button(self)
	CommandButtonHotkeys.assign_grid_hotkeys(self)
	_set_unit_tooltip(
		_light_rifle_infantry_button,
		LightRifleInfantryUnit,
		"LIGHT_RIFLE_INFANTRY",
		"LIGHT_RIFLE_INFANTRY_DESCRIPTION"
	)
	_set_unit_tooltip(
		_rocket_infantry_button,
		RocketInfantryUnit,
		"ROCKET_INFANTRY",
		"ROCKET_INFANTRY_DESCRIPTION"
	)
	_set_unit_tooltip(
		_field_medic_button,
		FieldMedicUnit,
		"FIELD_MEDIC",
		"FIELD_MEDIC_DESCRIPTION"
	)
	_set_unit_tooltip(
		_shield_trooper_button,
		ShieldTrooperUnit,
		"SHIELD_TROOPER",
		"SHIELD_TROOPER_DESCRIPTION"
	)
	_set_unit_tooltip(
		_flak_rocket_team_button,
		FlakRocketTeamUnit,
		"FLAK_ROCKET_TEAM",
		"FLAK_ROCKET_TEAM_DESCRIPTION"
	)
	_set_unit_tooltip(
		_flak_rocket_team_mk2_button,
		FlakRocketTeamMk2Unit,
		"FLAK_ROCKET_TEAM_MK2",
		"FLAK_ROCKET_TEAM_MK2_DESCRIPTION"
	)
	_set_unit_tooltip(
		_heavy_machinegun_trooper_button,
		HeavyMachinegunTrooperUnit,
		"HEAVY_MACHINEGUN_TROOPER",
		"HEAVY_MACHINEGUN_TROOPER_DESCRIPTION"
	)
	_set_unit_tooltip(
		_shock_trooper_button,
		ShockTrooperUnit,
		"SHOCK_TROOPER",
		"SHOCK_TROOPER_DESCRIPTION"
	)
	_set_unit_tooltip(
		_grenadier_trooper_button,
		GrenadierTrooperUnit,
		"GRENADIER_TROOPER",
		"GRENADIER_TROOPER_DESCRIPTION"
	)
	_set_unit_tooltip(_mortar_team_button, MortarTeamUnit, "MORTAR_TEAM", "MORTAR_TEAM_DESCRIPTION")
	_set_unit_tooltip(
		_cryo_sprayer_button,
		CryoSprayerUnit,
		"CRYO_SPRAYER",
		"CRYO_SPRAYER_DESCRIPTION"
	)
	_set_unit_tooltip(
		_sniper_scout_button,
		SniperScoutUnit,
		"SNIPER_SCOUT",
		"SNIPER_SCOUT_DESCRIPTION"
	)
	_set_unit_tooltip(
		_rail_sniper_team_button,
		RailSniperTeamUnit,
		"RAIL_SNIPER_TEAM",
		"RAIL_SNIPER_TEAM_DESCRIPTION"
	)
	_set_unit_tooltip(
		_phase_saboteur_button,
		PhaseSaboteurUnit,
		"PHASE_SABOTEUR",
		"PHASE_SABOTEUR_DESCRIPTION"
	)
	_set_unit_tooltip(
		_saboteur_infiltrator_button,
		SaboteurInfiltratorUnit,
		"SABOTEUR_INFILTRATOR",
		"SABOTEUR_INFILTRATOR_DESCRIPTION"
	)
	_set_unit_tooltip(
		_pulse_rifle_commando_button,
		PulseRifleCommandoUnit,
		"PULSE_RIFLE_COMMANDO",
		"PULSE_RIFLE_COMMANDO_DESCRIPTION"
	)
	_set_unit_tooltip(
		_tactical_officer_button,
		TacticalOfficerUnit,
		"TACTICAL_OFFICER",
		"TACTICAL_OFFICER_DESCRIPTION"
	)


func refresh():
	_refresh_unit_button(
		_light_rifle_infantry_button,
		LightRifleInfantryUnit,
		"LIGHT_RIFLE_INFANTRY",
		"LIGHT_RIFLE_INFANTRY_DESCRIPTION"
	)
	_refresh_unit_button(
		_rocket_infantry_button,
		RocketInfantryUnit,
		"ROCKET_INFANTRY",
		"ROCKET_INFANTRY_DESCRIPTION"
	)
	_refresh_unit_button(
		_field_medic_button,
		FieldMedicUnit,
		"FIELD_MEDIC",
		"FIELD_MEDIC_DESCRIPTION"
	)
	_refresh_unit_button(
		_shield_trooper_button,
		ShieldTrooperUnit,
		"SHIELD_TROOPER",
		"SHIELD_TROOPER_DESCRIPTION"
	)
	_refresh_unit_button(
		_flak_rocket_team_button,
		FlakRocketTeamUnit,
		"FLAK_ROCKET_TEAM",
		"FLAK_ROCKET_TEAM_DESCRIPTION"
	)
	_refresh_unit_button(
		_flak_rocket_team_mk2_button,
		FlakRocketTeamMk2Unit,
		"FLAK_ROCKET_TEAM_MK2",
		"FLAK_ROCKET_TEAM_MK2_DESCRIPTION"
	)
	_refresh_unit_button(
		_heavy_machinegun_trooper_button,
		HeavyMachinegunTrooperUnit,
		"HEAVY_MACHINEGUN_TROOPER",
		"HEAVY_MACHINEGUN_TROOPER_DESCRIPTION"
	)
	_refresh_unit_button(
		_shock_trooper_button,
		ShockTrooperUnit,
		"SHOCK_TROOPER",
		"SHOCK_TROOPER_DESCRIPTION"
	)
	_refresh_unit_button(
		_grenadier_trooper_button,
		GrenadierTrooperUnit,
		"GRENADIER_TROOPER",
		"GRENADIER_TROOPER_DESCRIPTION"
	)
	_refresh_unit_button(_mortar_team_button, MortarTeamUnit, "MORTAR_TEAM", "MORTAR_TEAM_DESCRIPTION")
	_refresh_unit_button(
		_cryo_sprayer_button,
		CryoSprayerUnit,
		"CRYO_SPRAYER",
		"CRYO_SPRAYER_DESCRIPTION"
	)
	_refresh_unit_button(
		_sniper_scout_button,
		SniperScoutUnit,
		"SNIPER_SCOUT",
		"SNIPER_SCOUT_DESCRIPTION"
	)
	_refresh_unit_button(
		_rail_sniper_team_button,
		RailSniperTeamUnit,
		"RAIL_SNIPER_TEAM",
		"RAIL_SNIPER_TEAM_DESCRIPTION"
	)
	_refresh_unit_button(
		_phase_saboteur_button,
		PhaseSaboteurUnit,
		"PHASE_SABOTEUR",
		"PHASE_SABOTEUR_DESCRIPTION"
	)
	_refresh_unit_button(
		_saboteur_infiltrator_button,
		SaboteurInfiltratorUnit,
		"SABOTEUR_INFILTRATOR",
		"SABOTEUR_INFILTRATOR_DESCRIPTION"
	)
	_refresh_unit_button(
		_pulse_rifle_commando_button,
		PulseRifleCommandoUnit,
		"PULSE_RIFLE_COMMANDO",
		"PULSE_RIFLE_COMMANDO_DESCRIPTION"
	)
	_refresh_unit_button(
		_tactical_officer_button,
		TacticalOfficerUnit,
		"TACTICAL_OFFICER",
		"TACTICAL_OFFICER_DESCRIPTION"
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


func _on_produce_light_rifle_infantry_button_pressed():
	_produce(LightRifleInfantryUnit)


func _on_produce_rocket_infantry_button_pressed():
	_produce(RocketInfantryUnit)


func _on_produce_field_medic_button_pressed():
	_produce(FieldMedicUnit)


func _on_produce_shield_trooper_button_pressed():
	_produce(ShieldTrooperUnit)


func _on_produce_flak_rocket_team_button_pressed():
	_produce(FlakRocketTeamUnit)


func _on_produce_flak_rocket_team_mk2_button_pressed():
	_produce(FlakRocketTeamMk2Unit)


func _on_produce_heavy_machinegun_trooper_button_pressed():
	_produce(HeavyMachinegunTrooperUnit)


func _on_produce_shock_trooper_button_pressed():
	_produce(ShockTrooperUnit)


func _on_produce_grenadier_trooper_button_pressed():
	_produce(GrenadierTrooperUnit)


func _on_produce_mortar_team_button_pressed():
	_produce(MortarTeamUnit)


func _on_produce_cryo_sprayer_button_pressed():
	_produce(CryoSprayerUnit)


func _on_produce_sniper_scout_button_pressed():
	_produce(SniperScoutUnit)


func _on_produce_rail_sniper_team_button_pressed():
	_produce(RailSniperTeamUnit)


func _on_produce_phase_saboteur_button_pressed():
	_produce(PhaseSaboteurUnit)


func _on_produce_saboteur_infiltrator_button_pressed():
	_produce(SaboteurInfiltratorUnit)


func _on_produce_pulse_rifle_commando_button_pressed():
	_produce(PulseRifleCommandoUnit)


func _on_produce_tactical_officer_button_pressed():
	_produce(TacticalOfficerUnit)


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
