extends Node

const Structure = preload("res://source/match/units/Structure.gd")
const SupportPowerEffects = preload("res://source/match/support-powers/SupportPowerEffects.gd")

const REFRESH_INTERVAL_S = 1.0
const MIN_CLUSTER_TARGETS = 2
const ORBITAL_STRIKE_MIN_SCORE = 3.0
const WEATHER_STORM_MIN_SCORE = 5.0
const STRATEGIC_MISSILE_MIN_SCORE = 5.0
const NANITE_REPAIR_MIN_MISSING_HP = 4.0
const CHRONO_RELAY_MIN_MOBILE_UNITS = 2
const SHIELD_OVERDRIVE_MIN_SCORE = 2.0
const SHIELD_OVERDRIVE_MOBILE_PRESSURE_BONUS = 12.0
const POWER_PRIORITY = [
	Constants.Match.SupportPowers.EMP_PULSE,
	Constants.Match.SupportPowers.NANITE_REPAIR_SWARM,
	Constants.Match.SupportPowers.SHIELD_OVERDRIVE,
	Constants.Match.SupportPowers.CHRONO_RELAY,
	Constants.Match.SupportPowers.WEATHER_STORM,
	Constants.Match.SupportPowers.STRATEGIC_MISSILE,
	Constants.Match.SupportPowers.ORBITAL_STRIKE,
	Constants.Match.SupportPowers.PARADROP,
	Constants.Match.SupportPowers.RADAR_SWEEP,
]

var _player = null
var _cooldown_ready_at = {}
var _ready_notification_sent = {}
var _initial_charge_started = {}
var _refresh_timer = null

@onready var _match = find_parent("Match")


func setup(player):
	_player = player
	for power_id in POWER_PRIORITY:
		_cooldown_ready_at[power_id] = 0.0
		_ready_notification_sent[power_id] = false
		_initial_charge_started[power_id] = false
	_setup_refresh_timer()
	_refresh_timer.paused = false


func can_activate(power_id):
	if _player == null:
		return false
	_ensure_initial_charge_state(power_id)
	if not _missing_requirements(power_id).is_empty():
		return false
	if _definition(power_id).get("requires_power", false) and _player.is_low_power():
		return false
	return get_cooldown_remaining(power_id) <= 0.0


func get_cooldown_remaining(power_id):
	return maxf(0.0, _cooldown_ready_at.get(power_id, 0.0) - _now())


func reset_cooldowns():
	for power_id in POWER_PRIORITY:
		_cooldown_ready_at[power_id] = 0.0
		_ready_notification_sent[power_id] = false
		_initial_charge_started[power_id] = true


func set_auto_refresh_enabled(enabled):
	_setup_refresh_timer()
	_refresh_timer.paused = not enabled


func try_activate_best_power():
	if _match == null or _player == null:
		return ""
	_emit_ready_notifications()
	for power_id in POWER_PRIORITY:
		if not can_activate(power_id):
			continue
		var target_position = _pick_target_position(power_id)
		if target_position == null:
			continue
		if not SupportPowerEffects.activate(_match, power_id, _player, target_position):
			continue
		_cooldown_ready_at[power_id] = _now() + _definition(power_id)["cooldown"]
		_ready_notification_sent[power_id] = false
		MatchSignals.support_power_activated.emit(power_id, _player, target_position)
		return power_id
	return ""


func _emit_ready_notifications():
	for power_id in POWER_PRIORITY:
		if can_activate(power_id):
			if not _ready_notification_sent.get(power_id, false):
				_ready_notification_sent[power_id] = true
				MatchSignals.support_power_ready.emit(power_id, _player)
		else:
			_ready_notification_sent[power_id] = false


func _setup_refresh_timer():
	if _refresh_timer != null and is_instance_valid(_refresh_timer):
		return
	_refresh_timer = Timer.new()
	_refresh_timer.name = "SupportPowerRefreshTimer"
	add_child(_refresh_timer)
	_refresh_timer.timeout.connect(try_activate_best_power)
	_refresh_timer.start(REFRESH_INTERVAL_S)


func _pick_target_position(power_id):
	match power_id:
		Constants.Match.SupportPowers.EMP_PULSE:
			return _pick_best_cluster_position(power_id, true, MIN_CLUSTER_TARGETS)
		Constants.Match.SupportPowers.ORBITAL_STRIKE:
			return _pick_best_scored_strike_position(power_id, ORBITAL_STRIKE_MIN_SCORE)
		Constants.Match.SupportPowers.WEATHER_STORM:
			return _pick_best_scored_strike_position(power_id, WEATHER_STORM_MIN_SCORE)
		Constants.Match.SupportPowers.STRATEGIC_MISSILE:
			return _pick_best_scored_strike_position(power_id, STRATEGIC_MISSILE_MIN_SCORE)
		Constants.Match.SupportPowers.PARADROP:
			return _pick_any_enemy_position()
		Constants.Match.SupportPowers.NANITE_REPAIR_SWARM:
			return _pick_best_repair_position(power_id, NANITE_REPAIR_MIN_MISSING_HP)
		Constants.Match.SupportPowers.SHIELD_OVERDRIVE:
			return _pick_best_shield_position(power_id, SHIELD_OVERDRIVE_MIN_SCORE)
		Constants.Match.SupportPowers.CHRONO_RELAY:
			return _pick_best_chrono_position(power_id, CHRONO_RELAY_MIN_MOBILE_UNITS)
		Constants.Match.SupportPowers.RADAR_SWEEP:
			return _pick_any_enemy_position()
		_:
			return null


func _pick_best_cluster_position(power_id, mobile_only, min_targets):
	var candidates = _enemy_units(mobile_only)
	var best_position = null
	var best_score = 0
	var radius = _definition(power_id)["radius"]
	for candidate in candidates:
		var score = 0
		for unit in candidates:
			if unit.global_position_yless.distance_to(candidate.global_position_yless) <= radius:
				score += 1
		if score > best_score:
			best_score = score
			best_position = candidate.global_position
	return best_position if best_score >= min_targets else null


func _pick_best_scored_strike_position(power_id, min_score):
	var candidates = _enemy_units(false)
	var best_position = null
	var best_score = 0.0
	var radius = _definition(power_id)["radius"]
	for candidate in candidates:
		var score = 0.0
		for unit in candidates:
			if unit.global_position_yless.distance_to(candidate.global_position_yless) <= radius:
				score += _strike_target_score(unit)
		if score > best_score:
			best_score = score
			best_position = candidate.global_position
	return best_position if best_score >= min_score else null


func _pick_best_repair_position(power_id, min_missing_hp):
	var candidates = _friendly_units()
	var best_position = null
	var best_score = 0.0
	var radius = _definition(power_id)["radius"]
	var healing = _definition(power_id)["healing"]
	for candidate in candidates:
		var score = 0.0
		for unit in candidates:
			if unit.hp_max == null:
				continue
			if unit.global_position_yless.distance_to(candidate.global_position_yless) > radius:
				continue
			score += minf(healing, maxf(0.0, unit.hp_max - unit.hp))
		if score > best_score:
			best_score = score
			best_position = candidate.global_position
	return best_position if best_score >= min_missing_hp else null


func _pick_best_shield_position(power_id, min_score):
	var candidates = _friendly_units()
	var best_position = null
	var best_score = 0.0
	var radius = _definition(power_id)["radius"]
	var pressure_radius = radius + 4.0
	for candidate in candidates:
		var pressure_distance = _nearest_enemy_pressure_distance(candidate.global_position_yless, pressure_radius)
		if pressure_distance == INF:
			continue
		var score = 0.0
		for unit in candidates:
			if unit.global_position_yless.distance_to(candidate.global_position_yless) <= radius:
				score += _shield_target_score(unit)
		if _is_mobile_unit(candidate):
			score += SHIELD_OVERDRIVE_MOBILE_PRESSURE_BONUS
		score += maxf(0.0, pressure_radius - pressure_distance) * 0.3
		if score > best_score:
			best_score = score
			best_position = candidate.global_position
	return best_position if best_score >= min_score else null


func _pick_best_chrono_position(power_id, min_mobile_units):
	var candidates = _friendly_mobile_units()
	var best_position = null
	var best_score = 0
	var radius = _definition(power_id)["radius"]
	for candidate in candidates:
		var score = 0
		for unit in candidates:
			if unit.global_position_yless.distance_to(candidate.global_position_yless) <= radius:
				score += 1
		if score > best_score:
			best_score = score
			best_position = candidate.global_position
	return best_position if best_score >= min_mobile_units else null


func _strike_target_score(unit):
	var score = 1.0
	if unit is Structure:
		score += 2.5
	if "attack_damage" in unit and unit.attack_damage != null and unit.attack_damage > 0:
		score += 1.0
	var scene_path = unit.get_script().resource_path.replace(".gd", ".tscn")
	if Constants.Match.Units.CONSTRUCTION_COSTS.has(scene_path):
		score += _resource_score(Constants.Match.Units.CONSTRUCTION_COSTS[scene_path])
	elif Constants.Match.Units.PRODUCTION_COSTS.has(scene_path):
		score += _resource_score(Constants.Match.Units.PRODUCTION_COSTS[scene_path]) * 0.5
	return score


func _resource_score(resources):
	var total = 0.0
	for resource in resources:
		total += float(resources[resource])
	return minf(2.0, total / 8.0)


func _shield_target_score(unit):
	var score = 1.0
	if unit is Structure:
		score += 2.0
	if "attack_damage" in unit and unit.attack_damage != null and unit.attack_damage > 0:
		score += 1.0
	return score


func _is_mobile_unit(unit):
	return unit.find_child("Movement") != null


func _nearest_enemy_pressure_distance(position_yless, radius):
	var best_distance = INF
	for unit in _enemy_units(false):
		var distance = unit.global_position_yless.distance_to(position_yless)
		if distance <= radius:
			best_distance = minf(best_distance, distance)
	return best_distance


func _has_enemy_pressure(position_yless, radius):
	for unit in _enemy_units(false):
		if unit.global_position_yless.distance_to(position_yless) <= radius:
			return true
	return false


func _pick_any_enemy_position():
	var candidates = _enemy_units(false)
	if candidates.is_empty():
		return null
	candidates.shuffle()
	return candidates.front().global_position


func _enemy_units(mobile_only):
	return get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return (
				"player" in unit
				and _player.is_enemy_with(unit.player)
				and "hp" in unit
				and unit.hp != null
				and unit.hp > 0
				and (not mobile_only or unit.find_child("Movement") != null)
				and (not mobile_only or not unit.is_emp_disabled())
			)
	)


func _friendly_units():
	return get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return (
				"player" in unit
				and unit.player == _player
				and "hp" in unit
				and unit.hp != null
				and unit.hp > 0
			)
	)


func _friendly_mobile_units():
	return _friendly_units().filter(
		func(unit):
			return _is_mobile_unit(unit) and not unit.is_chrono_relayed()
	)


func _missing_requirements(power_id):
	var missing_requirements = []
	for requirement_path in _definition(power_id)["requirements"]:
		if not Utils.Match.Unit.Tech.player_has_constructed_structure(_player, requirement_path):
			missing_requirements.append(requirement_path)
	return missing_requirements


func _ensure_initial_charge_state(power_id):
	if _player == null:
		return
	if not _missing_requirements(power_id).is_empty():
		_initial_charge_started[power_id] = false
		_ready_notification_sent[power_id] = false
		return
	if _initial_charge_started.get(power_id, false):
		return
	_initial_charge_started[power_id] = true
	var initial_cooldown = _definition(power_id).get("initial_cooldown", 0.0)
	if initial_cooldown <= 0.0:
		return
	if _cooldown_ready_at.get(power_id, 0.0) <= _now():
		_cooldown_ready_at[power_id] = _now() + initial_cooldown
		MatchSignals.support_power_charging.emit(power_id, _player, initial_cooldown)


func _definition(power_id):
	return Constants.Match.SupportPowers.DEFINITIONS[power_id]


func _now():
	return Time.get_ticks_msec() / 1000.0
