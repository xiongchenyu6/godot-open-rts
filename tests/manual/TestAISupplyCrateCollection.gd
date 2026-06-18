extends "res://tests/manual/Match.gd"

const MovingToUnit = preload("res://source/match/units/actions/MovingToUnit.gd")
const TankScene = preload("res://source/match/units/Tank.tscn")

var _crate_collected = false
var _resource_crate_collected = false
var _collector = null
var _effect_type = ""
var _collector_unit = null

@onready var _ai = $Players/SimpleClairvoyantAI
@onready var _controller = $Players/SimpleClairvoyantAI/SupplyCrateCollectionController
@onready var _resource_crate = $SupplyCrates/ResourceCrate


func _ready():
	super()
	MatchSignals.supply_crate_collected.connect(_on_supply_crate_collected)
	await get_tree().process_frame
	_spawn_collector_unit()
	await get_tree().process_frame
	await get_tree().process_frame

	var resource_a_before = _ai.resource_a
	var resource_b_before = _ai.resource_b
	var resource_a_bonus = _resource_crate.resource_a_bonus
	var resource_b_bonus = _resource_crate.resource_b_bonus
	var assigned = await _wait_for_collection_assignment()
	if not assigned:
		return

	_collector_unit.global_position = _resource_crate.global_position + Vector3(0.15, 0.0, 0.0)
	var collected = await _wait_for_crate_collection()
	if not collected:
		return

	assert(_resource_crate_collected, "AI should collect the resource crate")
	assert(_collector == _collector_unit, "AI collector unit should be assigned to collect the crate")
	assert(_effect_type == "resources", "AI should collect the resource crate effect")
	assert(
		_ai.resource_a == resource_a_before + resource_a_bonus,
		"resource crate should add blue crystal to the AI player"
	)
	assert(
		_ai.resource_b == resource_b_before + resource_b_bonus,
		"resource crate should add red crystal to the AI player"
	)

	get_tree().quit()


func _wait_for_collection_assignment():
	for _step in range(40):
		if _controller.is_collecting(_collector_unit, _resource_crate):
			assert(_collector_unit.action is MovingToUnit, "collector should move to assigned crate")
			assert(
				_collector_unit.action._target_unit == _resource_crate,
				"AI collector unit should target the available supply crate first"
			)
			return true
		if _collector_unit.action is MovingToUnit:
			assert(
				_collector_unit.action._target_unit == _resource_crate,
				"AI collector unit should target the available supply crate first"
			)
		await get_tree().create_timer(0.2).timeout
	var action_description = str(_collector_unit.action)
	var action_target = _collector_unit.action._target_unit if _collector_unit.action is MovingToUnit else null
	push_error(
		(
			"AI collector unit was not assigned to the available supply crate: "
			+ "action={0}, target={1}, collector_position={2}, crate_position={3}, distance={4}, crate_count={5}, assignment_count={6}"
		).format(
			[
				action_description,
				action_target,
				_collector_unit.global_position_yless,
				_resource_crate.global_position_yless,
				_collector_unit.global_position_yless.distance_to(
					_resource_crate.global_position_yless
				),
				get_tree().get_nodes_in_group("supply_crates").size(),
				_controller.get_active_assignment_count(),
			]
		)
	)
	get_tree().quit(1)
	return false


func _wait_for_crate_collection():
	for _step in range(12):
		if _crate_collected:
			return true
		await get_tree().process_frame
	var distance = INF
	if is_instance_valid(_resource_crate):
		distance = _collector_unit.global_position_yless.distance_to(_resource_crate.global_position_yless)
	push_error(
		"AI collector unit reached the assigned supply crate but collection did not fire: distance={0}".format(
			[distance]
		)
	)
	get_tree().quit(1)
	return false


func _on_supply_crate_collected(crate, unit, effect_type):
	_crate_collected = true
	_resource_crate_collected = crate == _resource_crate
	_collector = unit
	_effect_type = effect_type


func _spawn_collector_unit():
	_collector_unit = TankScene.instantiate()
	var spawn_transform = Transform3D.IDENTITY.translated(Vector3(20.0, 0.0, 20.0))
	MatchSignals.setup_and_spawn_unit.emit(_collector_unit, spawn_transform, _ai)
