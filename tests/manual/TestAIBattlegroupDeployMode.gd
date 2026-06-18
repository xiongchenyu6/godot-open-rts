extends "res://tests/manual/Match.gd"

const AutoAttacking = preload("res://source/match/units/actions/AutoAttacking.gd")
const AutoAttackingBattlegroup = preload(
	"res://source/match/players/simple-clairvoyant-ai/AutoAttackingBattlegroup.gd"
)

@onready var _drill = $Players/Human/SiegeDrillTank
@onready var _enemy_player = $Players/Enemy
@onready var _enemy_command_center = $Players/Enemy/CommandCenter


func _ready():
	super()
	await get_tree().process_frame

	_enemy_command_center.global_position = _drill.global_position + Vector3(5.2, 0.0, 0.0)

	var battlegroup = AutoAttackingBattlegroup.new(1, [_enemy_player])
	add_child(battlegroup)
	battlegroup.attach_unit(_drill)
	await get_tree().process_frame

	assert(
		_drill.is_deployed_mode(),
		"AI siege drill tanks should deploy when a structure is inside deployed range"
	)
	assert(
		_drill.action is AutoAttacking,
		"AI deployed siege drill tanks should attack the structure from anchor mode"
	)

	_enemy_command_center.global_position = _drill.global_position + Vector3(18.0, 0.0, 0.0)
	battlegroup._assign_actions_for_current_target()
	await get_tree().process_frame

	assert(
		not _drill.is_deployed_mode(),
		"AI siege drill tanks should pack up when the target leaves deployed range"
	)
	assert(
		_drill.action is AutoAttacking,
		"AI siege drill tanks should chase out-of-range structure targets after packing up"
	)
	get_tree().quit()
