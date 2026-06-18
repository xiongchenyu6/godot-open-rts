extends "res://tests/manual/Match.gd"

const Capturing = preload("res://source/match/units/actions/Capturing.gd")

const TEST_SABOTAGE_DURATION_S = 0.45

@onready var _human = $Players/Human
@onready var _enemy = $Players/Enemy
@onready var _saboteur = $Players/Human/SaboteurInfiltrator
@onready var _enemy_power_reactor = $Players/Enemy/PowerReactor
@onready var _enemy_turret = $Players/Enemy/AntiGroundTurret


func _ready():
	super()
	for _i in range(4):
		await get_tree().process_frame

	_saboteur.infiltration_power_sabotage_duration = TEST_SABOTAGE_DURATION_S
	_enemy_turret.attack_damage = 0

	_assert(
		not _enemy.is_low_power(),
		"test setup should start the enemy with enough power"
	)
	_assert(
		not _enemy.is_power_sabotaged(),
		"test setup should start without active power sabotage"
	)
	_assert(
		_enemy.get_power_supply() == 26,
		"enemy should start with command-center and reactor power supply"
	)
	_assert(
		_enemy.get_power_drain() == 8,
		"enemy should start with barracks and turret power drain"
	)
	_assert(
		Capturing.is_applicable(_saboteur, _enemy_power_reactor),
		"saboteur infiltrator should be able to infiltrate enemy power structures"
	)

	_saboteur.find_child("Selection").select()
	MatchSignals.unit_targeted.emit(_enemy_power_reactor)
	if not await _wait_until(
		func(): return is_instance_valid(_enemy_power_reactor) and _enemy_power_reactor.player == _human,
		8.0,
		_power_sabotage_failure_state()
	):
		return

	_assert(_enemy.is_power_sabotaged(), "power infiltration should sabotage the previous owner")
	_assert(_enemy.get_power_supply() == 0, "sabotaged players should temporarily lose supply")
	_assert(_enemy.is_low_power(), "power sabotage should force the victim into low power")
	_assert(
		_enemy.get_production_speed_multiplier()
		== Constants.Match.Power.LOW_POWER_PRODUCTION_SPEED_MULTIPLIER,
		"power sabotage should apply the existing low-power production penalty"
	)
	_assert(
		_enemy_turret.is_powered_combat_offline(),
		"power sabotage should turn powered defenses offline"
	)
	_assert(
		not is_instance_valid(_saboteur),
		"saboteur infiltrator should be consumed after power infiltration"
	)

	if not await _wait_until(
		func(): return not _enemy.is_power_sabotaged(),
		2.0,
		"power sabotage should expire after its configured duration"
	):
		return
	_assert(_enemy.get_power_supply() == 8, "enemy should recover remaining command-center supply")
	_assert(not _enemy.is_low_power(), "enemy should leave low power after sabotage expires")
	_assert(
		not _enemy_turret.is_powered_combat_offline(),
		"powered defenses should come back online after sabotage expires"
	)
	get_tree().quit()


func _assert(condition, message):
	if condition:
		return true
	push_error(message)
	get_tree().quit(1)
	return false


func _power_sabotage_failure_state():
	var saboteur_state = "freed"
	if is_instance_valid(_saboteur):
		saboteur_state = "hp={0}, action={1}, distance={2}".format(
			[
				_saboteur.hp,
				str(_saboteur.action),
				_saboteur.global_position_yless.distance_to(_enemy_power_reactor.global_position_yless),
			]
		)
	var reactor_owner = _enemy_power_reactor.player.name if is_instance_valid(_enemy_power_reactor) else "freed"
	return (
		"saboteur should finish infiltrating the enemy power reactor; "
		+ "saboteur={0}, reactor_owner={1}, enemy_sabotaged={2}"
	).format([saboteur_state, reactor_owner, _enemy.is_power_sabotaged()])


func _wait_until(condition, timeout_s, message):
	var deadline = Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if condition.call():
			return true
		await get_tree().process_frame
	if not condition.call():
		push_error(message)
		get_tree().quit(1)
		return false
	return true
