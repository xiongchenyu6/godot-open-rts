extends "res://tests/manual/Match.gd"

const Capturing = preload("res://source/match/units/actions/Capturing.gd")

@onready var _human = $Players/Human
@onready var _enemy = $Players/Enemy
@onready var _saboteur = $Players/Human/SaboteurInfiltrator
@onready var _enemy_refinery = $Players/Enemy/Refinery


func _ready():
	super()
	for _i in range(4):
		await get_tree().process_frame

	var human_resource_a_before = _human.resource_a
	var human_resource_b_before = _human.resource_b
	var enemy_resource_a_before = _enemy.resource_a
	var enemy_resource_b_before = _enemy.resource_b
	var expected_resource_a_stolen = _expected_steal(enemy_resource_a_before)
	var expected_resource_b_stolen = _expected_steal(enemy_resource_b_before)

	_assert(
		Capturing.is_applicable(_saboteur, _enemy_refinery),
		"saboteur infiltrator should be able to infiltrate enemy economy structures"
	)
	_assert(
		_saboteur.infiltration_resource_steal_ratio
		== Constants.Match.Capture.SABOTEUR_RESOURCE_STEAL_RATIO,
		"saboteur should expose configured resource steal ratio"
	)

	_saboteur.action = Capturing.new(_enemy_refinery)
	if not await _wait_until(
		func(): return is_instance_valid(_enemy_refinery) and _enemy_refinery.player == _human,
		8.0,
		"saboteur should finish infiltrating the enemy refinery"
	):
		return

	_assert(_enemy.get_node_or_null("Refinery") == null, "captured refinery should leave enemy")
	_assert(
		$Players/Human.get_node_or_null("Refinery") == _enemy_refinery,
		"captured refinery should join human"
	)
	_assert(_enemy_refinery.player == _human, "captured refinery should report new owner")
	_assert(
		not is_instance_valid(_saboteur),
		"saboteur infiltrator should be consumed after a successful infiltration capture"
	)
	_assert(
		_human.resource_a == human_resource_a_before + expected_resource_a_stolen,
		"saboteur should transfer stolen resource A to the capturing player"
	)
	_assert(
		_human.resource_b == human_resource_b_before + expected_resource_b_stolen,
		"saboteur should transfer stolen resource B to the capturing player"
	)
	_assert(
		_enemy.resource_a == enemy_resource_a_before - expected_resource_a_stolen,
		"saboteur should remove stolen resource A from the previous owner"
	)
	_assert(
		_enemy.resource_b == enemy_resource_b_before - expected_resource_b_stolen,
		"saboteur should remove stolen resource B from the previous owner"
	)
	get_tree().quit()


func _expected_steal(available):
	if available <= 0:
		return 0
	return mini(
		Constants.Match.Capture.SABOTEUR_RESOURCE_STEAL_CAP,
		maxi(1, int(ceil(float(available) * Constants.Match.Capture.SABOTEUR_RESOURCE_STEAL_RATIO)))
	)


func _assert(condition, message):
	if condition:
		return true
	push_error(message)
	get_tree().quit(1)
	return false


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
