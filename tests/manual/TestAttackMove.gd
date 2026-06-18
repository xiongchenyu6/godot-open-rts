extends "res://tests/manual/Match.gd"

const AttackMoving = preload("res://source/match/units/actions/AttackMoving.gd")

const TARGET_KILL_TIMEOUT_S = 10.0
const RESUME_TIMEOUT_S = 5.0
const FINISH_TIMEOUT_S = 30.0
const DESTINATION_REACHED_DISTANCE = 2.0
const RESUME_PROGRESS_DISTANCE = 0.5

var _destination = Vector3(24.0, 0.0, 10.0)

@onready var _attacker = $Players/Human/Tank
@onready var _target = $Players/Player/Tank


func _ready():
	super()
	await get_tree().process_frame

	_target.hp = _attacker.attack_damage
	_attacker.find_child("Selection").select()
	await get_tree().process_frame
	MatchSignals.attack_move_requested.emit()
	MatchSignals.terrain_targeted.emit(_destination)
	await get_tree().process_frame
	assert(_attacker.action is AttackMoving, "attack-move command should arm targeting from the HUD")

	await _wait_until(
		func(): return not is_instance_valid(_target) or not _target.is_inside_tree(),
		TARGET_KILL_TIMEOUT_S,
		"attack-move should engage and destroy visible enemies along the route"
	)
	assert(_attacker.experience_points == 1, "attack-move kill should grant experience")

	var distance_after_engagement = _distance_to_destination()
	await _wait_until(
		func(): return _distance_to_destination() < distance_after_engagement - RESUME_PROGRESS_DISTANCE,
		RESUME_TIMEOUT_S,
		"attack-move should make movement progress after clearing the enemy"
	)

	await _wait_until(
		func(): return not (_attacker.action is AttackMoving),
		FINISH_TIMEOUT_S,
		"attack-move should finish moving after clearing the enemy"
	)
	assert(
		_distance_to_destination() < DESTINATION_REACHED_DISTANCE,
		"attack-move should finish at its destination"
	)
	get_tree().quit()


func _distance_to_destination():
	return _attacker.global_position_yless.distance_to(_destination * Vector3(1, 0, 1))


func _wait_until(condition, timeout_s, message):
	var started_at_msec = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at_msec < timeout_s * 1000.0:
		if condition.call():
			return
		await get_tree().process_frame
	push_error(
		"{0}; attacker_position={1}; destination={2}; distance={3}; action={4}".format(
			[
				message,
				_attacker.global_position,
				_destination,
				_distance_to_destination(),
				str(_attacker.action),
			]
		)
	)
	get_tree().quit(1)
