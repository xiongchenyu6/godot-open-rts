extends "res://source/match/units/actions/Action.gd"

var _target_unit = null

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")


func _init(target_unit):
	_target_unit = target_unit


func _ready():
	if not _has_runtime_unit(_unit) or not _has_runtime_unit(_target_unit):
		queue_free()
		return
	_target_unit.tree_exited.connect(queue_free)
	_target_unit.constructed.connect(queue_free)
	var sparkling = _unit.get_node_or_null("Sparkling")
	if sparkling != null:
		sparkling.enable()


func _exit_tree():
	if _unit == null or not is_instance_valid(_unit):
		return
	var sparkling = _unit.get_node_or_null("Sparkling")
	if sparkling != null:
		sparkling.disable()


func _process(delta):
	if (
		not _has_runtime_unit(_unit)
		or not _has_runtime_unit(_target_unit)
		or not Utils.Match.Unit.Movement.units_adhere(_unit, _target_unit)
		or _target_unit.is_constructed()
	):
		queue_free()
		return
	_target_unit.construct(delta * Constants.Match.Units.STRUCTURE_CONSTRUCTING_SPEED)


func _has_runtime_unit(unit):
	return unit != null and is_instance_valid(unit) and unit.is_inside_tree()
