extends "res://source/match/units/actions/Action.gd"

const Structure = preload("res://source/match/units/Structure.gd")

const CAPTURE_ENTRY_MARGIN_M = 1.0

var _target_unit = null
var _elapsed = 0.0

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")


static func is_capture_target(source_unit, target_unit):
	return (
		_has_runtime_unit(source_unit)
		and _has_runtime_unit(target_unit)
		and target_unit is Structure
		and "player" in source_unit
		and source_unit.player != null
		and target_unit.can_be_captured_by(source_unit.player)
		and "capture_time" in source_unit
		and source_unit.capture_time != null
		and source_unit.capture_time > 0.0
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
	if (
		not _units_are_in_entry_range(_unit, _target_unit)
		or not is_capture_target(_unit, _target_unit)
	):
		queue_free()
		return
	_elapsed += delta
	if _elapsed < maxf(0.01, _unit.capture_time):
		return
	if _unit.has_method("apply_infiltration_on_capture"):
		_unit.apply_infiltration_on_capture(_target_unit)
	var captured = _target_unit.capture_by(_unit.player)
	if captured and is_instance_valid(_unit):
		_unit.queue_free()
	queue_free()


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
			+ CAPTURE_ENTRY_MARGIN_M
		)
	)


static func _has_runtime_unit(unit):
	return unit != null and is_instance_valid(unit) and unit.is_inside_tree()
