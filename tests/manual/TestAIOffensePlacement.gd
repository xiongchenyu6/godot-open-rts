extends "res://tests/manual/Match.gd"

const OffenseController = preload(
	"res://source/match/players/simple-clairvoyant-ai/OffenseController.gd"
)
const VehicleFactoryUnit = preload("res://source/match/units/VehicleFactory.tscn")
const VehicleFactory = preload("res://source/match/units/VehicleFactory.gd")


class OffenseHarness:
	extends Node

	enum OffensiveStructure { VEHICLE_FACTORY, AIRCRAFT_FACTORY, BARRACKS }

	var primary_offensive_structure = OffensiveStructure.VEHICLE_FACTORY
	var secondary_offensive_structure = OffensiveStructure.BARRACKS
	var tertiary_offensive_structure = OffensiveStructure.AIRCRAFT_FACTORY
	var expected_number_of_battlegroups = 1
	var expected_number_of_units_in_battlegroup = 4


@onready var _ai_player = $Players/AI
@onready var _rear_command_center = $Players/AI/RearCommandCenter
@onready var _front_command_center = $Players/AI/FrontCommandCenter
@onready var _enemy_command_center = $Players/Enemy/CommandCenter


func _ready():
	super()
	for _i in range(4):
		await get_tree().process_frame
		await get_tree().physics_frame
	_rear_command_center.global_position = Vector3(8.0, 0.0, 10.0)
	_front_command_center.global_position = Vector3(22.0, 0.0, 10.0)
	_enemy_command_center.global_position = Vector3(44.0, 0.0, 10.0)
	await get_tree().process_frame
	await get_tree().physics_frame

	var harness = OffenseHarness.new()
	add_child(harness)
	var controller = OffenseController.new()
	harness.add_child(controller)
	controller._player = _ai_player

	controller._construct_structure(VehicleFactoryUnit)
	await get_tree().process_frame

	var factories = _vehicle_factories()
	var vehicle_factory = factories.front() if not factories.is_empty() else null
	_assert(vehicle_factory != null, "AI offense should construct a vehicle factory")
	_assert(
		vehicle_factory.player == _ai_player,
		"AI offense should construct the production structure for its player"
	)
	_assert(
		vehicle_factory.global_position.x > _front_command_center.global_position.x,
		(
			"AI offense should place production on the enemy-facing side of the frontline command center: "
			+ "factory={0}, front_cc={1}, enemy={2}"
		).format(
			[
				vehicle_factory.global_position,
				_front_command_center.global_position,
				_enemy_command_center.global_position,
			]
		)
	)
	_assert(
		vehicle_factory.global_position.distance_to(_enemy_command_center.global_position)
		< _front_command_center.global_position.distance_to(_enemy_command_center.global_position),
		(
			"AI offense production should be closer to the enemy approach than the frontline command center: "
			+ "factory={0}, front_cc={1}, enemy={2}"
		).format(
			[
				vehicle_factory.global_position,
				_front_command_center.global_position,
				_enemy_command_center.global_position,
			]
		)
	)
	_assert(
		vehicle_factory.global_position.distance_to(_front_command_center.global_position)
		< vehicle_factory.global_position.distance_to(_rear_command_center.global_position),
		"AI offense should prefer the frontline command center over a rear command center"
	)
	get_tree().quit()


func _vehicle_factories():
	return get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is VehicleFactory and unit.player == _ai_player
	)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
