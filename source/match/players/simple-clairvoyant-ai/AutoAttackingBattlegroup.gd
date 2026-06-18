extends Node

enum State { FORMING, ATTACKING }

const PLAYER_TO_ATTACK_SWITCHING_DELAY_S = 0.5
const Structure = preload("res://source/match/units/Structure.gd")


class Actions:
	const MovingToUnit = preload("res://source/match/units/actions/MovingToUnit.gd")
	const AutoAttacking = preload("res://source/match/units/actions/AutoAttacking.gd")
	const Repairing = preload("res://source/match/units/actions/Repairing.gd")


var _expected_number_of_units = null
var _players_to_attack = null
var _player_to_attack = null
var _target_unit = null

var _state = State.FORMING
var _attached_units = []


func _init(expected_number_of_units, players_to_attack):
	_expected_number_of_units = expected_number_of_units
	_players_to_attack = players_to_attack
	_player_to_attack = _players_to_attack.front()


func size():
	return _attached_units.size()


func _ready():
	MatchSignals.unit_damaged.connect(_on_unit_damaged)


func attach_unit(unit):
	assert(_state == State.FORMING, "unexpected state")
	_attached_units.append(unit)
	unit.tree_exited.connect(_on_unit_died.bind(unit))
	unit.action_changed.connect(_on_attached_unit_action_changed.bind(unit))
	if size() == _expected_number_of_units:
		_start_attacking()


func _start_attacking():
	_state = State.ATTACKING
	_attack_next_adversary_unit()


func _attack_next_adversary_unit():
	var adversary_units = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit.player == _player_to_attack
	)
	if adversary_units.is_empty():
		_attack_next_player()
		return
	var battlegroup_position = _attached_units[0].global_position
	var adversary_units_sorted_by_distance = adversary_units.map(
		func(adversary_unit):
			return {
				"distance":
				(adversary_unit.global_position * Vector3(1, 0, 1)).distance_to(
					battlegroup_position
				),
				"unit": adversary_unit
			}
	)
	adversary_units_sorted_by_distance.sort_custom(
		func(tuple_a, tuple_b): return tuple_a["distance"] < tuple_b["distance"]
	)
	for tuple in adversary_units_sorted_by_distance:
		_target_unit = tuple["unit"]
		if _attached_units.any(
			func(attached_unit):
				return Actions.AutoAttacking.is_applicable(attached_unit, _target_unit)
		):
			_target_unit.tree_exited.connect(_on_target_unit_died.bind(_target_unit))
			_assign_actions_for_current_target()
			return
	# if not possible to attack remaining units:
	_attack_next_player()


func _attack_next_player():
	_pack_deployable_units()
	var player_to_attack_index = _players_to_attack.find(_player_to_attack)
	var next_player_to_attack_index = (player_to_attack_index + 1) % _players_to_attack.size()
	_player_to_attack = _players_to_attack[next_player_to_attack_index]
	get_tree().create_timer(PLAYER_TO_ATTACK_SWITCHING_DELAY_S).timeout.connect(
		_attack_next_adversary_unit
	)


func _on_unit_died(unit):
	if not is_inside_tree():
		return
	_attached_units.erase(unit)
	if _state == State.ATTACKING and _attached_units.is_empty():
		queue_free()
	elif _state == State.ATTACKING:
		_assign_actions_for_current_target()


func _on_target_unit_died(died_target):
	if not is_inside_tree():
		return
	if died_target != _target_unit:
		return
	_target_unit = null
	_attack_next_adversary_unit()


func _on_unit_damaged(unit):
	if _state != State.ATTACKING or not unit in _attached_units:
		return
	_assign_support_actions_for_current_target()


func _on_attached_unit_action_changed(_new_action, attached_unit):
	if (
		_state != State.ATTACKING
		or not _is_active_attached_unit(attached_unit)
		or not _has_active_target()
	):
		return
	call_deferred("_restore_attached_unit_action_if_needed", attached_unit)


func _restore_attached_unit_action_if_needed(attached_unit):
	if (
		_state != State.ATTACKING
		or not _is_active_attached_unit(attached_unit)
		or not _has_active_target()
		or _is_expected_action_for_current_target(attached_unit, attached_unit.action)
		or not _has_available_action_for_current_target(attached_unit)
	):
		return
	_assign_action_for_current_target(attached_unit)


func _assign_actions_for_current_target():
	if not _has_active_target():
		return
	for attached_unit in _attached_units:
		_assign_action_for_current_target(attached_unit)


func _assign_support_actions_for_current_target():
	if not _has_active_target():
		return
	for attached_unit in _attached_units:
		if (
			_repair_target_for(attached_unit) != null
			or attached_unit.action is Actions.Repairing
		):
			_assign_action_for_current_target(attached_unit)


func _assign_action_for_current_target(attached_unit):
	if not _is_active_attached_unit(attached_unit) or not _has_active_target():
		return
	_configure_deploy_mode_for_current_target(attached_unit)
	var repair_target = _repair_target_for(attached_unit)
	if repair_target != null:
		var repair_action = Actions.Repairing.new(repair_target)
		repair_action.tree_exited.connect(_on_support_action_finished.bind(attached_unit))
		attached_unit.action = repair_action
	elif Actions.AutoAttacking.is_applicable(attached_unit, _target_unit):
		attached_unit.action = Actions.AutoAttacking.new(_target_unit)
	elif Actions.MovingToUnit.is_applicable(attached_unit):
		attached_unit.action = Actions.MovingToUnit.new(_target_unit)
	else:
		attached_unit.action = null


func _configure_deploy_mode_for_current_target(unit):
	if not _is_deployable_unit(unit):
		return
	if not _target_unit is Structure:
		unit.set_deploy_mode(false)
		return
	unit.set_deploy_mode(true)
	if not Actions.AutoAttacking.is_applicable(unit, _target_unit):
		unit.set_deploy_mode(false)


func _pack_deployable_units():
	for unit in _attached_units:
		if _is_active_attached_unit(unit) and _is_deployable_unit(unit):
			unit.set_deploy_mode(false)


func _repair_target_for(repair_unit):
	if not _is_active_attached_unit(repair_unit):
		return null
	var repair_targets = _attached_units.filter(
		func(candidate):
			return (
				_is_active_attached_unit(candidate)
				and Actions.Repairing.is_applicable(repair_unit, candidate)
			)
	)
	if repair_targets.is_empty():
		return null
	repair_targets.sort_custom(
		func(unit_a, unit_b):
			return _missing_hp_ratio(unit_a) > _missing_hp_ratio(unit_b)
	)
	return repair_targets[0]


func _missing_hp_ratio(unit):
	if not "hp" in unit or not "hp_max" in unit or unit.hp_max <= 0:
		return 0.0
	return 1.0 - float(unit.hp) / float(unit.hp_max)


func _on_support_action_finished(attached_unit):
	if not is_inside_tree():
		return
	call_deferred("_resume_support_unit_if_idle", attached_unit)


func _resume_support_unit_if_idle(attached_unit):
	if (
		not _is_active_attached_unit(attached_unit)
		or _state != State.ATTACKING
		or attached_unit.action != null
	):
		return
	_assign_action_for_current_target(attached_unit)


func _is_expected_action_for_current_target(attached_unit, action):
	if action == null:
		return not _has_available_action_for_current_target(attached_unit)
	var repair_target = _repair_target_for(attached_unit)
	if repair_target != null:
		return action is Actions.Repairing and _action_targets_unit(action, repair_target)
	if action is Actions.AutoAttacking or action is Actions.MovingToUnit:
		return _action_targets_unit(action, _target_unit)
	return not _has_available_action_for_current_target(attached_unit)


func _has_available_action_for_current_target(attached_unit):
	return (
		_repair_target_for(attached_unit) != null
		or Actions.AutoAttacking.is_applicable(attached_unit, _target_unit)
		or Actions.MovingToUnit.is_applicable(attached_unit)
	)


func _action_targets_unit(action, target_unit):
	return "_target_unit" in action and action._target_unit == target_unit


func _has_active_target():
	return _target_unit != null and is_instance_valid(_target_unit) and _target_unit.is_inside_tree()


func _is_active_attached_unit(unit):
	return unit != null and is_instance_valid(unit) and unit.is_inside_tree() and unit in _attached_units


func _is_deployable_unit(unit):
	return (
		unit.has_method("can_toggle_deploy_mode")
		and unit.has_method("set_deploy_mode")
		and unit.has_method("is_deployed_mode")
		and unit.can_toggle_deploy_mode()
	)
