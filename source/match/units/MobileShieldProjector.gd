extends "res://source/match/units/CombatUnit.gd"

const Unit = preload("res://source/match/units/Unit.gd")

const SHIELD_REFRESH_INTERVAL_S = 0.2

var support_shield_radius = 4.0
var support_shield_duration = 0.7
var support_shield_damage_multiplier = 0.55

var _refresh_cooldown = 0.0


func _ready():
	await super()
	var sparkling = find_child("Sparkling")
	if sparkling != null:
		sparkling.enable()


func _process(delta):
	if hp == null or hp <= 0 or is_emp_disabled():
		return
	_refresh_cooldown -= delta
	if _refresh_cooldown > 0.0:
		return
	_refresh_cooldown = SHIELD_REFRESH_INTERVAL_S
	_refresh_nearby_shields()


func _refresh_nearby_shields():
	for unit in get_tree().get_nodes_in_group("units"):
		if _can_shield(unit):
			unit.apply_support_shield(support_shield_duration, support_shield_damage_multiplier)


func _can_shield(unit):
	if not unit is Unit:
		return false
	if not player.is_allied_with(unit.player):
		return false
	if unit.hp == null or unit.hp <= 0:
		return false
	var unit_radius = unit.radius if unit.radius != null else 0.0
	return (
		global_position_yless.distance_to(unit.global_position_yless)
		<= support_shield_radius + unit_radius
	)
