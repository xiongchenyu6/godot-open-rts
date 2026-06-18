extends "res://tests/manual/Match.gd"

@onready var _test_camera = $IsometricCamera3D


func _ready():
	super()
	_test_camera.screen_margin_for_movement = 24
	_test_camera.movement_speed = 12.0
	_test_camera.set_position_safely(Vector3(32.0, 0.0, 32.0))
	await get_tree().process_frame

	get_viewport().warp_mouse(Vector2.ZERO)
	_test_camera._mouse_edge_movement_active = false
	var initial_center = _camera_center_yless()
	for _i in range(8):
		await get_tree().physics_frame
	var idle_center = _camera_center_yless()
	_assert(
		idle_center.distance_to(initial_center) < 0.25,
		"camera should not edge-scroll from an uninitialized top-left mouse position"
	)

	var motion_event = InputEventMouseMotion.new()
	motion_event.position = Vector2.ZERO
	motion_event.relative = Vector2(-4.0, -4.0)
	_test_camera._unhandled_input(motion_event)
	get_viewport().warp_mouse(Vector2.ZERO)
	for _i in range(4):
		await get_tree().physics_frame
	var moved_center = _camera_center_yless()
	_assert(
		moved_center.distance_to(idle_center) > 0.25,
		"camera should edge-scroll after receiving real mouse motion"
	)

	get_tree().quit()


func _camera_center_yless():
	var center = _test_camera.get_ray_intersection(get_viewport().size / 2.0)
	return center * Vector3(1, 0, 1)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
