extends "res://source/match/units/Structure.gd"

const Structure = preload("res://source/match/units/Structure.gd")

const REPAIR_RADIUS = 3.2
const WEB_REPAIR_SCAN_INTERVAL_SECONDS = 0.2

var _web_repair_scan_elapsed = 0.0


func _process(delta):
	if not is_constructed() or is_powered_repair_offline():
		return
	if OS.has_feature("web"):
		_web_repair_scan_elapsed += delta
		if _web_repair_scan_elapsed < WEB_REPAIR_SCAN_INTERVAL_SECONDS:
			return
		delta = _web_repair_scan_elapsed
		_web_repair_scan_elapsed = 0.0
	var target = _find_repair_target()
	if target == null:
		return
	target.hp = min(target.hp_max, target.hp + delta * repair_rate)


func is_powered_repair_offline():
	if player == null or not is_constructed():
		return false
	var scene_path = get_script().resource_path.replace(".gd", ".tscn")
	return Constants.Match.Units.POWER_DRAIN.get(scene_path, 0) > 0 and player.is_low_power()


func _find_repair_target():
	var targets = get_tree().get_nodes_in_group("units").filter(_can_repair)
	if targets.is_empty():
		return null
	targets.sort_custom(
		func(a, b): return _distance_to_repair_target(a) < _distance_to_repair_target(b)
	)
	return targets[0]


func _can_repair(unit):
	if unit == self or not is_instance_valid(unit) or not unit.is_inside_tree():
		return false
	if not ("player" in unit) or not player.is_allied_with(unit.player):
		return false
	if unit is Structure:
		return false
	if (
		not ("movement_domain" in unit)
		or unit.movement_domain != Constants.Match.Navigation.Domain.TERRAIN
	):
		return false
	if not ("hp" in unit) or not ("hp_max" in unit):
		return false
	if unit.hp == null or unit.hp_max == null or unit.hp >= unit.hp_max:
		return false
	var unit_radius = unit.radius if unit.radius != null else 0.0
	return global_position_yless.distance_to(unit.global_position_yless) <= REPAIR_RADIUS + unit_radius


func _distance_to_repair_target(unit):
	return global_position_yless.distance_to(unit.global_position_yless)
