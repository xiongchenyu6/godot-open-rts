extends Node

signal resources_required(resources, metadata)

const CommandCenter = preload("res://source/match/units/CommandCenter.gd")
const EngineerDrone = preload("res://source/match/units/EngineerDrone.gd")
const EngineerDroneScene = preload("res://source/match/units/EngineerDrone.tscn")
const Structure = preload("res://source/match/units/Structure.gd")
const Capturing = preload("res://source/match/units/actions/Capturing.gd")

const REFRESH_INTERVAL_S = 1.0
const ENGINEER_METADATA = "engineer_capture"
const NEUTRAL_TECH_TARGET_BONUS = 18.0
const TARGET_PRIORITY_BY_SCENE = {
	"res://source/match/units/CommandCenter.tscn": 120.0,
	"res://source/match/units/TechLab.tscn": 105.0,
	"res://source/match/units/RoboticsBay.tscn": 95.0,
	"res://source/match/units/VehicleFactory.tscn": 90.0,
	"res://source/match/units/AircraftFactory.tscn": 88.0,
	"res://source/match/units/TechAirport.tscn": 87.0,
	"res://source/match/units/TechOilDerrick.tscn": 86.0,
	"res://source/match/units/TechHospital.tscn": 85.0,
	"res://source/match/units/TechBunker.tscn": 84.75,
	"res://source/match/units/TechRepairDepot.tscn": 84.5,
	"res://source/match/units/Barracks.tscn": 84.0,
	"res://source/match/units/Refinery.tscn": 78.0,
	"res://source/match/units/PowerReactor.tscn": 72.0,
	"res://source/match/units/RadarUplink.tscn": 70.0,
	"res://source/match/units/LanceBeamDefenseTower.tscn": 62.0,
	"res://source/match/units/ArcCoilDefenseTower.tscn": 58.0,
	"res://source/match/units/AntiGroundTurret.tscn": 48.0,
	"res://source/match/units/AntiAirTurret.tscn": 44.0,
}

var _player = null
var _pending_engineer_resource_requests = 0
var _pending_engineers = 0
var _active_engineers = {}


func setup(player):
	_player = player
	_setup_refresh_timer()
	_attach_current_engineers()
	MatchSignals.unit_spawned.connect(_on_unit_spawned)
	MatchSignals.unit_captured.connect(_on_unit_captured)
	_enforce_capture_pressure()


func provision(resources, metadata):
	if metadata != ENGINEER_METADATA:
		push_warning("Ignoring unknown AI engineer resource request metadata: {0}".format([metadata]))
		return
	_pending_engineer_resource_requests = max(0, _pending_engineer_resource_requests - 1)
	if not _resources_match(
		resources, Constants.Match.Units.PRODUCTION_COSTS[EngineerDroneScene.resource_path]
	):
		return
	var command_center = _best_command_center()
	if command_center == null:
		return
	var queue_element = command_center.production_queue.produce(EngineerDroneScene, true)
	if queue_element != null:
		_pending_engineers += 1


func _resources_match(resources, expected_resources):
	if resources == expected_resources:
		return true
	push_warning(
		"Ignoring AI engineer resource provision: expected {0}, got {1}".format(
			[expected_resources, resources]
		)
	)
	return false


func try_dispatch_engineer():
	_cleanup_active_engineers()
	var idle_engineer = _idle_engineer()
	if idle_engineer == null:
		return false
	return _dispatch_engineer(idle_engineer)


func get_pending_engineer_count():
	return _pending_engineers + _pending_engineer_resource_requests


func _setup_refresh_timer():
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_refresh_timer_timeout)
	timer.start(REFRESH_INTERVAL_S)


func _attach_current_engineers():
	for engineer in _current_engineers():
		_attach_engineer(engineer)


func _attach_engineer(engineer):
	if _active_engineers.has(engineer):
		return
	_active_engineers[engineer] = null
	var exited_callable = _on_engineer_removed.bind(engineer)
	if not engineer.tree_exited.is_connected(exited_callable):
		engineer.tree_exited.connect(exited_callable)
	if engineer.action == null:
		_dispatch_engineer(engineer)


func _enforce_capture_pressure():
	if not is_inside_tree() or _player == null:
		return
	_cleanup_active_engineers()
	if not _should_request_engineer():
		return
	_pending_engineer_resource_requests += 1
	resources_required.emit(
		Constants.Match.Units.PRODUCTION_COSTS[EngineerDroneScene.resource_path],
		ENGINEER_METADATA
	)


func _should_request_engineer():
	if not Utils.Match.Unit.Tech.can_produce(_player, EngineerDroneScene.resource_path):
		return false
	if _best_command_center() == null:
		return false
	if _best_capture_target() == null:
		return false
	if _pending_engineer_resource_requests + _pending_engineers > 0:
		return false
	if _active_capture_engineer_count() > 0:
		return false
	return true


func _current_engineers():
	return get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is EngineerDrone and unit.player == _player
	)


func _idle_engineer():
	for engineer in _current_engineers():
		if engineer.action == null:
			return engineer
	return null


func _active_capture_engineer_count():
	var count = 0
	for engineer in _active_engineers.keys():
		if not is_instance_valid(engineer):
			continue
		if engineer.player == _player and engineer.action != null and engineer.action is Capturing:
			count += 1
	return count


func _dispatch_engineer(engineer):
	var target = _best_capture_target(engineer.global_position)
	if target == null or not Capturing.is_applicable(engineer, target):
		return false
	engineer.action = Capturing.new(target)
	_active_engineers[engineer] = target
	return true


func _best_command_center():
	var command_centers = get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return unit is CommandCenter and unit.player == _player and unit.is_constructed()
	)
	command_centers.sort_custom(
		func(a, b): return a.production_queue.size() < b.production_queue.size()
	)
	return command_centers[0] if not command_centers.is_empty() else null


func _best_capture_target(reference_position = null):
	var targets = get_tree().get_nodes_in_group("units").filter(_is_capture_target)
	if targets.is_empty():
		return null
	var origin = reference_position if reference_position != null else _player.global_position
	targets.sort_custom(
		func(a, b): return _target_score(a, origin) > _target_score(b, origin)
	)
	return targets[0]


func _is_capture_target(unit):
	return (
		unit is Structure
		and unit.can_be_captured_by(_player)
		and not _is_already_targeted(unit)
	)


func _is_already_targeted(target):
	for engineer in _active_engineers.keys():
		if not is_instance_valid(engineer):
			continue
		if _active_engineers[engineer] == target:
			return true
	return false


func _target_score(target, origin):
	var scene_path = target.get_script().resource_path.replace(".gd", ".tscn")
	var score = TARGET_PRIORITY_BY_SCENE.get(scene_path, 30.0)
	var construction_cost = Constants.Match.Units.CONSTRUCTION_COSTS.get(
		scene_path, {"resource_a": 0, "resource_b": 0}
	)
	score += float(construction_cost.get("resource_a", 0) + construction_cost.get("resource_b", 0))
	score += float(Constants.Match.Units.POWER_SUPPLY.get(scene_path, 0))
	score += float(Constants.Match.Units.POWER_DRAIN.get(scene_path, 0))
	if _is_neutral_target(target):
		score += NEUTRAL_TECH_TARGET_BONUS
	score -= origin.distance_to(target.global_position) * 0.08
	return score


func _is_neutral_target(target):
	return (
		target.player != null
		and "participates_in_match" in target.player
		and not target.player.participates_in_match
	)


func _cleanup_active_engineers():
	for engineer in _active_engineers.keys().duplicate():
		if (
			not is_instance_valid(engineer)
			or engineer.player != _player
			or not engineer.is_inside_tree()
		):
			_active_engineers.erase(engineer)


func _on_unit_spawned(unit):
	if unit.player != _player or not unit is EngineerDrone:
		return
	_pending_engineers = maxi(0, _pending_engineers - 1)
	_attach_engineer(unit)


func _on_unit_captured(_unit, previous_player, new_player):
	if previous_player != _player and new_player != _player:
		return
	_enforce_capture_pressure()


func _on_engineer_removed(engineer):
	_active_engineers.erase(engineer)
	_enforce_capture_pressure()


func _on_refresh_timer_timeout():
	if not try_dispatch_engineer():
		_enforce_capture_pressure()
