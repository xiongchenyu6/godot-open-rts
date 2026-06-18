extends "res://source/match/units/CombatUnit.gd"

const DEPLOYED_ATTACK_RANGE = 6.5
const DEPLOYED_ATTACK_INTERVAL = 1.0
const DEPLOYED_STRUCTURE_DAMAGE_MULTIPLIER = 3.6
const DEPLOYED_SIGHT_RANGE = 9.5

var _deployed_mode = false
var _base_attack_range = null
var _base_attack_interval = null
var _base_structure_damage_multiplier = null
var _base_sight_range = null
var _base_movement_speed = null
var _hold_position_before_deploy = false


func _ready():
	await super()
	_base_attack_range = attack_range
	_base_attack_interval = attack_interval
	_base_structure_damage_multiplier = structure_damage_multiplier
	_base_sight_range = sight_range
	var movement = find_child("Movement")
	if movement != null:
		_base_movement_speed = movement.speed


func can_toggle_deploy_mode():
	return hp != null and hp > 0 and not is_emp_disabled()


func can_receive_movement_commands():
	return not _deployed_mode


func is_deployed_mode():
	return _deployed_mode


func set_deploy_mode(enabled):
	if _deployed_mode == enabled:
		return true
	if not can_toggle_deploy_mode():
		return false
	_deployed_mode = enabled
	if _deployed_mode:
		_enter_deployed_mode()
	else:
		_exit_deployed_mode()
	action = null
	action_updated.emit()
	return true


func toggle_deploy_mode():
	return set_deploy_mode(not _deployed_mode)


func _enter_deployed_mode():
	_hold_position_before_deploy = hold_position
	hold_position = true
	attack_range = DEPLOYED_ATTACK_RANGE
	attack_interval = DEPLOYED_ATTACK_INTERVAL
	structure_damage_multiplier = DEPLOYED_STRUCTURE_DAMAGE_MULTIPLIER
	sight_range = DEPLOYED_SIGHT_RANGE
	var movement = find_child("Movement")
	if movement != null:
		movement.stop()
		movement.speed = 0.0


func _exit_deployed_mode():
	hold_position = _hold_position_before_deploy
	attack_range = _base_attack_range
	attack_interval = _base_attack_interval
	structure_damage_multiplier = _base_structure_damage_multiplier
	sight_range = _base_sight_range
	var movement = find_child("Movement")
	if movement != null and _base_movement_speed != null:
		movement.speed = _base_movement_speed
