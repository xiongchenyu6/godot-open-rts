extends "res://tests/manual/Match.gd"

const OreHarvesterUnit = preload("res://source/match/units/OreHarvester.tscn")

@onready var _ai = $Players/SimpleClairvoyantAI
@onready var _economy_controller = $Players/SimpleClairvoyantAI/EconomyController
@onready var _vehicle_factory = $Players/SimpleClairvoyantAI/VehicleFactory


func _ready():
	super()
	for _i in range(8):
		await get_tree().process_frame
	var queued_paths = _vehicle_factory.production_queue.get_elements().map(
		func(element): return element.unit_prototype.resource_path
	)
	assert(
		OreHarvesterUnit.resource_path in queued_paths,
		"AI economy should queue ore harvesters from a constructed vehicle factory"
	)
	assert(
		_ai.expected_number_of_ore_harvesters > 0,
		"AI should expose an expected ore harvester target"
	)
	_economy_controller.provision({}, "unknown_test_metadata")
	var queue_size_before_bad_provision = _vehicle_factory.production_queue.size()
	_economy_controller.provision({"resource_a": 999, "resource_b": 999}, "ore_harvester")
	assert(
		_vehicle_factory.production_queue.size() == queue_size_before_bad_provision,
		"AI economy should ignore mismatched harvester resources instead of queueing production"
	)
	assert(
		_economy_controller._number_of_pending_harvester_resource_requests >= 0,
		"AI economy mismatched resource provision should not leave negative pending harvesters"
	)
	get_tree().quit()
