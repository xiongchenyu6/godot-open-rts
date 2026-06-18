extends Node3D

signal changed

const Structure = preload("res://source/match/units/Structure.gd")

@export var resource_a = 0:
	set(value):
		resource_a = value
		emit_changed()
@export var resource_b = 0:
	set(value):
		resource_b = value
		emit_changed()
@export var color = Color.WHITE
@export var team_id = -1
@export var participates_in_match = true

var _color_material = null
var _production_veterancy_rank_by_structure_path = {}
var _power_sabotage_until_msec = 0
var _power_sabotage_timer = null


func is_allied_with(other_player):
	return (
		other_player == self
		or (
			other_player != null
			and "team_id" in other_player
			and team_id >= 0
			and other_player.team_id == team_id
		)
	)


func is_enemy_with(other_player):
	return other_player != null and not is_allied_with(other_player)


func add_resources(resources):
	for resource in resources:
		set(resource, get(resource) + resources[resource])


func has_resources(resources):
	if FeatureFlags.allow_resources_deficit_spending:
		return true
	for resource in resources:
		if get(resource) < resources[resource]:
			return false
	return true


func subtract_resources(resources):
	for resource in resources:
		set(resource, get(resource) - resources[resource])


func grant_production_veterancy_rank(producer_scene_path, rank):
	if producer_scene_path == null or producer_scene_path == "" or rank <= 0:
		return false
	var previous_rank = get_production_veterancy_rank(producer_scene_path)
	var next_rank = maxi(previous_rank, rank)
	if next_rank == previous_rank:
		return false
	_production_veterancy_rank_by_structure_path[producer_scene_path] = next_rank
	emit_changed()
	return true


func get_production_veterancy_rank(producer_scene_path):
	return int(_production_veterancy_rank_by_structure_path.get(producer_scene_path, 0))


func sabotage_power(duration_seconds):
	if duration_seconds <= 0.0:
		return false
	var was_sabotaged = is_power_sabotaged()
	var sabotage_until = Time.get_ticks_msec() + int(duration_seconds * 1000.0)
	_power_sabotage_until_msec = maxi(_power_sabotage_until_msec, sabotage_until)
	_start_power_sabotage_timer()
	if not was_sabotaged:
		emit_changed()
	return true


func is_power_sabotaged():
	return Time.get_ticks_msec() < _power_sabotage_until_msec


func get_power_sabotage_time_left():
	return maxf(0.0, float(_power_sabotage_until_msec - Time.get_ticks_msec()) / 1000.0)


func get_power_supply(include_under_construction = false):
	if is_power_sabotaged():
		return 0
	return _sum_structure_power(Constants.Match.Units.POWER_SUPPLY, include_under_construction)


func get_power_drain(include_under_construction = false):
	return _sum_structure_power(Constants.Match.Units.POWER_DRAIN, include_under_construction)


func get_power_margin(include_under_construction = false):
	return (
		get_power_supply(include_under_construction)
		- get_power_drain(include_under_construction)
	)


func is_low_power():
	return get_power_supply() < get_power_drain()


func get_production_speed_multiplier():
	if is_low_power():
		return Constants.Match.Power.LOW_POWER_PRODUCTION_SPEED_MULTIPLIER
	return 1.0


func get_color_material():
	if _color_material == null:
		_color_material = StandardMaterial3D.new()
		_color_material.vertex_color_use_as_albedo = true
		_color_material.albedo_color = color
		_color_material.metallic = 1
	return _color_material


func emit_changed():
	changed.emit()


func _start_power_sabotage_timer():
	if not is_inside_tree():
		return
	if _power_sabotage_timer == null or not is_instance_valid(_power_sabotage_timer):
		_power_sabotage_timer = Timer.new()
		_power_sabotage_timer.one_shot = true
		add_child(_power_sabotage_timer)
		_power_sabotage_timer.timeout.connect(_on_power_sabotage_timer_timeout)
	_power_sabotage_timer.start(maxf(0.01, get_power_sabotage_time_left()))


func _on_power_sabotage_timer_timeout():
	if is_power_sabotaged():
		_start_power_sabotage_timer()
		return
	emit_changed()


func _sum_structure_power(power_map, include_under_construction):
	var total = 0
	for child in get_children():
		if not child is Structure:
			continue
		if not include_under_construction and not child.is_constructed():
			continue
		var scene_path = child.get_script().resource_path.replace(".gd", ".tscn")
		total += power_map.get(scene_path, 0)
	return total
