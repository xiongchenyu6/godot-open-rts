extends "res://source/match/units/actions/Action.gd"

const Worker = preload("res://source/match/units/Worker.gd")
const Structure = preload("res://source/match/units/Structure.gd")
const MovingToUnit = preload("res://source/match/units/actions/MovingToUnit.gd")
const ConstructingWhileInRange = preload(
	"res://source/match/units/actions/ConstructingWhileInRange.gd"
)

var _target_unit = null
var _sub_action = null

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")


static func is_applicable(source_unit, target_unit):
	return (
		_has_runtime_unit(source_unit)
		and _has_runtime_unit(target_unit)
		and source_unit is Worker
		and source_unit.can_construct_structures()
		and target_unit is Structure
		and not target_unit.is_constructed()
		and source_unit.player == target_unit.player
	)


func _init(target_unit):
	_target_unit = target_unit


func _ready():
	if not is_applicable(_unit, _target_unit):
		queue_free()
		return
	_target_unit.tree_exited.connect(_on_target_unit_removed)
	_target_unit.constructed.connect(_on_target_unit_constructed)
	_construct_or_move_closer()


func _construct_or_move_closer():
	if not is_applicable(_unit, _target_unit):
		queue_free()
		return
	_sub_action = (
		MovingToUnit.new(_target_unit)
		if not Utils.Match.Unit.Movement.units_adhere(_unit, _target_unit)
		else ConstructingWhileInRange.new(_target_unit)
	)
	_sub_action.tree_exited.connect(_on_sub_action_finished)
	add_child(_sub_action)
	_unit.action_updated.emit()


func _to_string():
	return "{0}({1})".format([super(), str(_sub_action) if _sub_action != null else ""])


func _on_sub_action_finished():
	if not is_inside_tree():
		return
	if not is_applicable(_unit, _target_unit):
		queue_free()
		return
	_sub_action = null
	_construct_or_move_closer()


func _on_target_unit_constructed():
	if not is_inside_tree():
		return
	if _sub_action != null and _sub_action.tree_exited.is_connected(_on_sub_action_finished):
		_sub_action.tree_exited.disconnect(_on_sub_action_finished)
	queue_free()


func _on_target_unit_removed():
	queue_free()


static func _has_runtime_unit(unit):
	return unit != null and is_instance_valid(unit) and unit.is_inside_tree()
