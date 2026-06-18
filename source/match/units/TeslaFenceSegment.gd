extends "res://source/match/units/Structure.gd"

const TeslaFenceCombatVfx = preload("res://source/match/utils/CombatVfxUtils.gd")

var _zap_timer = null


func _ready():
	await super()
	_start_zap_timer()


func _start_zap_timer():
	_zap_timer = Timer.new()
	_zap_timer.wait_time = maxf(0.05, attack_interval)
	_zap_timer.timeout.connect(_on_zap_timer_timeout)
	add_child(_zap_timer)
	_zap_timer.start()


func _on_zap_timer_timeout():
	if not is_constructed() or is_powered_combat_offline() or attack_damage == null:
		return
	for target in _zap_targets():
		if not is_instance_valid(target):
			continue
		target.register_damage_source(self)
		target.hp -= attack_damage
		TeslaFenceCombatVfx.spawn_impact_at_unit(target, 0.45)


func _zap_targets():
	var targets = []
	for target in get_tree().get_nodes_in_group("units"):
		if _can_zap(target):
			targets.append(target)
	return targets


func _can_zap(target):
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
	return global_position_yless.distance_to(target.global_position_yless) <= attack_range + target_radius
