extends Node

signal resources_required(resources, metadata)

const Worker = preload("res://source/match/units/Worker.gd")
const Structure = preload("res://source/match/units/Structure.gd")
const CommandCenter = preload("res://source/match/units/CommandCenter.gd")
const AGTurret = preload("res://source/match/units/AntiGroundTurret.gd")
const AGTurretScene = preload("res://source/match/units/AntiGroundTurret.tscn")
const AATurret = preload("res://source/match/units/AntiAirTurret.gd")
const AATurretScene = preload("res://source/match/units/AntiAirTurret.tscn")
const TeslaFenceSegment = preload("res://source/match/units/TeslaFenceSegment.gd")
const TeslaFenceSegmentScene = preload("res://source/match/units/TeslaFenceSegment.tscn")
const ArcCoilDefenseTower = preload("res://source/match/units/ArcCoilDefenseTower.gd")
const ArcCoilDefenseTowerScene = preload("res://source/match/units/ArcCoilDefenseTower.tscn")
const LanceBeamDefenseTower = preload("res://source/match/units/LanceBeamDefenseTower.gd")
const LanceBeamDefenseTowerScene = preload("res://source/match/units/LanceBeamDefenseTower.tscn")
const PrismDefenseObelisk = preload("res://source/match/units/PrismDefenseObelisk.gd")
const PrismDefenseObeliskScene = preload("res://source/match/units/PrismDefenseObelisk.tscn")
const RailCannonBunker = preload("res://source/match/units/RailCannonBunker.gd")
const RailCannonBunkerScene = preload("res://source/match/units/RailCannonBunker.tscn")

const REFRESH_INTERVAL_S = 1.0 / 60.0 * 30.0
const FRONTLINE_SEARCH_MIN_STEP_M = 2.0
const FRONTLINE_SEARCH_EXTRA_RANGE_M = 24.0

var _player = null
var _number_of_pending_ag_turret_resource_requests = 0
var _number_of_pending_aa_turret_resource_requests = 0
var _number_of_pending_tesla_fence_segment_resource_requests = 0
var _number_of_pending_arc_coil_tower_resource_requests = 0
var _number_of_pending_lance_beam_tower_resource_requests = 0
var _number_of_pending_prism_defense_obelisk_resource_requests = 0
var _number_of_pending_rail_cannon_bunker_resource_requests = 0

@onready var _ai = get_parent()


func setup(player):
	_setup_refresh_timer()
	_player = player
	_attach_current_turrets()
	MatchSignals.unit_spawned.connect(_on_unit_spawned)
	MatchSignals.unit_captured.connect(_on_unit_captured)
	_enforce_number_of_ag_turrets()
	_enforce_number_of_aa_turrets()
	_enforce_number_of_tesla_fence_segments()
	_enforce_number_of_arc_coil_towers()
	_enforce_number_of_lance_beam_towers()
	_enforce_number_of_prism_defense_obelisks()
	_enforce_number_of_rail_cannon_bunkers()
	_repair_damaged_structures()


func provision(resources, metadata):
	var workers = get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return unit is Worker and unit.can_construct_structures() and unit.player == _player
	)
	var ccs = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is CommandCenter and unit.player == _player
	)
	if metadata == "ag_turret":
		_number_of_pending_ag_turret_resource_requests = max(
			0, _number_of_pending_ag_turret_resource_requests - 1
		)
		if not _resources_match(
			resources, Constants.Match.Units.CONSTRUCTION_COSTS[AGTurretScene.resource_path], metadata
		):
			return
		if workers.is_empty() or ccs.is_empty():
			return
		_construct_turret(AGTurretScene)
	elif metadata == "aa_turret":
		_number_of_pending_aa_turret_resource_requests = max(
			0, _number_of_pending_aa_turret_resource_requests - 1
		)
		if not _resources_match(
			resources, Constants.Match.Units.CONSTRUCTION_COSTS[AATurretScene.resource_path], metadata
		):
			return
		if workers.is_empty() or ccs.is_empty():
			return
		_construct_turret(AATurretScene)
	elif metadata == "tesla_fence_segment":
		_number_of_pending_tesla_fence_segment_resource_requests = max(
			0, _number_of_pending_tesla_fence_segment_resource_requests - 1
		)
		if not _resources_match(
			resources,
			Constants.Match.Units.CONSTRUCTION_COSTS[TeslaFenceSegmentScene.resource_path],
			metadata
		):
			return
		if (
			workers.is_empty()
			or ccs.is_empty()
			or not Utils.Match.Unit.Tech.can_construct(
				_player, TeslaFenceSegmentScene.resource_path
			)
		):
			return
		_construct_turret(TeslaFenceSegmentScene)
	elif metadata == "arc_coil_tower":
		_number_of_pending_arc_coil_tower_resource_requests = max(
			0, _number_of_pending_arc_coil_tower_resource_requests - 1
		)
		if not _resources_match(
			resources,
			Constants.Match.Units.CONSTRUCTION_COSTS[ArcCoilDefenseTowerScene.resource_path],
			metadata
		):
			return
		if (
			workers.is_empty()
			or ccs.is_empty()
			or not Utils.Match.Unit.Tech.can_construct(
				_player, ArcCoilDefenseTowerScene.resource_path
			)
		):
			return
		_construct_turret(ArcCoilDefenseTowerScene)
	elif metadata == "lance_beam_tower":
		_number_of_pending_lance_beam_tower_resource_requests = max(
			0, _number_of_pending_lance_beam_tower_resource_requests - 1
		)
		if not _resources_match(
			resources,
			Constants.Match.Units.CONSTRUCTION_COSTS[LanceBeamDefenseTowerScene.resource_path],
			metadata
		):
			return
		if (
			workers.is_empty()
			or ccs.is_empty()
			or not Utils.Match.Unit.Tech.can_construct(
				_player, LanceBeamDefenseTowerScene.resource_path
			)
		):
			return
		_construct_turret(LanceBeamDefenseTowerScene)
	elif metadata == "prism_defense_obelisk":
		_number_of_pending_prism_defense_obelisk_resource_requests = max(
			0, _number_of_pending_prism_defense_obelisk_resource_requests - 1
		)
		if not _resources_match(
			resources,
			Constants.Match.Units.CONSTRUCTION_COSTS[PrismDefenseObeliskScene.resource_path],
			metadata
		):
			return
		if (
			workers.is_empty()
			or ccs.is_empty()
			or not Utils.Match.Unit.Tech.can_construct(
				_player, PrismDefenseObeliskScene.resource_path
			)
		):
			return
		_construct_turret(PrismDefenseObeliskScene)
	elif metadata == "rail_cannon_bunker":
		_number_of_pending_rail_cannon_bunker_resource_requests = max(
			0, _number_of_pending_rail_cannon_bunker_resource_requests - 1
		)
		if not _resources_match(
			resources,
			Constants.Match.Units.CONSTRUCTION_COSTS[RailCannonBunkerScene.resource_path],
			metadata
		):
			return
		if (
			workers.is_empty()
			or ccs.is_empty()
			or not Utils.Match.Unit.Tech.can_construct(
				_player, RailCannonBunkerScene.resource_path
			)
		):
			return
		_construct_turret(RailCannonBunkerScene)
	else:
		push_warning("Ignoring unknown AI defense resource request metadata: {0}".format([metadata]))


func _resources_match(resources, expected_resources, metadata):
	if resources == expected_resources:
		return true
	push_warning(
		"Ignoring AI defense resource provision for {0}: expected {1}, got {2}".format(
			[metadata, expected_resources, resources]
		)
	)
	return false


func _setup_refresh_timer():
	var timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_refresh_timer_timeout)
	timer.start(REFRESH_INTERVAL_S)


func _attach_current_turrets():
	var turrets = get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return (
				(
					unit is AGTurret
					or unit is AATurret
					or unit is TeslaFenceSegment
					or unit is ArcCoilDefenseTower
					or unit is LanceBeamDefenseTower
					or unit is PrismDefenseObelisk
					or unit is RailCannonBunker
				)
				and unit.player == _player
			)
	)
	for turret in turrets:
		_attach_turret(turret)


func _attach_turret(turret):
	turret.tree_exited.connect(_on_unit_died.bind(turret))


func _enforce_number_of_ag_turrets():
	var ag_turrets = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is AGTurret and unit.player == _player
	)
	if (
		ag_turrets.size() + _number_of_pending_ag_turret_resource_requests
		>= _ai.expected_number_of_ag_turrets
	):
		return
	var number_of_extra_ag_turrets_required = (
		_ai.expected_number_of_ag_turrets
		- (ag_turrets.size() + _number_of_pending_ag_turret_resource_requests)
	)
	for _i in range(number_of_extra_ag_turrets_required):
		resources_required.emit(
			Constants.Match.Units.CONSTRUCTION_COSTS[AGTurretScene.resource_path], "ag_turret"
		)
		_number_of_pending_ag_turret_resource_requests += 1


func _enforce_number_of_aa_turrets():
	var aa_turrets = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is AATurret and unit.player == _player
	)
	if (
		aa_turrets.size() + _number_of_pending_aa_turret_resource_requests
		>= _ai.expected_number_of_aa_turrets
	):
		return
	var number_of_extra_aa_turrets_required = (
		_ai.expected_number_of_aa_turrets
		- (aa_turrets.size() + _number_of_pending_aa_turret_resource_requests)
	)
	for _i in range(number_of_extra_aa_turrets_required):
		resources_required.emit(
			Constants.Match.Units.CONSTRUCTION_COSTS[AATurretScene.resource_path], "aa_turret"
		)
		_number_of_pending_aa_turret_resource_requests += 1


func _enforce_number_of_tesla_fence_segments():
	if not Utils.Match.Unit.Tech.can_construct(_player, TeslaFenceSegmentScene.resource_path):
		return
	var tesla_fence_segments = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is TeslaFenceSegment and unit.player == _player
	)
	if (
		tesla_fence_segments.size() + _number_of_pending_tesla_fence_segment_resource_requests
		>= _ai.expected_number_of_tesla_fence_segments
	):
		return
	var number_of_extra_tesla_fence_segments_required = (
		_ai.expected_number_of_tesla_fence_segments
		- (
			tesla_fence_segments.size()
			+ _number_of_pending_tesla_fence_segment_resource_requests
		)
	)
	for _i in range(number_of_extra_tesla_fence_segments_required):
		resources_required.emit(
			Constants.Match.Units.CONSTRUCTION_COSTS[TeslaFenceSegmentScene.resource_path],
			"tesla_fence_segment"
		)
		_number_of_pending_tesla_fence_segment_resource_requests += 1


func _enforce_number_of_arc_coil_towers():
	if not Utils.Match.Unit.Tech.can_construct(_player, ArcCoilDefenseTowerScene.resource_path):
		return
	var arc_coil_towers = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is ArcCoilDefenseTower and unit.player == _player
	)
	if (
		arc_coil_towers.size() + _number_of_pending_arc_coil_tower_resource_requests
		>= _ai.expected_number_of_arc_coil_towers
	):
		return
	var number_of_extra_arc_coil_towers_required = (
		_ai.expected_number_of_arc_coil_towers
		- (arc_coil_towers.size() + _number_of_pending_arc_coil_tower_resource_requests)
	)
	for _i in range(number_of_extra_arc_coil_towers_required):
		resources_required.emit(
			Constants.Match.Units.CONSTRUCTION_COSTS[ArcCoilDefenseTowerScene.resource_path],
			"arc_coil_tower"
		)
		_number_of_pending_arc_coil_tower_resource_requests += 1


func _enforce_number_of_lance_beam_towers():
	if not Utils.Match.Unit.Tech.can_construct(_player, LanceBeamDefenseTowerScene.resource_path):
		return
	var lance_beam_towers = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is LanceBeamDefenseTower and unit.player == _player
	)
	if (
		lance_beam_towers.size() + _number_of_pending_lance_beam_tower_resource_requests
		>= _ai.expected_number_of_lance_beam_towers
	):
		return
	var number_of_extra_lance_beam_towers_required = (
		_ai.expected_number_of_lance_beam_towers
		- (lance_beam_towers.size() + _number_of_pending_lance_beam_tower_resource_requests)
	)
	for _i in range(number_of_extra_lance_beam_towers_required):
		resources_required.emit(
			Constants.Match.Units.CONSTRUCTION_COSTS[LanceBeamDefenseTowerScene.resource_path],
			"lance_beam_tower"
		)
		_number_of_pending_lance_beam_tower_resource_requests += 1


func _enforce_number_of_prism_defense_obelisks():
	if not Utils.Match.Unit.Tech.can_construct(_player, PrismDefenseObeliskScene.resource_path):
		return
	var prism_defense_obelisks = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is PrismDefenseObelisk and unit.player == _player
	)
	if (
		prism_defense_obelisks.size()
		+ _number_of_pending_prism_defense_obelisk_resource_requests
		>= _ai.expected_number_of_prism_defense_obelisks
	):
		return
	var number_of_extra_prism_defense_obelisks_required = (
		_ai.expected_number_of_prism_defense_obelisks
		- (
			prism_defense_obelisks.size()
			+ _number_of_pending_prism_defense_obelisk_resource_requests
		)
	)
	for _i in range(number_of_extra_prism_defense_obelisks_required):
		resources_required.emit(
			Constants.Match.Units.CONSTRUCTION_COSTS[PrismDefenseObeliskScene.resource_path],
			"prism_defense_obelisk"
		)
		_number_of_pending_prism_defense_obelisk_resource_requests += 1


func _enforce_number_of_rail_cannon_bunkers():
	if not Utils.Match.Unit.Tech.can_construct(_player, RailCannonBunkerScene.resource_path):
		return
	var rail_cannon_bunkers = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is RailCannonBunker and unit.player == _player
	)
	if (
		rail_cannon_bunkers.size() + _number_of_pending_rail_cannon_bunker_resource_requests
		>= _ai.expected_number_of_rail_cannon_bunkers
	):
		return
	var number_of_extra_rail_cannon_bunkers_required = (
		_ai.expected_number_of_rail_cannon_bunkers
		- (rail_cannon_bunkers.size() + _number_of_pending_rail_cannon_bunker_resource_requests)
	)
	for _i in range(number_of_extra_rail_cannon_bunkers_required):
		resources_required.emit(
			Constants.Match.Units.CONSTRUCTION_COSTS[RailCannonBunkerScene.resource_path],
			"rail_cannon_bunker"
		)
		_number_of_pending_rail_cannon_bunker_resource_requests += 1


func _construct_turret(turret_scene):
	var construction_cost = Constants.Match.Units.CONSTRUCTION_COSTS[turret_scene.resource_path]
	assert(
		_player.has_resources(construction_cost),
		"player should have enough resources at this point"
	)
	var ccs = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is CommandCenter and unit.player == _player
	)
	var unit_to_spawn = turret_scene.instantiate()
	var command_center = _frontline_command_center(ccs)
	var defense_direction = _defense_direction_from(command_center.global_position)
	var navigation_map_rid = find_parent("Match").navigation.get_navigation_map_rid_by_domain(
		unit_to_spawn.movement_domain
	)
	var placement_position = _frontline_defense_position(
		command_center, unit_to_spawn, defense_direction, navigation_map_rid
	)
	if placement_position == Vector3.INF:
		placement_position = Utils.Match.Unit.Placement.find_valid_position_radially_yet_skip_starting_radius(
			command_center.global_position,
			command_center.radius,
			unit_to_spawn.radius,
			0.1,
			defense_direction,
			false,
			navigation_map_rid,
			get_tree()
		)
	if (
		placement_position != Vector3.INF
		and not Utils.Match.Unit.Placement.is_within_base_construction_radius(
			_player, placement_position, unit_to_spawn.radius
		)
	):
		placement_position = Vector3.INF
	if placement_position == Vector3.INF:
		unit_to_spawn.free()
		return
	var target_transform = Transform3D(Basis(), placement_position).looking_at(
		placement_position + defense_direction, Vector3.UP
	)
	_player.subtract_resources(construction_cost)
	MatchSignals.setup_and_spawn_unit.emit(unit_to_spawn, target_transform, _player)


func _frontline_defense_position(
	command_center, unit_to_spawn, defense_direction, navigation_map_rid
):
	var origin = command_center.global_position * Vector3(1, 0, 1)
	var forward = defense_direction * Vector3(1, 0, 1)
	if forward.is_zero_approx():
		forward = Vector3(0, 0, 1)
	forward = forward.normalized()
	var lateral = forward.rotated(Vector3.UP, PI * 0.5).normalized()
	var step = maxf(unit_to_spawn.radius * 0.25, FRONTLINE_SEARCH_MIN_STEP_M)
	var max_forward = (
		command_center.radius + unit_to_spawn.radius * 3.0 + FRONTLINE_SEARCH_EXTRA_RANGE_M
	)
	var max_side = (
		command_center.radius + unit_to_spawn.radius * 3.0 + FRONTLINE_SEARCH_EXTRA_RANGE_M
	)
	var side_offsets = _frontline_side_offsets(max_side, step)
	var existing_units = (
		get_tree().get_nodes_in_group("units") + get_tree().get_nodes_in_group("resource_units")
	)
	var nearest_enemy = _nearest_enemy_to(origin)
	var command_center_enemy_distance = (
		INF
		if nearest_enemy == null
		else origin.distance_to(nearest_enemy.global_position_yless)
	)
	var forward_distance = unit_to_spawn.radius
	while forward_distance <= max_forward:
		for side_offset in side_offsets:
			var candidate_position = (
				origin + forward * forward_distance + lateral * side_offset
			)
			if not _is_frontline_candidate(
				origin,
				candidate_position,
				forward,
				nearest_enemy,
				command_center_enemy_distance
			):
				continue
			if (
				not Utils.Match.Unit.Placement.is_within_base_construction_radius(
					_player, candidate_position, unit_to_spawn.radius
				)
			):
				continue
			if (
				Utils.Match.Unit.Placement.validate_agent_placement_position(
					candidate_position, unit_to_spawn.radius, existing_units, navigation_map_rid
				)
				== Utils.Match.Unit.Placement.VALID
			):
				return candidate_position
		forward_distance += step
	return Vector3.INF


func _frontline_side_offsets(max_side, step):
	var side_offsets = [0.0]
	var side_offset = step
	while side_offset <= max_side:
		side_offsets.append(side_offset)
		side_offsets.append(-side_offset)
		side_offset += step
	return side_offsets


func _is_frontline_candidate(
	origin, candidate_position, forward, nearest_enemy, command_center_enemy_distance
):
	if (candidate_position - origin).dot(forward) <= 0.0:
		return false
	if nearest_enemy == null:
		return true
	return (
		candidate_position.distance_to(nearest_enemy.global_position_yless)
		< command_center_enemy_distance
	)


func _frontline_command_center(command_centers):
	var enemies = _enemy_units()
	if enemies.is_empty():
		return command_centers[0]
	var best_command_center = command_centers[0]
	var best_distance = INF
	for command_center in command_centers:
		var distance = _distance_to_nearest_enemy(command_center.global_position_yless, enemies)
		if distance < best_distance:
			best_distance = distance
			best_command_center = command_center
	return best_command_center


func _defense_direction_from(origin):
	var nearest_enemy = _nearest_enemy_to(origin)
	if nearest_enemy == null:
		return Vector3(0, 0, 1)
	var direction = nearest_enemy.global_position_yless - (origin * Vector3(1, 0, 1))
	if direction.is_zero_approx():
		return Vector3(0, 0, 1)
	return direction.normalized()


func _nearest_enemy_to(origin):
	var enemies = _enemy_units()
	if enemies.is_empty():
		return null
	var origin_yless = origin * Vector3(1, 0, 1)
	var best_enemy = enemies[0]
	var best_distance = INF
	for enemy in enemies:
		var distance = enemy.global_position_yless.distance_to(origin_yless)
		if distance < best_distance:
			best_distance = distance
			best_enemy = enemy
	return best_enemy


func _distance_to_nearest_enemy(origin_yless, enemies):
	var best_distance = INF
	for enemy in enemies:
		best_distance = minf(best_distance, enemy.global_position_yless.distance_to(origin_yless))
	return best_distance


func _enemy_units():
	return get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return (
				"player" in unit
				and _player.is_enemy_with(unit.player)
				and "hp" in unit
				and unit.hp != null
				and unit.hp > 0
			)
	)


func _repair_damaged_structures():
	var structures = get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is Structure and unit.player == _player and _should_ai_repair(unit)
	)
	structures.sort_custom(func(a, b): return _hp_ratio(a) < _hp_ratio(b))
	var repairs_started = 0
	for structure in structures:
		if repairs_started >= Constants.Match.Structure.AI_REPAIR_MAX_STARTS_PER_REFRESH:
			return
		if not _player.has_resources(structure.get_repair_cost()):
			continue
		if structure.repair():
			repairs_started += 1


func _should_ai_repair(structure):
	return (
		structure.can_repair()
		and _missing_hitpoint_ratio(structure)
		>= Constants.Match.Structure.AI_REPAIR_MIN_MISSING_HITPOINT_RATIO
	)


func _missing_hitpoint_ratio(structure):
	if structure.hp_max == null or structure.hp_max <= 0:
		return 0.0
	return clampf(
		(float(structure.hp_max) - float(structure.hp)) / float(structure.hp_max), 0.0, 1.0
	)


func _hp_ratio(structure):
	if structure.hp_max == null or structure.hp_max <= 0:
		return 1.0
	return clampf(float(structure.hp) / float(structure.hp_max), 0.0, 1.0)


func _on_unit_died(unit):
	if not is_inside_tree():
		return
	if unit is AGTurret:
		_enforce_number_of_ag_turrets()
	elif unit is AATurret:
		_enforce_number_of_aa_turrets()
	elif unit is TeslaFenceSegment:
		_enforce_number_of_tesla_fence_segments()
	elif unit is ArcCoilDefenseTower:
		_enforce_number_of_arc_coil_towers()
	elif unit is LanceBeamDefenseTower:
		_enforce_number_of_lance_beam_towers()
	elif unit is PrismDefenseObelisk:
		_enforce_number_of_prism_defense_obelisks()
	elif unit is RailCannonBunker:
		_enforce_number_of_rail_cannon_bunkers()
	else:
		push_warning("Ignoring non-defense unit removal in AI defense controller: {0}".format([unit.name]))


func _on_unit_spawned(unit):
	if unit.player != _player:
		return
	if (
		unit is AGTurret
		or unit is AATurret
		or unit is TeslaFenceSegment
		or unit is ArcCoilDefenseTower
		or unit is LanceBeamDefenseTower
		or unit is PrismDefenseObelisk
		or unit is RailCannonBunker
	):
		_attach_turret(unit)


func _on_unit_captured(_unit, previous_player, new_player):
	if previous_player != _player and new_player != _player:
		return
	_enforce_number_of_ag_turrets()
	_enforce_number_of_aa_turrets()
	_enforce_number_of_tesla_fence_segments()
	_enforce_number_of_arc_coil_towers()
	_enforce_number_of_lance_beam_towers()
	_enforce_number_of_prism_defense_obelisks()
	_enforce_number_of_rail_cannon_bunkers()


func _on_refresh_timer_timeout():
	_enforce_number_of_ag_turrets()
	_enforce_number_of_aa_turrets()
	_enforce_number_of_tesla_fence_segments()
	_enforce_number_of_arc_coil_towers()
	_enforce_number_of_lance_beam_towers()
	_enforce_number_of_prism_defense_obelisks()
	_enforce_number_of_rail_cannon_bunkers()
	_repair_damaged_structures()
