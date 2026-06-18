extends "res://tests/manual/Match.gd"

const CollectingResourcesSequentially = preload(
	"res://source/match/units/actions/CollectingResourcesSequentially.gd"
)

@onready var _human = $Players/Human
@onready var _worker = $Players/Human/Worker
@onready var _harvester = $Players/Human/OreHarvester
@onready var _refinery = $Players/Human/Refinery


func _ready():
	super()
	await _wait_frames(4)
	$Players/Human/CommandCenter.global_position = Vector3(28.0, 0.0, 10.0)
	_refinery.global_position = Vector3(10.5, 0.0, 14.5)
	_worker.global_position = Vector3(12.5, 0.0, 14.8)
	_harvester.global_position = Vector3(13.5, 0.0, 15.8)
	_worker.find_child("Movement").stop()
	_harvester.find_child("Movement").stop()
	await get_tree().physics_frame

	assert(
		CollectingResourcesSequentially.is_applicable(_worker, _refinery),
		"workers should be able to target refineries as resource drop-off points"
	)
	assert(
		CollectingResourcesSequentially.is_applicable(_harvester, _refinery),
		"ore harvesters should be able to target refineries as resource drop-off points"
	)
	assert(_harvester.resources_max > _worker.resources_max, "ore harvesters should carry more")
	assert(not _harvester.can_construct_structures(), "ore harvesters should not build structures")
	var closest_dropoff = CollectingResourcesSequentially._find_dropoff_closest_to_unit(_worker)
	assert(
		closest_dropoff == _refinery,
		"workers should prefer the closest constructed resource drop-off, got {0}".format(
			[closest_dropoff.name if closest_dropoff != null else "<none>"]
		)
	)
	await _assert_resource_collection_state_transition_queue()

	var initial_resource_a = _human.resource_a
	_worker.resource_a = _worker.resources_max
	_worker.action = CollectingResourcesSequentially.new(_refinery)
	await _wait_until(func(): return _human.resource_a >= initial_resource_a + _worker.resources_max)
	assert(
		_human.resource_a >= initial_resource_a + _worker.resources_max,
		"refinery should receive carried worker resources"
	)
	initial_resource_a = _human.resource_a
	_harvester.resource_a = _harvester.resources_max
	_harvester.action = CollectingResourcesSequentially.new(_refinery)
	await _wait_until(func(): return _human.resource_a >= initial_resource_a + _harvester.resources_max)
	assert(
		_human.resource_a >= initial_resource_a + _harvester.resources_max,
		"refinery should receive carried ore harvester resources"
	)
	get_tree().quit()


func _assert_resource_collection_state_transition_queue():
	var action = CollectingResourcesSequentially.new(_refinery)
	_worker.add_child(action)
	await get_tree().process_frame
	action._state_locked = true
	action._change_state_to(CollectingResourcesSequentially.State.MOVING_TO_RESOURCE)
	assert(
		action._queued_state == CollectingResourcesSequentially.State.MOVING_TO_RESOURCE,
		"resource collection should queue state transitions requested during locked transitions"
	)
	action._state_locked = false
	action._apply_queued_state_transition()
	await get_tree().process_frame
	assert(action._queued_state == null, "queued resource collection state should be consumed")
	assert(
		action._state == CollectingResourcesSequentially.State.MOVING_TO_RESOURCE,
		"queued resource collection state should be applied after transition unlock"
	)
	assert(action._sub_action != null, "queued resource collection state should create a new sub-action")
	action.queue_free()
	await get_tree().process_frame


func _wait_until(condition, timeout_seconds = 5.0):
	var deadline = Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		if condition.call():
			return


func _wait_frames(count):
	for _i in range(count):
		await get_tree().process_frame
