extends Node

signal resources_required(resources, metadata)

const CommandCenter = preload("res://source/match/units/CommandCenter.gd")
const CommandCenterScene = preload("res://source/match/units/CommandCenter.tscn")
const Refinery = preload("res://source/match/units/Refinery.gd")
const RefineryScene = preload("res://source/match/units/Refinery.tscn")
const OrePurifier = preload("res://source/match/units/OrePurifier.gd")
const OrePurifierScene = preload("res://source/match/units/OrePurifier.tscn")
const TechLabScene = preload("res://source/match/units/TechLab.tscn")
const VehicleFactory = preload("res://source/match/units/VehicleFactory.gd")
const Worker = preload("res://source/match/units/Worker.gd")
const WorkerScene = preload("res://source/match/units/Worker.tscn")
const OreHarvester = preload("res://source/match/units/OreHarvester.gd")
const OreHarvesterScene = preload("res://source/match/units/OreHarvester.tscn")
const CollectingResourcesSequentially = preload(
	"res://source/match/units/actions/CollectingResourcesSequentially.gd"
)

var _player = null
var _ccs = []
var _refineries = []
var _ore_purifiers = []
var _workers = []
var _ore_harvesters = []
var _resource_collectors = []
var _number_of_pending_cc_resource_requests = 0
var _number_of_pending_refinery_resource_requests = 0
var _number_of_pending_ore_purifier_resource_requests = 0
var _number_of_pending_worker_resource_requests = 0
var _number_of_pending_harvester_resource_requests = 0
var _number_of_pending_workers = 0
var _number_of_pending_harvesters = 0
var _cc_base_position = null

@onready var _ai = get_parent()


func setup(player):
	_player = player
	_attach_current_ccs()
	_attach_current_refineries()
	_attach_current_ore_purifiers()
	_attach_current_resource_units()
	MatchSignals.unit_spawned.connect(_on_unit_spawned)
	MatchSignals.unit_construction_finished.connect(_on_unit_construction_finished)
	MatchSignals.unit_captured.connect(_on_unit_captured)
	_enforce_number_of_ccs()
	_enforce_number_of_refineries()
	_enforce_ore_purifier()
	_enforce_number_of_workers()
	_enforce_number_of_harvesters()


func provision(resources, metadata):
	if metadata == "worker":
		_number_of_pending_worker_resource_requests = max(0, _number_of_pending_worker_resource_requests - 1)
		if not _resources_match(
			resources, Constants.Match.Units.PRODUCTION_COSTS[WorkerScene.resource_path], metadata
		):
			return
		if _ccs.is_empty():
			return
		if _ccs[0].production_queue.produce(WorkerScene, true) != null:
			_number_of_pending_workers += 1
	elif metadata == "ore_harvester":
		_number_of_pending_harvester_resource_requests = max(
			0, _number_of_pending_harvester_resource_requests - 1
		)
		if not _resources_match(
			resources,
			Constants.Match.Units.PRODUCTION_COSTS[OreHarvesterScene.resource_path],
			metadata
		):
			return
		var vehicle_factory = _constructed_vehicle_factory()
		if vehicle_factory == null:
			return
		if vehicle_factory.production_queue.produce(OreHarvesterScene, true) != null:
			_number_of_pending_harvesters += 1
	elif metadata == "cc":
		_number_of_pending_cc_resource_requests = max(0, _number_of_pending_cc_resource_requests - 1)
		if not _resources_match(
			resources,
			Constants.Match.Units.CONSTRUCTION_COSTS[CommandCenterScene.resource_path],
			metadata
		):
			return
		if _workers.is_empty():
			return
		_construct_cc()
	elif metadata == "refinery":
		_number_of_pending_refinery_resource_requests = max(
			0, _number_of_pending_refinery_resource_requests - 1
		)
		if not _resources_match(
			resources,
			Constants.Match.Units.CONSTRUCTION_COSTS[RefineryScene.resource_path],
			metadata
		):
			return
		if _workers.is_empty():
			return
		_construct_refinery()
	elif metadata == "ore_purifier":
		_number_of_pending_ore_purifier_resource_requests = max(
			0, _number_of_pending_ore_purifier_resource_requests - 1
		)
		if not _resources_match(
			resources,
			Constants.Match.Units.CONSTRUCTION_COSTS[OrePurifierScene.resource_path],
			metadata
		):
			return
		if _workers.is_empty():
			return
		_construct_ore_purifier()
	else:
		push_warning("Ignoring unknown AI economy resource request metadata: {0}".format([metadata]))


func _resources_match(resources, expected_resources, metadata):
	if resources == expected_resources:
		return true
	push_warning(
		"Ignoring AI economy resource provision for {0}: expected {1}, got {2}".format(
			[metadata, expected_resources, resources]
		)
	)
	return false


func _attach_cc(cc):
	if cc in _ccs:
		return
	_ccs.append(cc)
	var died_callable = _on_cc_died.bind(cc)
	if not cc.tree_exited.is_connected(died_callable):
		cc.tree_exited.connect(died_callable)


func _attach_refinery(refinery):
	if refinery in _refineries:
		return
	_refineries.append(refinery)
	var died_callable = _on_refinery_died.bind(refinery)
	if not refinery.tree_exited.is_connected(died_callable):
		refinery.tree_exited.connect(died_callable)


func _attach_ore_purifier(ore_purifier):
	if ore_purifier in _ore_purifiers:
		return
	_ore_purifiers.append(ore_purifier)
	var died_callable = _on_ore_purifier_died.bind(ore_purifier)
	if not ore_purifier.tree_exited.is_connected(died_callable):
		ore_purifier.tree_exited.connect(died_callable)


func _attach_current_ccs():
	var ccs = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is CommandCenter and unit.player == _player
	)
	if not ccs.is_empty():
		_cc_base_position = ccs[0].global_position
	for cc in ccs:
		_attach_cc(cc)


func _attach_current_refineries():
	var refineries = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is Refinery and unit.player == _player
	)
	for refinery in refineries:
		_attach_refinery(refinery)


func _attach_current_ore_purifiers():
	var ore_purifiers = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is OrePurifier and unit.player == _player
	)
	for ore_purifier in ore_purifiers:
		_attach_ore_purifier(ore_purifier)


func _attach_worker(worker):
	if worker in _workers:
		return
	_workers.append(worker)
	worker.tree_exited.connect(_on_worker_died.bind(worker))
	_attach_resource_collector(worker)


func _attach_ore_harvester(harvester):
	if harvester in _ore_harvesters:
		return
	_ore_harvesters.append(harvester)
	harvester.tree_exited.connect(_on_harvester_died.bind(harvester))
	_attach_resource_collector(harvester)


func _attach_resource_collector(collector):
	if collector in _resource_collectors:
		return
	_resource_collectors.append(collector)
	collector.tree_exited.connect(_on_resource_collector_died.bind(collector))
	collector.action_changed.connect(_on_resource_collector_action_changed.bind(collector))
	if collector.action != null:
		return
	_make_resource_collector_collecting_resources(collector)


func _attach_current_resource_units():
	var resource_units = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is Worker and unit.player == _player
	)
	for unit in resource_units:
		if unit.can_construct_structures():
			_attach_worker(unit)
		elif unit is OreHarvester:
			_attach_ore_harvester(unit)


func _enforce_number_of_ccs():
	if (
		_ccs.size() + _number_of_pending_cc_resource_requests + _number_of_pending_workers
		>= _ai.expected_number_of_ccs
	):
		return
	var number_of_extra_ccs_required = (
		_ai.expected_number_of_ccs
		- (_ccs.size() + _number_of_pending_cc_resource_requests + _number_of_pending_workers)
	)
	for _i in range(number_of_extra_ccs_required):
		resources_required.emit(
			Constants.Match.Units.CONSTRUCTION_COSTS[CommandCenterScene.resource_path], "cc"
		)
		_number_of_pending_cc_resource_requests += 1


func _enforce_number_of_refineries():
	if _workers.is_empty():
		return
	if (
		_refineries.size() + _number_of_pending_refinery_resource_requests
		>= _ai.expected_number_of_refineries
	):
		return
	var number_of_extra_refineries_required = (
		_ai.expected_number_of_refineries
		- (_refineries.size() + _number_of_pending_refinery_resource_requests)
	)
	for _i in range(number_of_extra_refineries_required):
		resources_required.emit(
			Constants.Match.Units.CONSTRUCTION_COSTS[RefineryScene.resource_path], "refinery"
		)
		_number_of_pending_refinery_resource_requests += 1


func _enforce_ore_purifier():
	if _workers.is_empty():
		return
	if not _has_constructed_refinery():
		return
	if not Utils.Match.Unit.Tech.can_construct(_player, OrePurifierScene.resource_path):
		return
	if _ore_purifiers.size() + _number_of_pending_ore_purifier_resource_requests >= 1:
		return
	resources_required.emit(
		Constants.Match.Units.CONSTRUCTION_COSTS[OrePurifierScene.resource_path], "ore_purifier"
	)
	_number_of_pending_ore_purifier_resource_requests += 1


func _enforce_number_of_workers():
	if (
		_workers.size() + _number_of_pending_worker_resource_requests
		>= _ai.expected_number_of_workers
	):
		return
	var number_of_extra_workers_required = (
		_ai.expected_number_of_workers
		- (_workers.size() + _number_of_pending_worker_resource_requests)
	)
	for _i in range(number_of_extra_workers_required):
		resources_required.emit(
			Constants.Match.Units.PRODUCTION_COSTS[WorkerScene.resource_path], "worker"
		)
		_number_of_pending_worker_resource_requests += 1


func _enforce_number_of_harvesters():
	if not _has_constructed_refinery():
		return
	if _constructed_vehicle_factory() == null:
		return
	if (
		_ore_harvesters.size()
		+ _number_of_pending_harvester_resource_requests
		+ _number_of_pending_harvesters
		>= _ai.expected_number_of_ore_harvesters
	):
		return
	var number_of_extra_harvesters_required = (
		_ai.expected_number_of_ore_harvesters
		- (
			_ore_harvesters.size()
			+ _number_of_pending_harvester_resource_requests
			+ _number_of_pending_harvesters
		)
	)
	for _i in range(number_of_extra_harvesters_required):
		resources_required.emit(
			Constants.Match.Units.PRODUCTION_COSTS[OreHarvesterScene.resource_path],
			"ore_harvester"
		)
		_number_of_pending_harvester_resource_requests += 1


func _construct_cc():
	var construction_cost = Constants.Match.Units.CONSTRUCTION_COSTS[
		CommandCenterScene.resource_path
	]
	assert(
		_player.has_resources(construction_cost),
		"player should have enough resources at this point"
	)
	var unit_to_spawn = CommandCenterScene.instantiate()
	var placement_position = Utils.Match.Unit.Placement.find_valid_position_radially(
		_cc_base_position if _cc_base_position != null else _workers[0].global_position,
		unit_to_spawn.radius + Constants.Match.Units.EMPTY_SPACE_RADIUS_SURROUNDING_STRUCTURE_M,
		find_parent("Match").navigation.get_navigation_map_rid_by_domain(
			unit_to_spawn.movement_domain
		),
		get_tree()
	)
	var target_transform = _structure_placement_transform(placement_position, Vector3(0, 0, 1))
	if target_transform == null:
		unit_to_spawn.free()
		return
	_player.subtract_resources(construction_cost)
	MatchSignals.setup_and_spawn_unit.emit(unit_to_spawn, target_transform, _player)


func _construct_refinery():
	_construct_structure_near_base(RefineryScene)


func _construct_ore_purifier():
	_construct_structure_near_base(OrePurifierScene)


func _construct_structure_near_base(structure_scene):
	var construction_cost = Constants.Match.Units.CONSTRUCTION_COSTS[structure_scene.resource_path]
	assert(
		_player.has_resources(construction_cost),
		"player should have enough resources at this point"
	)
	var unit_to_spawn = structure_scene.instantiate()
	var placement_position = Utils.Match.Unit.Placement.find_valid_position_radially(
		_cc_base_position if _cc_base_position != null else _workers[0].global_position,
		unit_to_spawn.radius + Constants.Match.Units.EMPTY_SPACE_RADIUS_SURROUNDING_STRUCTURE_M,
		find_parent("Match").navigation.get_navigation_map_rid_by_domain(
			unit_to_spawn.movement_domain
		),
		get_tree()
	)
	var target_transform = _structure_placement_transform(placement_position, Vector3(1, 0, 1))
	if target_transform == null:
		unit_to_spawn.free()
		return
	_player.subtract_resources(construction_cost)
	MatchSignals.setup_and_spawn_unit.emit(unit_to_spawn, target_transform, _player)


func _structure_placement_transform(placement_position, facing_direction):
	if placement_position == Vector3.INF:
		return null
	var normalized_direction = facing_direction * Vector3(1, 0, 1)
	if normalized_direction.is_zero_approx():
		normalized_direction = Vector3(0, 0, 1)
	else:
		normalized_direction = normalized_direction.normalized()
	return Transform3D(Basis(), placement_position).looking_at(
		placement_position + normalized_direction, Vector3.UP
	)


func _calculate_resource_collecting_statistics():
	var number_of_workers_per_resource_kind = {
		"resource_a": 0,
		"resource_b": 0,
	}
	for collector in _resource_collectors:
		if collector.action != null and collector.action is CollectingResourcesSequentially:
			var resource_unit = collector.action.get_resource_unit()
			if resource_unit == null:
				continue
			if "resource_a" in resource_unit:
				number_of_workers_per_resource_kind["resource_a"] += 1
			elif "resource_b" in resource_unit:
				number_of_workers_per_resource_kind["resource_b"] += 1
			else:
				push_warning(
					"Ignoring unknown resource unit while balancing AI collectors: {0}".format(
						[resource_unit.get_path()]
					)
				)
	return number_of_workers_per_resource_kind


func _make_resource_collector_collecting_resources(collector):
	var number_of_workers_per_resource_kind = _calculate_resource_collecting_statistics()
	var resource_filter = null
	if (
		number_of_workers_per_resource_kind["resource_a"] != 0
		or number_of_workers_per_resource_kind["resource_b"] != 0
	):
		if (
			number_of_workers_per_resource_kind["resource_a"]
			<= number_of_workers_per_resource_kind["resource_b"]
		):
			resource_filter = func(resource_unit): return "resource_a" in resource_unit
		else:
			resource_filter = func(resource_unit): return "resource_b" in resource_unit
	var closest_resource_unit = (
		Utils
		. Match
		. Resources
		. find_resource_unit_closest_to_unit_yet_no_further_than(
			collector, Constants.Match.Units.NEW_RESOURCE_SEARCH_RADIUS_M, resource_filter
		)
	)
	if closest_resource_unit != null:
		collector.action = CollectingResourcesSequentially.new(closest_resource_unit)


func _retarget_workers_if_necessary():
	var number_of_workers_per_resource_kind = _calculate_resource_collecting_statistics()
	if (
		abs(
			(
				number_of_workers_per_resource_kind["resource_a"]
				- number_of_workers_per_resource_kind["resource_b"]
			)
		)
		>= 2
	):
		for collector in _resource_collectors:
			_make_resource_collector_collecting_resources(collector)


func _has_constructed_refinery():
	return _refineries.any(func(refinery): return refinery.is_constructed())


func _constructed_vehicle_factory():
	var vehicle_factories = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is VehicleFactory and unit.player == _player and unit.is_constructed()
	)
	return vehicle_factories[0] if not vehicle_factories.is_empty() else null


func _on_cc_died(cc):
	if not is_inside_tree():
		return
	_ccs.erase(cc)
	_enforce_number_of_ccs()


func _on_refinery_died(refinery):
	if not is_inside_tree():
		return
	_refineries.erase(refinery)
	_enforce_number_of_refineries()
	_enforce_ore_purifier()


func _on_ore_purifier_died(ore_purifier):
	if not is_inside_tree():
		return
	_ore_purifiers.erase(ore_purifier)
	_enforce_ore_purifier()


func _on_worker_died(worker):
	if not is_inside_tree():
		return
	_workers.erase(worker)
	_enforce_number_of_workers()
	_enforce_number_of_refineries()
	_retarget_workers_if_necessary()


func _on_harvester_died(harvester):
	if not is_inside_tree():
		return
	_ore_harvesters.erase(harvester)
	_enforce_number_of_harvesters()


func _on_resource_collector_died(collector):
	if not is_inside_tree():
		return
	_resource_collectors.erase(collector)
	_retarget_workers_if_necessary()


func _on_unit_spawned(unit):
	if unit.player != _player:
		return
	if unit is Worker:
		if unit.can_construct_structures():
			if _number_of_pending_workers > 0:
				_number_of_pending_workers -= 1
			_attach_worker(unit)
			_enforce_number_of_refineries()
			_enforce_ore_purifier()
		elif unit is OreHarvester:
			if _number_of_pending_harvesters > 0:
				_number_of_pending_harvesters -= 1
			_attach_ore_harvester(unit)
			_enforce_number_of_harvesters()
	elif unit is CommandCenter:
		_attach_cc(unit)
	elif unit is Refinery:
		_attach_refinery(unit)
	elif unit is OrePurifier:
		_attach_ore_purifier(unit)


func _on_unit_construction_finished(unit):
	if unit.player != _player:
		return
	if unit is Refinery:
		_enforce_number_of_harvesters()
		_enforce_ore_purifier()
	elif unit is VehicleFactory:
		_enforce_number_of_harvesters()
	else:
		_enforce_ore_purifier()


func _on_unit_captured(unit, previous_player, new_player):
	if previous_player == _player and unit is CommandCenter:
		_ccs.erase(unit)
		_enforce_number_of_ccs()
	if new_player == _player and unit is CommandCenter:
		_attach_cc(unit)
		_cc_base_position = unit.global_position
		_enforce_number_of_ccs()
	if previous_player == _player and unit is Refinery:
		_refineries.erase(unit)
		_enforce_number_of_refineries()
		_enforce_ore_purifier()
	if new_player == _player and unit is Refinery:
		_attach_refinery(unit)
		_enforce_number_of_refineries()
		_enforce_number_of_harvesters()
		_enforce_ore_purifier()
	if previous_player == _player and unit is OrePurifier:
		_ore_purifiers.erase(unit)
		_enforce_ore_purifier()
	if new_player == _player and unit is OrePurifier:
		_attach_ore_purifier(unit)


func _on_resource_collector_action_changed(new_action, collector):
	if new_action != null:
		return
	_make_resource_collector_collecting_resources(collector)
