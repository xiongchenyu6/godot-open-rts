extends "res://tests/manual/Match.gd"

const Capturing = preload("res://source/match/units/actions/Capturing.gd")
const LightRifleInfantryScript = preload("res://source/match/units/LightRifleInfantry.gd")
const LightRifleInfantryUnit = preload("res://source/match/units/LightRifleInfantry.tscn")

@onready var _human = $Players/Human
@onready var _enemy = $Players/Enemy
@onready var _saboteur = $Players/Human/SaboteurInfiltrator
@onready var _enemy_barracks = $Players/Enemy/Barracks


func _ready():
	super()
	for _i in range(4):
		await get_tree().process_frame

	var barracks_path = _enemy_barracks.get_script().resource_path.replace(".gd", ".tscn")
	_assert(
		_human.get_production_veterancy_rank(barracks_path) == 0,
		"player should not start with infiltrated barracks production veterancy"
	)
	_assert(
		Capturing.is_applicable(_saboteur, _enemy_barracks),
		"saboteur infiltrator should be able to infiltrate enemy barracks"
	)
	_assert(
		_saboteur.infiltration_production_veterancy_rank
		== Constants.Match.Capture.SABOTEUR_PRODUCTION_VETERANCY_RANK,
		"saboteur should expose configured production veterancy rank"
	)

	_saboteur.action = Capturing.new(_enemy_barracks)
	if not await _wait_until(
		func(): return is_instance_valid(_enemy_barracks) and _enemy_barracks.player == _human,
		8.0,
		"saboteur should finish infiltrating the enemy barracks"
	):
		return

	_assert(
		$Players/Human.get_node_or_null("Barracks") == _enemy_barracks,
		"captured barracks should join human"
	)
	_assert(_enemy.get_node_or_null("Barracks") == null, "captured barracks should leave enemy")
	_assert(
		_human.get_production_veterancy_rank(barracks_path)
		== Constants.Match.Capture.SABOTEUR_PRODUCTION_VETERANCY_RANK,
		"infiltrated barracks should unlock veteran infantry production"
	)
	_assert(
		not is_instance_valid(_saboteur),
		"saboteur infiltrator should be consumed after successful barracks infiltration"
	)

	var produced_before = _produced_riflemen()
	var element = _enemy_barracks.production_queue.produce(LightRifleInfantryUnit)
	_assert(element != null, "captured barracks should queue rifle infantry")
	await get_tree().create_timer(element.time_total + 0.8).timeout

	var produced_after = _produced_riflemen()
	_assert(
		produced_after.size() == produced_before.size() + 1,
		"captured barracks should finish one rifle infantry"
	)
	var produced_rifle = produced_after.back()
	_assert(
		produced_rifle.veterancy_rank
		== Constants.Match.Capture.SABOTEUR_PRODUCTION_VETERANCY_RANK,
		"infiltrated barracks should produce veteran infantry"
	)
	_assert(produced_rifle.hp_max > 0 and produced_rifle.hp == produced_rifle.hp_max, "veteran infantry should spawn alive")
	get_tree().quit()


func _produced_riflemen():
	return _human.get_children().filter(func(child): return child is LightRifleInfantryScript)


func _assert(condition, message):
	if condition:
		return true
	push_error(message)
	get_tree().quit(1)
	return false


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
