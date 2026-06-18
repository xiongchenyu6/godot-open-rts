extends Node

const Structure = preload("res://source/match/units/Structure.gd")
const ResourceUnit = preload("res://source/match/units/non-player/ResourceUnit.gd")
const TERRAIN_TARGET_MAP_MARGIN = 2.5


class Actions:
	const Moving = preload("res://source/match/units/actions/Moving.gd")
	const AttackMoving = preload("res://source/match/units/actions/AttackMoving.gd")
	const Patrolling = preload("res://source/match/units/actions/Patrolling.gd")
	const MovingToUnit = preload("res://source/match/units/actions/MovingToUnit.gd")
	const Following = preload("res://source/match/units/actions/Following.gd")
	const CollectingResourcesSequentially = preload(
		"res://source/match/units/actions/CollectingResourcesSequentially.gd"
	)
	const AutoAttacking = preload("res://source/match/units/actions/AutoAttacking.gd")
	const Constructing = preload("res://source/match/units/actions/Constructing.gd")
	const Repairing = preload("res://source/match/units/actions/Repairing.gd")
	const Capturing = preload("res://source/match/units/actions/Capturing.gd")
	const Garrisoning = preload("res://source/match/units/actions/Garrisoning.gd")

var _attack_move_armed = false
var _patrol_armed = false
var _rally_point_targeting_active = false
var _support_power_targeting_active = false

@onready var _match = find_parent("Match")


func _ready():
	MatchSignals.terrain_targeted.connect(_on_terrain_targeted)
	MatchSignals.unit_targeted.connect(_on_unit_targeted)
	MatchSignals.unit_spawned.connect(_on_unit_spawned)
	MatchSignals.navigate_unit_to_rally_point.connect(_on_navigate_unit_to_rally_point)
	MatchSignals.attack_move_requested.connect(_on_attack_move_requested)
	MatchSignals.patrol_requested.connect(_on_patrol_requested)
	MatchSignals.rally_point_requested.connect(_on_rally_point_requested)
	MatchSignals.support_power_targeting_started.connect(_on_support_power_targeting_started)
	MatchSignals.support_power_targeting_finished.connect(_on_support_power_targeting_finished)


func _unhandled_input(event):
	if event.is_action_pressed("cancel_current_action"):
		var selected_units = Utils.Match.UnitCommands.selected_controlled_units(get_tree())
		if Utils.Match.UnitCommands.cancel_current_actions(selected_units):
			_attack_move_armed = false
			_patrol_armed = false
			_rally_point_targeting_active = false
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("hold_position"):
		Utils.Match.UnitCommands.toggle_hold_position(
			Utils.Match.UnitCommands.selected_controlled_units(get_tree())
		)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("guard_area"):
		var selected_units = Utils.Match.UnitCommands.selected_controlled_units(get_tree())
		if Utils.Match.UnitCommands.guard_area(selected_units):
			_attack_move_armed = false
			_patrol_armed = false
			_rally_point_targeting_active = false
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("scatter"):
		var selected_units = Utils.Match.UnitCommands.selected_controlled_units(get_tree())
		if Utils.Match.UnitCommands.scatter_units(selected_units):
			_attack_move_armed = false
			_patrol_armed = false
			_rally_point_targeting_active = false
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("attack_move"):
		_attack_move_armed = true
		_patrol_armed = false
	if event.is_action_pressed("patrol"):
		_patrol_armed = true
		_attack_move_armed = false


func _try_navigating_selected_units_towards_position(target_point, queued = false):
	var terrain_units_to_move = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit):
			return (
				unit.is_in_group("controlled_units")
				and unit.movement_domain == Constants.Match.Navigation.Domain.TERRAIN
				and Actions.Moving.is_applicable(unit)
			)
	)
	var air_units_to_move = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit):
			return (
				unit.is_in_group("controlled_units")
				and unit.movement_domain == Constants.Match.Navigation.Domain.AIR
				and Actions.Moving.is_applicable(unit)
			)
	)
	var new_unit_targets = Utils.Match.Unit.Movement.crowd_moved_to_new_pivot(
		terrain_units_to_move, target_point
	)
	new_unit_targets += Utils.Match.Unit.Movement.crowd_moved_to_new_pivot(
		air_units_to_move, target_point
	)
	for tuple in new_unit_targets:
		var unit = tuple[0]
		var new_target = tuple[1]
		_assign_or_queue_action(unit, Actions.Moving.new(new_target), queued)


func _try_attack_moving_selected_units_towards_position(target_point, queued = false):
	var terrain_units_to_move = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit):
			return (
				unit.is_in_group("controlled_units")
				and unit.movement_domain == Constants.Match.Navigation.Domain.TERRAIN
				and Actions.AttackMoving.is_applicable(unit)
			)
	)
	var air_units_to_move = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit):
			return (
				unit.is_in_group("controlled_units")
				and unit.movement_domain == Constants.Match.Navigation.Domain.AIR
				and Actions.AttackMoving.is_applicable(unit)
			)
	)
	var new_unit_targets = Utils.Match.Unit.Movement.crowd_moved_to_new_pivot(
		terrain_units_to_move, target_point
	)
	new_unit_targets += Utils.Match.Unit.Movement.crowd_moved_to_new_pivot(
		air_units_to_move, target_point
	)
	for tuple in new_unit_targets:
		var unit = tuple[0]
		var new_target = tuple[1]
		_assign_or_queue_action(unit, Actions.AttackMoving.new(new_target), queued)


func _try_patrolling_selected_units_towards_position(target_point, queued = false):
	var terrain_units_to_move = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit):
			return (
				unit.is_in_group("controlled_units")
				and unit.movement_domain == Constants.Match.Navigation.Domain.TERRAIN
				and Actions.Patrolling.is_applicable(unit)
			)
	)
	var air_units_to_move = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit):
			return (
				unit.is_in_group("controlled_units")
				and unit.movement_domain == Constants.Match.Navigation.Domain.AIR
				and Actions.Patrolling.is_applicable(unit)
			)
	)
	var new_unit_targets = Utils.Match.Unit.Movement.crowd_moved_to_new_pivot(
		terrain_units_to_move, target_point
	)
	new_unit_targets += Utils.Match.Unit.Movement.crowd_moved_to_new_pivot(
		air_units_to_move, target_point
	)
	for tuple in new_unit_targets:
		var unit = tuple[0]
		var new_target = tuple[1]
		_assign_or_queue_action(unit, Actions.Patrolling.new(new_target), queued)


func _assign_or_queue_action(unit, action_node, queued):
	if queued and unit.has_method("queue_action"):
		unit.queue_action(action_node)
	else:
		unit.action = action_node


func _try_setting_rally_points(target_point: Vector3):
	var controlled_structures = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit):
			return (
				unit.is_in_group("controlled_units")
				and unit.find_child("RallyPoint", true, false) != null
			)
	)
	for structure in controlled_structures:
		var rally_point = structure.find_child("RallyPoint", true, false)
		if rally_point != null:
			rally_point.set_target_position(target_point)


func _try_setting_rally_points_to_unit(target_unit):
	var rally_point_set = false
	for structure in get_tree().get_nodes_in_group("selected_units"):
		if not structure.is_in_group("controlled_units"):
			continue
		if _try_setting_rally_point_to_unit(structure, target_unit):
			rally_point_set = true
	return rally_point_set


func _try_ordering_selected_workers_to_construct_structure(potential_structure):
	if not potential_structure is Structure or potential_structure.is_constructed():
		return
	var structure = potential_structure
	var selected_constructors = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit):
			return (
				unit.is_in_group("controlled_units")
				and Actions.Constructing.is_applicable(unit, structure)
			)
	)
	for unit in selected_constructors:
		unit.action = Actions.Constructing.new(structure)


func _navigate_selected_units_towards_unit(target_unit):
	var at_least_one_unit_navigated = false
	var units_to_move_in_formation = []
	for unit in get_tree().get_nodes_in_group("selected_units"):
		if not unit.is_in_group("controlled_units"):
			continue
		if _navigate_unit_towards_unit_with_dedicated_action(unit, target_unit):
			at_least_one_unit_navigated = true
		elif _try_setting_rally_point_to_unit(unit, target_unit):
			at_least_one_unit_navigated = true
		elif Actions.Following.is_applicable(unit):
			units_to_move_in_formation.append(unit)
	if _navigate_units_towards_unit_in_formation(units_to_move_in_formation, target_unit):
		at_least_one_unit_navigated = true
	return at_least_one_unit_navigated


func _force_move_selected_units_towards_unit(target_unit):
	var units_to_move_in_formation = []
	for unit in get_tree().get_nodes_in_group("selected_units"):
		if not unit.is_in_group("controlled_units"):
			continue
		if Actions.Following.is_applicable(unit):
			units_to_move_in_formation.append(unit)
	return _navigate_units_towards_unit_in_formation(units_to_move_in_formation, target_unit)


func _navigate_unit_towards_unit(unit, target_unit):
	if _navigate_unit_towards_unit_with_dedicated_action(unit, target_unit):
		return true
	if _try_setting_rally_point_to_unit(unit, target_unit):
		return true
	if Actions.Following.is_applicable(unit):
		unit.action = Actions.Following.new(target_unit)
		return true
	return false


func _navigate_unit_towards_unit_with_dedicated_action(unit, target_unit):
	if Actions.CollectingResourcesSequentially.is_applicable(unit, target_unit):
		unit.action = Actions.CollectingResourcesSequentially.new(target_unit)
		return true
	if Actions.Capturing.is_applicable(unit, target_unit):
		unit.action = Actions.Capturing.new(target_unit)
		return true
	if Actions.Garrisoning.is_applicable(unit, target_unit):
		unit.action = Actions.Garrisoning.new(target_unit)
		return true
	if Actions.AutoAttacking.is_applicable(unit, target_unit):
		unit.action = Actions.AutoAttacking.new(target_unit)
		return true
	if Actions.Constructing.is_applicable(unit, target_unit):
		unit.action = Actions.Constructing.new(target_unit)
		return true
	if Actions.Repairing.is_applicable(unit, target_unit):
		unit.action = Actions.Repairing.new(target_unit)
		return true
	return false


func _navigate_units_towards_unit_in_formation(units, target_unit):
	var at_least_one_unit_navigated = false
	var terrain_units_to_move = units.filter(
		func(unit): return unit.movement_domain == Constants.Match.Navigation.Domain.TERRAIN
	)
	var air_units_to_move = units.filter(
		func(unit): return unit.movement_domain == Constants.Match.Navigation.Domain.AIR
	)
	var new_unit_targets = Utils.Match.Unit.Movement.crowd_moved_to_unit(
		terrain_units_to_move, target_unit
	)
	new_unit_targets += Utils.Match.Unit.Movement.crowd_moved_to_unit(air_units_to_move, target_unit)
	for tuple in new_unit_targets:
		var unit = tuple[0]
		var target_position = tuple[1]
		var target_position_offset = target_position - target_unit.global_position_yless
		unit.action = Actions.Following.new(target_unit, target_position_offset)
		at_least_one_unit_navigated = true
	return at_least_one_unit_navigated


func _try_setting_rally_point_to_unit(unit, target_unit):
	if not unit is Structure:
		return false
	if not target_unit is ResourceUnit and unit.player != target_unit.player:
		# it's not allowed to set rally point to enemy at the moment as with current implementation
		# the position of enemy unit hidden in the fog of war could be hinted
		return false
	var rally_point = unit.find_child("RallyPoint", true, false)
	if rally_point == null:
		return false
	rally_point.set_target_unit(target_unit)
	return true


func _on_terrain_targeted(position):
	var target_position = _validated_terrain_target(position)
	if target_position == null:
		return
	if _support_power_targeting_active:
		_attack_move_armed = false
		_patrol_armed = false
		_rally_point_targeting_active = false
		return
	if _rally_point_targeting_active:
		_try_setting_rally_points(target_position)
		_rally_point_targeting_active = false
		_attack_move_armed = false
		_patrol_armed = false
		return
	var queued = _should_queue_terrain_command()
	if _should_patrol():
		_try_patrolling_selected_units_towards_position(target_position, queued)
	elif _should_attack_move():
		_try_attack_moving_selected_units_towards_position(target_position, queued)
	else:
		_try_navigating_selected_units_towards_position(target_position, queued)
		if not queued:
			_try_setting_rally_points(target_position)
	_attack_move_armed = false
	_patrol_armed = false


func _validated_terrain_target(position):
	if not position is Vector3:
		return null
	if not position.is_finite():
		return null

	var target_position = position * Vector3(1, 0, 1)
	var map_node = _match.map if _match != null else null
	if map_node == null:
		return target_position

	var map_size = map_node.size
	if (
		target_position.x < -TERRAIN_TARGET_MAP_MARGIN
		or target_position.z < -TERRAIN_TARGET_MAP_MARGIN
		or target_position.x > map_size.x + TERRAIN_TARGET_MAP_MARGIN
		or target_position.z > map_size.y + TERRAIN_TARGET_MAP_MARGIN
	):
		return null

	return Vector3(
		clampf(target_position.x, 0.0, map_size.x),
		0.0,
		clampf(target_position.z, 0.0, map_size.y)
	)


func _on_unit_targeted(unit):
	_attack_move_armed = false
	_patrol_armed = false
	if _support_power_targeting_active:
		_rally_point_targeting_active = false
		return
	if _should_force_move():
		_rally_point_targeting_active = false
		if _force_move_selected_units_towards_unit(unit):
			var targetability = unit.find_child("Targetability")
			if targetability != null:
				targetability.animate()
		return
	if _rally_point_targeting_active:
		_try_setting_rally_points_to_unit(unit)
		_rally_point_targeting_active = false
		return
	if _navigate_selected_units_towards_unit(unit):
		var targetability = unit.find_child("Targetability")
		if targetability != null:
			targetability.animate()


func _on_unit_spawned(unit):
	_try_ordering_selected_workers_to_construct_structure(unit)


func _on_navigate_unit_to_rally_point(unit, rally_point):
	if not rally_point.is_set:
		return
	if rally_point.target_unit != null:
		_navigate_unit_towards_unit(unit, rally_point.target_unit)
	else:
		unit.action = Actions.Moving.new(rally_point.global_position)


func _on_attack_move_requested():
	if _support_power_targeting_active:
		return
	_rally_point_targeting_active = false
	_patrol_armed = false
	_attack_move_armed = true


func _on_patrol_requested():
	if _support_power_targeting_active:
		return
	_rally_point_targeting_active = false
	_attack_move_armed = false
	_patrol_armed = true


func _on_rally_point_requested():
	if _support_power_targeting_active:
		return
	_attack_move_armed = false
	_patrol_armed = false
	_rally_point_targeting_active = true


func _should_attack_move():
	return _attack_move_armed or Input.is_action_pressed("attack_move")


func _should_patrol():
	return _patrol_armed or Input.is_action_pressed("patrol")


func _should_force_move():
	return Input.is_key_pressed(KEY_ALT)


func _should_queue_terrain_command():
	return Input.is_action_pressed("shift_selecting")


func _on_support_power_targeting_started(_power_id):
	_support_power_targeting_active = true
	_rally_point_targeting_active = false
	_attack_move_armed = false
	_patrol_armed = false


func _on_support_power_targeting_finished(_power_id):
	call_deferred("_finish_support_power_targeting")


func _finish_support_power_targeting():
	_support_power_targeting_active = false
