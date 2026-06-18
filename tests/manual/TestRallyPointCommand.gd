extends "res://tests/manual/Match.gd"

const Following = preload("res://source/match/units/actions/Following.gd")
const Moving = preload("res://source/match/units/actions/Moving.gd")
const WorkerUnit = preload("res://source/match/units/Worker.tscn")

@onready var _command_center = $Players/Human/CommandCenter
@onready var _friendly_worker = $Players/Human/Worker


func _ready():
	super()
	await get_tree().process_frame
	var produced_units = []
	var production_recorder = func(produced_unit, producer):
		if producer == _command_center:
			produced_units.append(produced_unit)
	MatchSignals.unit_production_finished.connect(production_recorder)

	_command_center.find_child("Selection").select()
	await get_tree().process_frame

	var rally_point = _command_center.find_child("RallyPoint")
	_assert(rally_point != null, "production structures should expose a rally point")
	_assert(not rally_point.is_set, "initial rally point should not be treated as an active order")

	var default_rally_worker = await _finish_worker_production(produced_units)
	_assert(
		not (default_rally_worker.action is Moving) and not (default_rally_worker.action is Following),
		"produced units should not move to an unset initial rally point"
	)

	var target_position = Vector3(18.0, 0.0, 12.0)
	MatchSignals.rally_point_requested.emit()
	_emit_terrain_input_event(target_position)
	await get_tree().process_frame

	_assert(rally_point.target_unit == null, "terrain rally point should clear unit target")
	_assert(
		rally_point.global_position.distance_to(target_position) < 0.01,
		"terrain rally point command should move the rally marker"
	)
	var terrain_rally_worker = await _finish_worker_production(produced_units)
	_assert(terrain_rally_worker.action is Moving, "produced units should move to terrain rally points")
	_assert(
		terrain_rally_worker.action._target_position.distance_to(target_position) < 0.01,
		"produced units should move toward the selected terrain rally position"
	)

	MatchSignals.rally_point_requested.emit()
	MatchSignals.terrain_targeted.emit(Vector3(-50.0, 0.0, -50.0))
	await get_tree().process_frame
	_assert(
		rally_point.global_position.distance_to(target_position) < 0.01,
		"out-of-map terrain commands should not move the rally point"
	)

	MatchSignals.rally_point_requested.emit()
	MatchSignals.unit_targeted.emit(_friendly_worker)
	await get_tree().process_frame

	_assert(
		rally_point.target_unit == _friendly_worker,
		"unit rally point command should track the targeted friendly unit"
	)
	var unit_rally_worker = await _finish_worker_production(produced_units)
	_assert(unit_rally_worker.action is Following, "produced units should follow unit rally targets")
	_assert(
		unit_rally_worker.action._target_unit == _friendly_worker,
		"produced units should follow the selected friendly unit rally target"
	)
	_friendly_worker.queue_free()
	await get_tree().process_frame
	_assert(rally_point.target_unit == null, "rally point should clear a removed unit target")
	MatchSignals.unit_production_finished.disconnect(production_recorder)
	get_tree().quit()


func _finish_worker_production(produced_units):
	var initial_count = produced_units.size()
	var queue_element = _command_center.production_queue.produce(WorkerUnit)
	_assert(queue_element != null, "command center should queue worker production for rally testing")
	queue_element.time_left = 0.0
	for _i in range(10):
		await get_tree().process_frame
		if produced_units.size() > initial_count:
			return produced_units.back()
	_assert(false, "worker production should finish when the queue element reaches zero time")
	return null


func _emit_terrain_input_event(click_position: Vector3):
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	event.position = Vector2.ZERO
	$Terrain._on_input_event(null, event, click_position, Vector3.UP, 0)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
