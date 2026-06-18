extends "res://tests/manual/Match.gd"

const TankUnit = preload("res://source/match/units/Tank.tscn")

@onready var _attacker = $Players/Human/Tank
@onready var _enemy = $Players/Player


func _ready():
	super()
	await get_tree().process_frame

	var base_hp_max = _attacker.hp_max
	var base_attack_damage = _attacker.attack_damage
	var base_attack_range = _attacker.attack_range
	var base_sight_range = _attacker.sight_range
	var rank_badge = _attacker.find_child("RankBadge", true, false)
	assert(rank_badge != null, "health bar should expose a rank badge for veteran units")
	assert(not rank_badge.visible, "green units should not show a rank badge")
	var promoted_ranks = []
	var record_promotion = func(unit, rank):
		if unit == _attacker:
			promoted_ranks.append(rank)
	MatchSignals.unit_promoted.connect(record_promotion)

	_kill_target($Players/Player/Tank)
	await get_tree().process_frame
	assert(_attacker.experience_points == 1, "first kill should grant one experience point")
	assert(_attacker.veterancy_rank == 0, "one kill should not promote the unit")

	_kill_target(_spawn_enemy_target(1))
	await get_tree().process_frame
	assert(_attacker.experience_points == 2, "second kill should grant two experience points")
	assert(_attacker.veterancy_rank == 1, "two kills should promote the unit to veteran")
	assert(promoted_ranks == [1], "veteran promotion should emit a global notification signal")
	assert(rank_badge.visible and rank_badge.text == "V", "veteran units should show a V badge")
	assert(
		_promotion_effect_count() > 0,
		"veteran promotion should create a battlefield promotion effect"
	)
	_assert_veterancy_properties(
		base_hp_max,
		base_attack_damage,
		base_attack_range,
		base_sight_range,
		1
	)
	_attacker.hp = _attacker.hp_max - 2.0
	var veteran_damaged_hp = _attacker.hp
	await get_tree().create_timer(Constants.Match.Veterancy.ELITE_REGEN_TICK_SECONDS + 0.25).timeout
	assert(_attacker.hp == veteran_damaged_hp, "veteran units should not self-repair")
	_attacker.hp = _attacker.hp_max

	for kill_index in range(2, 5):
		_kill_target(_spawn_enemy_target(kill_index))
		await get_tree().process_frame

	assert(_attacker.experience_points == 5, "five kills should grant five experience points")
	assert(_attacker.veterancy_rank == 2, "five kills should promote the unit to elite")
	assert(promoted_ranks == [1, 2], "elite promotion should emit a global notification signal")
	assert(rank_badge.visible and rank_badge.text == "E", "elite units should show an E badge")
	assert(
		_promotion_effect_count() > 0,
		"elite promotion should create a battlefield promotion effect"
	)
	_assert_veterancy_properties(
		base_hp_max,
		base_attack_damage,
		base_attack_range,
		base_sight_range,
		2
	)
	_attacker.hp = _attacker.hp_max - 2.0
	var elite_damaged_hp = _attacker.hp
	await get_tree().create_timer(Constants.Match.Veterancy.ELITE_REGEN_TICK_SECONDS + 0.25).timeout
	assert(_attacker.hp > elite_damaged_hp, "elite units should self-repair over time")
	assert(_attacker.hp <= _attacker.hp_max, "elite self-repair should not exceed max hit points")
	await get_tree().create_timer(1.2).timeout
	assert(_promotion_effect_count() == 0, "promotion effects should clean up after their lifetime")
	MatchSignals.unit_promoted.disconnect(record_promotion)
	get_tree().quit()


func _spawn_enemy_target(index):
	var target = TankUnit.instantiate()
	MatchSignals.setup_and_spawn_unit.emit(
		target,
		Transform3D(Basis(), Vector3(18.0 + index * 2.0, 0.0, 10.0)),
		_enemy,
		false
	)
	return target


func _kill_target(target):
	target.register_damage_source(_attacker)
	target.hp = 0


func _assert_veterancy_properties(
	base_hp_max,
	base_attack_damage,
	base_attack_range,
	base_sight_range,
	rank
):
	assert(
		_attacker.hp_max
		== int(ceil(base_hp_max * Constants.Match.Veterancy.HP_MULTIPLIER_BY_RANK[rank])),
		"veterancy should increase maximum hitpoints"
	)
	assert(_attacker.hp == _attacker.hp_max, "promoted full-health units should stay full")
	_assert_approx(
		_attacker.attack_damage,
		base_attack_damage * Constants.Match.Veterancy.DAMAGE_MULTIPLIER_BY_RANK[rank],
		"veterancy should increase attack damage"
	)
	_assert_approx(
		_attacker.attack_range,
		base_attack_range + Constants.Match.Veterancy.RANGE_BONUS_BY_RANK[rank],
		"veterancy should increase attack range"
	)
	_assert_approx(
		_attacker.sight_range,
		base_sight_range + Constants.Match.Veterancy.SIGHT_BONUS_BY_RANK[rank],
		"veterancy should increase sight range"
	)


func _assert_approx(actual, expected, message):
	assert(is_equal_approx(actual, expected), "%s: expected %s, got %s" % [message, expected, actual])


func _promotion_effect_count():
	return get_tree().get_nodes_in_group("veterancy_promotion_effects").size()
