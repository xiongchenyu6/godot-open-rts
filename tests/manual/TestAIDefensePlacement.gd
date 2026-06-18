extends "res://tests/manual/Match.gd"

const AntiGroundTurret = preload("res://source/match/units/AntiGroundTurret.gd")
const AntiGroundTurretUnit = preload("res://source/match/units/AntiGroundTurret.tscn")
const AntiAirTurret = preload("res://source/match/units/AntiAirTurret.gd")
const AntiAirTurretUnit = preload("res://source/match/units/AntiAirTurret.tscn")
const TeslaFenceSegment = preload("res://source/match/units/TeslaFenceSegment.gd")
const TeslaFenceSegmentUnit = preload("res://source/match/units/TeslaFenceSegment.tscn")
const ArcCoilDefenseTower = preload("res://source/match/units/ArcCoilDefenseTower.gd")
const ArcCoilDefenseTowerUnit = preload("res://source/match/units/ArcCoilDefenseTower.tscn")
const LanceBeamDefenseTower = preload("res://source/match/units/LanceBeamDefenseTower.gd")
const LanceBeamDefenseTowerUnit = preload("res://source/match/units/LanceBeamDefenseTower.tscn")
const PrismDefenseObelisk = preload("res://source/match/units/PrismDefenseObelisk.gd")
const PrismDefenseObeliskUnit = preload("res://source/match/units/PrismDefenseObelisk.tscn")
const RailCannonBunker = preload("res://source/match/units/RailCannonBunker.gd")
const RailCannonBunkerUnit = preload("res://source/match/units/RailCannonBunker.tscn")
const RadarUplinkUnit = preload("res://source/match/units/RadarUplink.tscn")
const RoboticsBayUnit = preload("res://source/match/units/RoboticsBay.tscn")
const TechLabUnit = preload("res://source/match/units/TechLab.tscn")
const DefenseController = preload(
	"res://source/match/players/simple-clairvoyant-ai/DefenseController.gd"
)

class DefenseHarness:
	extends Node

	var expected_number_of_ag_turrets = 1
	var expected_number_of_aa_turrets = 0
	var expected_number_of_tesla_fence_segments = 0
	var expected_number_of_arc_coil_towers = 0
	var expected_number_of_lance_beam_towers = 0
	var expected_number_of_prism_defense_obelisks = 0
	var expected_number_of_rail_cannon_bunkers = 0

@onready var _ai_player = $Players/Human
@onready var _ai_command_center = $Players/Human/CommandCenter
@onready var _enemy_command_center = $Players/Enemy/CommandCenter


func _ready():
	super()
	for _i in range(4):
		await get_tree().process_frame
		await get_tree().physics_frame
	_ai_command_center.global_position = Vector3(10.0, 0.0, 10.0)
	_enemy_command_center.global_position = Vector3(34.0, 0.0, 10.0)
	await get_tree().process_frame
	await get_tree().physics_frame

	var harness = DefenseHarness.new()
	add_child(harness)
	var controller = DefenseController.new()
	harness.add_child(controller)

	var requests = []
	controller.resources_required.connect(
		func(resources, metadata): requests.append({"resources": resources, "metadata": metadata})
	)
	controller.setup(_ai_player)
	controller.provision({}, "unknown_test_metadata")
	_assert_defense_request(
		requests[0], "ag_turret", AntiGroundTurretUnit, "anti-ground turret"
	)
	var ag_turrets_before_bad_provision = _defense_structures(AntiGroundTurret).size()
	controller.provision({"resource_a": 999, "resource_b": 999}, "ag_turret")
	await get_tree().process_frame
	_assert(
		_defense_structures(AntiGroundTurret).size() == ag_turrets_before_bad_provision,
		"AI defense should ignore mismatched turret resources instead of constructing"
	)
	_assert(
		controller._number_of_pending_ag_turret_resource_requests >= 0,
		"AI defense mismatched resource provision should not leave negative turret requests"
	)

	controller.provision(requests[0]["resources"], requests[0]["metadata"])
	await get_tree().process_frame

	_assert_defense_structure(
		_defense_structures(AntiGroundTurret),
		"anti-ground turret"
	)
	await _assert_ai_repairs_damaged_structures(controller)

	controller.queue_free()
	harness.queue_free()

	await _assert_ai_constructs_unlocked_advanced_defenses()
	get_tree().quit()


func _assert_ai_constructs_unlocked_advanced_defenses():
	_unlock_advanced_defense_tech()
	var harness = DefenseHarness.new()
	harness.expected_number_of_ag_turrets = 1
	harness.expected_number_of_aa_turrets = 1
	harness.expected_number_of_tesla_fence_segments = 1
	harness.expected_number_of_arc_coil_towers = 1
	harness.expected_number_of_lance_beam_towers = 1
	harness.expected_number_of_prism_defense_obelisks = 1
	harness.expected_number_of_rail_cannon_bunkers = 1
	add_child(harness)

	var controller = DefenseController.new()
	harness.add_child(controller)
	var requests = []
	controller.resources_required.connect(
		func(resources, metadata): requests.append({"resources": resources, "metadata": metadata})
	)
	controller.setup(_ai_player)

	var expected_requests = [
		{
			"metadata": "aa_turret",
			"scene": AntiAirTurretUnit,
			"label": "anti-air turret",
		},
		{
			"metadata": "tesla_fence_segment",
			"scene": TeslaFenceSegmentUnit,
			"label": "tesla fence segment",
		},
		{
			"metadata": "arc_coil_tower",
			"scene": ArcCoilDefenseTowerUnit,
			"label": "arc coil tower",
		},
		{
			"metadata": "lance_beam_tower",
			"scene": LanceBeamDefenseTowerUnit,
			"label": "lance beam tower",
		},
		{
			"metadata": "prism_defense_obelisk",
			"scene": PrismDefenseObeliskUnit,
			"label": "prism defense obelisk",
		},
		{
			"metadata": "rail_cannon_bunker",
			"scene": RailCannonBunkerUnit,
			"label": "rail cannon bunker",
		},
	]
	_assert(
		requests.size() == expected_requests.size(),
		"AI defense should request every missing unlocked advanced defense"
	)
	for index in range(expected_requests.size()):
		var expected_request = expected_requests[index]
		_assert_defense_request(
			requests[index],
			expected_request["metadata"],
			expected_request["scene"],
			expected_request["label"]
		)
		controller.provision(requests[index]["resources"], requests[index]["metadata"])
		await get_tree().process_frame

	_assert_defense_structure(_defense_structures(AntiGroundTurret), "anti-ground turret")
	_assert_defense_structure(_defense_structures(AntiAirTurret), "anti-air turret")
	_assert_defense_structure(_defense_structures(TeslaFenceSegment), "tesla fence segment")
	_assert_defense_structure(_defense_structures(ArcCoilDefenseTower), "arc coil tower")
	_assert_defense_structure(_defense_structures(LanceBeamDefenseTower), "lance beam tower")
	_assert_defense_structure(_defense_structures(PrismDefenseObelisk), "prism defense obelisk")
	_assert_defense_structure(_defense_structures(RailCannonBunker), "rail cannon bunker")


func _unlock_advanced_defense_tech():
	_setup_and_spawn_unit(
		RadarUplinkUnit.instantiate(),
		Transform3D(Basis(), Vector3(6.0, 0.0, 15.0)),
		_ai_player,
		false
	)
	_setup_and_spawn_unit(
		RoboticsBayUnit.instantiate(),
		Transform3D(Basis(), Vector3(6.0, 0.0, 6.0)),
		_ai_player,
		false
	)
	_setup_and_spawn_unit(
		TechLabUnit.instantiate(),
		Transform3D(Basis(), Vector3(15.0, 0.0, 6.0)),
		_ai_player,
		false
	)
	await get_tree().process_frame


func _assert_defense_request(request, metadata, scene, label):
	_assert(request["metadata"] == metadata, "AI defense should tag the {0} request".format([label]))
	_assert(
		request["resources"] == Constants.Match.Units.CONSTRUCTION_COSTS[scene.resource_path],
		"AI defense should request the configured {0} cost".format([label])
	)


func _assert_defense_structure(defense_structures, label):
	var structure = defense_structures.back() if not defense_structures.is_empty() else null
	_assert(structure != null, "AI defense should construct a {0}".format([label]))
	_assert(
		structure.player == _ai_player,
		"AI defense should construct the {0} for its player".format([label])
	)
	_assert(
		structure.global_position.x > _ai_command_center.global_position.x,
		"AI defense should place the {0} on the enemy-facing side of the command center".format(
			[label]
		)
		+ _placement_debug_message(structure)
	)
	_assert(
		structure.global_position.distance_to(_enemy_command_center.global_position)
		< _ai_command_center.global_position.distance_to(_enemy_command_center.global_position),
		"AI defense {0} should be closer to the enemy approach than the command center".format(
			[label]
		)
		+ _placement_debug_message(structure)
	)


func _assert_ai_repairs_damaged_structures(controller):
	var previous_deficit_spending = FeatureFlags.allow_resources_deficit_spending
	FeatureFlags.allow_resources_deficit_spending = false
	_ai_player.resource_a = 20
	_ai_player.resource_b = 20

	_ai_command_center.hp = int(floor(float(_ai_command_center.hp_max) * 0.5))
	var repair_cost = _ai_command_center.get_repair_cost()
	var starting_resource_a = _ai_player.resource_a
	var starting_resource_b = _ai_player.resource_b
	controller._on_refresh_timer_timeout()

	_assert(_ai_command_center.is_repairing(), "AI should start repairing damaged base structures")
	_assert(
		_ai_player.resource_a == starting_resource_a - repair_cost["resource_a"],
		"AI structure repair should spend resource A upfront"
	)
	_assert(
		_ai_player.resource_b == starting_resource_b - repair_cost["resource_b"],
		"AI structure repair should spend resource B upfront"
	)
	await _wait_until(
		func(): return not _ai_command_center.is_repairing(),
		4.0,
		"AI structure repair should complete"
	)
	_assert(_ai_command_center.hp == _ai_command_center.hp_max, "AI repair should restore HP")

	_ai_command_center.hp = int(floor(float(_ai_command_center.hp_max) * 0.5))
	var damaged_hp = _ai_command_center.hp
	_ai_player.resource_a = 0
	_ai_player.resource_b = 0
	var not_enough_resources_count = [0]
	var on_not_enough_resources = func(_player_arg): not_enough_resources_count[0] += 1
	MatchSignals.not_enough_resources_for_construction.connect(on_not_enough_resources)
	controller._on_refresh_timer_timeout()
	MatchSignals.not_enough_resources_for_construction.disconnect(on_not_enough_resources)

	_assert(
		not _ai_command_center.is_repairing(),
		"AI should not start structure repair without resources"
	)
	_assert(_ai_command_center.hp == damaged_hp, "unaffordable AI repair should leave HP unchanged")
	_assert(
		not_enough_resources_count[0] == 0,
		"AI should not emit player-facing resource warnings for unaffordable repairs"
	)
	_ai_command_center.hp = _ai_command_center.hp_max
	FeatureFlags.allow_resources_deficit_spending = previous_deficit_spending


func _defense_structures(defense_script):
	return get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit.get_script() == defense_script and unit.player == _ai_player
	)


func _placement_debug_message(structure):
	return " structure={0} command_center={1} enemy_command_center={2}".format(
		[
			structure.global_position,
			_ai_command_center.global_position,
			_enemy_command_center.global_position,
		]
	)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)


func _wait_until(condition, timeout_seconds, message):
	var elapsed_seconds = 0.0
	while elapsed_seconds < timeout_seconds:
		if condition.call():
			return
		await get_tree().create_timer(0.1).timeout
		elapsed_seconds += 0.1
	_assert(condition.call(), message)
