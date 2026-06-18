extends "res://tests/manual/Match.gd"

const Moving = preload("res://source/match/units/actions/Moving.gd")
const TankUnit = preload("res://source/match/units/Tank.tscn")
const ScoutRoverUnit = preload("res://source/match/units/ScoutRover.tscn")
const LightRifleInfantryUnit = preload("res://source/match/units/LightRifleInfantry.tscn")
const RocketInfantryUnit = preload("res://source/match/units/RocketInfantry.tscn")
const DroneUnit = preload("res://source/match/units/Drone.tscn")

const CRUSH_TIMEOUT_S = 6.0
const PASS_THROUGH_TIMEOUT_S = 5.0

@onready var _human = $Players/Human
@onready var _enemy = $Players/Enemy


func _ready():
	super()
	await get_tree().process_frame
	await get_tree().process_frame

	_assert_crush_data()
	await _test_heavy_vehicle_crushes_enemy_infantry()
	await _test_light_vehicle_does_not_crush_infantry()
	await _test_crushing_respects_allies_and_air_units()
	get_tree().quit()


func _assert_crush_data():
	_assert(
		Constants.Match.Units.CRUSHER_UNIT_PATHS.has(TankUnit.resource_path),
		"tank should be configured as a crusher"
	)
	_assert(
		not Constants.Match.Units.CRUSHER_UNIT_PATHS.has(ScoutRoverUnit.resource_path),
		"scout rover should stay a light vehicle, not a crusher"
	)
	_assert(
		Constants.Match.Units.CRUSHABLE_UNIT_PATHS.has(LightRifleInfantryUnit.resource_path),
		"rifle infantry should be crushable"
	)
	_assert(
		not Constants.Match.Units.CRUSHABLE_UNIT_PATHS.has(DroneUnit.resource_path),
		"air units should not be crushable"
	)


func _test_heavy_vehicle_crushes_enemy_infantry():
	var crusher = await _spawn_unit(TankUnit, _human, Vector3(10.0, 0.0, 10.0))
	var infantry = await _spawn_unit(LightRifleInfantryUnit, _enemy, Vector3(13.0, 0.0, 10.0))

	_assert(crusher.can_crush_units(), "tank should report crush capability")
	_assert(infantry.can_be_crushed_by(crusher), "enemy infantry should accept tank crushing")

	crusher.action = Moving.new(Vector3(17.0, 0.0, 10.0))
	await _wait_until(
		func(): return not _is_alive(infantry),
		CRUSH_TIMEOUT_S,
		"moving tank should crush enemy infantry on contact"
	)
	_assert(crusher.experience_points == 1, "crush kills should grant veterancy credit")


func _test_light_vehicle_does_not_crush_infantry():
	var scout = await _spawn_unit(ScoutRoverUnit, _human, Vector3(10.0, 0.0, 20.0))
	var infantry = await _spawn_unit(RocketInfantryUnit, _enemy, Vector3(13.0, 0.0, 20.0))
	var infantry_hp = infantry.hp

	_assert(not scout.can_crush_units(), "scout rover should not report crush capability")
	_assert(not infantry.can_be_crushed_by(scout), "infantry should reject light vehicle crushing")

	scout.action = Moving.new(Vector3(17.0, 0.0, 20.0))
	await _wait_until(
		func(): return scout.global_position.x > 14.0,
		PASS_THROUGH_TIMEOUT_S,
		"scout rover should move past nearby infantry for the non-crush check"
	)
	_assert(_is_alive(infantry), "scout rover should not crush enemy infantry")
	_assert(infantry.hp == infantry_hp, "non-crushing light vehicles should not damage infantry")


func _test_crushing_respects_allies_and_air_units():
	var crusher = await _spawn_unit(TankUnit, _human, Vector3(10.0, 0.0, 30.0))
	var allied_infantry = await _spawn_unit(LightRifleInfantryUnit, _human, Vector3(13.0, 0.0, 30.0))
	var enemy_drone = await _spawn_unit(DroneUnit, _enemy, Vector3(14.0, 0.0, 30.0))
	var allied_hp = allied_infantry.hp
	var drone_hp = enemy_drone.hp

	_assert(not allied_infantry.can_be_crushed_by(crusher), "allied infantry should reject crushing")
	_assert(not enemy_drone.can_be_crushed_by(crusher), "air units should reject crushing")

	crusher.action = Moving.new(Vector3(18.0, 0.0, 30.0))
	await _wait_until(
		func(): return crusher.global_position.x > 14.5,
		PASS_THROUGH_TIMEOUT_S,
		"tank should move through the ally and air-unit safety check"
	)
	_assert(_is_alive(allied_infantry), "heavy vehicles should not crush allied infantry")
	_assert(allied_infantry.hp == allied_hp, "allied infantry should not take crush damage")
	_assert(_is_alive(enemy_drone), "heavy vehicles should not crush air units")
	_assert(enemy_drone.hp == drone_hp, "air units should not take crush damage")


func _spawn_unit(unit_scene, player, position):
	var unit = unit_scene.instantiate()
	MatchSignals.setup_and_spawn_unit.emit(unit, Transform3D(Basis(), position), player)
	await get_tree().process_frame
	_disable_unit_autonomy(unit)
	return unit


func _disable_unit_autonomy(unit):
	if "attack_domains" in unit:
		unit.attack_domains = []
	var movement = unit.find_child("Movement")
	if movement != null:
		movement.stop()


func _is_alive(unit):
	return unit != null and is_instance_valid(unit) and unit.is_inside_tree() and unit.hp > 0


func _wait_until(condition, timeout_s, message):
	var started_at_msec = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at_msec < timeout_s * 1000.0:
		if condition.call():
			return
		await get_tree().process_frame
	_assert(false, message)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
