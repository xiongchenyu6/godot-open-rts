extends "res://source/match/units/actions/Action.gd"

const AttackingWhileInRange = preload("res://source/match/units/actions/AttackingWhileInRange.gd")
const FollowingToReachDistance = preload(
	"res://source/match/units/actions/FollowingToReachDistance.gd"
)
const Moving = preload("res://source/match/units/actions/Moving.gd")

var _target_unit = null
var _sub_action = null
@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")


static func is_applicable(source_unit, target_unit):
	return (
		_has_source_unit(source_unit)
		and _has_target_unit(target_unit)
		and source_unit.attack_range != null
		and "player" in source_unit
		and "player" in target_unit
		and source_unit.player != null
		and target_unit.player != null
		and source_unit.player.is_enemy_with(target_unit.player)
		and "movement_domain" in target_unit
		and "attack_domains" in source_unit
		and target_unit.movement_domain in source_unit.attack_domains
		and (
			source_unit.global_position_yless.distance_to(target_unit.global_position_yless)
			<= source_unit.attack_range
			or Moving.is_applicable(source_unit)
		)
	)


func _init(target_unit):
	_target_unit = target_unit


func _ready():
	if _teardown_if_invalid_target():
		return
	_target_unit.tree_exited.connect(_on_target_unit_removed)
	_attack_or_move_closer()


func _to_string():
	return "{0}({1})".format([super(), str(_sub_action) if _sub_action != null else ""])


func _target_in_range():
	if _teardown_if_invalid_target():
		return false
	return (
		_unit.global_position_yless.distance_to(_target_unit.global_position_yless)
		<= _unit.attack_range
	)


func _attack_or_move_closer():
	if _teardown_if_invalid_target():
		return
	_sub_action = (
		AttackingWhileInRange.new(_target_unit)
		if _target_in_range()
		else FollowingToReachDistance.new(_target_unit, _unit.attack_range)
	)
	_sub_action.tree_exited.connect(_on_sub_action_finished)
	add_child(_sub_action)
	_unit.action_updated.emit()


func _on_target_unit_removed():
	queue_free()


func _on_sub_action_finished():
	if not is_inside_tree():
		return
	if _teardown_if_invalid_target():
		queue_free()
		return
	_attack_or_move_closer()


func _teardown_if_invalid_target():
	if not _has_source_unit(_unit) or not _has_target_unit(_target_unit):
		queue_free()
		return true
	return false


static func _has_source_unit(unit):
	return unit != null and is_instance_valid(unit) and unit.is_inside_tree()


static func _has_target_unit(unit):
	return unit != null and is_instance_valid(unit) and unit.is_inside_tree()
