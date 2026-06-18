extends "res://tests/manual/Match.gd"

const SaboteurInfiltrator = preload("res://source/match/units/SaboteurInfiltrator.gd")
const BarracksUnit = preload("res://source/match/units/Barracks.tscn")

var _captured_unit = null
var _previous_owner = null
var _new_owner = null

@onready var _human = $Players/Human
@onready var _ai = $Players/SimpleClairvoyantAI
@onready var _controller = $Players/SimpleClairvoyantAI/SaboteurInfiltrationController
@onready var _target_barracks = $Players/Human/Barracks


func _ready():
	super()
	MatchSignals.unit_captured.connect(_on_unit_captured)
	var pending_saboteurs_before_unknown_metadata = _controller.get_pending_saboteur_count()
	_controller.provision({}, "unknown_test_metadata")
	assert(
		_controller.get_pending_saboteur_count() == pending_saboteurs_before_unknown_metadata,
		"unknown saboteur metadata should not change pending saboteur pressure"
	)
	var captured = await _wait_for_ai_infiltration()
	if not captured:
		return

	assert(_captured_unit == _target_barracks, "AI saboteur should infiltrate the enemy barracks")
	assert(_previous_owner == _human, "AI infiltration should report the previous owner")
	assert(_new_owner == _ai, "AI infiltration should report the new owner")
	assert(
		_target_barracks.get_parent() == _ai,
		"infiltrated barracks should be reparented to the AI"
	)
	assert(
		_ai.get_production_veterancy_rank(BarracksUnit.resource_path)
		== Constants.Match.Capture.SABOTEUR_PRODUCTION_VETERANCY_RANK,
		"AI infiltration should unlock veteran infantry production"
	)
	assert(
		_controller.get_pending_saboteur_count() == 0,
		"AI should clear pending saboteur state after the infiltration resolves"
	)
	_controller.provision({"resource_a": 999, "resource_b": 999}, "saboteur_infiltration")
	assert(
		_controller.get_pending_saboteur_count() == 0,
		"AI saboteur should ignore mismatched resources without recreating pending pressure"
	)
	get_tree().quit()


func _wait_for_ai_infiltration():
	var saw_saboteur_activity = false
	for _step in range(90):
		if _captured_unit != null:
			return true
		var barracks = $Players/SimpleClairvoyantAI/Barracks
		var produced_saboteurs = get_tree().get_nodes_in_group("units").filter(
			func(unit): return unit is SaboteurInfiltrator
		)
		saw_saboteur_activity = (
			saw_saboteur_activity
			or barracks.production_queue.size() > 0
			or not produced_saboteurs.is_empty()
		)
		await get_tree().create_timer(0.25).timeout
	if not saw_saboteur_activity:
		push_error("AI saboteur raid did not queue or spawn a saboteur")
	else:
		push_error("AI saboteur raid queued or spawned a saboteur but did not infiltrate")
	get_tree().quit(1)
	return false


func _on_unit_captured(unit, previous_player, new_player):
	if new_player != _ai:
		return
	_captured_unit = unit
	_previous_owner = previous_player
	_new_owner = new_player
