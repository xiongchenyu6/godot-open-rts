extends "res://tests/manual/Match.gd"

@onready var _ai = $Players/SimpleClairvoyantAI
@onready var _engineer_drone = $Players/SimpleClairvoyantAI/EngineerDrone
@onready var _rifle_infantry = $Players/SimpleClairvoyantAI/LightRifleInfantry
@onready var _rocket_infantry = $Players/SimpleClairvoyantAI/RocketInfantry
@onready var _bunker = $Players/NeutralTech/TechBunker


func _ready():
	super()
	await get_tree().process_frame

	_make_passive(_rifle_infantry)
	_make_passive(_rocket_infantry)

	assert(
		$Players/SimpleClairvoyantAI/TechBunkerGarrisonController != null,
		"AI should include the tech bunker garrison controller"
	)
	assert(_bunker.player != _ai, "test bunker should start neutral")
	assert(_bunker.get_garrison_count() == 0, "neutral bunker should start empty")

	if not await _wait_until(
		func(): return is_instance_valid(_bunker) and _bunker.player == _ai,
		8.0,
		"AI engineer should capture the neutral tech bunker"
	):
		return
	assert(
		not is_instance_valid(_engineer_drone),
		"engineer should be consumed after capturing the tech bunker"
	)
	assert(
		$Players/SimpleClairvoyantAI/TechBunker == _bunker,
		"captured tech bunker should be reparented to the AI"
	)

	if not await _wait_until(
		func():
			return (
				_bunker.get_garrison_count() == 2
				and not is_instance_valid(_rifle_infantry)
				and not is_instance_valid(_rocket_infantry)
			),
		6.0,
		"AI should garrison nearby idle infantry into its captured tech bunker"
	):
		return
	assert(
		is_equal_approx(_bunker.attack_damage, _bunker.garrison_attack_damage_per_unit * 2.0),
		"AI-garrisoned bunker damage should scale with garrison count"
	)

	get_tree().quit()


func _make_passive(unit):
	unit.hold_position = true
	unit.attack_domains = []
	unit.clear_action_queue()
	unit.action = null
	var movement = unit.find_child("Movement")
	if movement != null:
		movement.stop()


func _wait_until(condition, timeout_s, message):
	var deadline = Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if condition.call():
			return true
		await get_tree().process_frame
	if not condition.call():
		push_error(message)
		get_tree().quit(1)
		return false
	return true
