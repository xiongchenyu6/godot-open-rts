extends "res://tests/manual/Match.gd"

const DummyAction = preload("res://source/match/units/actions/Action.gd")

@onready var _test_camera = $IsometricCamera3D
@onready var _army_selection_handler = $Handlers/ArmySelectionHotkeysHandler
@onready var _near_tank = $Players/Human/NearTank
@onready var _far_tank = $Players/Human/FarTank
@onready var _field_medic = $Players/Human/FieldMedic
@onready var _worker = $Players/Human/Worker
@onready var _busy_worker = $Players/Human/BusyWorker
@onready var _idle_harvester = $Players/Human/IdleHarvester
@onready var _busy_harvester = $Players/Human/BusyHarvester
@onready var _command_center = $Players/Human/CommandCenter


func _ready():
	super()
	_test_camera.screen_margin_for_movement = -1
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_place_test_units()

	var on_screen_event = _select_army_on_screen_event()
	var all_army_event = _select_all_army_event()
	var idle_workers_event = _select_idle_workers_event()
	var idle_harvesters_event = _select_idle_harvesters_event()
	_assert(InputMap.has_action("select_army_on_screen"), "screen army selection action should exist")
	_assert(InputMap.has_action("select_all_army"), "all army selection action should exist")
	_assert(InputMap.has_action("select_idle_workers"), "idle worker selection action should exist")
	_assert(InputMap.has_action("select_idle_harvesters"), "idle harvester selection action should exist")
	_assert(
		on_screen_event.is_action_pressed("select_army_on_screen", false, true),
		"Alt+A should select army on screen"
	)
	_assert(
		all_army_event.is_action_pressed("select_all_army", false, true),
		"Ctrl+Alt+A should select all army"
	)
	_assert(
		not all_army_event.is_action_pressed("select_army_on_screen", false, true),
		"Ctrl+Alt+A should not also match screen-only army selection"
	)
	_assert(
		idle_workers_event.is_action_pressed("select_idle_workers", false, true),
		"Alt+I should select idle construction workers"
	)
	_assert(
		idle_harvesters_event.is_action_pressed("select_idle_harvesters", false, true),
		"Ctrl+Alt+I should select idle harvesters"
	)
	_assert(
		not idle_harvesters_event.is_action_pressed("select_idle_workers", false, true),
		"Ctrl+Alt+I should not also match construction worker selection"
	)

	_test_camera.set_size_safely(10.0)
	_test_camera.set_position_safely(Vector3(12.0, 0.0, 12.0))
	await get_tree().process_frame
	_busy_worker.action = DummyAction.new()
	_busy_harvester.action = DummyAction.new()
	await get_tree().process_frame
	_assert(_near_tank.is_in_group("controlled_units"), "near tank should be controllable")
	_assert(_field_medic.is_in_group("controlled_units"), "field medic should be controllable")
	_assert(_worker.is_in_group("controlled_units"), "worker should be controllable")
	_assert(_busy_worker.is_in_group("controlled_units"), "busy worker should be controllable")
	_assert(_idle_harvester.is_in_group("controlled_units"), "idle harvester should be controllable")
	_assert(_busy_harvester.is_in_group("controlled_units"), "busy harvester should be controllable")
	_assert(_command_center.is_in_group("controlled_units"), "command center should be controllable")
	var all_army_count = _army_selection_handler.select_all_army()
	_assert(
		all_army_count == 3,
		"army unit filter should include tactical units only, count {0}".format([all_army_count])
	)
	MatchSignals.deselect_all_units.emit()
	await get_tree().process_frame
	_assert(
		_army_selection_handler._is_unit_on_screen(_near_tank),
		"near tank should be on screen, screen {0}, viewport {1}, center {2}, unit {3}".format(
			[
				_test_camera.unproject_position(_near_tank.global_position),
				get_viewport().size,
				_camera_center_yless(),
				_near_tank.global_position
			]
		)
	)
	_assert(not _army_selection_handler._is_unit_on_screen(_far_tank), "far tank should be off screen")

	_army_selection_handler._input(on_screen_event)
	await get_tree().process_frame
	var selected_units = _selected_controlled_units()
	_assert(selected_units.size() == 2, "Alt+A should select only visible army units on screen")
	_assert(_near_tank.is_in_group("selected_units"), "Alt+A should select the on-screen tank")
	_assert(_field_medic.is_in_group("selected_units"), "Alt+A should select support army units")
	_assert(not _far_tank.is_in_group("selected_units"), "Alt+A should not select off-screen army")
	_assert(not _worker.is_in_group("selected_units"), "Alt+A should not select workers")
	_assert(not _command_center.is_in_group("selected_units"), "Alt+A should not select structures")

	MatchSignals.deselect_all_units.emit()
	await get_tree().process_frame
	_army_selection_handler._input(all_army_event)
	await get_tree().process_frame
	selected_units = _selected_controlled_units()
	_assert(selected_units.size() == 3, "Ctrl+Alt+A should select all visible army units")
	_assert(_near_tank.is_in_group("selected_units"), "Ctrl+Alt+A should select near army")
	_assert(_far_tank.is_in_group("selected_units"), "Ctrl+Alt+A should select off-screen army")
	_assert(_field_medic.is_in_group("selected_units"), "Ctrl+Alt+A should select support army")
	_assert(not _worker.is_in_group("selected_units"), "Ctrl+Alt+A should not select workers")
	_assert(not _idle_harvester.is_in_group("selected_units"), "Ctrl+Alt+A should not select harvesters")
	_assert(not _command_center.is_in_group("selected_units"), "Ctrl+Alt+A should not select structures")

	MatchSignals.deselect_all_units.emit()
	await get_tree().process_frame
	var idle_worker_count = _army_selection_handler.select_idle_workers()
	_assert(idle_worker_count == 1, "idle worker selection should find one idle construction worker")
	selected_units = _selected_controlled_units()
	_assert(selected_units.size() == 1, "idle worker selection should select exactly one unit")
	_assert(_worker.is_in_group("selected_units"), "idle worker selection should select the idle worker")
	_assert(not _busy_worker.is_in_group("selected_units"), "idle worker selection should skip busy workers")
	_assert(not _idle_harvester.is_in_group("selected_units"), "idle worker selection should skip harvesters")

	MatchSignals.deselect_all_units.emit()
	await get_tree().process_frame
	_army_selection_handler._input(idle_workers_event)
	await get_tree().process_frame
	selected_units = _selected_controlled_units()
	_assert(selected_units.size() == 1, "Alt+I should select exactly one idle worker")
	_assert(_worker.is_in_group("selected_units"), "Alt+I should select the idle worker")
	_assert(not _busy_worker.is_in_group("selected_units"), "Alt+I should skip busy workers")
	_assert(not _idle_harvester.is_in_group("selected_units"), "Alt+I should not select harvesters")

	MatchSignals.deselect_all_units.emit()
	await get_tree().process_frame
	_army_selection_handler._input(idle_harvesters_event)
	await get_tree().process_frame
	selected_units = _selected_controlled_units()
	_assert(selected_units.size() == 1, "Ctrl+Alt+I should select exactly one idle harvester")
	_assert(_idle_harvester.is_in_group("selected_units"), "Ctrl+Alt+I should select idle harvesters")
	_assert(not _busy_harvester.is_in_group("selected_units"), "Ctrl+Alt+I should skip busy harvesters")
	_assert(not _worker.is_in_group("selected_units"), "Ctrl+Alt+I should not select construction workers")

	get_tree().quit()


func _selected_controlled_units():
	return get_tree().get_nodes_in_group("selected_units").filter(
		func(unit): return unit.is_in_group("controlled_units")
	)


func _place_test_units():
	_place_unit(_near_tank, Vector3(12.0, -0.6, 12.0))
	_place_unit(_far_tank, Vector3(44.0, -0.6, 44.0))
	_place_unit(_field_medic, Vector3(14.0, -0.6, 12.0))
	_place_unit(_worker, Vector3(12.0, -0.6, 14.0))
	_place_unit(_busy_worker, Vector3(14.0, -0.6, 14.0))
	_place_unit(_idle_harvester, Vector3(16.0, -0.6, 14.0))
	_place_unit(_busy_harvester, Vector3(18.0, -0.6, 14.0))
	_place_unit(_command_center, Vector3(16.0, 0.0, 12.0))


func _place_unit(unit, position: Vector3):
	unit.global_position = position
	var movement = unit.find_child("Movement")
	if movement != null:
		movement.stop()


func _camera_center_yless():
	var center = _test_camera.get_ray_intersection(get_viewport().size / 2.0)
	return center * Vector3(1, 0, 1)


func _select_army_on_screen_event():
	return _key_event(KEY_A, true, false)


func _select_all_army_event():
	return _key_event(KEY_A, true, true)


func _select_idle_workers_event():
	return _key_event(KEY_I, true, false)


func _select_idle_harvesters_event():
	return _key_event(KEY_I, true, true)


func _key_event(keycode: int, alt_pressed: bool, ctrl_pressed: bool):
	var event = InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	event.physical_keycode = keycode
	event.alt_pressed = alt_pressed
	event.ctrl_pressed = ctrl_pressed
	if not ctrl_pressed:
		event.unicode = keycode + 32
	return event


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
