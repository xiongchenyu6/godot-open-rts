extends "res://source/match/units/actions/Action.gd"

const Structure = preload("res://source/match/units/Structure.gd")

const REPAIR_ENTRY_MARGIN_M = 1.0

var _target_unit = null

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")


static func is_applicable(source_unit, target_unit):
	return is_repair_target(target_unit) and _units_are_in_repair_range(source_unit, target_unit)


static func is_repair_target(unit):
	if unit == null or not is_instance_valid(unit):
		return false
	if not unit.is_inside_tree():
		return false
	if not "hp" in unit or not "hp_max" in unit:
		return false
	if unit.hp == null or unit.hp_max == null:
		return false
	if unit is Structure and not unit.is_constructed():
		return false
	return unit.hp < unit.hp_max


static func _units_are_in_repair_range(source_unit, target_unit):
	if source_unit == null or target_unit == null:
		return false
	if not is_instance_valid(source_unit) or not is_instance_valid(target_unit):
		return false
	if not source_unit.is_inside_tree() or not target_unit.is_inside_tree():
		return false
	var target_radius = target_unit.radius if target_unit.radius != null else 0.0
	var distance = source_unit.global_position_yless.distance_to(target_unit.global_position_yless)
	if (
		"repair_radius" in source_unit
		and source_unit.repair_radius != null
		and source_unit.repair_radius > 0.0
	):
		return distance <= source_unit.repair_radius + target_radius
	return (
		distance
		<= (
			source_unit.radius
			+ target_radius
			+ Constants.Match.Units.ADHERENCE_MARGIN_M
			+ REPAIR_ENTRY_MARGIN_M
		)
	)


func _init(target_unit):
	_target_unit = target_unit


func _ready():
	if not _has_runtime_unit(_unit) or not _has_runtime_unit(_target_unit):
		queue_free()
		return
	_target_unit.tree_exited.connect(queue_free)
	var sparkling = _unit.find_child("Sparkling")
	if sparkling != null:
		sparkling.enable()


func _exit_tree():
	if _unit == null or not is_instance_valid(_unit):
		return
	var sparkling = _unit.find_child("Sparkling")
	if sparkling != null:
		sparkling.disable()


func _process(delta):
	if not is_applicable(_unit, _target_unit):
		queue_free()
		return
	var repair_rate = (
		_unit.repair_rate
		if "repair_rate" in _unit and _unit.repair_rate != null
		else Constants.Match.Repair.HITPOINTS_PER_SECOND
	)
	_target_unit.hp = min(_target_unit.hp_max, _target_unit.hp + delta * repair_rate)


static func _has_runtime_unit(unit):
	return unit != null and is_instance_valid(unit) and unit.is_inside_tree()
