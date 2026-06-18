extends Node

signal resources_required(resources, metadata)

const Barracks = preload("res://source/match/units/Barracks.gd")
const SaboteurInfiltrator = preload("res://source/match/units/SaboteurInfiltrator.gd")
const SaboteurInfiltratorScene = preload("res://source/match/units/SaboteurInfiltrator.tscn")
const Structure = preload("res://source/match/units/Structure.gd")
const Capturing = preload("res://source/match/units/actions/Capturing.gd")
const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")

const REFRESH_INTERVAL_S = 1.0
const SABOTEUR_METADATA = "saboteur_infiltration"
const TARGET_PRIORITY_BY_SCENE = {
	"res://source/match/units/Barracks.tscn": 120.0,
	"res://source/match/units/VehicleFactory.tscn": 116.0,
	"res://source/match/units/AircraftFactory.tscn": 112.0,
	"res://source/match/units/AdvancedReactorPlant.tscn": 106.0,
	"res://source/match/units/PowerReactor.tscn": 104.0,
	"res://source/match/units/OrePurifier.tscn": 96.0,
	"res://source/match/units/Refinery.tscn": 88.0,
	"res://source/match/units/CommandCenter.tscn": 82.0,
}

var _player = null
var _pending_saboteur_resource_requests = 0
var _pending_saboteurs = 0
var _active_saboteurs = {}


func setup(player):
	_player = player
	_setup_refresh_timer()
	_attach_current_saboteurs()
	MatchSignals.unit_spawned.connect(_on_unit_spawned)
	MatchSignals.unit_captured.connect(_on_unit_captured)
	MatchSignals.unit_construction_finished.connect(_on_unit_construction_finished)
	_enforce_infiltration_pressure()


func provision(resources, metadata):
	if metadata != SABOTEUR_METADATA:
		push_warning("Ignoring unknown AI saboteur resource request metadata: {0}".format([metadata]))
		return
	_pending_saboteur_resource_requests = max(0, _pending_saboteur_resource_requests - 1)
	if not _resources_match(
		resources,
		Constants.Match.Units.PRODUCTION_COSTS[SaboteurInfiltratorScene.resource_path]
	):
		return
	var barracks = _best_barracks()
	if barracks == null:
		return
	var queue_element = barracks.production_queue.produce(SaboteurInfiltratorScene, true)
	if queue_element != null:
		_pending_saboteurs += 1


func _resources_match(resources, expected_resources):
	if resources == expected_resources:
		return true
	push_warning(
		"Ignoring AI saboteur resource provision: expected {0}, got {1}".format(
			[expected_resources, resources]
		)
	)
	return false


func try_dispatch_saboteur():
	_cleanup_active_saboteurs()
	var idle_saboteur = _idle_saboteur()
	if idle_saboteur == null:
		return false
	return _dispatch_saboteur(idle_saboteur)


func get_pending_saboteur_count():
	return _pending_saboteurs + _pending_saboteur_resource_requests


func _setup_refresh_timer():
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_refresh_timer_timeout)
	timer.start(REFRESH_INTERVAL_S)


func _attach_current_saboteurs():
	for saboteur in _current_saboteurs():
		_attach_saboteur(saboteur)


func _attach_saboteur(saboteur):
	if _active_saboteurs.has(saboteur):
		return
	_active_saboteurs[saboteur] = null
	var exited_callable = _on_saboteur_removed.bind(saboteur)
	if not saboteur.tree_exited.is_connected(exited_callable):
		saboteur.tree_exited.connect(exited_callable)
	if _is_idle_for_infiltration(saboteur):
		_dispatch_saboteur(saboteur)


func _enforce_infiltration_pressure():
	_cleanup_active_saboteurs()
	if not _should_request_saboteur():
		return
	_pending_saboteur_resource_requests += 1
	resources_required.emit(
		Constants.Match.Units.PRODUCTION_COSTS[SaboteurInfiltratorScene.resource_path],
		SABOTEUR_METADATA
	)


func _should_request_saboteur():
	if not Utils.Match.Unit.Tech.can_produce(_player, SaboteurInfiltratorScene.resource_path):
		return false
	if _best_barracks() == null:
		return false
	if _best_infiltration_target() == null:
		return false
	if _pending_saboteur_resource_requests + _pending_saboteurs > 0:
		return false
	if _active_infiltration_saboteur_count() > 0:
		return false
	return true


func _current_saboteurs():
	return get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is SaboteurInfiltrator and unit.player == _player
	)


func _idle_saboteur():
	for saboteur in _current_saboteurs():
		if _is_idle_for_infiltration(saboteur):
			return saboteur
	return null


func _is_idle_for_infiltration(saboteur):
	if saboteur.has_method("has_queued_actions") and saboteur.has_queued_actions():
		return false
	if saboteur.action == null:
		return true
	if saboteur.action is WaitingForTargets:
		return saboteur.action.is_idle()
	return false


func _active_infiltration_saboteur_count():
	var count = 0
	for saboteur in _active_saboteurs.keys():
		if not is_instance_valid(saboteur):
			continue
		if saboteur.player == _player and saboteur.action != null and saboteur.action is Capturing:
			count += 1
	return count


func _dispatch_saboteur(saboteur):
	var target = _best_infiltration_target(saboteur.global_position)
	if target == null or not Capturing.is_applicable(saboteur, target):
		return false
	saboteur.clear_action_queue()
	saboteur.action = Capturing.new(target)
	_active_saboteurs[saboteur] = target
	return true


func _best_barracks():
	var barracks_list = get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return unit is Barracks and unit.player == _player and unit.is_constructed()
	)
	barracks_list.sort_custom(
		func(a, b): return a.production_queue.size() < b.production_queue.size()
	)
	return barracks_list[0] if not barracks_list.is_empty() else null


func _best_infiltration_target(reference_position = null):
	var targets = get_tree().get_nodes_in_group("units").filter(_is_infiltration_target)
	if targets.is_empty():
		return null
	var origin = reference_position if reference_position != null else _player.global_position
	targets.sort_custom(
		func(a, b): return _target_score(a, origin) > _target_score(b, origin)
	)
	return targets[0]


func _is_infiltration_target(unit):
	return (
		unit is Structure
		and unit.can_be_captured_by(_player)
		and _target_has_infiltration_value(unit)
		and not _is_already_targeted(unit)
	)


func _target_has_infiltration_value(target):
	var scene_path = target.get_script().resource_path.replace(".gd", ".tscn")
	if Constants.Match.Capture.INFILTRATION_PRODUCTION_VETERANCY_TARGETS.has(scene_path):
		var producer_scene_path = (
			Constants.Match.Capture.INFILTRATION_PRODUCTION_VETERANCY_TARGETS[scene_path]
		)
		if (
			_player.get_production_veterancy_rank(producer_scene_path)
			< Constants.Match.Capture.SABOTEUR_PRODUCTION_VETERANCY_RANK
		):
			return true
	if Constants.Match.Capture.INFILTRATION_RESOURCE_TARGETS.has(scene_path):
		var victim = target.player
		return int(victim.resource_a) > 0 or int(victim.resource_b) > 0
	if Constants.Match.Capture.INFILTRATION_POWER_SABOTAGE_TARGETS.has(scene_path):
		return not target.player.is_power_sabotaged()
	return false


func _is_already_targeted(target):
	for saboteur in _active_saboteurs.keys():
		if not is_instance_valid(saboteur):
			continue
		if _active_saboteurs[saboteur] == target:
			return true
	return false


func _target_score(target, origin):
	var scene_path = target.get_script().resource_path.replace(".gd", ".tscn")
	var score = TARGET_PRIORITY_BY_SCENE.get(scene_path, 30.0)
	var construction_cost = Constants.Match.Units.CONSTRUCTION_COSTS.get(
		scene_path, {"resource_a": 0, "resource_b": 0}
	)
	score += float(
		construction_cost.get("resource_a", 0) + construction_cost.get("resource_b", 0)
	)
	if Constants.Match.Capture.INFILTRATION_RESOURCE_TARGETS.has(scene_path):
		score += float(target.player.resource_a + target.player.resource_b) * 0.5
	if Constants.Match.Capture.INFILTRATION_POWER_SABOTAGE_TARGETS.has(scene_path):
		score += float(Constants.Match.Units.POWER_SUPPLY.get(scene_path, 0)) * 0.5
	score -= origin.distance_to(target.global_position) * 0.06
	return score


func _cleanup_active_saboteurs():
	for saboteur in _active_saboteurs.keys().duplicate():
		if (
			not is_instance_valid(saboteur)
			or saboteur.player != _player
			or not saboteur.is_inside_tree()
		):
			_active_saboteurs.erase(saboteur)


func _on_unit_spawned(unit):
	if unit.player != _player or not unit is SaboteurInfiltrator:
		return
	_pending_saboteurs = maxi(0, _pending_saboteurs - 1)
	_attach_saboteur(unit)


func _on_unit_captured(_unit, previous_player, new_player):
	if previous_player != _player and new_player != _player:
		return
	_enforce_infiltration_pressure()


func _on_unit_construction_finished(unit):
	if unit.player != _player:
		return
	if unit is Barracks or _is_saboteur_production_requirement(unit):
		_enforce_infiltration_pressure()


func _is_saboteur_production_requirement(unit):
	var unit_scene_path = unit.get_script().resource_path.replace(".gd", ".tscn")
	var requirement_paths = Constants.Match.Units.PRODUCTION_REQUIREMENTS.get(
		SaboteurInfiltratorScene.resource_path, []
	)
	return unit_scene_path in requirement_paths


func _on_saboteur_removed(saboteur):
	_active_saboteurs.erase(saboteur)
	if not is_inside_tree():
		return
	_enforce_infiltration_pressure()


func _on_refresh_timer_timeout():
	if not try_dispatch_saboteur():
		_enforce_infiltration_pressure()
