extends "res://source/match/units/Structure.gd"

const Structure = preload("res://source/match/units/Structure.gd")
const Unit = preload("res://source/match/units/Unit.gd")

const WEB_REPAIR_SCAN_INTERVAL_SECONDS = 0.2

const INFANTRY_SCENE_PATHS = {
	"res://source/match/units/LightRifleInfantry.tscn": true,
	"res://source/match/units/RocketInfantry.tscn": true,
	"res://source/match/units/FieldMedic.tscn": true,
	"res://source/match/units/ShieldTrooper.tscn": true,
	"res://source/match/units/FlakRocketTeam.tscn": true,
	"res://source/match/units/FlakRocketTeamMk2.tscn": true,
	"res://source/match/units/HeavyMachinegunTrooper.tscn": true,
	"res://source/match/units/ShockTrooper.tscn": true,
	"res://source/match/units/GrenadierTrooper.tscn": true,
	"res://source/match/units/MortarTeam.tscn": true,
	"res://source/match/units/CryoSprayer.tscn": true,
	"res://source/match/units/SniperScout.tscn": true,
	"res://source/match/units/RailSniperTeam.tscn": true,
	"res://source/match/units/PhaseSaboteur.tscn": true,
	"res://source/match/units/SaboteurInfiltrator.tscn": true,
	"res://source/match/units/PulseRifleCommando.tscn": true,
	"res://source/match/units/TacticalOfficer.tscn": true,
}

var repair_radius = 4.75
var _web_repair_scan_elapsed = 0.0


func _process(delta):
	if not is_constructed() or player == null:
		return
	if repair_rate == null or repair_rate <= 0.0:
		return
	if "participates_in_match" in player and not player.participates_in_match:
		return
	if OS.has_feature("web"):
		_web_repair_scan_elapsed += delta
		if _web_repair_scan_elapsed < WEB_REPAIR_SCAN_INTERVAL_SECONDS:
			return
		delta = _web_repair_scan_elapsed
		_web_repair_scan_elapsed = 0.0
	for unit in get_tree().get_nodes_in_group("units"):
		if _can_repair(unit):
			unit.hp = min(unit.hp_max, unit.hp + delta * repair_rate)


func _can_repair(unit):
	if unit == self or not is_instance_valid(unit) or not unit.is_inside_tree():
		return false
	if not unit is Unit:
		return false
	if not "player" in unit or not player.is_allied_with(unit.player):
		return false
	if unit is Structure:
		return false
	if _is_infantry(unit):
		return false
	if not "movement_domain" in unit or unit.movement_domain != Constants.Match.Navigation.Domain.TERRAIN:
		return false
	if not "movement_speed" in unit or unit.movement_speed <= 0.0:
		return false
	if not "hp" in unit or not "hp_max" in unit:
		return false
	if unit.hp == null or unit.hp_max == null or unit.hp >= unit.hp_max:
		return false
	var unit_radius = unit.radius if "radius" in unit and unit.radius != null else 0.0
	return global_position_yless.distance_to(unit.global_position_yless) <= repair_radius + unit_radius


func _is_infantry(unit):
	var scene_path = unit.get_script().resource_path.replace(".gd", ".tscn")
	return INFANTRY_SCENE_PATHS.has(scene_path)
