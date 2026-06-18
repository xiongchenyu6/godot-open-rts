extends "res://tests/manual/Match.gd"

const ArcCoilDefenseTowerUnit = preload("res://source/match/units/ArcCoilDefenseTower.tscn")
const LanceBeamDefenseTowerUnit = preload("res://source/match/units/LanceBeamDefenseTower.tscn")
const PrismDefenseObeliskUnit = preload("res://source/match/units/PrismDefenseObelisk.tscn")
const RailCannonBunkerUnit = preload("res://source/match/units/RailCannonBunker.tscn")
const WorkerMenuScene = preload("res://source/match/hud/unit-menus/WorkerMenu.tscn")
const ASSAULT_ICON_SET = "rts-assault-tech-20260615-01"
const LATE_TECH_ICON_SET = "imagegen-rts-late-tech-20260616-01"
const NEW_ASSET_ICON_SET = "imagegen-rts-new-assets-20260616-01"

@onready var _player = $Players/Human


func _ready():
	super()
	await get_tree().process_frame

	var empty_player = Node.new()
	add_child(empty_player)
	assert(
		not Utils.Match.Unit.Tech.can_construct(
			empty_player, ArcCoilDefenseTowerUnit.resource_path
		),
		"arc coil tower should require robotics bay"
	)
	assert(
		not Utils.Match.Unit.Tech.can_construct(
			empty_player, LanceBeamDefenseTowerUnit.resource_path
		),
		"lance beam tower should require tech lab"
	)
	assert(
		not Utils.Match.Unit.Tech.can_construct(
			empty_player, PrismDefenseObeliskUnit.resource_path
		),
		"prism defense obelisk should require tech lab"
	)
	assert(
		not Utils.Match.Unit.Tech.can_construct(
			empty_player, RailCannonBunkerUnit.resource_path
		),
		"rail cannon bunker should require tech lab"
	)
	empty_player.queue_free()

	assert(
		Utils.Match.Unit.Tech.can_construct(_player, ArcCoilDefenseTowerUnit.resource_path),
		"robotics bay should unlock arc coil defense tower construction"
	)
	assert(
		Utils.Match.Unit.Tech.can_construct(_player, LanceBeamDefenseTowerUnit.resource_path),
		"tech lab should unlock lance beam defense tower construction"
	)
	assert(
		Utils.Match.Unit.Tech.can_construct(_player, PrismDefenseObeliskUnit.resource_path),
		"tech lab should unlock prism defense obelisk construction"
	)
	assert(
		Utils.Match.Unit.Tech.can_construct(_player, RailCannonBunkerUnit.resource_path),
		"tech lab should unlock rail cannon bunker construction"
	)
	_assert_structure_constants(ArcCoilDefenseTowerUnit, "ARC_COIL_DEFENSE_TOWER")
	_assert_structure_constants(LanceBeamDefenseTowerUnit, "LANCE_BEAM_DEFENSE_TOWER")
	_assert_structure_constants(PrismDefenseObeliskUnit, "PRISM_DEFENSE_OBELISK")
	_assert_structure_constants(RailCannonBunkerUnit, "RAIL_CANNON_BUNKER")
	_assert_worker_menu_has_advanced_defenses()
	_assert_structure_blueprint_rotation_dead_zone()
	_assert_structure_blueprint_respects_base_radius()

	_setup_and_spawn_unit(
		ArcCoilDefenseTowerUnit.instantiate(),
		Transform3D(Basis(), Vector3(18.0, 0.0, 10.0)),
		_player,
		false
	)
	_setup_and_spawn_unit(
		LanceBeamDefenseTowerUnit.instantiate(),
		Transform3D(Basis(), Vector3(21.0, 0.0, 10.0)),
		_player,
		false
	)
	_setup_and_spawn_unit(
		PrismDefenseObeliskUnit.instantiate(),
		Transform3D(Basis(), Vector3(24.0, 0.0, 10.0)),
		_player,
		false
	)
	_setup_and_spawn_unit(
		RailCannonBunkerUnit.instantiate(),
		Transform3D(Basis(), Vector3(27.0, 0.0, 10.0)),
		_player,
		false
	)
	await get_tree().process_frame

	var arc_tower = $Players/Human/ArcCoilDefenseTower
	var lance_tower = $Players/Human/LanceBeamDefenseTower
	var prism_obelisk = $Players/Human/PrismDefenseObelisk
	var rail_bunker = $Players/Human/RailCannonBunker
	assert(arc_tower.hp == arc_tower.hp_max, "arc coil tower should spawn at full HP")
	assert(lance_tower.hp == lance_tower.hp_max, "lance beam tower should spawn at full HP")
	assert(prism_obelisk.hp == prism_obelisk.hp_max, "prism defense obelisk should spawn at full HP")
	assert(rail_bunker.hp == rail_bunker.hp_max, "rail cannon bunker should spawn at full HP")
	assert(arc_tower.splash_radius > 0.0, "arc coil tower should provide splash damage")
	assert(
		Constants.Match.Navigation.Domain.TERRAIN in arc_tower.attack_domains,
		"arc coil tower should fight ground targets"
	)
	assert(
		Constants.Match.Navigation.Domain.AIR in arc_tower.attack_domains,
		"arc coil tower should fight air targets"
	)
	assert(
		Constants.Match.Navigation.Domain.TERRAIN in lance_tower.attack_domains,
		"lance beam tower should fight ground targets"
	)
	assert(
		Constants.Match.Navigation.Domain.AIR in lance_tower.attack_domains,
		"lance beam tower should fight air targets"
	)
	assert(
		lance_tower.attack_range > arc_tower.attack_range,
		"lance beam tower should be the longer-range advanced defense"
	)
	assert(
		lance_tower.attack_damage > arc_tower.attack_damage,
		"lance beam tower should hit harder per shot than arc coil tower"
	)
	assert(
		Constants.Match.Navigation.Domain.TERRAIN in prism_obelisk.attack_domains,
		"prism defense obelisk should fight ground targets"
	)
	assert(
		Constants.Match.Navigation.Domain.AIR in prism_obelisk.attack_domains,
		"prism defense obelisk should fight air targets"
	)
	assert(
		prism_obelisk.attack_range > lance_tower.attack_range,
		"prism defense obelisk should outrange the lance beam tower"
	)
	assert(
		prism_obelisk.structure_damage_multiplier > lance_tower.structure_damage_multiplier,
		"prism defense obelisk should specialize in structure damage"
	)
	assert(
		Constants.Match.Navigation.Domain.TERRAIN in rail_bunker.attack_domains,
		"rail cannon bunker should fight ground targets"
	)
	assert(
		not Constants.Match.Navigation.Domain.AIR in rail_bunker.attack_domains,
		"rail cannon bunker should not replace dedicated air defenses"
	)
	assert(
		rail_bunker.attack_range > lance_tower.attack_range,
		"rail cannon bunker should outrange the lance beam tower"
	)
	assert(
		rail_bunker.splash_radius > arc_tower.splash_radius,
		"rail cannon bunker should provide heavier splash damage"
	)
	assert(
		Constants.Match.Units.POWER_DRAIN[LanceBeamDefenseTowerUnit.resource_path]
		> Constants.Match.Units.POWER_DRAIN[ArcCoilDefenseTowerUnit.resource_path],
		"lance beam tower should cost more power than arc coil tower"
	)
	assert(
		Constants.Match.Units.POWER_DRAIN[RailCannonBunkerUnit.resource_path]
		> Constants.Match.Units.POWER_DRAIN[LanceBeamDefenseTowerUnit.resource_path],
		"rail cannon bunker should cost more power than lance beam tower"
	)
	assert(
		Constants.Match.Units.POWER_DRAIN[PrismDefenseObeliskUnit.resource_path]
		> Constants.Match.Units.POWER_DRAIN[RailCannonBunkerUnit.resource_path],
		"prism defense obelisk should be the most power-hungry point defense"
	)
	get_tree().quit()


func _assert_structure_constants(structure_scene, name_key):
	var structure_path = structure_scene.resource_path
	assert(
		Constants.Match.Units.STRUCTURE_BLUEPRINTS.has(structure_path),
		"advanced defense should have a construction blueprint"
	)
	assert(
		ResourceLoader.exists(Constants.Match.Units.STRUCTURE_BLUEPRINTS[structure_path]),
		"advanced defense construction blueprint should load"
	)
	assert(
		Constants.Match.Units.STRUCTURE_NAME_KEYS[structure_path] == name_key,
		"advanced defense should have a translated structure name key"
	)
	assert(
		Constants.Match.Units.CONSTRUCTION_COSTS[structure_path]["resource_a"] > 0,
		"advanced defense should cost resource A"
	)
	assert(
		Constants.Match.Units.CONSTRUCTION_COSTS[structure_path]["resource_b"] > 0,
		"advanced defense should cost resource B"
	)
	assert(
		Constants.Match.Units.POWER_DRAIN[structure_path] > 0,
		"advanced defense should drain base power"
	)
	assert(
		Constants.Match.Units.PROJECTILES.has(structure_path),
		"advanced defense should have a projectile mapping"
	)
	assert(
		ResourceLoader.exists(Constants.Match.Units.PROJECTILES[structure_path]),
		"advanced defense projectile should load"
	)


func _assert_worker_menu_has_advanced_defenses():
	var worker_menu = WorkerMenuScene.instantiate()
	add_child(worker_menu)
	assert(
		worker_menu.find_child("PlaceArcCoilDefenseTowerButton") != null,
		"worker menu should expose arc coil defense tower"
	)
	assert(
		worker_menu.find_child("PlaceLanceBeamDefenseTowerButton") != null,
		"worker menu should expose lance beam defense tower"
	)
	var prism_button = worker_menu.find_child("PlacePrismDefenseObeliskButton")
	assert(prism_button != null, "worker menu should expose prism defense obelisk")
	var prism_icon = prism_button.find_child("TextureRect").texture
	assert(prism_icon != null, "prism defense obelisk should load a generated icon")
	assert(
		_icon_uses_canonical_or_marker(prism_icon, NEW_ASSET_ICON_SET),
		"prism defense obelisk should use a packaged root icon or generated new asset icon set"
	)
	var rail_button = worker_menu.find_child("PlaceRailCannonBunkerButton")
	assert(rail_button != null, "worker menu should expose rail cannon bunker")
	var rail_icon = rail_button.find_child("TextureRect").texture
	assert(rail_icon != null, "rail cannon bunker should load a generated icon")
	assert(
		_icon_uses_canonical_or_marker(rail_icon, LATE_TECH_ICON_SET),
		"rail cannon bunker should use a packaged root icon or latest late-tech generated icon set"
	)
	worker_menu.queue_free()


func _icon_uses_canonical_or_marker(icon, marker):
	return (
		icon.resource_path.begins_with("res://assets/ui/icons/")
		and not icon.resource_path.contains("/generated/")
	) or marker in icon.resource_path


func _assert_structure_blueprint_respects_base_radius():
	var placement_handler = $Players/Human/StructurePlacementHandler
	var command_center = $Players/Human/CommandCenter
	placement_handler._start_structure_placement(ArcCoilDefenseTowerUnit)
	placement_handler._active_blueprint_node.global_position = (
		command_center.global_position + Vector3(4.0, 0.0, 0.0)
	)
	assert(
		placement_handler._active_blueprint_within_base_construction_radius(),
		"structure placement should recognize blueprints inside friendly base build radius"
	)

	var far_offset = (
		command_center.radius
		+ placement_handler._pending_structure_radius
		+ Constants.Match.Units.BASE_CONSTRUCTION_RADIUS_M
		+ 4.0
	)
	placement_handler._active_blueprint_node.global_position = _find_far_position_inside_map(
		placement_handler, command_center, far_offset
	)
	var far_validity = placement_handler._calculate_blueprint_position_validity()
	assert(
		far_validity == placement_handler.BlueprintPositionValidity.OUT_OF_BASE_RADIUS,
		"structure placement should reject blueprints outside friendly base build radius"
	)
	placement_handler._update_feedback_label(far_validity)
	assert(
		placement_handler._feedback_label.text == tr("BLUEPRINT_OUT_OF_BASE_RADIUS"),
		"structure placement should explain base radius failures"
	)
	placement_handler._cancel_structure_placement()
	assert(
		not placement_handler._structure_placement_started(),
		"base radius test should leave no active placement"
	)


func _find_far_position_inside_map(placement_handler, command_center, far_offset):
	for direction in _placement_test_directions():
		var candidate = command_center.global_position + direction * far_offset
		placement_handler._active_blueprint_node.global_position = candidate
		if placement_handler._active_bluprint_out_of_map():
			continue
		if (
			Utils.Match.Unit.Placement.is_within_base_construction_radius(
				_player, candidate, placement_handler._pending_structure_radius
			)
		):
			continue
		return candidate
	assert(false, "test setup should provide an in-map point outside the base build radius")
	return command_center.global_position


func _placement_test_directions():
	return [
		Vector3(0, 0, -1),
		Vector3(1, 0, 0),
		Vector3(0, 0, 1),
		Vector3(-1, 0, 0),
		Vector3(1, 0, -1).normalized(),
		Vector3(1, 0, 1).normalized(),
		Vector3(-1, 0, 1).normalized(),
		Vector3(-1, 0, -1).normalized(),
	]


func _assert_structure_blueprint_rotation_dead_zone():
	var placement_handler = $Players/Human/StructurePlacementHandler
	placement_handler._start_structure_placement(ArcCoilDefenseTowerUnit)
	var blueprint_position = Vector3(20.0, 0.0, 20.0)
	placement_handler._active_blueprint_node.global_position = blueprint_position

	var near_target = placement_handler._calculate_blueprint_rotation_target(
		blueprint_position + Vector3(0.02, 0.0, 0.02)
	)
	assert(near_target == null, "blueprint rotation should ignore pointer movement in the dead zone")

	var far_target = placement_handler._calculate_blueprint_rotation_target(
		blueprint_position + Vector3(0.0, 0.0, 3.0)
	)
	assert(far_target != null, "blueprint rotation should accept pointer movement outside the dead zone")
	assert(
		far_target.is_equal_approx(Vector3(20.0, 0.0, 23.0)),
		"blueprint rotation target should preserve the blueprint Y coordinate"
	)

	placement_handler._cancel_structure_placement()
	assert(
		not placement_handler._structure_placement_started(),
		"blueprint rotation test should leave no active placement"
	)
