extends "res://source/match/Match.gd"

const AutoAttacking = preload("res://source/match/units/actions/AutoAttacking.gd")
const StructureScript = preload("res://source/match/units/Structure.gd")
const SupportPowerEffects = preload("res://source/match/support-powers/SupportPowerEffects.gd")
const WorkerUnit = preload("res://source/match/units/Worker.tscn")
const WorkerScript = preload("res://source/match/units/Worker.gd")

var _result = ""

@onready var _human = $Players/Human
@onready var _ally = $Players/Ally
@onready var _enemy = $Players/Enemy
@onready var _human_tank = $Players/Human/Tank
@onready var _ally_tank = $Players/Ally/Tank
@onready var _enemy_tank = $Players/Enemy/Tank


func _ready():
	FeatureFlags.handle_match_end = true
	super()
	MatchSignals.match_finished_with_victory.connect(func(): _result = "victory")
	MatchSignals.match_finished_with_defeat.connect(func(): _result = "defeat")
	_stop_test_tanks()
	await get_tree().process_frame
	await get_tree().process_frame

	_assert_player_relations()
	_assert_visible_allies()
	_assert_unit_groups()
	_assert_combat_respects_teams()
	await _assert_support_powers_respect_teams()
	await _assert_team_victory()

	get_tree().paused = false
	get_tree().quit()


func _stop_test_tanks():
	for unit in [_human_tank, _ally_tank, _enemy_tank]:
		unit.hold_position = true
		unit.action = null


func _assert_player_relations():
	_assert(_human.is_allied_with(_ally), "players on the same team should be allies")
	_assert(_ally.is_allied_with(_human), "alliance checks should be symmetric")
	_assert(_human.is_enemy_with(_enemy), "players on different teams should be enemies")
	_assert(_enemy.is_enemy_with(_ally), "enemy should treat the allied team as hostile")


func _assert_visible_allies():
	_assert(_human in visible_players, "human should see its own units")
	_assert(_ally in visible_players, "human should share vision with allied players")
	_assert(not (_enemy in visible_players), "human should not automatically see enemy players")


func _assert_unit_groups():
	_assert(_human_tank.is_in_group("controlled_units"), "human unit should remain controlled")
	_assert(not _ally_tank.is_in_group("adversary_units"), "allied unit should not be adversary")
	_assert(_enemy_tank.is_in_group("adversary_units"), "enemy unit should be adversary")


func _assert_combat_respects_teams():
	_assert(
		not AutoAttacking.is_applicable(_human_tank, _ally_tank),
		"same-team units should not be valid attack targets"
	)
	_assert(
		AutoAttacking.is_applicable(_human_tank, _enemy_tank),
		"different-team units should remain valid attack targets"
	)


func _assert_support_powers_respect_teams():
	var ally_hp = _ally_tank.hp
	var enemy_hp = _enemy_tank.hp
	SupportPowerEffects.activate(
		self, Constants.Match.SupportPowers.ORBITAL_STRIKE, _human, _ally_tank.global_position
	)
	await get_tree().process_frame
	_assert(
		get_tree().get_nodes_in_group("support_power_warning_markers").size() > 0,
		"offensive support powers should telegraph delayed impact areas"
	)
	_assert(_ally_tank.hp == ally_hp, "offensive support powers should not damage allies")
	_assert(
		_enemy_tank.hp == enemy_hp,
		"offensive support powers should wait for the impact delay before damaging enemies"
	)
	await get_tree().create_timer(_impact_delay(Constants.Match.SupportPowers.ORBITAL_STRIKE) + 0.2).timeout
	_assert(_enemy_tank.hp < enemy_hp, "offensive support powers should still damage enemies")


func _assert_team_victory():
	MatchSignals.setup_and_spawn_unit.emit(
		WorkerUnit.instantiate(), Transform3D(Basis(), Vector3(42.0, 0.0, 10.0)), _enemy, false
	)
	await get_tree().process_frame
	_assert(
		_enemy.get_children().any(func(unit): return unit is WorkerScript),
		"test scene should keep an enemy worker anchor before elimination checks"
	)
	_queue_free_units_matching(_enemy, func(unit): return unit is StructureScript)
	await get_tree().process_frame
	_assert(_result == "", "enemy should not be eliminated while a worker anchor remains")
	_queue_free_units_matching(_enemy, func(unit): return unit is WorkerScript)
	await _wait_for_result()
	_assert(_result == "victory", "human team should win when all enemy anchors are gone")


func _queue_free_units_matching(player, predicate):
	for unit in player.get_children():
		if predicate.call(unit):
			unit.queue_free()


func _wait_for_result(max_frames = 10):
	for _i in range(max_frames):
		await get_tree().process_frame
		if _result != "":
			return


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)


func _impact_delay(power_id):
	return Constants.Match.SupportPowers.DEFINITIONS[power_id].get("impact_delay", 0.0)
