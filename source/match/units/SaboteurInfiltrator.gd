extends "res://source/match/units/CombatUnit.gd"

var infiltration_resource_steal_ratio = 0.0
var infiltration_resource_steal_cap = 0
var infiltration_production_veterancy_rank = 0
var infiltration_power_sabotage_duration = 0.0


func apply_infiltration_on_capture(target_structure):
	if target_structure == null or not is_instance_valid(target_structure):
		return
	var target_scene_path = target_structure.get_script().resource_path.replace(".gd", ".tscn")
	_apply_resource_infiltration(target_structure, target_scene_path)
	_apply_power_sabotage_infiltration(target_structure, target_scene_path)
	_apply_production_veterancy_infiltration(target_scene_path)


func _apply_resource_infiltration(target_structure, target_scene_path):
	if not Constants.Match.Capture.INFILTRATION_RESOURCE_TARGETS.has(target_scene_path):
		return
	var victim = target_structure.player
	if victim == null or victim == player:
		return
	for resource_name in ["resource_a", "resource_b"]:
		_steal_resource(victim, resource_name)


func _apply_production_veterancy_infiltration(target_scene_path):
	if not Constants.Match.Capture.INFILTRATION_PRODUCTION_VETERANCY_TARGETS.has(
		target_scene_path
	):
		return
	var producer_scene_path = (
		Constants.Match.Capture.INFILTRATION_PRODUCTION_VETERANCY_TARGETS[
			target_scene_path
		]
	)
	player.grant_production_veterancy_rank(
		producer_scene_path, infiltration_production_veterancy_rank
	)


func _apply_power_sabotage_infiltration(target_structure, target_scene_path):
	if not Constants.Match.Capture.INFILTRATION_POWER_SABOTAGE_TARGETS.has(target_scene_path):
		return
	var victim = target_structure.player
	if victim == null or victim == player or not victim.has_method("sabotage_power"):
		return
	victim.sabotage_power(infiltration_power_sabotage_duration)


func _steal_resource(victim, resource_name):
	var available = int(victim.get(resource_name))
	if available <= 0:
		return
	var amount = mini(
		infiltration_resource_steal_cap,
		maxi(1, int(ceil(float(available) * infiltration_resource_steal_ratio)))
	)
	amount = mini(amount, available)
	victim.set(resource_name, available - amount)
	player.set(resource_name, int(player.get(resource_name)) + amount)
