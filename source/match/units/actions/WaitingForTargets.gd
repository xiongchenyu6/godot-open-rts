extends "res://source/match/units/actions/Action.gd"

const AttackingWhileInRange = preload("res://source/match/units/actions/AttackingWhileInRange.gd")
const AutoAttacking = preload("res://source/match/units/actions/AutoAttacking.gd")

const REFRESH_INTERVAL = 1.0 / 60.0 * 10.0

var _timer = null
var _sub_action = null

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")


func _ready():
	_timer = Timer.new()
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start(REFRESH_INTERVAL)


func _to_string():
	return "{0}({1})".format([super(), str(_sub_action) if _sub_action != null else ""])


func is_idle():
	return _sub_action == null


func _unit_can_auto_acquire_targets():
	if _unit == null or not is_instance_valid(_unit):
		return false
	return not _unit.has_method("can_auto_acquire_targets") or _unit.can_auto_acquire_targets()


func _get_units_to_attack():
	if _unit == null or not is_instance_valid(_unit):
		return []
	return get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return (
				_unit.player.is_enemy_with(unit.player)
				and unit.movement_domain in _unit.attack_domains
				and (
					_unit.global_position_yless.distance_to(unit.global_position_yless)
					<= _unit.sight_range
				)
			)
	)


func _attack_unit(unit):
	_sub_action = (
		AutoAttacking.new(unit) if _unit.movement_speed > 0.0 else AttackingWhileInRange.new(unit)
	)
	_sub_action.tree_exited.connect(_on_attack_finished)
	add_child(_sub_action)
	_unit.action_updated.emit()


func _on_timer_timeout():
	if _unit == null or not is_instance_valid(_unit):
		_clear_sub_action()
		return
	if not _unit_can_auto_acquire_targets():
		_clear_sub_action()
		return
	if _sub_action != null:
		return
	if _unit.hold_position:
		return
	var units_to_attack = _get_units_to_attack()
	if not units_to_attack.is_empty():
		_attack_unit(_pick_closest_unit(units_to_attack, _unit))


func _on_attack_finished():
	if not is_inside_tree():
		return
	_sub_action = null
	_unit.action_updated.emit()


func _clear_sub_action():
	if _sub_action == null:
		return
	var sub_action = _sub_action
	_sub_action = null
	if sub_action.tree_exited.is_connected(_on_attack_finished):
		sub_action.tree_exited.disconnect(_on_attack_finished)
	if sub_action.is_inside_tree():
		remove_child(sub_action)
	sub_action.queue_free()
	if _unit != null and is_instance_valid(_unit):
		_unit.action_updated.emit()


static func _pick_closest_unit(units, unit):
	assert(not units.is_empty())
	var distance_to_closest_unit = unit.global_position_yless.distance_to(
		units[0].global_position_yless
	)
	var closest_unit = units[0]
	for unit_to_check in units:
		var distance = unit.global_position_yless.distance_to(unit_to_check.global_position_yless)
		if distance < distance_to_closest_unit:
			distance_to_closest_unit = distance
			closest_unit = unit_to_check
	return closest_unit
