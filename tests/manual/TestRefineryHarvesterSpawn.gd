extends "res://tests/manual/Match.gd"

const CollectingResourcesSequentially = preload(
	"res://source/match/units/actions/CollectingResourcesSequentially.gd"
)
const RefineryUnit = preload("res://source/match/units/Refinery.tscn")
const OreHarvester = preload("res://source/match/units/OreHarvester.gd")

@onready var _human = $Players/Human


func _ready():
	super()
	await _wait_frames(4)

	var initial_harvesters = _harvesters()
	var refinery = RefineryUnit.instantiate()
	_setup_and_spawn_unit(
		refinery,
		Transform3D(Basis(), Vector3(10.5, 0.0, 14.5)),
		_human
	)
	await get_tree().process_frame
	assert(refinery.is_under_construction(), "test refinery should start under construction")
	assert(_harvesters().size() == initial_harvesters.size(), "unfinished refinery should not spawn a harvester")

	refinery.construct(1.0)
	await _wait_until(func(): return _harvesters().size() == initial_harvesters.size() + 1)
	var harvester = _harvesters().back()
	assert(harvester.player == _human, "free ore harvester should belong to refinery owner")
	assert(not harvester.can_construct_structures(), "free ore harvester should not build structures")
	assert(
		CollectingResourcesSequentially.is_applicable(harvester, refinery),
		"free ore harvester should be able to drop resources at its refinery"
	)
	assert(
		harvester.global_position_yless.distance_to(refinery.global_position_yless)
		> refinery.radius,
		"free ore harvester should spawn outside the refinery footprint"
	)
	get_tree().quit()


func _harvesters():
	return get_tree().get_nodes_in_group("units").filter(
		func(unit): return unit is OreHarvester and unit.player == _human
	)


func _wait_until(condition, timeout_seconds = 5.0):
	var deadline = Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		if condition.call():
			return


func _wait_frames(count):
	for _i in range(count):
		await get_tree().process_frame
