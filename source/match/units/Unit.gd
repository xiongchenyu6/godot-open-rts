extends Area3D

signal selected
signal deselected
signal hp_changed
signal action_changed(new_action)
signal action_updated
signal veterancy_changed(new_rank)
signal emp_disabled_changed(disabled)

const MATERIAL_ALBEDO_TO_REPLACE = Color(0.99, 0.81, 0.48)
const MATERIAL_ALBEDO_TO_REPLACE_EPSILON = 0.05
const CombatVfx = preload("res://source/match/utils/CombatVfxUtils.gd")
const _WaitingForTargetsAction = preload("res://source/match/units/actions/WaitingForTargets.gd")

var hp = null:
	set = _set_hp
var hp_max = null:
	set = _set_hp_max
var attack_damage = null
var attack_interval = null
var attack_range = null
var attack_domains = []
var splash_radius = 0.0
var splash_damage_multiplier = 0.5
var structure_damage_multiplier = 1.0
var repair_rate = null
var capture_time = null
var radius:
	get = _get_radius
var movement_domain:
	get = _get_movement_domain
var movement_speed:
	get = _get_movement_speed
var sight_range = null
var experience_points = 0
var veterancy_rank = 0
var hold_position = false
var emp_disabled:
	get:
		return is_emp_disabled()
var chrono_relayed:
	get:
		return is_chrono_relayed()
var support_shielded:
	get:
		return is_support_shielded()
var last_damage_source = null
var player:
	get:
		return get_parent()
var color:
	get:
		return player.color
var action = null:
	set = _set_action
var action_queue = []
var global_position_yless:
	get:
		return global_position * Vector3(1, 0, 1)
var type:
	get = _get_type

var _action_locked = false
var _base_veterancy_properties = {}
var _death_handled = false
var _chrono_relay_until = 0.0
var _chrono_relay_speed_multiplier = 1.0
var _emp_disabled_until = 0.0
var _emp_disabled_timer = null
var _support_shield_until = 0.0
var _support_shield_damage_multiplier = 1.0
var _elite_regeneration_timer = null
var _setting_queued_action = false
var _clearing_finished_action = false

@onready var _match = find_parent("Match")


func _ready():
	if not _match.is_node_ready():
		await _match.ready
	_setup_color()
	_setup_default_properties_from_constants()
	_capture_base_veterancy_properties()
	assert(_safety_checks())


func is_revealing():
	return is_in_group("revealed_units") and visible


func is_emp_disabled():
	return _emp_disabled_until > _now()


func is_chrono_relayed():
	return _chrono_relay_until > _now()


func is_support_shielded():
	return _support_shield_until > _now()


func apply_chrono_relay(duration, speed_multiplier):
	if hp != null and hp <= 0:
		return
	if find_child("Movement") == null:
		return
	var was_relayed = is_chrono_relayed()
	_chrono_relay_until = maxf(_chrono_relay_until, _now() + duration)
	if was_relayed:
		_chrono_relay_speed_multiplier = maxf(_chrono_relay_speed_multiplier, speed_multiplier)
	else:
		_chrono_relay_speed_multiplier = speed_multiplier


func get_chrono_speed_multiplier():
	if is_chrono_relayed():
		return _chrono_relay_speed_multiplier
	return 1.0


func disable_by_emp(duration):
	if hp != null and hp <= 0:
		return
	var was_disabled = is_emp_disabled()
	_emp_disabled_until = maxf(_emp_disabled_until, _now() + duration)
	_interrupt_for_emp()
	_start_emp_disabled_timer()
	if not was_disabled:
		emp_disabled_changed.emit(true)


func apply_support_shield(duration, damage_multiplier):
	if hp != null and hp <= 0:
		return
	_support_shield_until = maxf(_support_shield_until, _now() + duration)
	_support_shield_damage_multiplier = clampf(damage_multiplier, 0.0, 1.0)


func can_auto_acquire_targets():
	return not is_emp_disabled()


func can_crush_units():
	return (
		hp != null
		and hp > 0
		and not is_emp_disabled()
		and find_child("Movement") != null
		and movement_domain == Constants.Match.Navigation.Domain.TERRAIN
		and Constants.Match.Units.CRUSHER_UNIT_PATHS.has(_unit_scene_path())
	)


func can_be_crushed_by(crusher_unit):
	return (
		crusher_unit != null
		and is_instance_valid(crusher_unit)
		and crusher_unit.has_method("can_crush_units")
		and crusher_unit.can_crush_units()
		and hp != null
		and hp > 0
		and find_child("Movement") != null
		and movement_domain == Constants.Match.Navigation.Domain.TERRAIN
		and Constants.Match.Units.CRUSHABLE_UNIT_PATHS.has(_unit_scene_path())
		and crusher_unit.player.is_enemy_with(player)
	)


func try_crush_nearby_units(from_position_yless = null, to_position_yless = null):
	if not can_crush_units():
		return []
	if from_position_yless == null:
		from_position_yless = global_position_yless
	if to_position_yless == null:
		to_position_yless = global_position_yless
	var crushed_units = []
	for target in get_tree().get_nodes_in_group("units"):
		if _can_crush_target(target, from_position_yless, to_position_yless):
			_crush_target(target)
			crushed_units.append(target)
	return crushed_units


func queue_action(action_node):
	if action_node == null:
		return
	if not is_inside_tree() or is_emp_disabled():
		action_node.queue_free()
		return
	action_queue.append(action_node)
	if not _current_action_blocks_queue():
		_start_next_queued_action()
	else:
		action_updated.emit()


func clear_action_queue():
	for queued_action in action_queue:
		if queued_action != null and is_instance_valid(queued_action):
			queued_action.queue_free()
	action_queue.clear()
	action_updated.emit()


func has_queued_actions():
	return not action_queue.is_empty()


func _set_hp(value):
	var old_hp = hp
	if old_hp != null and value < old_hp and is_support_shielded():
		var damage = old_hp - value
		value = old_hp - damage * _support_shield_damage_multiplier
	hp = max(0, value)
	if old_hp != null and hp < old_hp:
		MatchSignals.unit_damaged.emit(self)
	hp_changed.emit()
	if hp == 0 and not _death_handled:
		_handle_unit_death()


func _set_hp_max(value):
	hp_max = value
	hp_changed.emit()


func _get_radius():
	if find_child("Movement") != null:
		return find_child("Movement").radius
	if find_child("MovementObstacle") != null:
		return find_child("MovementObstacle").radius
	return null


func _get_movement_domain():
	if find_child("Movement") != null:
		return find_child("Movement").domain
	if find_child("MovementObstacle") != null:
		return find_child("MovementObstacle").domain
	return null


func _get_movement_speed():
	if find_child("Movement") != null:
		return find_child("Movement").speed
	return 0.0


func _is_movable():
	return _get_movement_speed() > 0.0


func _unit_scene_path():
	return get_script().resource_path.replace(".gd", ".tscn")


func _can_crush_target(target, from_position_yless, to_position_yless):
	if target == self or target == null or not is_instance_valid(target):
		return false
	if not target.is_inside_tree() or not target.has_method("can_be_crushed_by"):
		return false
	if not target.can_be_crushed_by(self):
		return false
	var target_radius = target.radius if target.radius != null else 0.0
	var crush_distance = radius + target_radius + Constants.Match.Units.CRUSH_RADIUS_MARGIN_M
	return (
		_distance_point_to_crush_segment(
			target.global_position_yless, from_position_yless, to_position_yless
		)
		<= crush_distance
	)


func _crush_target(target):
	target.register_damage_source(self)
	target.hp -= Constants.Match.Units.CRUSH_DAMAGE
	CombatVfx.spawn_impact_at_unit(target, 0.9)


func _distance_point_to_crush_segment(point, segment_start, segment_end):
	var segment = segment_end - segment_start
	var segment_length_squared = segment.length_squared()
	if is_zero_approx(segment_length_squared):
		return point.distance_to(segment_start)
	var point_projection = clampf(
		(point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0
	)
	var closest_point = segment_start + segment * point_projection
	return point.distance_to(closest_point)


func register_damage_source(source_unit):
	if source_unit == null or not is_instance_valid(source_unit) or source_unit == self:
		return
	if player.is_allied_with(source_unit.player):
		return
	last_damage_source = source_unit


func register_kill(target_unit):
	if not _can_gain_veterancy():
		return
	if target_unit != null and player.is_allied_with(target_unit.player):
		return
	experience_points += 1
	var new_rank = _rank_for_experience_points(experience_points)
	if new_rank > veterancy_rank:
		_apply_veterancy_rank(new_rank)


func grant_veterancy_rank(rank):
	if not _can_gain_veterancy():
		return false
	var target_rank = clampi(rank, 0, Constants.Match.Veterancy.MAX_RANK)
	if target_rank <= veterancy_rank:
		return false
	_apply_veterancy_rank(target_rank)
	experience_points = max(
		experience_points,
		Constants.Match.Veterancy.KILLS_BY_RANK[target_rank]
	)
	return true


func _setup_color():
	var material = player.get_color_material()
	Utils.Match.traverse_node_tree_and_replace_materials_matching_albedo(
		find_child("Geometry"),
		MATERIAL_ALBEDO_TO_REPLACE,
		MATERIAL_ALBEDO_TO_REPLACE_EPSILON,
		material
	)


func _set_action(action_node):
	if not is_inside_tree() or _action_locked:
		if action_node != null:
			action_node.queue_free()
		return
	if action_node != null and is_emp_disabled():
		clear_action_queue()
		action_node.queue_free()
		return
	if action_node != null and not _setting_queued_action and not _is_default_waiting_action(action_node):
		clear_action_queue()
	elif action_node == null and not _clearing_finished_action:
		clear_action_queue()
	_action_locked = true
	_teardown_current_action()
	action = action_node
	if action != null:
		var action_copy = action  # bind() performs copy itself, but lets force copy just in case
		action.tree_exited.connect(_on_action_node_tree_exited.bind(action_copy))
		add_child(action_node)
	_action_locked = false
	action_changed.emit(action)


func _get_type():
	var unit_script_path = get_script().resource_path
	var unit_file_name = unit_script_path.substr(unit_script_path.rfind("/") + 1)
	var unit_name = unit_file_name.split(".")[0]
	return unit_name


func _teardown_current_action():
	if action != null and action.is_inside_tree():
		action.queue_free()
		remove_child(action)  # triggers _on_action_node_tree_exited immediately


func _start_next_queued_action():
	if _current_action_blocks_queue() or action_queue.is_empty():
		return
	var next_action = action_queue.pop_front()
	_setting_queued_action = true
	action = next_action
	_setting_queued_action = false


func _current_action_blocks_queue():
	return action != null and not _is_default_waiting_action(action)


func _is_default_waiting_action(action_node):
	return action_node is _WaitingForTargetsAction


func _safety_checks():
	if movement_domain == Constants.Match.Navigation.Domain.AIR:
		assert(
			(
				radius < Constants.Match.Air.Navmesh.MAX_AGENT_RADIUS
				or is_equal_approx(radius, Constants.Match.Air.Navmesh.MAX_AGENT_RADIUS)
			),
			"Unit radius exceeds the established limit"
		)
	elif movement_domain == Constants.Match.Navigation.Domain.TERRAIN:
		assert(
			(
				not _is_movable()
				or (
					radius < Constants.Match.Terrain.Navmesh.MAX_AGENT_RADIUS
					or is_equal_approx(radius, Constants.Match.Terrain.Navmesh.MAX_AGENT_RADIUS)
				)
			),
			"Unit radius exceeds the established limit"
		)
	return true


func _handle_unit_death():
	_death_handled = true
	set_meta("death_position", global_position)
	set_meta("death_player", player)
	if last_damage_source != null and is_instance_valid(last_damage_source):
		set_meta("death_source_player", last_damage_source.player)
	_award_kill_to_last_damage_source()
	CombatVfx.spawn_impact_at_unit(self, 1.6)
	CombatVfx.spawn_wreckage_at_unit(self)
	tree_exited.connect(func(): MatchSignals.unit_died.emit(self))
	queue_free()


func _setup_default_properties_from_constants():
	var default_properties = Constants.Match.Units.DEFAULT_PROPERTIES[_unit_scene_path()]
	for property in default_properties:
		set(property, default_properties[property])


func _capture_base_veterancy_properties():
	for property in ["hp_max", "attack_damage", "attack_range", "sight_range"]:
		if get(property) != null:
			_base_veterancy_properties[property] = get(property)


func _award_kill_to_last_damage_source():
	if last_damage_source == null or not is_instance_valid(last_damage_source):
		return
	if last_damage_source == self or player.is_allied_with(last_damage_source.player):
		return
	if last_damage_source.has_method("register_kill"):
		last_damage_source.register_kill(self)


func _can_gain_veterancy():
	return attack_damage != null and _is_movable()


func _rank_for_experience_points(points):
	var rank = 0
	for index in range(Constants.Match.Veterancy.KILLS_BY_RANK.size()):
		if points >= Constants.Match.Veterancy.KILLS_BY_RANK[index]:
			rank = index
	return min(rank, Constants.Match.Veterancy.MAX_RANK)


func _apply_veterancy_rank(new_rank):
	var old_hp_ratio = 1.0
	if hp != null and hp_max != null and hp_max > 0:
		old_hp_ratio = float(hp) / hp_max
	veterancy_rank = min(new_rank, Constants.Match.Veterancy.MAX_RANK)
	if _base_veterancy_properties.has("hp_max"):
		hp_max = int(ceil(_base_veterancy_properties["hp_max"]
			* Constants.Match.Veterancy.HP_MULTIPLIER_BY_RANK[veterancy_rank]))
		hp = clampi(int(ceil(old_hp_ratio * hp_max)), 1, hp_max)
	if _base_veterancy_properties.has("attack_damage"):
		attack_damage = snappedf(
			_base_veterancy_properties["attack_damage"]
			* Constants.Match.Veterancy.DAMAGE_MULTIPLIER_BY_RANK[veterancy_rank],
			0.1
		)
	if _base_veterancy_properties.has("attack_range"):
		attack_range = (
			_base_veterancy_properties["attack_range"]
			+ Constants.Match.Veterancy.RANGE_BONUS_BY_RANK[veterancy_rank]
		)
	if _base_veterancy_properties.has("sight_range"):
		sight_range = (
			_base_veterancy_properties["sight_range"]
			+ Constants.Match.Veterancy.SIGHT_BONUS_BY_RANK[veterancy_rank]
		)
	if veterancy_rank >= Constants.Match.Veterancy.MAX_RANK:
		_start_elite_regeneration()
	CombatVfx.spawn_promotion_at_unit(self, veterancy_rank)
	veterancy_changed.emit(veterancy_rank)
	MatchSignals.unit_promoted.emit(self, veterancy_rank)


func _start_elite_regeneration():
	if _elite_regeneration_timer != null:
		return
	_elite_regeneration_timer = Timer.new()
	_elite_regeneration_timer.wait_time = Constants.Match.Veterancy.ELITE_REGEN_TICK_SECONDS
	_elite_regeneration_timer.timeout.connect(_on_elite_regeneration_timer_timeout)
	add_child(_elite_regeneration_timer)
	_elite_regeneration_timer.start()


func _on_elite_regeneration_timer_timeout():
	if veterancy_rank < Constants.Match.Veterancy.MAX_RANK:
		return
	if hp == null or hp_max == null or hp <= 0 or hp >= hp_max:
		return
	if is_emp_disabled():
		return
	var recovered_hp = (
		Constants.Match.Veterancy.ELITE_REGEN_HITPOINTS_PER_SECOND
		* Constants.Match.Veterancy.ELITE_REGEN_TICK_SECONDS
	)
	hp = min(hp_max, hp + recovered_hp)


func _interrupt_for_emp():
	var movement_trait = find_child("Movement")
	if movement_trait != null:
		movement_trait.stop()
	clear_action_queue()
	action = null


func _start_emp_disabled_timer():
	if _emp_disabled_timer == null:
		_emp_disabled_timer = Timer.new()
		_emp_disabled_timer.one_shot = true
		_emp_disabled_timer.timeout.connect(_on_emp_disabled_timer_timeout)
		add_child(_emp_disabled_timer)
	_emp_disabled_timer.start(maxf(0.01, _emp_disabled_until - _now()))


func _on_emp_disabled_timer_timeout():
	var remaining = _emp_disabled_until - _now()
	if remaining > 0.0:
		_emp_disabled_timer.start(remaining)
		return
	_emp_disabled_until = 0.0
	emp_disabled_changed.emit(false)


func _now():
	return Time.get_ticks_msec() / 1000.0


func _on_action_node_tree_exited(action_node):
	assert(action_node == action, "unexpected action released")
	_clearing_finished_action = true
	action = null
	_clearing_finished_action = false
	_start_next_queued_action.call_deferred()
