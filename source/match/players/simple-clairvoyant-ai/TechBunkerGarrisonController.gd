extends Node

const TechBunker = preload("res://source/match/units/TechBunker.gd")
const Garrisoning = preload("res://source/match/units/actions/Garrisoning.gd")
const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")

const REFRESH_INTERVAL_S = 1.0
const SEARCH_RADIUS = 16.0

var _player = null


func setup(player):
	_player = player
	_setup_refresh_timer()
	MatchSignals.unit_spawned.connect(_on_unit_spawned)
	MatchSignals.unit_captured.connect(_on_unit_captured)
	call_deferred("_try_garrison_bunkers")


func _setup_refresh_timer():
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_refresh_timer_timeout)
	timer.start(REFRESH_INTERVAL_S)


func _try_garrison_bunkers():
	if _player == null or not is_inside_tree():
		return
	for bunker in _owned_open_bunkers():
		_fill_bunker(bunker)


func _owned_open_bunkers():
	var bunkers = get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return (
				unit is TechBunker
				and unit.player == _player
				and unit.is_constructed()
				and not unit.is_garrison_full()
			)
	)
	bunkers.sort_custom(
		func(a, b): return a.get_garrison_count() < b.get_garrison_count()
	)
	return bunkers


func _fill_bunker(bunker):
	var remaining_slots = bunker.garrison_capacity - bunker.get_garrison_count()
	for _slot in range(remaining_slots):
		var unit = _best_available_garrison_unit(bunker)
		if unit == null:
			return
		unit.action = Garrisoning.new(bunker)


func _best_available_garrison_unit(bunker):
	var candidates = get_tree().get_nodes_in_group("units").filter(
		func(unit): return _is_available_garrison_unit(unit, bunker)
	)
	if candidates.is_empty():
		return null
	candidates.sort_custom(
		func(a, b):
			return (
				a.global_position_yless.distance_to(bunker.global_position_yless)
				< b.global_position_yless.distance_to(bunker.global_position_yless)
			)
	)
	return candidates[0]


func _is_available_garrison_unit(unit, bunker):
	return (
		unit.player == _player
		and bunker.can_garrison_unit(unit)
		and _is_idle_for_garrison(unit)
		and (
			unit.global_position_yless.distance_to(bunker.global_position_yless)
			<= SEARCH_RADIUS
		)
	)


func _is_idle_for_garrison(unit):
	if unit.has_method("has_queued_actions") and unit.has_queued_actions():
		return false
	if unit.action == null:
		return true
	if unit.action is WaitingForTargets:
		return unit.action.is_idle()
	return false


func _on_unit_spawned(unit):
	if unit.player != _player:
		return
	call_deferred("_try_garrison_bunkers")


func _on_unit_captured(_unit, previous_player, new_player):
	if previous_player != _player and new_player != _player:
		return
	call_deferred("_try_garrison_bunkers")


func _on_refresh_timer_timeout():
	_try_garrison_bunkers()
