extends "res://tests/manual/Match.gd"

const AutoAttacking = preload("res://source/match/units/actions/AutoAttacking.gd")
const AutoAttackingBattlegroup = preload(
	"res://source/match/players/simple-clairvoyant-ai/AutoAttackingBattlegroup.gd"
)

const TIMEOUT_S = 1.0

@onready var _tank = $Players/Human/Tank
@onready var _enemy_player = $Players/Enemy
@onready var _enemy_command_center = $Players/Enemy/CommandCenter


func _ready():
	super()
	await get_tree().process_frame

	var battlegroup = AutoAttackingBattlegroup.new(1, [_enemy_player])
	add_child(battlegroup)
	battlegroup.attach_unit(_tank)

	await _wait_until(
		_tank_attacks_enemy_command_center,
		TIMEOUT_S,
		"AI battlegroup should initially assign its target to the attached tank"
	)

	_tank.action = null

	await _wait_until(
		_tank_attacks_enemy_command_center,
		TIMEOUT_S,
		"AI battlegroup should restore an attached unit action when it is interrupted"
	)
	get_tree().quit()


func _tank_attacks_enemy_command_center():
	return _tank.action is AutoAttacking and _tank.action._target_unit == _enemy_command_center


func _wait_until(condition, timeout_s, message):
	var started_at_msec = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at_msec < timeout_s * 1000.0:
		if condition.call():
			return
		await get_tree().process_frame
	assert(false, message)
