extends Node

const Structure = preload("res://source/match/units/Structure.gd")
const Worker = preload("res://source/match/units/Worker.gd")
const Constructing = preload("res://source/match/units/actions/Constructing.gd")

const REFRESH_INTERVAL_S = 1.0 / 60.0 * 30.0

var _player = null


func setup(player):
	_player = player
	_setup_refresh_timer()


func _setup_refresh_timer():
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_refresh_timer_timeout)
	timer.start(REFRESH_INTERVAL_S)


func _on_refresh_timer_timeout():
	var workers = get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return unit is Worker and unit.can_construct_structures() and unit.player == _player
	)
	if workers.any(func(worker): return worker.action != null and worker.action is Constructing):
		return
	var structures_to_construct = get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return unit is Structure and not unit.is_constructed() and unit.player == _player
	)
	if not structures_to_construct.is_empty() and not workers.is_empty():
		var assignment = _closest_worker_structure_assignment(workers, structures_to_construct)
		assignment["worker"].action = Constructing.new(assignment["structure"])


func _closest_worker_structure_assignment(workers, structures):
	var best_worker = workers[0]
	var best_structure = structures[0]
	var best_distance = INF
	for worker in workers:
		for structure in structures:
			var distance = worker.global_position_yless.distance_to(structure.global_position_yless)
			if distance < best_distance:
				best_distance = distance
				best_worker = worker
				best_structure = structure
	return {"worker": best_worker, "structure": best_structure}
