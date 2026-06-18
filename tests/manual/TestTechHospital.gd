extends "res://tests/manual/Match.gd"

const Capturing = preload("res://source/match/units/actions/Capturing.gd")

@onready var _human = $Players/Human
@onready var _neutral = $Players/NeutralTech
@onready var _engineer_drone = $Players/Human/EngineerDrone
@onready var _hospital = $Players/NeutralTech/TechHospital
@onready var _friendly_infantry = $Players/Human/LightRifleInfantry
@onready var _friendly_tank = $Players/Human/Tank
@onready var _enemy_medic = $Players/Enemy/FieldMedic
@onready var _far_infantry = $Players/Human/FarFieldMedic


func _ready():
	super()
	await get_tree().process_frame

	_make_passive(_friendly_infantry)
	_make_passive(_friendly_tank)
	_make_passive(_enemy_medic)
	_make_passive(_far_infantry)

	assert(not _neutral.participates_in_match, "neutral hospital owner should not participate")
	assert(
		Capturing.is_applicable(_engineer_drone, _hospital),
		"engineer drone should be able to capture neutral tech hospital"
	)

	_engineer_drone.action = Capturing.new(_hospital)
	if not await _wait_until(
		func():
			return _hospital.player == _human and not is_instance_valid(_engineer_drone),
		8.0,
		"engineer drone should capture neutral tech hospital"
	):
		return

	assert(_hospital.player == _human, "captured tech hospital should belong to human")
	assert(_hospital.is_in_group("controlled_units"), "captured tech hospital should be controllable")
	assert(
		not is_instance_valid(_engineer_drone),
		"engineer drone should be consumed after capturing tech hospital"
	)

	_friendly_infantry.global_position = _hospital.global_position + Vector3(1.0, 0.0, 0.0)
	_friendly_tank.global_position = _hospital.global_position + Vector3(1.4, 0.0, 1.0)
	_enemy_medic.global_position = _hospital.global_position + Vector3(0.0, 0.0, 4.0)
	_far_infantry.global_position = _hospital.global_position + Vector3(14.0, 0.0, 0.0)
	_friendly_infantry.process_mode = Node.PROCESS_MODE_DISABLED
	_friendly_tank.process_mode = Node.PROCESS_MODE_DISABLED
	_enemy_medic.process_mode = Node.PROCESS_MODE_DISABLED
	_far_infantry.process_mode = Node.PROCESS_MODE_DISABLED
	_friendly_infantry.hp = 1.0
	_friendly_tank.hp = 1.0
	_enemy_medic.hp = 1.0
	_far_infantry.hp = 1.0
	var friendly_infantry_hp = _friendly_infantry.hp
	var friendly_tank_hp = _friendly_tank.hp
	var enemy_medic_hp = _enemy_medic.hp
	var far_infantry_hp = _far_infantry.hp

	assert(_hospital._can_heal(_friendly_infantry), "tech hospital should accept nearby friendly infantry")
	assert(not _hospital._can_heal(_friendly_tank), "tech hospital should reject vehicles")
	assert(not _hospital._can_heal(_enemy_medic), "tech hospital should reject enemy infantry")
	assert(not _hospital._can_heal(_far_infantry), "tech hospital should reject far infantry")

	await get_tree().create_timer(1.25).timeout

	assert(
		_friendly_infantry.hp > friendly_infantry_hp + 0.5,
		"captured tech hospital should heal nearby friendly infantry"
	)
	assert(_friendly_tank.hp == friendly_tank_hp, "tech hospital should not heal vehicles")
	assert(_enemy_medic.hp == enemy_medic_hp, "tech hospital should not heal enemy infantry")
	assert(
		_far_infantry.hp == far_infantry_hp,
		"tech hospital should not heal infantry outside radius: hp {0}->{1}, distance {2}, can_heal={3}".format(
			[
				far_infantry_hp,
				_far_infantry.hp,
				_hospital.global_position_yless.distance_to(_far_infantry.global_position_yless),
				_hospital._can_heal(_far_infantry),
			]
		)
	)

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
