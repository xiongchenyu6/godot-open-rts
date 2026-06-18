extends "res://source/match/units/actions/Action.gd"

const MovingToUnit = preload("res://source/match/units/actions/MovingToUnit.gd")
const GarrisoningWhileInRange = preload(
	"res://source/match/units/actions/GarrisoningWhileInRange.gd"
)

var _target_unit = null
var _sub_action = null

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")


static func is_applicable(source_unit, target_unit):
	return (
		GarrisoningWhileInRange.is_garrison_target(source_unit, target_unit)
		and source_unit.find_child("Movement") != null
	)


func _init(target_unit):
	_target_unit = target_unit


func _ready():
	if _teardown_if_invalid_target():
		return
	_target_unit.tree_exited.connect(_on_target_unit_removed)
	_garrison_or_move_closer()


func _process(_delta):
	if _teardown_if_invalid_target():
		return
	if _sub_action is MovingToUnit and GarrisoningWhileInRange.is_applicable(_unit, _target_unit):
		_set_sub_action(GarrisoningWhileInRange.new(_target_unit))


func _to_string():
	return "{0}({1})".format([super(), str(_sub_action) if _sub_action != null else ""])


func _garrison_or_move_closer():
	if _teardown_if_invalid_target() or not is_applicable(_unit, _target_unit):
		queue_free()
		return
	_set_sub_action(
		MovingToUnit.new(_target_unit)
		if not GarrisoningWhileInRange.is_applicable(_unit, _target_unit)
		else GarrisoningWhileInRange.new(_target_unit)
	)


func _set_sub_action(sub_action):
	if _sub_action != null:
		if _sub_action.tree_exited.is_connected(_on_sub_action_finished):
			_sub_action.tree_exited.disconnect(_on_sub_action_finished)
		if _sub_action.is_inside_tree():
			remove_child(_sub_action)
		_sub_action.queue_free()
	_sub_action = sub_action
	_sub_action.tree_exited.connect(_on_sub_action_finished)
	add_child(_sub_action)
	_unit.action_updated.emit()


func _on_sub_action_finished():
	if not is_inside_tree():
		return
	if _teardown_if_invalid_target():
		queue_free()
		return
	_sub_action = null
	_garrison_or_move_closer()


func _on_target_unit_removed():
	queue_free()


func _teardown_if_invalid_target():
	if not _has_runtime_unit(_unit) or not _has_runtime_unit(_target_unit):
		queue_free()
		return true
	return false


static func _has_runtime_unit(unit):
	return unit != null and is_instance_valid(unit) and unit.is_inside_tree()
