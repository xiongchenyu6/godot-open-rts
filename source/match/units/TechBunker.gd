extends "res://source/match/units/Structure.gd"

const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")

const GARRISONABLE_SCENE_PATHS = {
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

var garrison_capacity = 4
var garrison_attack_damage_per_unit = 1.25

var _garrisoned_unit_paths = []


func _ready():
	await super()
	find_child("Geometry").visible = visible
	visibility_changed.connect(func(): find_child("Geometry").visible = visible)
	if not is_constructed():
		await constructed
	_refresh_garrison_attack_damage()
	action = WaitingForTargets.new()


func get_garrison_count():
	return _garrisoned_unit_paths.size()


func is_garrison_full():
	return get_garrison_count() >= garrison_capacity


func can_garrison_unit(unit):
	return (
		unit != null
		and is_instance_valid(unit)
		and unit != self
		and unit.is_inside_tree()
		and is_constructed()
		and player != null
		and "player" in unit
		and unit.player != null
		and player.is_allied_with(unit.player)
		and not is_garrison_full()
		and "hp" in unit
		and unit.hp != null
		and unit.hp > 0
		and "movement_domain" in unit
		and unit.movement_domain == Constants.Match.Navigation.Domain.TERRAIN
		and unit.find_child("Movement") != null
		and GARRISONABLE_SCENE_PATHS.has(_scene_path_for_unit(unit))
	)


func garrison_unit(unit):
	if not can_garrison_unit(unit):
		return false
	_garrisoned_unit_paths.append(_scene_path_for_unit(unit))
	_refresh_garrison_attack_damage()
	if unit.has_method("clear_action_queue"):
		unit.clear_action_queue()
	var selection = unit.find_child("Selection")
	if selection != null and selection.has_method("deselect"):
		selection.deselect()
	unit.queue_free()
	action_updated.emit()
	return true


func clear_garrison():
	if _garrisoned_unit_paths.is_empty():
		return
	_garrisoned_unit_paths.clear()
	_refresh_garrison_attack_damage()
	action_updated.emit()


func capture_by(capturing_player):
	if not can_be_captured_by(capturing_player):
		return false
	clear_garrison()
	return super(capturing_player)


func sell():
	clear_garrison()
	super()


func can_auto_acquire_targets():
	return super() and get_garrison_count() > 0


func _set_action(action_node):
	if not _action_locked and action == null:
		super(action_node)
	elif action_node != null:
		action_node.queue_free()


func _refresh_garrison_attack_damage():
	attack_damage = get_garrison_count() * garrison_attack_damage_per_unit


func _scene_path_for_unit(unit):
	return unit.get_script().resource_path.replace(".gd", ".tscn")
