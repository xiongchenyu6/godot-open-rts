const Unit = preload("res://source/match/units/Unit.gd")
const CombatVfx = preload("res://source/match/utils/CombatVfxUtils.gd")
const FadedCircle3D = preload("res://source/generic-scenes-and-nodes/3d/FadedCircle3D.tscn")
const TemporaryMapRevealer = preload("res://source/match/support-powers/TemporaryMapRevealer.gd")


static func activate(match_node, power_id, player, target_position):
	var definition = Constants.Match.SupportPowers.DEFINITIONS[power_id]
	match power_id:
		Constants.Match.SupportPowers.RADAR_SWEEP:
			_activate_radar_sweep(match_node, player, target_position, definition)
		Constants.Match.SupportPowers.ORBITAL_STRIKE:
			_activate_orbital_strike(match_node, player, target_position, definition)
		Constants.Match.SupportPowers.EMP_PULSE:
			_activate_emp_pulse(match_node, player, target_position, definition)
		Constants.Match.SupportPowers.CHRONO_RELAY:
			_activate_chrono_relay(match_node, player, target_position, definition)
		Constants.Match.SupportPowers.SHIELD_OVERDRIVE:
			_activate_shield_overdrive(match_node, player, target_position, definition)
		Constants.Match.SupportPowers.NANITE_REPAIR_SWARM:
			_activate_nanite_repair_swarm(match_node, player, target_position, definition)
		Constants.Match.SupportPowers.WEATHER_STORM:
			_activate_weather_storm(match_node, player, target_position, definition)
		Constants.Match.SupportPowers.STRATEGIC_MISSILE:
			_activate_strategic_missile(match_node, player, target_position, definition)
		Constants.Match.SupportPowers.PARADROP:
			_activate_paradrop(match_node, player, target_position, definition)
		_:
			return false
	return true


static func _activate_radar_sweep(match_node, player, target_position, definition):
	var revealer = TemporaryMapRevealer.new()
	revealer.player = player
	revealer.sight_range = definition["radius"]
	revealer.lifetime = definition["duration"]
	match_node.add_child(revealer)
	revealer.global_position = target_position


static func _activate_orbital_strike(match_node, player, target_position, definition):
	var delay = definition.get("impact_delay", 0.0)
	if delay > 0.0:
		_spawn_warning_marker(
			match_node, target_position, definition["radius"], delay, Color(1.0, 0.72, 0.22, 0.55)
		)
		_schedule_after(
			match_node, delay, func(): _resolve_orbital_strike(match_node, player, target_position, definition)
		)
		return
	_resolve_orbital_strike(match_node, player, target_position, definition)


static func _resolve_orbital_strike(match_node, player, target_position, definition):
	CombatVfx.spawn_impact(match_node, target_position + Vector3(0.0, 0.35, 0.0), definition["radius"])
	_apply_area_damage(match_node, player, target_position, definition["radius"], definition["damage"], 1.2)


static func _activate_weather_storm(match_node, player, target_position, definition):
	var delay = definition.get("impact_delay", 0.0)
	if delay > 0.0:
		_spawn_warning_marker(
			match_node, target_position, definition["radius"], delay, Color(0.4, 0.9, 1.0, 0.5)
		)
		_schedule_after(
			match_node, delay, func(): _resolve_weather_storm(match_node, player, target_position, definition)
		)
		return
	_resolve_weather_storm(match_node, player, target_position, definition)


static func _resolve_weather_storm(match_node, player, target_position, definition):
	CombatVfx.spawn_impact(match_node, target_position + Vector3(0.0, 0.55, 0.0), definition["radius"])
	CombatVfx.spawn_impact(match_node, target_position + Vector3(1.6, 0.45, -1.2), definition["radius"] * 0.55)
	CombatVfx.spawn_impact(match_node, target_position + Vector3(-1.4, 0.45, 1.1), definition["radius"] * 0.55)
	_apply_area_damage(match_node, player, target_position, definition["radius"], definition["damage"], 1.6)


static func _activate_strategic_missile(match_node, player, target_position, definition):
	var delay = definition.get("impact_delay", 0.0)
	if delay > 0.0:
		_spawn_warning_marker(
			match_node, target_position, definition["radius"], delay, Color(1.0, 0.16, 0.08, 0.58)
		)
		_spawn_strategic_missile_projectile(match_node, target_position, delay)
		_schedule_after(
			match_node, delay, func(): _resolve_strategic_missile(match_node, player, target_position, definition)
		)
		return
	_resolve_strategic_missile(match_node, player, target_position, definition)


static func _resolve_strategic_missile(match_node, player, target_position, definition):
	CombatVfx.spawn_impact(match_node, target_position + Vector3(0.0, 0.85, 0.0), definition["radius"])
	CombatVfx.spawn_impact(match_node, target_position + Vector3(0.9, 0.55, 0.9), definition["radius"] * 0.45)
	CombatVfx.spawn_impact(match_node, target_position + Vector3(-0.8, 0.55, -0.7), definition["radius"] * 0.45)
	_apply_area_damage(match_node, player, target_position, definition["radius"], definition["damage"], 2.0)


static func _spawn_strategic_missile_projectile(match_node, target_position, lifetime):
	if match_node == null or not is_instance_valid(match_node) or not match_node.is_inside_tree():
		return
	var projectile = Node3D.new()
	projectile.name = "StrategicMissileProjectile"
	projectile.add_to_group("support_power_projectiles")
	match_node.add_child(projectile)
	projectile.global_position = target_position + Vector3(0.0, 8.5, 0.0)

	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.75, 0.08, 0.04, 1.0)
	body_material.emission_enabled = true
	body_material.emission = Color(0.9, 0.05, 0.02, 1.0)
	body_material.emission_energy_multiplier = 0.55

	var body_mesh = CylinderMesh.new()
	body_mesh.height = 1.35
	body_mesh.top_radius = 0.13
	body_mesh.bottom_radius = 0.18
	body_mesh.radial_segments = 12
	var body = MeshInstance3D.new()
	body.name = "Body"
	body.mesh = body_mesh
	body.material_override = body_material
	projectile.add_child(body)

	var nose_material = StandardMaterial3D.new()
	nose_material.albedo_color = Color(0.98, 0.82, 0.46, 1.0)
	nose_material.emission_enabled = true
	nose_material.emission = Color(1.0, 0.36, 0.12, 1.0)
	nose_material.emission_energy_multiplier = 0.75
	var nose_mesh = SphereMesh.new()
	nose_mesh.radius = 0.16
	nose_mesh.height = 0.26
	var nose = MeshInstance3D.new()
	nose.name = "Nose"
	nose.mesh = nose_mesh
	nose.position = Vector3(0.0, -0.78, 0.0)
	nose.material_override = nose_material
	projectile.add_child(nose)

	var trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = Color(1.0, 0.38, 0.05, 0.58)
	trail_material.emission_enabled = true
	trail_material.emission = Color(1.0, 0.24, 0.02, 1.0)
	trail_material.emission_energy_multiplier = 1.45
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var trail_mesh = CylinderMesh.new()
	trail_mesh.height = 1.25
	trail_mesh.top_radius = 0.06
	trail_mesh.bottom_radius = 0.2
	trail_mesh.radial_segments = 10
	var trail = MeshInstance3D.new()
	trail.name = "ExhaustTrail"
	trail.mesh = trail_mesh
	trail.position = Vector3(0.0, 1.18, 0.0)
	trail.material_override = trail_material
	projectile.add_child(trail)

	var tween = match_node.get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(projectile, "global_position", target_position + Vector3(0.0, 0.85, 0.0), lifetime)
	tween.tween_property(projectile, "scale", Vector3(1.15, 1.35, 1.15), lifetime)
	tween.chain().tween_callback(
		func():
			if projectile != null and is_instance_valid(projectile):
				projectile.queue_free()
	)


static func _spawn_warning_marker(match_node, target_position, radius, lifetime, color):
	if match_node == null or not is_instance_valid(match_node) or not match_node.is_inside_tree():
		return
	var marker = FadedCircle3D.instantiate()
	marker.name = "SupportPowerWarningMarker"
	marker.add_to_group("support_power_warning_markers")
	marker.radius = radius
	marker.width = 38.0
	marker.inner_edge_width = 16.0
	marker.outer_edge_width = 8.0
	marker.color = color
	marker.render_priority = 4
	match_node.add_child(marker)
	marker.global_position = target_position + Vector3(0.0, 0.04, 0.0)
	var timer = Timer.new()
	timer.one_shot = true
	marker.add_child(timer)
	timer.timeout.connect(marker.queue_free)
	timer.start(lifetime)


static func _schedule_after(match_node, delay, callback):
	if match_node == null or not is_instance_valid(match_node) or not match_node.is_inside_tree():
		return
	var timer = Timer.new()
	timer.one_shot = true
	match_node.add_child(timer)
	timer.timeout.connect(
		func():
			timer.queue_free()
			if match_node != null and is_instance_valid(match_node) and match_node.is_inside_tree():
				callback.call()
	)
	timer.start(delay)


static func _activate_paradrop(match_node, player, target_position, definition):
	var delay = definition.get("impact_delay", 0.0)
	if delay > 0.0:
		_spawn_warning_marker(
			match_node, target_position, definition["radius"], delay, Color(0.25, 0.8, 1.0, 0.48)
		)
		_schedule_after(
			match_node, delay, func(): _resolve_paradrop(match_node, player, target_position, definition)
		)
		return
	_resolve_paradrop(match_node, player, target_position, definition)


static func _resolve_paradrop(match_node, player, target_position, definition):
	var offsets = [
		Vector3(-1.1, 0.0, -0.8),
		Vector3(1.1, 0.0, -0.6),
		Vector3(0.0, 0.0, 1.0),
	]
	var unit_paths = definition["unit_paths"]
	for index in range(unit_paths.size()):
		var unit_scene = load(unit_paths[index])
		if unit_scene == null:
			continue
		var unit_to_spawn = unit_scene.instantiate()
		var preferred_offset = offsets[index % offsets.size()]
		var spawn_position = _pick_paradrop_spawn_position(
			match_node, target_position, preferred_offset, unit_to_spawn
		)
		if spawn_position == Vector3.INF:
			unit_to_spawn.free()
			continue
		CombatVfx.spawn_impact(match_node, spawn_position + Vector3(0.0, 0.35, 0.0), 0.85)
		MatchSignals.setup_and_spawn_unit.emit(unit_to_spawn, Transform3D(Basis(), spawn_position), player)


static func _pick_paradrop_spawn_position(match_node, target_position, preferred_offset, unit):
	if (
		match_node == null
		or not is_instance_valid(match_node)
		or not match_node.is_inside_tree()
		or unit.radius == null
		or unit.movement_domain == null
	):
		return target_position + preferred_offset
	var navigation_map_rid = match_node.navigation.get_navigation_map_rid_by_domain(unit.movement_domain)
	var preferred_position = (target_position + preferred_offset) * Vector3(1, 0, 1)
	var existing_units = (
		match_node.get_tree().get_nodes_in_group("units")
		+ match_node.get_tree().get_nodes_in_group("resource_units")
	)
	if (
		Utils.Match.Unit.Placement.validate_agent_placement_position(
			preferred_position, unit.radius, existing_units, navigation_map_rid
		)
		== Utils.Match.Unit.Placement.VALID
	):
		return preferred_position
	var starting_direction = preferred_offset * Vector3(1, 0, 1)
	if starting_direction.is_zero_approx():
		starting_direction = Vector3(0, 0, 1)
	return Utils.Match.Unit.Placement.find_valid_position_radially_yet_skip_starting_radius(
		target_position,
		0.0,
		unit.radius,
		0.1,
		starting_direction,
		false,
		navigation_map_rid,
		match_node.get_tree()
	)


static func _activate_chrono_relay(match_node, player, target_position, definition):
	CombatVfx.spawn_impact(match_node, target_position + Vector3(0.0, 0.45, 0.0), definition["radius"])
	for unit in match_node.get_tree().get_nodes_in_group("units"):
		if not unit is Unit:
			continue
		if not player.is_allied_with(unit.player):
			continue
		if unit.hp == null or unit.hp <= 0:
			continue
		if unit.find_child("Movement") == null:
			continue
		if unit.global_position_yless.distance_to(target_position * Vector3(1, 0, 1)) > definition["radius"]:
			continue
		unit.apply_chrono_relay(definition["duration"], definition["speed_multiplier"])
		CombatVfx.spawn_impact_at_unit(unit, 0.65)


static func _activate_shield_overdrive(match_node, player, target_position, definition):
	CombatVfx.spawn_impact(match_node, target_position + Vector3(0.0, 0.45, 0.0), definition["radius"])
	for unit in match_node.get_tree().get_nodes_in_group("units"):
		if not unit is Unit:
			continue
		if not player.is_allied_with(unit.player):
			continue
		if unit.hp == null or unit.hp <= 0:
			continue
		if unit.global_position_yless.distance_to(target_position * Vector3(1, 0, 1)) > definition["radius"]:
			continue
		unit.apply_support_shield(definition["duration"], definition["damage_multiplier"])
		CombatVfx.spawn_impact_at_unit(unit, 0.75)


static func _activate_nanite_repair_swarm(match_node, player, target_position, definition):
	CombatVfx.spawn_impact(match_node, target_position + Vector3(0.0, 0.45, 0.0), definition["radius"])
	for unit in match_node.get_tree().get_nodes_in_group("units"):
		if not unit is Unit:
			continue
		if not player.is_allied_with(unit.player):
			continue
		if unit.hp == null or unit.hp <= 0 or unit.hp_max == null:
			continue
		if unit.global_position_yless.distance_to(target_position * Vector3(1, 0, 1)) > definition["radius"]:
			continue
		var previous_hp = unit.hp
		unit.hp = min(unit.hp_max, unit.hp + definition["healing"])
		if unit.hp > previous_hp:
			CombatVfx.spawn_impact_at_unit(unit, 0.7)


static func _apply_area_damage(match_node, player, target_position, radius, damage, impact_scale):
	for unit in match_node.get_tree().get_nodes_in_group("units"):
		if not unit is Unit:
			continue
		if not player.is_enemy_with(unit.player):
			continue
		if unit.hp == null or unit.hp <= 0:
			continue
		if unit.global_position_yless.distance_to(target_position * Vector3(1, 0, 1)) > radius:
			continue
		unit.register_damage_source(null)
		unit.hp -= damage
		CombatVfx.spawn_impact_at_unit(unit, impact_scale)


static func _activate_emp_pulse(match_node, player, target_position, definition):
	CombatVfx.spawn_impact(match_node, target_position + Vector3(0.0, 0.35, 0.0), definition["radius"])
	for unit in match_node.get_tree().get_nodes_in_group("units"):
		if not unit is Unit:
			continue
		if not player.is_enemy_with(unit.player):
			continue
		if unit.hp == null or unit.hp <= 0:
			continue
		if unit.find_child("Movement") == null:
			continue
		if unit.global_position_yless.distance_to(target_position * Vector3(1, 0, 1)) > definition["radius"]:
			continue
		unit.disable_by_emp(definition["duration"])
		CombatVfx.spawn_impact_at_unit(unit, 0.9)
