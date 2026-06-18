extends "res://source/match/units/Unit.gd"

const LandMineCombatVfx = preload("res://source/match/utils/CombatVfxUtils.gd")
const WEB_TRIGGER_SCAN_INTERVAL_SECONDS = 0.08

var mine_damage = 4.0
var trigger_radius = 0.9
var blast_radius = 1.5
var arming_delay = 0.25
var source_unit = null

var _armed_at = 0.0
var _web_trigger_scan_elapsed = 0.0


func _ready():
	await super()
	_armed_at = _now() + arming_delay


func _process(delta):
	if hp == null or hp <= 0 or _now() < _armed_at:
		return
	if OS.has_feature("web"):
		_web_trigger_scan_elapsed += delta
		if _web_trigger_scan_elapsed < WEB_TRIGGER_SCAN_INTERVAL_SECONDS:
			return
		_web_trigger_scan_elapsed = 0.0
	var trigger_target = _find_trigger_target()
	if trigger_target != null:
		_explode()


func _find_trigger_target():
	for target in get_tree().get_nodes_in_group("units"):
		if _can_trigger(target):
			return target
	return null


func _can_trigger(target):
	if target == self or target == null or not is_instance_valid(target):
		return false
	if not target.is_inside_tree() or not ("player" in target) or not player.is_enemy_with(target.player):
		return false
	if not ("hp" in target) or target.hp <= 0:
		return false
	if target.find_child("Movement") == null:
		return false
	if target.movement_domain != Constants.Match.Navigation.Domain.TERRAIN:
		return false
	var target_radius = target.radius if target.radius != null else 0.0
	return global_position_yless.distance_to(target.global_position_yless) <= trigger_radius + target_radius


func _explode():
	var impacted = false
	for target in get_tree().get_nodes_in_group("units"):
		if _can_damage_in_blast(target):
			target.register_damage_source(_damage_source())
			target.hp -= mine_damage
			LandMineCombatVfx.spawn_impact_at_unit(target, 0.7)
			impacted = true
	if impacted:
		LandMineCombatVfx.spawn_impact(get_parent(), global_position + Vector3(0, 0.25, 0), blast_radius)
	queue_free()


func _can_damage_in_blast(target):
	if not _can_trigger(target):
		return false
	var target_radius = target.radius if target.radius != null else 0.0
	return global_position_yless.distance_to(target.global_position_yless) <= blast_radius + target_radius


func _damage_source():
	if source_unit != null and is_instance_valid(source_unit) and source_unit.is_inside_tree():
		return source_unit
	return self
