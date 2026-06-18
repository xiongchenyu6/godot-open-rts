extends "res://source/match/players/Player.gd"

enum ResourceRequestPriority { LOW, MEDIUM, HIGH }
enum OffensiveStructure { VEHICLE_FACTORY, AIRCRAFT_FACTORY, BARRACKS }

@export var expected_number_of_workers = 3
@export var expected_number_of_refineries = 1
@export var expected_number_of_ore_harvesters = 2
@export var expected_number_of_ccs = 1
@export var expected_number_of_ag_turrets = 1
@export var expected_number_of_aa_turrets = 1
@export var expected_number_of_tesla_fence_segments = 2
@export var expected_number_of_arc_coil_towers = 1
@export var expected_number_of_lance_beam_towers = 1
@export var expected_number_of_prism_defense_obelisks = 1
@export var expected_number_of_rail_cannon_bunkers = 1
@export var primary_offensive_structure = OffensiveStructure.VEHICLE_FACTORY
@export var secondary_offensive_structure = OffensiveStructure.BARRACKS
@export var tertiary_offensive_structure = OffensiveStructure.AIRCRAFT_FACTORY
@export var expected_number_of_battlegroups = 2
@export var expected_number_of_units_in_battlegroup = 4
@export var active_offense_enabled = true

var _provisioning_ongoing = false
var _resource_requests = {
	ResourceRequestPriority.LOW: [],
	ResourceRequestPriority.MEDIUM: [],
	ResourceRequestPriority.HIGH: [],
}
var _call_to_perform_during_process = null

@onready var _match = find_parent("Match")

@onready var _economy_controller = find_child("EconomyController")
@onready var _defense_controller = find_child("DefenseController")
@onready var _offense_controller = find_child("OffenseController")
@onready var _intelligence_controller = find_child("IntelligenceController")
@onready var _supply_crate_collection_controller = find_child("SupplyCrateCollectionController")
@onready var _construction_works_controller = find_child("ConstructionWorksController")
@onready var _tactical_support_powers_controller = find_child("TacticalSupportPowersController")
@onready var _engineer_capture_controller = find_child("EngineerCaptureController")
@onready var _tech_bunker_garrison_controller = find_child("TechBunkerGarrisonController")
@onready var _saboteur_infiltration_controller = find_child("SaboteurInfiltrationController")


func apply_player_settings(player_settings):
	match player_settings.controller:
		Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_BEGINNER:
			_apply_beginner_profile()
		Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_EASY:
			_apply_easy_profile()
		Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_HARD:
			_apply_hard_profile()
		_:
			_apply_normal_profile()


func _apply_beginner_profile():
	expected_number_of_workers = 2
	expected_number_of_refineries = 1
	expected_number_of_ore_harvesters = 1
	expected_number_of_ccs = 1
	expected_number_of_ag_turrets = 1
	expected_number_of_aa_turrets = 0
	expected_number_of_tesla_fence_segments = 0
	expected_number_of_arc_coil_towers = 0
	expected_number_of_lance_beam_towers = 0
	expected_number_of_prism_defense_obelisks = 0
	expected_number_of_rail_cannon_bunkers = 0
	primary_offensive_structure = OffensiveStructure.VEHICLE_FACTORY
	secondary_offensive_structure = OffensiveStructure.BARRACKS
	tertiary_offensive_structure = OffensiveStructure.VEHICLE_FACTORY
	expected_number_of_battlegroups = 0
	expected_number_of_units_in_battlegroup = 0
	active_offense_enabled = false


func _apply_easy_profile():
	expected_number_of_workers = 2
	expected_number_of_refineries = 1
	expected_number_of_ore_harvesters = 1
	expected_number_of_ccs = 1
	expected_number_of_ag_turrets = 0
	expected_number_of_aa_turrets = 0
	expected_number_of_tesla_fence_segments = 0
	expected_number_of_arc_coil_towers = 0
	expected_number_of_lance_beam_towers = 0
	expected_number_of_prism_defense_obelisks = 0
	expected_number_of_rail_cannon_bunkers = 0
	primary_offensive_structure = OffensiveStructure.VEHICLE_FACTORY
	secondary_offensive_structure = OffensiveStructure.BARRACKS
	tertiary_offensive_structure = OffensiveStructure.VEHICLE_FACTORY
	expected_number_of_battlegroups = 1
	expected_number_of_units_in_battlegroup = 3
	active_offense_enabled = true


func _apply_normal_profile():
	expected_number_of_workers = 3
	expected_number_of_refineries = 1
	expected_number_of_ore_harvesters = 2
	expected_number_of_ccs = 1
	expected_number_of_ag_turrets = 1
	expected_number_of_aa_turrets = 1
	expected_number_of_tesla_fence_segments = 2
	expected_number_of_arc_coil_towers = 1
	expected_number_of_lance_beam_towers = 1
	expected_number_of_prism_defense_obelisks = 1
	expected_number_of_rail_cannon_bunkers = 1
	primary_offensive_structure = OffensiveStructure.VEHICLE_FACTORY
	secondary_offensive_structure = OffensiveStructure.BARRACKS
	tertiary_offensive_structure = OffensiveStructure.AIRCRAFT_FACTORY
	expected_number_of_battlegroups = 2
	expected_number_of_units_in_battlegroup = 4
	active_offense_enabled = true


func _apply_hard_profile():
	expected_number_of_workers = 4
	expected_number_of_refineries = 2
	expected_number_of_ore_harvesters = 3
	expected_number_of_ccs = 2
	expected_number_of_ag_turrets = 2
	expected_number_of_aa_turrets = 2
	expected_number_of_tesla_fence_segments = 4
	expected_number_of_arc_coil_towers = 2
	expected_number_of_lance_beam_towers = 2
	expected_number_of_prism_defense_obelisks = 2
	expected_number_of_rail_cannon_bunkers = 2
	primary_offensive_structure = OffensiveStructure.VEHICLE_FACTORY
	secondary_offensive_structure = OffensiveStructure.BARRACKS
	tertiary_offensive_structure = OffensiveStructure.AIRCRAFT_FACTORY
	expected_number_of_battlegroups = 3
	expected_number_of_units_in_battlegroup = 5
	active_offense_enabled = true


func _ready():
	# wait for match to be ready
	if not _match.is_node_ready():
		await _match.ready
	# wait additional frame to make sure other players are in place
	await get_tree().physics_frame

	changed.connect(_on_player_data_changed)
	_economy_controller.resources_required.connect(
		_on_resource_request.bind(_economy_controller, ResourceRequestPriority.HIGH)
	)
	_economy_controller.setup(self)
	_defense_controller.resources_required.connect(
		_on_resource_request.bind(_defense_controller, ResourceRequestPriority.MEDIUM)
	)
	_defense_controller.setup(self)
	if active_offense_enabled:
		_offense_controller.resources_required.connect(
			_on_resource_request.bind(_offense_controller, ResourceRequestPriority.LOW)
		)
		_offense_controller.setup(self)
		_engineer_capture_controller.resources_required.connect(
			_on_resource_request.bind(_engineer_capture_controller, ResourceRequestPriority.MEDIUM)
		)
		_engineer_capture_controller.setup(self)
		_saboteur_infiltration_controller.resources_required.connect(
			_on_resource_request.bind(
				_saboteur_infiltration_controller, ResourceRequestPriority.MEDIUM
			)
		)
		_saboteur_infiltration_controller.setup(self)
		_tech_bunker_garrison_controller.setup(self)
	_intelligence_controller.setup(self)
	_supply_crate_collection_controller.setup(self)
	_construction_works_controller.setup(self)
	if active_offense_enabled:
		_tactical_support_powers_controller.setup(self)


func _process(_delta):
	if _call_to_perform_during_process != null:
		var call_to_perform = _call_to_perform_during_process
		_call_to_perform_during_process = null
		call_to_perform.call()


func _provision(controller, resources, metadata):
	_provisioning_ongoing = true
	controller.provision(resources, metadata)
	_provisioning_ongoing = false


func _try_fulfilling_resource_requests_according_to_priorities_next_frame():
	"""This function defers call so that:
	1. 'add_child() from tree_exited signal handler' bug is avoided
	2. high level loop of signals triggering each other is avoided"""
	_call_to_perform_during_process = _try_fulfilling_resource_requests_according_to_priorities


func _try_fulfilling_resource_requests_according_to_priorities():
	if _provisioning_ongoing:
		return
	for priority in [
		ResourceRequestPriority.HIGH, ResourceRequestPriority.MEDIUM, ResourceRequestPriority.LOW
	]:
		while (
			not _resource_requests[priority].is_empty()
			and has_resources(_resource_requests[priority].front()["resources"])
		):
			var resource_request = _resource_requests[priority].pop_front()
			_provision(
				resource_request["controller"],
				resource_request["resources"],
				resource_request["metadata"]
			)
		if (
			not _resource_requests[priority].is_empty()
			and not has_resources(_resource_requests[priority].front()["resources"])
		):
			break


func _on_player_data_changed():
	_try_fulfilling_resource_requests_according_to_priorities_next_frame()


func _on_resource_request(resources, metadata, controller, priority):
	if _provisioning_ongoing:
		push_warning(
			"Deferring AI resource request received during provisioning: {0}".format([metadata])
		)
	_resource_requests[priority].append(
		{"controller": controller, "resources": resources, "metadata": metadata}
	)
	_try_fulfilling_resource_requests_according_to_priorities_next_frame()
