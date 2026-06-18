extends "res://source/match/units/actions/Action.gd"

const GARRISON_ENTRY_MARGIN_M = 1.0

var _target_unit = null

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")


static func is_garrison_target(source_unit, target_unit):
	return (
		_has_runtime_unit(source_unit)
		and _has_runtime_unit(target_unit)
		and target_unit.has_method("can_garrison_unit")
		and target_unit.can_garrison_unit(source_unit)
	)


static func is_applicable(source_unit, target_unit):
	return (
		is_garrison_target(source_unit, target_unit)
		and _units_are_in_entry_range(source_unit, target_unit)
	)


static func _units_are_in_entry_range(source_unit, target_unit):
	if not _has_runtime_unit(source_unit) or not _has_runtime_unit(target_unit):
		return false
	var source_radius = source_unit.radius if source_unit.radius != null else 0.0
	var target_radius = target_unit.radius if target_unit.radius != null else 0.0
	return (
		source_unit.global_position_yless.distance_to(target_unit.global_position_yless)
		<= (
			source_radius
			+ target_radius
			+ Constants.Match.Units.ADHERENCE_MARGIN_M
			+ GARRISON_ENTRY_MARGIN_M
		)
	)


func _init(target_unit):
	_target_unit = target_unit


func _ready():
	if not _has_runtime_unit(_unit) or not _has_runtime_unit(_target_unit):
		queue_free()
		return
	_target_unit.tree_exited.connect(queue_free)
	if is_applicable(_unit, _target_unit):
		_target_unit.garrison_unit(_unit)
	queue_free()


static func _has_runtime_unit(unit):
	return unit != null and is_instance_valid(unit) and unit.is_inside_tree()
