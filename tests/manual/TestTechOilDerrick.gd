extends "res://source/match/Match.gd"

const Capturing = preload("res://source/match/units/actions/Capturing.gd")
const StructureScript = preload("res://source/match/units/Structure.gd")
const WorkerScript = preload("res://source/match/units/Worker.gd")

var _result = ""

@onready var _human = $Players/Human
@onready var _enemy = $Players/Enemy
@onready var _neutral = $Players/NeutralTech
@onready var _engineer_drone = $Players/Human/EngineerDrone
@onready var _oil_derrick = $Players/NeutralTech/TechOilDerrick


func _ready():
	super()
	MatchSignals.match_finished_with_victory.connect(func(): _result = "victory")
	MatchSignals.match_finished_with_defeat.connect(func(): _result = "defeat")
	await get_tree().process_frame

	assert(not _neutral.participates_in_match, "neutral oil owner should not participate")
	assert(
		Capturing.is_applicable(_engineer_drone, _oil_derrick),
		"engineer drone should be able to capture neutral oil derrick"
	)

	var resources_before_capture = _human.resource_a
	_engineer_drone.action = Capturing.new(_oil_derrick)
	if not await _wait_until(
		func():
			return _oil_derrick.player == _human and not is_instance_valid(_engineer_drone),
		8.0,
		"engineer drone should capture neutral oil derrick"
	):
		return

	assert(_oil_derrick.player == _human, "captured oil derrick should belong to human")
	assert(_oil_derrick.is_in_group("controlled_units"), "captured oil derrick should be controllable")
	assert(
		not _oil_derrick.is_in_group("adversary_units"),
		"captured oil derrick should leave adversary units"
	)
	assert(
		not is_instance_valid(_engineer_drone),
		"engineer drone should be consumed after capturing oil derrick"
	)
	assert(
		_human.resource_a >= resources_before_capture + _oil_derrick.capture_bonus_a,
		"capturing oil derrick should grant an immediate resource bonus"
	)

	var resources_after_capture = _human.resource_a
	await get_tree().create_timer(_oil_derrick.income_interval_s + 0.25).timeout
	assert(
		_human.resource_a >= resources_after_capture + _oil_derrick.resource_income_a,
		"captured oil derrick should grant steady income"
	)

	_queue_free_units_matching(_enemy, func(unit): return unit is StructureScript or unit is WorkerScript)
	await _wait_for_result()
	assert(_result == "victory", "neutral oil derrick should not block victory")

	get_tree().paused = false
	get_tree().quit()


func _queue_free_units_matching(player, predicate):
	for unit in player.get_children():
		if predicate.call(unit):
			unit.queue_free()


func _wait_for_result(max_frames = 12):
	for _i in range(max_frames):
		await get_tree().process_frame
		if _result != "":
			return


func _wait_until(condition, timeout_s, message):
	var deadline = Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if condition.call():
			return true
		await get_tree().process_frame
	push_error(message)
	get_tree().quit(1)
	return false
