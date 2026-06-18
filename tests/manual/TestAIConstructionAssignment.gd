extends "res://tests/manual/Match.gd"

const ConstructionWorksController = preload(
	"res://source/match/players/simple-clairvoyant-ai/ConstructionWorksController.gd"
)
const Constructing = preload("res://source/match/units/actions/Constructing.gd")

@onready var _ai_player = $Players/AI
@onready var _near_worker = $Players/AI/NearWorker
@onready var _far_worker = $Players/AI/FarWorker
@onready var _near_reactor = $Players/AI/NearPowerReactor
@onready var _far_reactor = $Players/AI/FarPowerReactor


func _ready():
	super()
	for _i in range(4):
		await get_tree().process_frame
		await get_tree().physics_frame
	_near_worker.global_position = Vector3(12.0, 0.0, 10.0)
	_far_worker.global_position = Vector3(38.0, 0.0, 10.0)
	_near_reactor.global_position = Vector3(14.5, 0.0, 10.0)
	_far_reactor.global_position = Vector3(40.5, 0.0, 10.0)
	_near_reactor.mark_as_under_construction()
	_far_reactor.mark_as_under_construction()
	await get_tree().process_frame
	await get_tree().physics_frame

	var controller = ConstructionWorksController.new()
	add_child(controller)
	controller._player = _ai_player
	controller._on_refresh_timer_timeout()
	await get_tree().process_frame

	_assert(_near_worker.action != null, "nearest worker should receive a construction order")
	_assert(_near_worker.action is Constructing, "nearest worker should be constructing")
	_assert(
		_near_worker.action._target_unit == _near_reactor,
		"nearest worker should be assigned to the nearest unfinished structure"
	)
	_assert(
		_far_worker.action == null,
		"far worker should stay idle when a nearer worker can handle the current construction task"
	)
	get_tree().quit()


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
