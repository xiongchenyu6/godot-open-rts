extends "res://source/match/units/actions/Action.gd"

const REFRESH_INTERVAL = 1.0 / 60.0 * 10.0

var _target_unit = null
var _distance_to_reach = null
var _timer = null
var _last_known_target_unit_position = null

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")
@onready var _movement_trait = _unit.find_child("Movement")


func _init(target_unit, distance_to_reach):
	_target_unit = target_unit
	_distance_to_reach = distance_to_reach


func _ready():
	if _teardown_if_invalid_target():
		return
	_target_unit.tree_exited.connect(queue_free)
	_timer = Timer.new()
	_timer.timeout.connect(_refresh)
	add_child(_timer)
	_timer.start(REFRESH_INTERVAL)
	if _movement_trait == null or not is_instance_valid(_movement_trait):
		queue_free()
		return
	_movement_trait.movement_finished.connect(_on_movement_finished)
	_refresh()


func _exit_tree():
	if _movement_trait != null and is_instance_valid(_movement_trait):
		_movement_trait.stop()


func _refresh():
	if _teardown_if_invalid_target():
		return
	if _teardown_if_distance_reached():
		return
	_align_movement_if_needed()


func _teardown_if_distance_reached():
	if _teardown_if_invalid_target():
		return true
	if (
		_unit.global_position_yless.distance_to(_target_unit.global_position_yless)
		<= _distance_to_reach
	):
		queue_free()
		return true
	return false


func _align_movement_if_needed():
	if _teardown_if_invalid_target():
		return
	if (
		_last_known_target_unit_position == null
		or not _last_known_target_unit_position.is_equal_approx(_target_unit.global_position)
	):
		_movement_trait.move(_target_unit.global_position)
		_last_known_target_unit_position = _target_unit.global_position


func _on_movement_finished():
	if _teardown_if_invalid_target():
		return
	_movement_trait.move(_target_unit.global_position)


func _teardown_if_invalid_target():
	if not _has_source_unit() or not _has_target_unit():
		queue_free()
		return true
	return false


func _has_source_unit():
	return _unit != null and is_instance_valid(_unit) and _unit.is_inside_tree()


func _has_target_unit():
	return _target_unit != null and is_instance_valid(_target_unit) and _target_unit.is_inside_tree()
