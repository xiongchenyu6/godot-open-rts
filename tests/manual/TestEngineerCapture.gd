extends "res://tests/manual/Match.gd"

const Capturing = preload("res://source/match/units/actions/Capturing.gd")
const Repairing = preload("res://source/match/units/actions/Repairing.gd")
const PowerReactorUnit = preload("res://source/match/units/PowerReactor.tscn")

var _captured_units_count = 0
var _captured_unit = null
var _previous_owner = null
var _new_owner = null

@onready var _human = $Players/Human
@onready var _enemy = $Players/Enemy
@onready var _engineer_drone = $Players/Human/EngineerDrone
@onready var _enemy_power_reactor = $Players/Enemy/PowerReactor


func _ready():
	super()
	await get_tree().process_frame
	MatchSignals.unit_captured.connect(_on_unit_captured)

	var power_supply = Constants.Match.Units.POWER_SUPPLY[PowerReactorUnit.resource_path]
	var human_power_before = _human.get_power_supply()
	var enemy_power_before = _enemy.get_power_supply()

	assert(
		Capturing.is_applicable(_engineer_drone, _enemy_power_reactor),
		"engineer drone should be able to capture enemy constructed structures"
	)
	assert(
		not Repairing.is_applicable(_engineer_drone, _enemy_power_reactor),
		"engineer drone should not repair enemy structures"
	)

	_engineer_drone.find_child("Selection").select()
	MatchSignals.unit_targeted.emit(_enemy_power_reactor)
	if not await _wait_until(
		func(): return _captured_units_count == 1 and not is_instance_valid(_engineer_drone),
		8.0,
		"engineer drone should capture enemy power reactor"
	):
		return

	assert(_captured_units_count == 1, "capturing should emit one capture signal")
	assert(_captured_unit == _enemy_power_reactor, "capture signal should include captured structure")
	assert(_previous_owner == _enemy, "capture signal should include previous owner")
	assert(_new_owner == _human, "capture signal should include new owner")
	assert(_enemy.get_node_or_null("PowerReactor") == null, "captured structure should leave enemy")
	assert(
		$Players/Human/PowerReactor == _enemy_power_reactor,
		"captured structure should become a human structure"
	)
	assert(_enemy_power_reactor.player == _human, "captured structure should report new owner")
	assert(
		_enemy_power_reactor.is_in_group("controlled_units"),
		"captured structure should become controllable"
	)
	assert(
		not _enemy_power_reactor.is_in_group("adversary_units"),
		"captured structure should leave adversary group"
	)
	assert(
		not is_instance_valid(_engineer_drone),
		"engineer drone should be consumed after capture"
	)
	assert(
		_human.get_power_supply() == human_power_before + power_supply,
		"captured power reactor should add power supply to new owner"
	)
	assert(
		_enemy.get_power_supply() == enemy_power_before - power_supply,
		"captured power reactor should remove power supply from previous owner"
	)
	get_tree().quit()


func _on_unit_captured(unit, previous_player, new_player):
	_captured_units_count += 1
	_captured_unit = unit
	_previous_owner = previous_player
	_new_owner = new_player


func _wait_until(condition, timeout_s, message):
	var deadline = Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if condition.call():
			return true
		await get_tree().process_frame
	push_error(message)
	get_tree().quit(1)
	return false
