extends "res://tests/manual/Match.gd"

const AttackMoving = preload("res://source/match/units/actions/AttackMoving.gd")
const Moving = preload("res://source/match/units/actions/Moving.gd")
const Patrolling = preload("res://source/match/units/actions/Patrolling.gd")
const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")

const POSITION_EPSILON = 0.01

@onready var _tank = $Players/Human/Tank
var _action_queue_visualizer = null


func _ready():
	super()
	await get_tree().process_frame
	await get_tree().process_frame
	_action_queue_visualizer = get_node("Handlers/ActionQueueVisualizer")

	_tank.find_child("Selection").select()
	await get_tree().process_frame

	var first_destination = Vector3(16.0, 0.0, 10.0)
	MatchSignals.terrain_targeted.emit(first_destination)
	await get_tree().process_frame

	var first_action = _tank.action
	_assert(first_action is Moving, "normal terrain targeting should assign a moving action")
	_assert(not _tank.has_queued_actions(), "normal terrain targeting should not queue actions")
	_assert_position(first_action._target_position, first_destination, "normal move target")

	var second_destination = Vector3(20.0, 0.0, 10.0)
	_queue_terrain_target(second_destination)
	await get_tree().process_frame

	_assert(_tank.action == first_action, "Shift terrain targeting should keep current action active")
	_assert(_tank.action_queue.size() == 1, "Shift terrain targeting should append one action")
	_assert(_tank.action_queue[0] is Moving, "Shift terrain targeting should queue movement")
	_assert_position(_tank.action_queue[0]._target_position, second_destination, "queued move target")

	var attack_move_destination = Vector3(24.0, 0.0, 10.0)
	_queue_attack_move_target(attack_move_destination)
	await get_tree().process_frame

	_assert(_tank.action_queue.size() == 2, "Shift attack-move should append behind queued movement")
	_assert(_tank.action_queue[1] is AttackMoving, "Shift attack-move should queue attack-moving")
	_assert_position(
		_tank.action_queue[1]._target_position,
		attack_move_destination,
		"queued attack-move target"
	)

	var patrol_destination = Vector3(28.0, 0.0, 10.0)
	_queue_patrol_target(patrol_destination)
	await get_tree().process_frame

	_assert(_tank.action_queue.size() == 3, "Shift patrol should append behind other queued actions")
	_assert(_tank.action_queue[2] is Patrolling, "Shift patrol should queue patrolling")
	_assert_position(
		_tank.action_queue[2]._patrol_position,
		patrol_destination,
		"queued patrol target"
	)
	_assert_visualized_path(
		[first_destination, second_destination, attack_move_destination, patrol_destination],
		"visualized queued terrain command path"
	)

	first_action.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	_assert(_tank.action is Moving, "finished action should start the next queued action")
	_assert(_tank.action != first_action, "started queued action should be a different node")
	_assert_position(_tank.action._target_position, second_destination, "started queued move target")
	_assert(_tank.action_queue.size() == 2, "starting the next action should remove it from the queue")
	_assert_visualized_path(
		[second_destination, attack_move_destination, patrol_destination],
		"visualized path after starting the next queued action"
	)

	var replacement_destination = Vector3(12.0, 0.0, 18.0)
	MatchSignals.terrain_targeted.emit(replacement_destination)
	await get_tree().process_frame

	_assert(_tank.action is Moving, "normal terrain targeting should replace queued command chains")
	_assert_position(_tank.action._target_position, replacement_destination, "replacement move target")
	_assert(not _tank.has_queued_actions(), "normal terrain targeting should clear queued commands")
	_assert_visualized_path([replacement_destination], "visualized replacement terrain command")

	var queued_destination = Vector3(18.0, 0.0, 18.0)
	_queue_terrain_target(queued_destination)
	await get_tree().process_frame
	_assert(_tank.has_queued_actions(), "test setup should have a queued command before cancel")

	Utils.Match.UnitCommands.cancel_current_actions([_tank])
	await get_tree().process_frame

	_assert(
		_tank.action is WaitingForTargets and _tank.action.is_idle(),
		"cancel current action should return combat units to idle target-watching"
	)
	_assert(not _tank.has_queued_actions(), "cancel current action should clear queued commands")
	_assert(
		_action_queue_visualizer.get_path_points_for_unit(_tank).is_empty(),
		"cancel current action should clear visualized queued commands"
	)
	get_tree().quit()


func _queue_terrain_target(position):
	Input.action_press("shift_selecting")
	MatchSignals.terrain_targeted.emit(position)
	Input.action_release("shift_selecting")


func _queue_attack_move_target(position):
	Input.action_press("shift_selecting")
	MatchSignals.attack_move_requested.emit()
	MatchSignals.terrain_targeted.emit(position)
	Input.action_release("shift_selecting")


func _queue_patrol_target(position):
	Input.action_press("shift_selecting")
	MatchSignals.patrol_requested.emit()
	MatchSignals.terrain_targeted.emit(position)
	Input.action_release("shift_selecting")


func _assert_position(actual, expected, label):
	_assert(
		actual.distance_to(expected) <= POSITION_EPSILON,
		"{0} should be {1}, got {2}".format([label, expected, actual])
	)


func _assert_visualized_path(expected_targets, label):
	var points = _action_queue_visualizer.get_path_points_for_unit(_tank)
	_assert(
		points.size() == expected_targets.size() + 1,
		"{0} should include unit origin plus {1} target points, got {2}".format(
			[label, expected_targets.size(), points.size()]
		)
	)
	for index in range(expected_targets.size()):
		_assert_position(points[index + 1], expected_targets[index], "{0} target {1}".format(
			[label, index]
		))


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
