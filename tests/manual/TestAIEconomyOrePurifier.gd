extends "res://tests/manual/Match.gd"

const EconomyController = preload(
	"res://source/match/players/simple-clairvoyant-ai/EconomyController.gd"
)
const OrePurifier = preload("res://source/match/units/OrePurifier.gd")
const OrePurifierUnit = preload("res://source/match/units/OrePurifier.tscn")

class EconomyHarness:
	extends Node

	var expected_number_of_ccs = 0
	var expected_number_of_refineries = 0
	var expected_number_of_workers = 0
	var expected_number_of_ore_harvesters = 0

@onready var _human = $Players/Human


func _ready():
	super()
	for _i in range(4):
		await get_tree().process_frame
	var harness = EconomyHarness.new()
	add_child(harness)
	var controller = EconomyController.new()
	harness.add_child(controller)
	_assert(
		controller._structure_placement_transform(Vector3.INF, Vector3(1, 0, 1)) == null,
		"AI economy placement should skip structure spawning when no valid position exists"
	)
	_assert(
		controller._structure_placement_transform(Vector3(4, 0, 4), Vector3.ZERO) != null,
		"AI economy placement should tolerate a zero facing direction"
	)
	var requests = []
	controller.resources_required.connect(
		func(resources, metadata): requests.append({"resources": resources, "metadata": metadata})
	)
	controller.setup(_human)

	_assert(
		requests.size() == 1,
		"AI economy should request exactly one ore purifier when tech lab and refinery exist"
	)
	_assert(
		requests[0]["metadata"] == "ore_purifier",
		"AI economy should tag the late economy request as ore_purifier"
	)
	_assert(
		requests[0]["resources"] == Constants.Match.Units.CONSTRUCTION_COSTS[
			OrePurifierUnit.resource_path
		],
		"AI economy should request the configured ore purifier construction cost"
	)
	_assert(
		_ore_purifiers().is_empty(),
		"AI economy request test should not spawn structures through the full construction loop"
	)
	get_tree().quit()


func _ore_purifiers():
	return get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is OrePurifier and unit.player == _human
	)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
