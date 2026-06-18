extends "res://source/match/units/actions/Action.gd"

const AutoAttacking = preload("res://source/match/units/actions/AutoAttacking.gd")
const Moving = preload("res://source/match/units/actions/Moving.gd")

const SCAN_INTERVAL = 1.0 / 60.0 * 10.0
const DESTINATION_REACHED_DISTANCE = 2.0

var _target_position = null
var _sub_action = null
var _sub_action_mode = ""
var _scan_timer = null

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")


static func is_applicable(unit):
	return (
		Moving.is_applicable(unit)
		and unit.attack_range != null
		and not unit.attack_domains.is_empty()
	)


func _init(target_position):
	_target_position = target_position


func _ready():
	_setup_scan_timer()
	_start_moving()


func _exit_tree():
	_stop_movement()


func _to_string():
	return "{0}({1})".format([super(), str(_sub_action) if _sub_action != null else ""])


func _process(_delta):
	if _sub_action_mode == "moving" and _has_reached_destination():
		queue_free()


func _setup_scan_timer():
	_scan_timer = Timer.new()
	_scan_timer.timeout.connect(_on_scan_timer_timeout)
	add_child(_scan_timer)
	_scan_timer.start(SCAN_INTERVAL)


func _start_moving():
	_replace_sub_action(Moving.new(_target_position), "moving")


func _start_attacking(target_unit):
	_replace_sub_action(AutoAttacking.new(target_unit), "attacking")


func _replace_sub_action(new_sub_action, mode):
	_clear_sub_action()
	_sub_action = new_sub_action
	_sub_action_mode = mode
	_sub_action.tree_exited.connect(_on_sub_action_finished)
	add_child(_sub_action)
	_unit.action_updated.emit()


func _clear_sub_action():
	if _sub_action == null:
		return
	if _sub_action.tree_exited.is_connected(_on_sub_action_finished):
		_sub_action.tree_exited.disconnect(_on_sub_action_finished)
	if _sub_action.is_inside_tree():
		remove_child(_sub_action)
	_stop_movement()
	_sub_action.queue_free()
	_sub_action = null
	_sub_action_mode = ""


func _stop_movement():
	var movement_trait = _unit.find_child("Movement")
	if movement_trait != null:
		movement_trait.stop()


func _get_units_to_attack():
	return get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return (
				unit.visible
				and AutoAttacking.is_applicable(_unit, unit)
				and (
					_unit.global_position_yless.distance_to(unit.global_position_yless)
					<= _unit.sight_range
				)
			)
	)


func _pick_closest_unit(units):
	assert(not units.is_empty())
	var distance_to_closest_unit = _unit.global_position_yless.distance_to(
		units[0].global_position_yless
	)
	var closest_unit = units[0]
	for unit_to_check in units:
		var distance = _unit.global_position_yless.distance_to(unit_to_check.global_position_yless)
		if distance < distance_to_closest_unit:
			distance_to_closest_unit = distance
			closest_unit = unit_to_check
	return closest_unit


func _has_reached_destination():
	return (
		_unit.global_position_yless.distance_to(_target_position * Vector3(1, 0, 1))
		<= DESTINATION_REACHED_DISTANCE
	)


func _on_scan_timer_timeout():
	if _sub_action_mode != "moving":
		return
	var units_to_attack = _get_units_to_attack()
	if not units_to_attack.is_empty():
		_start_attacking(_pick_closest_unit(units_to_attack))


func _on_sub_action_finished():
	var finished_mode = _sub_action_mode
	_sub_action = null
	_sub_action_mode = ""
	if not is_inside_tree():
		return
	if finished_mode == "moving":
		queue_free()
	elif finished_mode == "attacking":
		_start_moving()
