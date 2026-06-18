extends "res://tests/manual/Match.gd"

const AutoAttackingBattlegroup = preload(
	"res://source/match/players/simple-clairvoyant-ai/AutoAttackingBattlegroup.gd"
)
const Repairing = preload("res://source/match/units/actions/Repairing.gd")

const TIMEOUT_S = 4.0

@onready var _tank = $Players/Human/Tank
@onready var _repair_crawler = $Players/Human/MobileRepairCrawler
@onready var _enemy_player = $Players/Player


func _ready():
	super()
	await get_tree().process_frame

	var battlegroup = AutoAttackingBattlegroup.new(2, [_enemy_player])
	add_child(battlegroup)

	_tank.hp = max(1.0, _tank.hp_max - 4.0)
	var damaged_hp = _tank.hp
	battlegroup.attach_unit(_tank)
	battlegroup.attach_unit(_repair_crawler)

	await get_tree().process_frame
	assert(
		_repair_crawler.action is Repairing,
		"AI support unit should repair damaged battlegroup allies before following attacks"
	)

	await _wait_until(
		func(): return _tank.hp > damaged_hp,
		TIMEOUT_S,
		"AI support unit should restore hit points to the damaged ally"
	)
	_tank.hp = max(1.0, _tank.hp - 2.0)
	var second_damaged_hp = _tank.hp
	await get_tree().process_frame
	assert(
		_repair_crawler.action is Repairing,
		"AI support unit should keep or re-enter repair mode when battlegroup allies take fresh damage"
	)
	await _wait_until(
		func(): return _tank.hp > second_damaged_hp,
		TIMEOUT_S,
		"AI support unit should keep repairing after repeated damage"
	)
	get_tree().quit()


func _wait_until(condition, timeout_s, message):
	var started_at_msec = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at_msec < timeout_s * 1000.0:
		if condition.call():
			return
		await get_tree().process_frame
	assert(false, message)
