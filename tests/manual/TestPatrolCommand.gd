extends "res://tests/manual/Match.gd"

const Patrolling = preload("res://source/match/units/actions/Patrolling.gd")

const TIMEOUT_S = 12.0

var _destination = Vector3(16.0, 0.0, 10.0)

@onready var _patroller = $Players/Human/Tank
@onready var _target = $Players/Player/Tank


func _ready():
	super()
	await get_tree().process_frame

	_target.hp = _patroller.attack_damage
	_patroller.find_child("Selection").select()
	await get_tree().process_frame
	MatchSignals.patrol_requested.emit()
	MatchSignals.terrain_targeted.emit(_destination)
	await get_tree().process_frame
	assert(_patroller.action is Patrolling, "patrol command should arm targeting from the HUD")

	await _wait_until(
		func(): return not is_instance_valid(_target) or not _target.is_inside_tree(),
		TIMEOUT_S,
		"patrol should engage and destroy visible enemies along the route"
	)
	assert(_patroller.action is Patrolling, "patrol should continue after clearing the enemy")
	assert(_patroller.experience_points == 1, "patrol kill should grant experience")

	await _wait_until(
		func(): return _patroller.action is Patrolling and not _patroller.action.is_moving_to_patrol_position(),
		TIMEOUT_S,
		"patrol should complete the first leg and turn back"
	)
	assert(_patroller.action is Patrolling, "patrol should continue after reaching the endpoint")

	await _wait_until(
		func(): return _patroller.action is Patrolling and _patroller.action.is_moving_to_patrol_position(),
		TIMEOUT_S,
		"patrol should return to its origin leg and keep cycling"
	)
	assert(_patroller.action is Patrolling, "patrol should keep cycling between endpoints")
	get_tree().quit()


func _wait_until(condition, timeout_s, message):
	var started_at_msec = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at_msec < timeout_s * 1000.0:
		if condition.call():
			return
		await get_tree().process_frame
	assert(false, message)
