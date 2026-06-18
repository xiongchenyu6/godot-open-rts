extends "res://tests/manual/Match.gd"

const Capturing = preload("res://source/match/units/actions/Capturing.gd")
const Garrisoning = preload("res://source/match/units/actions/Garrisoning.gd")

@onready var _human = $Players/Human
@onready var _neutral = $Players/NeutralTech
@onready var _engineer_drone = $Players/Human/EngineerDrone
@onready var _rifle_infantry = $Players/Human/LightRifleInfantry
@onready var _rocket_infantry = $Players/Human/RocketInfantry
@onready var _friendly_tank = $Players/Human/Tank
@onready var _enemy_tank = $Players/Enemy/Tank
@onready var _bunker = $Players/NeutralTech/TechBunker


func _ready():
	super()
	await get_tree().process_frame

	_disable_attacks(_rifle_infantry)
	_disable_attacks(_rocket_infantry)
	_disable_attacks(_friendly_tank)
	_disable_attacks(_enemy_tank)
	_enemy_tank.process_mode = Node.PROCESS_MODE_DISABLED

	assert(is_instance_valid(_rifle_infantry), "rifle infantry should exist after setup")
	assert(is_instance_valid(_rocket_infantry), "rocket infantry should exist after setup")

	assert(not _neutral.participates_in_match, "neutral bunker owner should not participate")
	assert(Capturing.is_applicable(_engineer_drone, _bunker), "engineer should capture tech bunker")
	assert(_bunker.get_garrison_count() == 0, "empty bunker should report zero garrison")
	assert(is_equal_approx(_bunker.attack_damage, 0.0), "empty bunker should start unarmed")

	_engineer_drone.action = Capturing.new(_bunker)
	if not await _wait_until(
		func(): return _bunker.player == _human and not is_instance_valid(_engineer_drone),
		8.0,
		"engineer should capture neutral tech bunker"
	):
		return

	assert(is_instance_valid(_rifle_infantry), "rifle infantry should survive capture setup")
	assert(is_instance_valid(_rocket_infantry), "rocket infantry should survive capture setup")
	assert(_bunker.player == _human, "captured tech bunker should belong to human")
	assert(_bunker.is_in_group("controlled_units"), "captured tech bunker should be controllable")
	assert(not is_instance_valid(_engineer_drone), "engineer should be consumed after capture")
	assert(is_instance_valid(_rifle_infantry), "rifle infantry should still exist before garrison")
	assert(_rifle_infantry.is_inside_tree(), "rifle infantry should still be in tree")
	assert(_bunker.is_constructed(), "captured bunker should remain constructed")
	assert(_bunker.player.is_allied_with(_rifle_infantry.player), "bunker should be allied with rifle")
	assert(_rifle_infantry.hp != null and _rifle_infantry.hp > 0, "rifle should be alive")
	assert(
		_rifle_infantry.movement_domain == Constants.Match.Navigation.Domain.TERRAIN,
		"rifle should be a terrain unit"
	)
	assert(_rifle_infantry.find_child("Movement") != null, "rifle should have movement")
	assert(not _bunker.is_garrison_full(), "empty bunker should not be full")
	assert(
		_bunker.GARRISONABLE_SCENE_PATHS.has(_rifle_infantry.get_script().resource_path.replace(".gd", ".tscn")),
		"rifle scene path should be garrisonable"
	)
	assert(_bunker.can_garrison_unit(_rifle_infantry), "rifle infantry should be able to garrison")
	assert(_bunker.can_garrison_unit(_rocket_infantry), "rocket infantry should be able to garrison")
	assert(not _bunker.can_garrison_unit(_friendly_tank), "vehicles should not garrison")

	await _garrison_unit(_rifle_infantry, 1)
	assert(
		is_equal_approx(_bunker.attack_damage, _bunker.garrison_attack_damage_per_unit),
		"one garrisoned infantry should arm the bunker"
	)

	await _garrison_unit(_rocket_infantry, 2)
	assert(
		is_equal_approx(_bunker.attack_damage, _bunker.garrison_attack_damage_per_unit * 2.0),
		"bunker damage should scale with garrison count"
	)

	_enemy_tank.global_position = _bunker.global_position + Vector3(0.0, 0.0, 5.0)
	_enemy_tank.hp = _enemy_tank.hp_max
	var enemy_hp_before = _enemy_tank.hp
	await _wait_until(
		func(): return is_instance_valid(_enemy_tank) and _enemy_tank.hp < enemy_hp_before,
		3.0,
		"garrisoned bunker should damage enemy ground units"
	)
	assert(_enemy_tank.last_damage_source == _bunker, "bunker should register as damage source")

	get_tree().quit()


func _garrison_unit(unit, expected_count):
	var unit_ref = weakref(unit)
	unit.global_position = (
		_bunker.global_position + Vector3(_bunker.radius + unit.radius + 0.05, 0.0, 0.0)
	)
	var movement = unit.find_child("Movement")
	if movement != null:
		movement.stop()
	assert(
		Utils.Match.Unit.Movement.units_adhere(unit, _bunker),
		"test infantry should start adjacent to the bunker"
	)
	unit.find_child("Selection").select()
	MatchSignals.unit_targeted.emit(_bunker)
	await get_tree().process_frame
	var current_unit = unit_ref.get_ref()
	assert(
		_bunker.get_garrison_count() == expected_count
		or (current_unit != null and current_unit.action is Garrisoning),
		"targeting the bunker should assign a garrison action"
	)
	await _wait_until(
		func(): return _bunker.get_garrison_count() == expected_count and unit_ref.get_ref() == null,
		3.0,
		"selected infantry should garrison into captured tech bunker"
	)
	assert(unit_ref.get_ref() == null, "garrisoned infantry should leave the field")


func _disable_attacks(unit):
	unit.hold_position = true
	unit.attack_domains = []
	if unit.has_method("clear_action_queue"):
		unit.clear_action_queue()
	unit.action = null
	var movement = unit.find_child("Movement")
	if movement != null:
		movement.stop()


func _wait_until(condition, timeout_s, message):
	var deadline = Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if condition.call():
			return true
		await get_tree().process_frame
	if condition.call():
		return true
	push_error(message)
	get_tree().quit(1)
	return false
