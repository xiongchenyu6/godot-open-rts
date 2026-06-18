const Structure = preload("res://source/match/units/Structure.gd")
const Unit = preload("res://source/match/units/Unit.gd")
const AttackMoving = preload("res://source/match/units/actions/AttackMoving.gd")
const Moving = preload("res://source/match/units/actions/Moving.gd")
const Patrolling = preload("res://source/match/units/actions/Patrolling.gd")
const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")
const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const CommandButtonStatus = preload("res://source/match/hud/unit-menus/CommandButtonStatus.gd")

const SCATTER_DISTANCE_M = 4.0
const COMMAND_CANCEL = "cancel_current_action"
const COMMAND_HOLD_POSITION = "hold_position"
const COMMAND_DEPLOY_MODE = "deploy_mode"
const COMMAND_GUARD_AREA = "guard_area"
const COMMAND_SCATTER = "scatter"


static func cancel_current_actions(units):
	if (
		len(units) == 1
		and units[0] is Structure
		and units[0].is_in_group("controlled_units")
		and units[0].is_under_construction()
	):
		units[0].cancel_construction()
		return true
	var cancelled = false
	var cancel_units = _cancel_action_units(units)
	for unit in cancel_units:
		if unit.has_method("clear_action_queue"):
			unit.clear_action_queue()
		unit.action = null
		cancelled = true
	if cancelled:
		_emit_command_confirmed(COMMAND_CANCEL, cancel_units)
	return cancelled


static func has_cancellable_actions(units):
	return _can_cancel_under_construction_structure(units) or not _cancel_action_units(units).is_empty()


static func refresh_cancel_action_button(button, units):
	if button == null:
		return
	var can_cancel = has_cancellable_actions(units)
	button.disabled = not can_cancel
	CommandButtonStatus.apply_action(button, "CANCEL_CURRENT_ACTION")
	button.tooltip_text = CommandButtonHotkeys.tooltip(button, _cancel_action_tooltip(button, can_cancel))


static func refresh_hold_position_button(button, units):
	if button == null:
		return
	var hold_units = _hold_position_units(units)
	button.disabled = hold_units.is_empty()
	button.set_pressed_no_signal(_all_hold_position(hold_units))
	CommandButtonStatus.apply_action(button, "HOLD_POSITION")
	button.tooltip_text = CommandButtonHotkeys.tooltip(button, _hold_position_tooltip(button, hold_units))


static func refresh_attack_move_button(button, units):
	if button == null:
		return
	var attack_move_units = _attack_move_units(units)
	button.disabled = attack_move_units.is_empty()
	CommandButtonStatus.apply_action(button, "ATTACK_MOVE")
	button.tooltip_text = CommandButtonHotkeys.tooltip(
		button, _attack_move_tooltip(button, attack_move_units)
	)


static func refresh_patrol_button(button, units):
	if button == null:
		return
	var patrol_units = _patrol_units(units)
	button.disabled = patrol_units.is_empty()
	CommandButtonStatus.apply_action(button, "PATROL")
	button.tooltip_text = CommandButtonHotkeys.tooltip(button, _patrol_tooltip(button, patrol_units))


static func refresh_guard_area_button(button, units):
	if button == null:
		return
	var guard_units = _guard_area_units(units)
	button.disabled = guard_units.is_empty()
	CommandButtonStatus.apply_action(button, "GUARD_AREA")
	button.tooltip_text = CommandButtonHotkeys.tooltip(button, _guard_area_tooltip(button, guard_units))


static func refresh_scatter_button(button, units):
	if button == null:
		return
	var scatter_units = _scatter_units(units)
	button.disabled = scatter_units.is_empty()
	CommandButtonStatus.apply_action(button, "SCATTER")
	button.tooltip_text = CommandButtonHotkeys.tooltip(
		button, _scatter_tooltip(button, scatter_units)
	)


static func refresh_deploy_mode_button(button, units):
	if button == null:
		return
	var deploy_units = _deploy_mode_units(units)
	button.disabled = deploy_units.is_empty()
	button.set_pressed_no_signal(_all_deployed(deploy_units))
	CommandButtonStatus.apply_action(button, "DEPLOY_MODE")
	button.tooltip_text = CommandButtonHotkeys.tooltip(button, _deploy_mode_tooltip(button, deploy_units))


static func set_hold_position(units, enabled):
	var hold_units = _hold_position_units(units)
	for unit in hold_units:
		unit.hold_position = enabled
		if enabled:
			unit.action = null
	if not hold_units.is_empty():
		_emit_command_confirmed(COMMAND_HOLD_POSITION, hold_units)


static func set_deploy_mode(units, enabled):
	var deploy_units = _deploy_mode_units(units)
	for unit in deploy_units:
		unit.set_deploy_mode(enabled)
	if not deploy_units.is_empty():
		_emit_command_confirmed(COMMAND_DEPLOY_MODE, deploy_units)


static func toggle_hold_position(units):
	var hold_units = _hold_position_units(units)
	if hold_units.is_empty():
		return
	set_hold_position(hold_units, not _all_hold_position(hold_units))


static func request_attack_move(units):
	if _attack_move_units(units).is_empty():
		return false
	MatchSignals.attack_move_requested.emit()
	return true


static func request_patrol(units):
	if _patrol_units(units).is_empty():
		return false
	MatchSignals.patrol_requested.emit()
	return true


static func guard_area(units):
	var guard_units = _guard_area_units(units)
	if guard_units.is_empty():
		return false
	for unit in guard_units:
		unit.hold_position = false
		unit.action = null
	_emit_command_confirmed(COMMAND_GUARD_AREA, guard_units)
	return true


static func scatter_units(units):
	var moving_units = _scatter_units(units)
	if moving_units.is_empty():
		return false
	var targets = scatter_targets(moving_units)
	for tuple in targets:
		var unit = tuple[0]
		var target_position = tuple[1]
		unit.action = Moving.new(target_position)
	_emit_command_confirmed(COMMAND_SCATTER, moving_units)
	return true


static func scatter_targets(units):
	if units.is_empty():
		return []
	var pivot = Utils.Match.Unit.Movement.calculate_aabb_crowd_pivot_yless(units)
	var targets = []
	var index = 0
	for unit in units:
		var direction = unit.global_position_yless - pivot
		if direction.is_zero_approx():
			var angle = TAU * float(index) / max(1.0, float(units.size()))
			direction = Vector3(cos(angle), 0.0, sin(angle))
		targets.append([unit, unit.global_position_yless + direction.normalized() * SCATTER_DISTANCE_M])
		index += 1
	return targets


static func selected_controlled_units(tree):
	return _controlled_units(tree.get_nodes_in_group("selected_units"))


static func _controlled_units(units):
	return units.filter(
		func(unit):
			return (
				unit != null
				and is_instance_valid(unit)
				and unit is Unit
				and unit.is_in_group("controlled_units")
			)
	)


static func _can_cancel_under_construction_structure(units):
	return (
		len(units) == 1
		and units[0] is Structure
		and units[0].is_in_group("controlled_units")
		and units[0].is_under_construction()
	)


static func _cancel_action_units(units):
	return _controlled_units(units).filter(
		func(unit):
			return (
				_has_user_command_action(unit)
				or (unit.has_method("has_queued_actions") and unit.has_queued_actions())
			)
	)


static func _has_user_command_action(unit):
	return unit.action != null and not (unit.action is WaitingForTargets)


static func _hold_position_units(units):
	return _controlled_units(units).filter(
		func(unit):
			return (
				unit.attack_range != null
				and unit.attack_damage != null
				and unit.find_child("Movement") != null
			)
	)


static func _attack_move_units(units):
	return _controlled_units(units).filter(func(unit): return AttackMoving.is_applicable(unit))


static func _patrol_units(units):
	return _controlled_units(units).filter(func(unit): return Patrolling.is_applicable(unit))


static func _guard_area_units(units):
	return _controlled_units(units).filter(
		func(unit):
			return (
				unit.attack_range != null
				and unit.attack_damage != null
				and unit.find_child("Movement") != null
			)
	)


static func _scatter_units(units):
	return _controlled_units(units).filter(func(unit): return Moving.is_applicable(unit))


static func _deploy_mode_units(units):
	return _controlled_units(units).filter(
		func(unit):
			return (
				unit.has_method("can_toggle_deploy_mode")
				and unit.has_method("set_deploy_mode")
				and unit.has_method("is_deployed_mode")
				and unit.can_toggle_deploy_mode()
			)
	)


static func _all_hold_position(units):
	if units.is_empty():
		return false
	for unit in units:
		if not unit.hold_position:
			return false
	return true


static func _all_deployed(units):
	if units.is_empty():
		return false
	for unit in units:
		if not unit.is_deployed_mode():
			return false
	return true


static func _emit_command_confirmed(command_key, units):
	MatchSignals.unit_command_confirmed.emit(command_key, units)


static func _hold_position_tooltip(button, hold_units):
	if hold_units.is_empty():
		return "{0} - {1}".format([button.tr("HOLD_POSITION"), button.tr("HOLD_POSITION_DISABLED")])
	return "{0} - {1}".format([button.tr("HOLD_POSITION"), button.tr("HOLD_POSITION_DESCRIPTION")])


static func _attack_move_tooltip(button, attack_move_units):
	if attack_move_units.is_empty():
		return "{0} - {1}".format([button.tr("ATTACK_MOVE"), button.tr("ATTACK_MOVE_DISABLED")])
	return "{0} - {1}".format([button.tr("ATTACK_MOVE"), button.tr("ATTACK_MOVE_DESCRIPTION")])


static func _patrol_tooltip(button, patrol_units):
	if patrol_units.is_empty():
		return "{0} - {1}".format([button.tr("PATROL"), button.tr("PATROL_DISABLED")])
	return "{0} - {1}".format([button.tr("PATROL"), button.tr("PATROL_DESCRIPTION")])


static func _guard_area_tooltip(button, guard_units):
	if guard_units.is_empty():
		return "{0} - {1}".format([button.tr("GUARD_AREA"), button.tr("GUARD_AREA_DISABLED")])
	return "{0} - {1}".format([button.tr("GUARD_AREA"), button.tr("GUARD_AREA_DESCRIPTION")])


static func _scatter_tooltip(button, scatter_units):
	if scatter_units.is_empty():
		return "{0} - {1}".format([button.tr("SCATTER"), button.tr("SCATTER_DISABLED")])
	return "{0} - {1}".format([button.tr("SCATTER"), button.tr("SCATTER_DESCRIPTION")])


static func _cancel_action_tooltip(button, can_cancel):
	if not can_cancel:
		return "{0} - {1}".format(
			[button.tr("CANCEL_CURRENT_ACTION"), button.tr("CANCEL_CURRENT_ACTION_DISABLED")]
		)
	return "{0} - {1}".format(
		[button.tr("CANCEL_CURRENT_ACTION"), button.tr("CANCEL_CURRENT_ACTION_DESCRIPTION")]
	)


static func _deploy_mode_tooltip(button, deploy_units):
	if deploy_units.is_empty():
		return "{0} - {1}".format([button.tr("DEPLOY_MODE"), button.tr("DEPLOY_MODE_DISABLED")])
	if _all_deployed(deploy_units):
		return "{0} - {1}".format(
			[button.tr("DEPLOY_MODE"), button.tr("DEPLOY_MODE_UNDEPLOY_DESCRIPTION")]
		)
	return "{0} - {1}".format([button.tr("DEPLOY_MODE"), button.tr("DEPLOY_MODE_DESCRIPTION")])
