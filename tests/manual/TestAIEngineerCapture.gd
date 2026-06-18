extends "res://tests/manual/Match.gd"

const EngineerDrone = preload("res://source/match/units/EngineerDrone.gd")

var _captured_unit = null
var _previous_owner = null
var _new_owner = null

@onready var _human = $Players/Human
@onready var _ai = $Players/SimpleClairvoyantAI
@onready var _neutral = $Players/NeutralTech
@onready var _controller = $Players/SimpleClairvoyantAI/EngineerCaptureController
@onready var _target_power_reactor = $Players/Human/PowerReactor
@onready var _neutral_oil_derrick = $Players/NeutralTech/TechOilDerrick


func _ready():
	super()
	get_tree().paused = false
	MatchSignals.unit_captured.connect(_on_unit_captured)
	await get_tree().process_frame

	assert(not _neutral.participates_in_match, "neutral tech owner should not participate")
	var pending_engineers_before_unknown_metadata = _controller.get_pending_engineer_count()
	_controller.provision({}, "unknown_test_metadata")
	assert(
		_controller.get_pending_engineer_count() == pending_engineers_before_unknown_metadata,
		"unknown engineer metadata should not change pending engineer pressure"
	)

	if not await _wait_for_next_ai_capture():
		return
	assert(
		_captured_unit == _neutral_oil_derrick,
		"AI engineer should prioritize neutral tech assets before enemy utility structures"
	)
	assert(_previous_owner == _neutral, "AI neutral tech capture should report the neutral owner")
	assert(_new_owner == _ai, "AI neutral tech capture should report the AI owner")
	assert(
		$Players/SimpleClairvoyantAI/TechOilDerrick == _neutral_oil_derrick,
		"captured neutral oil derrick should be reparented to the AI"
	)
	assert(
		_neutral_oil_derrick.is_in_group("adversary_units"),
		"AI-captured neutral tech should become an adversary unit for the human player"
	)
	_captured_unit = null

	if not await _wait_for_next_ai_capture():
		return

	assert(
		_captured_unit == _target_power_reactor,
		"AI engineer raid should continue onto enemy utility structures after taking neutral tech"
	)
	assert(_previous_owner == _human, "AI capture should report the previous owner")
	assert(_new_owner == _ai, "AI capture should report the new owner")
	assert(
		$Players/SimpleClairvoyantAI/PowerReactor == _target_power_reactor,
		"captured structure should be reparented to the AI"
	)
	assert(
		not _target_power_reactor.is_in_group("controlled_units"),
		"AI-captured structure should no longer be player-controllable"
	)
	assert(
		_target_power_reactor.is_in_group("adversary_units"),
		"AI-captured structure should become an adversary unit"
	)
	assert(
		_controller.get_pending_engineer_count() == 0,
		"AI should clear pending engineer state after the raid resolves"
	)
	_controller.provision({"resource_a": 999, "resource_b": 999}, "engineer_capture")
	assert(
		_controller.get_pending_engineer_count() == 0,
		"AI engineer should ignore mismatched resources without recreating pending pressure"
	)
	get_tree().paused = false
	get_tree().quit()


func _wait_for_next_ai_capture():
	var saw_engineer_activity = false
	var deadline = Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		if _captured_unit != null:
			return true
		var command_center = $Players/SimpleClairvoyantAI/CommandCenter
		var produced_engineers = get_tree().get_nodes_in_group("units").filter(
			func(unit): return unit is EngineerDrone
		)
		saw_engineer_activity = (
			saw_engineer_activity
			or command_center.production_queue.size() > 0
			or not produced_engineers.is_empty()
		)
		await get_tree().process_frame
	if not saw_engineer_activity:
		push_error("AI engineer raid did not queue or spawn an engineer")
	else:
		push_error("AI engineer raid queued or spawned an engineer but did not capture the target")
	get_tree().paused = false
	get_tree().quit(1)
	return false


func _on_unit_captured(unit, previous_player, new_player):
	if new_player != _ai:
		return
	_captured_unit = unit
	_previous_owner = previous_player
	_new_owner = new_player
