extends "res://tests/manual/Match.gd"

const MovingAction = preload("res://source/match/units/actions/Moving.gd")
const AttackMovingAction = preload("res://source/match/units/actions/AttackMoving.gd")
const PatrollingAction = preload("res://source/match/units/actions/Patrolling.gd")
const FollowingAction = preload("res://source/match/units/actions/Following.gd")
const MovingToUnitAction = preload("res://source/match/units/actions/MovingToUnit.gd")

@onready var _human_player = $Players/Human
@onready var _test_camera = $IsometricCamera3D


func _ready():
	super()
	_test_camera.screen_margin_for_movement = -1
	for _i in range(12):
		await get_tree().physics_frame

	var human_units = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit.player == _human_player
	)
	_assert(not human_units.is_empty(), "human player should have starting units")
	for unit in human_units:
		_assert(
			not _is_manual_movement_action(unit.action),
			"human starting unit should not receive an automatic movement order: {0}".format(
				[unit.name]
			)
		)
	_assert(
		_selected_controlled_units().is_empty(),
		"match start should not auto-select controlled units"
	)

	get_tree().quit()


func _is_manual_movement_action(action):
	return (
		action is MovingAction
		or action is AttackMovingAction
		or action is PatrollingAction
		or action is FollowingAction
		or action is MovingToUnitAction
	)


func _selected_controlled_units():
	return get_tree().get_nodes_in_group("selected_units").filter(
		func(unit): return unit.is_in_group("controlled_units")
	)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
