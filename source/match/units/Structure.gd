extends "res://source/match/units/Unit.gd"

signal constructed

const Human = preload("res://source/match/players/human/Human.gd")
const UNDER_CONSTRUCTION_MATERIAL = preload(
	"res://source/match/resources/materials/structure_under_construction.material.tres"
)

var _construction_progress = 1.0
var _manual_repair_points_remaining = 0.0
var _manual_repair_timer = null

@onready var production_queue = find_child("ProductionQueue"):
	set(_value):
		pass


func is_revealing():
	return super() and is_constructed()


func mark_as_under_construction():
	assert(not is_under_construction(), "structure already under construction")
	_construction_progress = 0.0
	_change_geometry_material(UNDER_CONSTRUCTION_MATERIAL)
	if hp == null:
		await ready
	hp = 1
	MatchSignals.unit_construction_started.emit(self)


func construct(progress):
	assert(is_under_construction(), "structure must be under construction")

	var expected_hp_before_progressing = int(_construction_progress * float(hp_max - 1))
	_construction_progress += progress
	var expected_hp_after_progressing = int(_construction_progress * float(hp_max - 1))
	if expected_hp_after_progressing > expected_hp_before_progressing:
		hp += 1
	if _construction_progress >= 1.0:
		_finish_construction()


func cancel_construction():
	var scene_path = get_script().resource_path.replace(".gd", ".tscn")
	var construction_cost = Constants.Match.Units.CONSTRUCTION_COSTS[scene_path]
	player.add_resources(construction_cost)
	MatchSignals.unit_construction_canceled.emit(self)
	queue_free()


func get_sell_refund():
	var scene_path = get_script().resource_path.replace(".gd", ".tscn")
	var construction_cost = Constants.Match.Units.CONSTRUCTION_COSTS.get(
		scene_path, {"resource_a": 0, "resource_b": 0}
	)
	var hp_ratio = 1.0
	if hp != null and hp_max != null and hp_max > 0:
		hp_ratio = clampf(float(hp) / float(hp_max), 0.0, 1.0)
	var refund = {}
	for resource in construction_cost:
		refund[resource] = int(
			ceil(
				float(construction_cost[resource])
				* Constants.Match.Structure.SELL_REFUND_RATIO
				* hp_ratio
			)
		)
	return refund


func sell():
	if is_under_construction():
		cancel_construction()
		return
	_stop_manual_repair()
	if production_queue != null:
		production_queue.cancel_all()
	player.add_resources(get_sell_refund())
	MatchSignals.unit_sell_started.emit(self)
	tree_exited.connect(func(): MatchSignals.unit_sold.emit(self))
	queue_free()


func get_repair_cost():
	var scene_path = get_script().resource_path.replace(".gd", ".tscn")
	var construction_cost = Constants.Match.Units.CONSTRUCTION_COSTS.get(
		scene_path, {"resource_a": 0, "resource_b": 0}
	)
	var missing_hp = _missing_repair_hitpoints()
	var hp_ratio = missing_hp / hp_max if hp_max != null and hp_max > 0 else 0.0
	var repair_cost = {}
	for resource in construction_cost:
		repair_cost[resource] = int(
			ceil(
				float(construction_cost[resource])
				* Constants.Match.Structure.MANUAL_REPAIR_COST_RATIO
				* hp_ratio
			)
		)
	return repair_cost


func can_repair():
	return (
		is_constructed()
		and not is_repairing()
		and hp != null
		and hp_max != null
		and hp > 0
		and hp < hp_max
	)


func is_repairing():
	return _manual_repair_points_remaining > 0.0


func repair():
	if not can_repair():
		return false
	var repair_cost = get_repair_cost()
	if not player.has_resources(repair_cost):
		MatchSignals.not_enough_resources_for_construction.emit(player)
		return false
	player.subtract_resources(repair_cost)
	_manual_repair_points_remaining = _missing_repair_hitpoints()
	_start_manual_repair_timer()
	MatchSignals.unit_repair_started.emit(self)
	return true


func can_be_captured_by(capturing_player):
	return (
		capturing_player != null
		and capturing_player.is_enemy_with(player)
		and is_constructed()
		and is_inside_tree()
	)


func capture_by(capturing_player):
	if not can_be_captured_by(capturing_player):
		return false
	var previous_player = player
	var preserved_transform = global_transform
	if production_queue != null:
		production_queue.cancel_all()
	previous_player.remove_child(self)
	capturing_player.add_child(self)
	global_transform = preserved_transform
	_refresh_owner_groups()
	_setup_color()
	MatchSignals.unit_captured.emit(self, previous_player, capturing_player)
	return true


func is_constructed():
	return _construction_progress >= 1.0


func is_under_construction():
	return not is_constructed()


func can_auto_acquire_targets():
	return super() and not is_powered_combat_offline()


func is_powered_combat_offline():
	if player == null or not is_constructed():
		return false
	if attack_range == null or attack_domains.is_empty():
		return false
	var scene_path = get_script().resource_path.replace(".gd", ".tscn")
	return Constants.Match.Units.POWER_DRAIN.get(scene_path, 0) > 0 and player.is_low_power()


func _finish_construction():
	_change_geometry_material(null)
	if is_inside_tree():
		constructed.emit()
		MatchSignals.unit_construction_finished.emit(self)


func _missing_repair_hitpoints():
	if hp == null or hp_max == null:
		return 0.0
	return maxf(0.0, float(hp_max) - float(hp))


func _start_manual_repair_timer():
	if _manual_repair_timer == null or not is_instance_valid(_manual_repair_timer):
		_manual_repair_timer = Timer.new()
		_manual_repair_timer.wait_time = Constants.Match.Structure.MANUAL_REPAIR_TICK_SECONDS
		_manual_repair_timer.timeout.connect(_on_manual_repair_timer_timeout)
		add_child(_manual_repair_timer)
	_manual_repair_timer.start()


func _stop_manual_repair():
	_manual_repair_points_remaining = 0.0
	if _manual_repair_timer != null and is_instance_valid(_manual_repair_timer):
		_manual_repair_timer.stop()
	if player != null and player.has_method("emit_changed"):
		player.emit_changed()


func _on_manual_repair_timer_timeout():
	if not is_repairing() or hp == null or hp_max == null or hp <= 0:
		_stop_manual_repair()
		return
	var repaired_hp = minf(
		Constants.Match.Structure.MANUAL_REPAIR_HITPOINTS_PER_SECOND
		* Constants.Match.Structure.MANUAL_REPAIR_TICK_SECONDS,
		minf(_manual_repair_points_remaining, _missing_repair_hitpoints())
	)
	if repaired_hp <= 0.0:
		_stop_manual_repair()
		return
	hp = min(hp_max, hp + repaired_hp)
	_manual_repair_points_remaining -= repaired_hp
	if hp >= hp_max or _manual_repair_points_remaining <= 0.0:
		_stop_manual_repair()


func _change_geometry_material(material):
	for child in find_child("Geometry").find_children("*"):
		if "material_override" in child:
			child.material_override = material


func _refresh_owner_groups():
	remove_from_group("controlled_units")
	remove_from_group("adversary_units")
	var human_player = _get_human_player()
	if player == human_player:
		add_to_group("controlled_units")
	elif human_player != null and player.is_enemy_with(human_player):
		add_to_group("adversary_units")
	if _match != null and "visible_players" in _match and player in _match.visible_players:
		add_to_group("revealed_units")
	else:
		remove_from_group("revealed_units")
	var selection = find_child("Selection")
	if selection != null and selection.has_method("_update_circle_color"):
		selection.call("_update_circle_color")


func _get_human_player():
	if _match != null and "visible_player" in _match and _match.visible_player is Human:
		return _match.visible_player
	for player_candidate in get_tree().get_nodes_in_group("players"):
		if player_candidate is Human:
			return player_candidate
	return null
