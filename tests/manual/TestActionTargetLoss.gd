extends "res://tests/manual/Match.gd"

const AttackingWhileInRange = preload("res://source/match/units/actions/AttackingWhileInRange.gd")
const AutoAttacking = preload("res://source/match/units/actions/AutoAttacking.gd")
const Capturing = preload("res://source/match/units/actions/Capturing.gd")
const Constructing = preload("res://source/match/units/actions/Constructing.gd")
const Following = preload("res://source/match/units/actions/Following.gd")
const FollowingToReachDistance = preload(
	"res://source/match/units/actions/FollowingToReachDistance.gd"
)
const Garrisoning = preload("res://source/match/units/actions/Garrisoning.gd")
const MovingToUnit = preload("res://source/match/units/actions/MovingToUnit.gd")
const Repairing = preload("res://source/match/units/actions/Repairing.gd")

const EngineerDroneScene = preload("res://source/match/units/EngineerDrone.tscn")
const LightRifleInfantryScene = preload("res://source/match/units/LightRifleInfantry.tscn")
const PowerReactorScene = preload("res://source/match/units/PowerReactor.tscn")
const TankScene = preload("res://source/match/units/Tank.tscn")
const TechBunkerScene = preload("res://source/match/units/TechBunker.tscn")
const WorkerScene = preload("res://source/match/units/Worker.tscn")

@onready var _human = $Players/Human
@onready var _enemy = $Players/Enemy


func _ready():
	super()
	await get_tree().process_frame

	await _assert_target_loss_cleans_action(
		"auto attack",
		await _spawn_unit(TankScene, _human, Vector3(10.0, 0.0, 10.0), "AutoAttackTank"),
		await _spawn_unit(TankScene, _enemy, Vector3(13.0, 0.0, 10.0), "AutoAttackTarget"),
		func(target): return AutoAttacking.new(target)
	)
	await _assert_target_loss_cleans_action(
		"direct attack",
		await _spawn_unit(TankScene, _human, Vector3(10.0, 0.0, 13.0), "DirectAttackTank"),
		await _spawn_unit(TankScene, _enemy, Vector3(13.0, 0.0, 13.0), "DirectAttackTarget"),
		func(target): return AttackingWhileInRange.new(target)
	)
	await _assert_target_loss_cleans_action(
		"move to unit",
		await _spawn_unit(TankScene, _human, Vector3(10.0, 0.0, 16.0), "MoveToUnitTank"),
		await _spawn_unit(TankScene, _human, Vector3(18.0, 0.0, 16.0), "MoveToUnitTarget"),
		func(target): return MovingToUnit.new(target)
	)
	await _assert_target_loss_cleans_action(
		"follow to range",
		await _spawn_unit(TankScene, _human, Vector3(10.0, 0.0, 19.0), "FollowRangeTank"),
		await _spawn_unit(TankScene, _enemy, Vector3(20.0, 0.0, 19.0), "FollowRangeTarget"),
		func(target): return FollowingToReachDistance.new(target, 5.0)
	)
	await _assert_target_loss_cleans_action(
		"follow rally unit",
		await _spawn_unit(WorkerScene, _human, Vector3(10.0, 0.0, 22.0), "FollowerWorker"),
		await _spawn_unit(WorkerScene, _human, Vector3(18.0, 0.0, 22.0), "FollowTargetWorker"),
		func(target): return Following.new(target)
	)

	var repair_target = await _spawn_unit(
		TankScene, _human, Vector3(18.0, 0.0, 25.0), "RepairTargetTank"
	)
	repair_target.hp = max(1.0, repair_target.hp_max - 5.0)
	await _assert_target_loss_cleans_action(
		"repair",
		await _spawn_unit(EngineerDroneScene, _human, Vector3(10.0, 0.0, 25.0), "RepairEngineer"),
		repair_target,
		func(target): return Repairing.new(target)
	)
	await _assert_target_loss_cleans_action(
		"capture",
		await _spawn_unit(EngineerDroneScene, _human, Vector3(10.0, 0.0, 28.0), "CaptureEngineer"),
		await _spawn_unit(PowerReactorScene, _enemy, Vector3(18.0, 0.0, 28.0), "CaptureTarget"),
		func(target): return Capturing.new(target)
	)

	var construction_target = await _spawn_unit(
		PowerReactorScene, _human, Vector3(18.0, 0.0, 31.0), "ConstructionTarget"
	)
	construction_target.mark_as_under_construction()
	await _assert_target_loss_cleans_action(
		"construct",
		await _spawn_unit(WorkerScene, _human, Vector3(10.0, 0.0, 31.0), "ConstructionWorker"),
		construction_target,
		func(target): return Constructing.new(target)
	)
	await _assert_target_loss_cleans_action(
		"garrison",
		await _spawn_unit(
			LightRifleInfantryScene, _human, Vector3(10.0, 0.0, 34.0), "GarrisonRifle"
		),
		await _spawn_unit(TechBunkerScene, _human, Vector3(18.0, 0.0, 34.0), "GarrisonBunker"),
		func(target): return Garrisoning.new(target)
	)

	get_tree().quit()


func _spawn_unit(scene, player, position, unit_name):
	var unit = scene.instantiate()
	unit.name = unit_name
	_setup_unit_groups(unit, player)
	player.add_child(unit)
	unit.global_position = position
	if not unit.is_node_ready():
		await unit.ready
	_disable_autonomous_combat(unit)
	return unit


func _disable_autonomous_combat(unit):
	if "hold_position" in unit:
		unit.hold_position = true
	if "attack_domains" in unit:
		unit.attack_domains = []
	if unit.has_method("clear_action_queue"):
		unit.clear_action_queue()


func _assert_target_loss_cleans_action(label, actor, target, action_factory):
	_disable_autonomous_combat(actor)
	_disable_autonomous_combat(target)
	var action = action_factory.call(target)
	actor.action = action
	await get_tree().process_frame
	target.queue_free()
	for _frame in range(10):
		await get_tree().process_frame
	if is_instance_valid(action) and action.is_inside_tree():
		push_error("{0} action should leave the tree after its target is removed".format([label]))
		get_tree().quit(1)
