extends "res://source/match/units/actions/Moving.gd"

var _target_unit = null
var _last_target_position_yless = Vector3.INF


func _init(target_unit):
	_target_unit = target_unit


func _process(_delta):
	if _teardown_if_invalid_target():
		return
	if Utils.Match.Unit.Movement.units_adhere(_unit, _target_unit):
		queue_free()
		return
	if _target_moved_since_last_path():
		_move_to_current_target_contact_position()


func _ready():
	if _teardown_if_invalid_target():
		return
	_target_unit.tree_exited.connect(queue_free)
	_move_to_current_target_contact_position()
	super()


func _move_to_current_target_contact_position():
	if _teardown_if_invalid_target():
		return
	_last_target_position_yless = _target_unit.global_position_yless
	_target_position = _target_contact_position()
	if _movement_trait != null:
		_movement_trait.move(_target_position)


func _target_moved_since_last_path():
	if _teardown_if_invalid_target():
		return false
	if not _is_finite_position(_last_target_position_yless):
		return true
	return _last_target_position_yless.distance_to(_target_unit.global_position_yless) > 0.2


func _is_finite_position(position):
	return is_finite(position.x) and is_finite(position.y) and is_finite(position.z)


func _target_contact_position():
	if _teardown_if_invalid_target():
		return _unit.global_position_yless if _has_source_unit() else Vector3.ZERO
	var direction_from_target = (
		(_unit.global_position_yless - _target_unit.global_position_yless).normalized()
	)
	if direction_from_target.is_zero_approx():
		direction_from_target = Vector3.RIGHT
	var target_radius = _target_unit.radius if _target_unit.radius != null else 0.0
	var unit_radius = _unit.radius if _unit.radius != null else 0.0
	return (
		_target_unit.global_position_yless
		+ direction_from_target
		* (target_radius + unit_radius + Constants.Match.Units.ADHERENCE_MARGIN_M)
	)


func _on_movement_finished():
	if _teardown_if_invalid_target():
		return
	if Utils.Match.Unit.Movement.units_adhere(_unit, _target_unit):
		queue_free()
	else:
		_move_to_current_target_contact_position()


func _teardown_if_invalid_target():
	if not _has_source_unit() or not _has_target_unit():
		queue_free()
		return true
	return false


func _has_source_unit():
	return _unit != null and is_instance_valid(_unit) and _unit.is_inside_tree()


func _has_target_unit():
	return _target_unit != null and is_instance_valid(_target_unit) and _target_unit.is_inside_tree()
