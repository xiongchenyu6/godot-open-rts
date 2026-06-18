extends "res://tests/manual/Match.gd"

const PowerReactorUnit = preload("res://source/match/units/PowerReactor.tscn")

@onready var _human = $Players/Human
@onready var _turret = $Players/Human/AntiGroundTurret
@onready var _target = $Players/Enemy/Tank


func _ready():
	super()
	await get_tree().process_frame
	await get_tree().physics_frame

	_assert(_human.is_low_power(), "test setup should start the human player in low power")
	_assert(
		_turret.is_powered_combat_offline(),
		"powered defense should report offline while the base is in low power"
	)
	var hp_before_low_power_wait = _target.hp
	await get_tree().create_timer(0.75).timeout
	_assert(
		_target.hp == hp_before_low_power_wait,
		"powered defense should not fire while the owning player is in low power"
	)

	var power_reactor = PowerReactorUnit.instantiate()
	_setup_and_spawn_unit(
		power_reactor,
		Transform3D(Basis(), Vector3(7.0, 0.0, 15.0)),
		_human,
		false
	)
	await get_tree().process_frame
	_assert(not _human.is_low_power(), "adding a power reactor should restore base power")

	await _wait_until(
		func(): return _target.hp < hp_before_low_power_wait,
		2.0,
		"powered defense should resume firing after power is restored"
	)
	get_tree().quit()


func _wait_until(condition, timeout_s, message):
	var started_at_msec = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at_msec < timeout_s * 1000.0:
		if condition.call():
			return
		await get_tree().process_frame
	_assert(false, message)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
