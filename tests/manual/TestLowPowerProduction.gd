extends "res://tests/manual/Match.gd"

const LightRifleInfantryUnit = preload("res://source/match/units/LightRifleInfantry.tscn")
const PowerReactorUnit = preload("res://source/match/units/PowerReactor.tscn")
const SAMPLE_SECONDS = 0.6


class BlockingUnit:
	extends Node3D

	var radius = 1000.0

@onready var _human = $Players/Human
@onready var _barracks = $Players/Human/Barracks


func _ready():
	super()
	await get_tree().process_frame
	await get_tree().physics_frame

	_assert(_human.is_low_power(), "test setup should start the human player in low power")
	_assert(
		_human.get_production_speed_multiplier()
		== Constants.Match.Power.LOW_POWER_PRODUCTION_SPEED_MULTIPLIER,
		"low-power players should use the configured production speed penalty"
	)

	var queue_element = _barracks.production_queue.produce(LightRifleInfantryUnit, true)
	_assert(queue_element != null, "barracks should queue infantry while low power")
	var low_power_step = await _measure_production_step(queue_element)
	_assert(low_power_step > 0.0, "low-power production should still make progress")

	var power_reactor = PowerReactorUnit.instantiate()
	_setup_and_spawn_unit(
		power_reactor,
		Transform3D(Basis(), Vector3(7.0, 0.0, 15.0)),
		_human,
		false
	)
	await get_tree().process_frame

	_assert(not _human.is_low_power(), "adding a power reactor should restore base power")
	_assert(
		_human.get_production_speed_multiplier() == 1.0,
		"powered players should produce at full speed"
	)

	var powered_step = await _measure_production_step(queue_element)
	_assert(
		powered_step > low_power_step * 1.5,
		"restored power should noticeably speed up queued production"
	)
	await _assert_blocked_production_notifies_once(queue_element)
	get_tree().quit()


func _measure_production_step(queue_element):
	var time_before = queue_element.time_left
	await get_tree().create_timer(SAMPLE_SECONDS).timeout
	return time_before - queue_element.time_left


func _assert_blocked_production_notifies_once(queue_element):
	if not _barracks.production_queue.get_elements().has(queue_element):
		queue_element = _barracks.production_queue.produce(LightRifleInfantryUnit, true)
	_assert(queue_element != null, "test should have a queued infantry element")

	var blocker = BlockingUnit.new()
	add_child(blocker)
	blocker.global_position = _barracks.global_position
	blocker.add_to_group("units")

	var blocked_events = []
	var blocked_recorder = func(unit_prototype, producer_unit):
		if producer_unit == _barracks:
			blocked_events.append(unit_prototype.resource_path)
	MatchSignals.unit_production_blocked.connect(blocked_recorder)

	queue_element.time_left = 0.0
	for _i in range(5):
		await get_tree().process_frame

	_assert(
		blocked_events == [LightRifleInfantryUnit.resource_path],
		"blocked production should notify exactly once while the exit remains blocked"
	)
	_assert(
		_barracks.production_queue.get_elements().has(queue_element),
		"blocked production should stay queued until a spawn position opens"
	)
	_assert(
		queue_element.blocked_notification_sent,
		"blocked queue element should remember that it already notified the player"
	)

	var produced_units = []
	var produced_recorder = func(produced_unit, producer_unit):
		if producer_unit == _barracks:
			produced_units.append(produced_unit)
	MatchSignals.unit_production_finished.connect(produced_recorder)

	blocker.remove_from_group("units")
	blocker.queue_free()
	await _wait_until(
		func(): return not produced_units.is_empty(),
		2.0,
		"blocked production should finish after the factory exit is cleared"
	)

	MatchSignals.unit_production_blocked.disconnect(blocked_recorder)
	MatchSignals.unit_production_finished.disconnect(produced_recorder)


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
