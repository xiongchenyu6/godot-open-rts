extends Node

const REFRESH_INTERVAL_S = 0.75
const MAX_ASSIGNMENTS = 2


class Actions:
	const MovingToUnit = preload("res://source/match/units/actions/MovingToUnit.gd")


const ScoutRover = preload("res://source/match/units/ScoutRover.gd")
const Unit = preload("res://source/match/units/Unit.gd")
const Structure = preload("res://source/match/units/Structure.gd")
const SupplyCrate = preload("res://source/match/units/non-player/SupplyCrate.gd")
const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")

var _player = null
var _assigned_crate_path_by_unit_path = {}


func setup(player):
	_player = player
	_setup_refresh_timer()
	MatchSignals.unit_spawned.connect(_on_unit_spawned)
	MatchSignals.supply_crate_collected.connect(_on_supply_crate_collected)
	call_deferred("_assign_collectors")


func get_active_assignment_count():
	_prune_assignments()
	return _assigned_crate_path_by_unit_path.size()


func has_assignment_for(crate):
	_prune_assignments()
	if crate == null or not is_instance_valid(crate):
		return false
	return _assigned_crate_path_by_unit_path.values().has(crate.get_path())


func is_collecting(unit, crate):
	_prune_assignments()
	if (
		unit == null
		or crate == null
		or not is_instance_valid(unit)
		or not is_instance_valid(crate)
		or not _assigned_crate_path_by_unit_path.has(unit.get_path())
	):
		return false
	return _assigned_crate_path_by_unit_path[unit.get_path()] == crate.get_path()


func _setup_refresh_timer():
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_refresh_timer_timeout)
	timer.start(REFRESH_INTERVAL_S)


func _assign_collectors():
	if _player == null or not is_inside_tree():
		return
	_prune_assignments()
	var assignment_budget = MAX_ASSIGNMENTS - _assigned_crate_path_by_unit_path.size()
	if assignment_budget <= 0:
		return
	for crate in _supply_crates_in_preference_order():
		if assignment_budget <= 0:
			return
		if has_assignment_for(crate):
			continue
		var collector = _best_available_collector_for(crate)
		if collector == null:
			continue
		_assign_collector(collector, crate)
		assignment_budget -= 1


func _assign_collector(collector, crate):
	collector.action = Actions.MovingToUnit.new(crate)
	_assigned_crate_path_by_unit_path[collector.get_path()] = crate.get_path()


func _best_available_collector_for(crate):
	var collectors = _available_collectors()
	if collectors.is_empty():
		return null
	collectors.sort_custom(
		func(a, b):
			return _collector_score(a, crate) < _collector_score(b, crate)
	)
	return collectors.front()


func _collector_score(unit, crate):
	var scout_bonus = -20.0 if unit is ScoutRover else 0.0
	return unit.global_position_yless.distance_to(crate.global_position_yless) + scout_bonus


func _available_collectors():
	return get_tree().get_nodes_in_group("units").filter(
		func(unit): return _is_available_collector(unit)
	)


func _is_available_collector(unit):
	return (
		unit is Unit
		and not unit is Structure
		and unit.player == _player
		and unit.is_inside_tree()
		and unit.is_node_ready()
		and _movement_is_ready(unit)
		and _has_combat_profile(unit)
		and unit.hp != null
		and unit.hp > 0
		and unit.movement_domain == Constants.Match.Navigation.Domain.TERRAIN
		and Actions.MovingToUnit.is_applicable(unit)
		and not _assigned_crate_path_by_unit_path.has(unit.get_path())
		and not _has_queued_orders(unit)
		and not unit.hold_position
		and _is_idle(unit)
	)


func _has_combat_profile(unit):
	return (
		unit.attack_damage != null
		and unit.attack_range != null
		and unit.attack_domains != null
		and not unit.attack_domains.is_empty()
	)


func _movement_is_ready(unit):
	var movement = unit.find_child("Movement")
	return movement != null and movement.is_node_ready()


func _has_queued_orders(unit):
	return unit.has_method("has_queued_actions") and unit.has_queued_actions()


func _is_idle(unit):
	if unit.action == null:
		return true
	if unit.action is WaitingForTargets:
		return unit.action.is_idle()
	return false


func _supply_crates_in_preference_order():
	var crates = get_tree().get_nodes_in_group("supply_crates").filter(
		func(crate): return _is_available_crate(crate)
	)
	crates.sort_custom(
		func(a, b): return _distance_to_player(a) < _distance_to_player(b)
	)
	return crates


func _is_available_crate(crate):
	return crate is SupplyCrate and crate.is_inside_tree()


func _distance_to_player(crate):
	var player_units = get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return unit.player == _player and unit.is_inside_tree() and "global_position_yless" in unit
	)
	if player_units.is_empty():
		return INF
	var closest_distance = INF
	for unit in player_units:
		closest_distance = minf(
			closest_distance, unit.global_position_yless.distance_to(crate.global_position_yless)
		)
	return closest_distance


func _prune_assignments():
	for unit_path in _assigned_crate_path_by_unit_path.keys():
		var unit = get_node_or_null(unit_path)
		var crate = get_node_or_null(_assigned_crate_path_by_unit_path[unit_path])
		if not _assignment_is_active(unit, crate):
			_assigned_crate_path_by_unit_path.erase(unit_path)


func _assignment_is_active(unit, crate):
	return (
		unit != null
		and crate != null
		and is_instance_valid(unit)
		and is_instance_valid(crate)
		and _is_available_crate(crate)
		and unit.player == _player
		and unit.hp != null
		and unit.hp > 0
		and unit.action is Actions.MovingToUnit
		and unit.action._target_unit == crate
	)


func _clear_assignments_for_crate(crate):
	if crate == null or not is_instance_valid(crate):
		return
	for unit_path in _assigned_crate_path_by_unit_path.keys():
		if _assigned_crate_path_by_unit_path[unit_path] == crate.get_path():
			_assigned_crate_path_by_unit_path.erase(unit_path)


func _on_refresh_timer_timeout():
	_assign_collectors()


func _on_unit_spawned(unit):
	if unit.player == _player:
		call_deferred("_assign_collectors")


func _on_supply_crate_collected(crate, unit, _effect_type):
	if unit != null and is_instance_valid(unit):
		_assigned_crate_path_by_unit_path.erase(unit.get_path())
	_clear_assignments_for_crate(crate)
	call_deferred("_assign_collectors")
