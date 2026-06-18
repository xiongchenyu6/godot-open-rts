extends "res://tests/manual/Match.gd"

const CannonShell = preload("res://source/match/units/projectiles/CannonShell.tscn")
const Rocket = preload("res://source/match/units/projectiles/Rocket.tscn")

@onready var _artillery = $Players/Human/SiegeArtilleryVehicle
@onready var _friendly_target = $Players/Human/FriendlyTarget
@onready var _primary_target = $Players/Player/PrimaryTarget
@onready var _nearby_target = $Players/Player/NearbyTarget
@onready var _far_target = $Players/Player/FarTarget


func _ready():
	super()
	await get_tree().process_frame
	_disable_test_auto_fire()
	await get_tree().process_frame

	assert(_artillery.splash_radius > 0.0, "siege artillery should have splash damage")
	var primary_hp = _primary_target.hp
	var nearby_hp = _nearby_target.hp
	var far_hp = _far_target.hp
	var friendly_hp = _friendly_target.hp

	var projectile = CannonShell.instantiate()
	projectile.target_unit = _primary_target
	_artillery.add_child(projectile)
	await get_tree().process_frame

	assert(
		is_equal_approx(_primary_target.hp, primary_hp - _artillery.attack_damage),
		"primary target should take full direct damage"
	)
	assert(
		is_equal_approx(
			_nearby_target.hp,
			nearby_hp - _artillery.attack_damage * _artillery.splash_damage_multiplier
		),
		"nearby enemy should take splash damage"
	)
	assert(_far_target.hp == far_hp, "enemy outside splash radius should not be damaged")
	assert(_friendly_target.hp == friendly_hp, "friendly units should not take splash damage")
	await _assert_projectile_without_target_is_discarded(CannonShell, "cannon shell")
	await _assert_projectile_without_target_is_discarded(Rocket, "rocket")
	await _assert_rocket_discards_when_target_exits()
	get_tree().quit()


func _disable_test_auto_fire():
	for unit in [_artillery, _friendly_target, _primary_target, _nearby_target, _far_target]:
		unit.attack_range = 0.0
		unit.set_meta("next_attack_availability_time", Time.get_ticks_msec() + 600000)
		unit.action = null


func _assert_projectile_without_target_is_discarded(projectile_scene, label):
	var hp_snapshot = _target_hp_snapshot()
	var projectile = projectile_scene.instantiate()
	_artillery.add_child(projectile)
	await get_tree().process_frame
	await get_tree().physics_frame
	_assert_projectile_discarded(projectile, "{0} without a target should be discarded".format([label]))
	_assert_target_hp_snapshot(
		hp_snapshot,
		"{0} without a target should not damage any units".format([label])
	)


func _assert_rocket_discards_when_target_exits():
	var hp_snapshot = _target_hp_snapshot()
	var projectile = Rocket.instantiate()
	projectile.target_unit = _primary_target
	_artillery.add_child(projectile)
	await get_tree().process_frame
	_primary_target.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	_assert_projectile_discarded(projectile, "rocket should be discarded when its target exits")
	_assert_remaining_target_hp_snapshot(
		hp_snapshot,
		"rocket with a removed target should not damage remaining units"
	)


func _assert_projectile_discarded(projectile, message):
	if is_instance_valid(projectile):
		assert(
			projectile.is_queued_for_deletion() or not projectile.is_inside_tree(),
			message
		)


func _target_hp_snapshot():
	return {
		"primary": _primary_target.hp,
		"nearby": _nearby_target.hp,
		"far": _far_target.hp,
		"friendly": _friendly_target.hp,
	}


func _assert_target_hp_snapshot(snapshot, message):
	assert(_primary_target.hp == snapshot["primary"], message)
	_assert_remaining_target_hp_snapshot(snapshot, message)


func _assert_remaining_target_hp_snapshot(snapshot, message):
	assert(_nearby_target.hp == snapshot["nearby"], message)
	assert(_far_target.hp == snapshot["far"], message)
	assert(_friendly_target.hp == snapshot["friendly"], message)
