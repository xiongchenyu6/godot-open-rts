extends Node

signal element_enqueued(element)
signal element_removed(element)


class ProductionQueueElement:
	extends Resource
	var unit_prototype = null
	var time_total = null
	var blocked_notification_sent = false
	var time_left = null:
		set(value):
			time_left = value
			emit_changed()

	func progress():
		return (time_total - time_left) / time_total


var _queue = []

@onready var _unit = get_parent()


func _process(delta):
	var production_delta = delta * _unit.player.get_production_speed_multiplier()
	while _queue.size() > 0 and production_delta > 0.0:
		var current_queue_element = _queue.front()
		if current_queue_element.time_left <= 0.0:
			if not _try_finalize_production(current_queue_element):
				break
			continue
		var step = min(production_delta, current_queue_element.time_left)
		current_queue_element.time_left = max(0.0, current_queue_element.time_left - step)
		production_delta -= step
		if current_queue_element.time_left <= 0.0:
			if not _try_finalize_production(current_queue_element):
				break


func size():
	return _queue.size()


func get_elements():
	return _queue


func produce(unit_prototype, ignore_limit = false):
	if not ignore_limit and _queue.size() >= Constants.Match.Units.PRODUCTION_QUEUE_LIMIT:
		return null
	if not Utils.Match.Unit.Tech.can_produce(_unit.player, unit_prototype.resource_path):
		return null
	var production_cost = Constants.Match.Units.PRODUCTION_COSTS[unit_prototype.resource_path]
	if not _unit.player.has_resources(production_cost):
		MatchSignals.not_enough_resources_for_production.emit(_unit.player)
		return null
	_unit.player.subtract_resources(production_cost)
	var queue_element = ProductionQueueElement.new()
	queue_element.unit_prototype = unit_prototype
	queue_element.time_total = Constants.Match.Units.PRODUCTION_TIMES[unit_prototype.resource_path]
	queue_element.time_left = Constants.Match.Units.PRODUCTION_TIMES[unit_prototype.resource_path]
	_enqueue_element(queue_element)
	MatchSignals.unit_production_started.emit(unit_prototype, _unit)
	return queue_element


func cancel_all():
	for element in _queue.duplicate():
		cancel(element)


func cancel(element):
	if not element in _queue:
		return
	var production_cost = Constants.Match.Units.PRODUCTION_COSTS[
		element.unit_prototype.resource_path
	]
	_unit.player.add_resources(production_cost)
	_remove_element(element)


func _enqueue_element(element):
	_queue.push_back(element)
	element_enqueued.emit(element)


func _remove_element(element):
	_queue.erase(element)
	element_removed.emit(element)


func _try_finalize_production(former_queue_element):
	var produced_unit = former_queue_element.unit_prototype.instantiate()
	var placement_position = (
		Utils
		. Match
		. Unit
		. Placement
		. find_valid_position_radially_yet_skip_starting_radius(
			_unit.global_position,
			_unit.radius,
			produced_unit.radius,
			0.1,
			Vector3(0, 0, 1),
			false,
			find_parent("Match").navigation.get_navigation_map_rid_by_domain(
				produced_unit.movement_domain
			),
			get_tree()
		)
	)
	if placement_position == Vector3.INF:
		_notify_production_blocked_once(former_queue_element)
		produced_unit.free()
		return false
	_remove_element(former_queue_element)
	MatchSignals.setup_and_spawn_unit.emit(
		produced_unit, Transform3D(Basis(), placement_position), _unit.player
	)
	_apply_production_veterancy_bonus(produced_unit)
	MatchSignals.unit_production_finished.emit(produced_unit, _unit)

	var rally_point = _unit.find_child("RallyPoint", true, false)
	if rally_point != null and "is_set" in rally_point and rally_point.is_set:
		MatchSignals.navigate_unit_to_rally_point.emit(produced_unit, rally_point)
	return true


func _apply_production_veterancy_bonus(produced_unit):
	if (
		not _unit.player.has_method("get_production_veterancy_rank")
		or not produced_unit.has_method("grant_veterancy_rank")
	):
		return
	var rank = _unit.player.get_production_veterancy_rank(_producer_scene_path())
	if rank <= 0:
		return
	if not produced_unit.is_node_ready():
		await produced_unit.ready
	if is_instance_valid(produced_unit):
		produced_unit.grant_veterancy_rank(rank)


func _producer_scene_path():
	return _unit.get_script().resource_path.replace(".gd", ".tscn")


func _notify_production_blocked_once(queue_element):
	if queue_element.blocked_notification_sent:
		return
	queue_element.blocked_notification_sent = true
	queue_element.emit_changed()
	MatchSignals.unit_production_blocked.emit(queue_element.unit_prototype, _unit)
