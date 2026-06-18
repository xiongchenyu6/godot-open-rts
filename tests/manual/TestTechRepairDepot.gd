extends "res://tests/manual/Match.gd"

const Capturing = preload("res://source/match/units/actions/Capturing.gd")

@onready var _human = $Players/Human
@onready var _neutral = $Players/NeutralTech
@onready var _engineer_drone = $Players/Human/EngineerDrone
@onready var _repair_depot = $Players/NeutralTech/TechRepairDepot
@onready var _friendly_tank = $Players/Human/Tank
@onready var _friendly_infantry = $Players/Human/LightRifleInfantry
@onready var _friendly_helicopter = $Players/Human/Helicopter
@onready var _far_tank = $Players/Human/FarTank
@onready var _enemy_tank = $Players/Enemy/Tank


func _ready():
	super()
	await get_tree().process_frame

	_make_passive(_friendly_tank)
	_make_passive(_friendly_infantry)
	_make_passive(_friendly_helicopter)
	_make_passive(_far_tank)
	_make_passive(_enemy_tank)

	assert(not _neutral.participates_in_match, "neutral repair depot owner should not participate")
	assert(
		Capturing.is_applicable(_engineer_drone, _repair_depot),
		"engineer drone should be able to capture neutral tech repair depot"
	)

	_engineer_drone.action = Capturing.new(_repair_depot)
	if not await _wait_until(
		func():
			return _repair_depot.player == _human and not is_instance_valid(_engineer_drone),
		8.0,
		"engineer drone should capture neutral tech repair depot"
	):
		return

	assert(_repair_depot.player == _human, "captured tech repair depot should belong to human")
	assert(_repair_depot.is_in_group("controlled_units"), "captured repair depot should be controllable")
	assert(
		not is_instance_valid(_engineer_drone),
		"engineer drone should be consumed after capturing tech repair depot"
	)

	_friendly_tank.global_position = _repair_depot.global_position + Vector3(1.0, 0.0, 0.0)
	_friendly_infantry.global_position = _repair_depot.global_position + Vector3(1.4, 0.0, 0.8)
	_friendly_helicopter.global_position = _repair_depot.global_position + Vector3(0.0, 0.0, 1.5)
	_enemy_tank.global_position = _repair_depot.global_position + Vector3(0.0, 0.0, 3.0)
	_far_tank.global_position = _repair_depot.global_position + Vector3(14.0, 0.0, 0.0)
	_friendly_tank.process_mode = Node.PROCESS_MODE_DISABLED
	_friendly_infantry.process_mode = Node.PROCESS_MODE_DISABLED
	_friendly_helicopter.process_mode = Node.PROCESS_MODE_DISABLED
	_enemy_tank.process_mode = Node.PROCESS_MODE_DISABLED
	_far_tank.process_mode = Node.PROCESS_MODE_DISABLED
	_friendly_tank.hp = 1.0
	_friendly_infantry.hp = 1.0
	_friendly_helicopter.hp = 1.0
	_enemy_tank.hp = 1.0
	_far_tank.hp = 1.0
	var friendly_tank_hp = _friendly_tank.hp
	var friendly_infantry_hp = _friendly_infantry.hp
	var friendly_helicopter_hp = _friendly_helicopter.hp
	var enemy_tank_hp = _enemy_tank.hp
	var far_tank_hp = _far_tank.hp

	assert(_repair_depot._can_repair(_friendly_tank), "repair depot should accept friendly tanks")
	assert(not _repair_depot._can_repair(_friendly_infantry), "repair depot should reject infantry")
	assert(not _repair_depot._can_repair(_friendly_helicopter), "repair depot should reject aircraft")
	assert(not _repair_depot._can_repair(_enemy_tank), "repair depot should reject enemy vehicles")
	assert(not _repair_depot._can_repair(_far_tank), "repair depot should reject far vehicles")

	await get_tree().create_timer(1.25).timeout

	assert(
		_friendly_tank.hp > friendly_tank_hp + 1.0,
		"captured repair depot should repair nearby friendly ground vehicles"
	)
	assert(_friendly_infantry.hp == friendly_infantry_hp, "repair depot should not repair infantry")
	assert(_friendly_helicopter.hp == friendly_helicopter_hp, "repair depot should not repair aircraft")
	assert(_enemy_tank.hp == enemy_tank_hp, "repair depot should not repair enemy vehicles")
	assert(_far_tank.hp == far_tank_hp, "repair depot should not repair vehicles outside radius")

	get_tree().quit()


func _make_passive(unit):
	unit.hold_position = true
	unit.attack_domains = []
	if unit.has_method("clear_action_queue"):
		unit.clear_action_queue()
	unit.action = null
	var movement = unit.find_child("Movement")
	if movement != null:
		movement.stop()
	unit.process_mode = Node.PROCESS_MODE_DISABLED


func _wait_until(condition, timeout_s, message):
	var deadline = Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if condition.call():
			return true
		await get_tree().process_frame
	push_error(message)
	get_tree().quit(1)
	return false
