extends "res://tests/manual/Match.gd"

const MobileShieldProjectorUnit = preload("res://source/match/units/MobileShieldProjector.tscn")

@onready var _human = $Players/Human
@onready var _friendly_tank = $Players/Human/Tank
@onready var _enemy_tank = $Players/Enemy/Tank


func _ready():
	super()
	await get_tree().process_frame
	await get_tree().physics_frame

	_assert(
		Utils.Match.Unit.Tech.can_produce(_human, MobileShieldProjectorUnit.resource_path),
		"robotics bay should unlock mobile shield projector production"
	)
	_assert(
		Constants.Match.Units.DEFAULT_PROPERTIES[MobileShieldProjectorUnit.resource_path]
		["support_shield_radius"]
		> 0.0,
		"mobile shield projector should define a shield radius"
	)
	_assert(
		Constants.Match.Units.DEFAULT_PROPERTIES[MobileShieldProjectorUnit.resource_path]
		["support_shield_damage_multiplier"]
		< 1.0,
		"mobile shield projector should reduce incoming damage"
	)

	var projector = MobileShieldProjectorUnit.instantiate()
	_setup_and_spawn_unit(
		projector,
		Transform3D(Basis(), _friendly_tank.global_position + Vector3(0.8, 0.0, 0.0)),
		_human,
		false
	)
	await get_tree().create_timer(0.25).timeout

	_assert(_friendly_tank.support_shielded, "projector should shield nearby friendly units")
	_assert(not _enemy_tank.support_shielded, "projector should not shield enemy units")

	var incoming_damage = 4.0
	var friendly_hp_before = _friendly_tank.hp
	var enemy_hp_before = _enemy_tank.hp
	_friendly_tank.hp -= incoming_damage
	_enemy_tank.hp -= incoming_damage
	_assert(
		_friendly_tank.hp > friendly_hp_before - incoming_damage,
		"shielded friendly unit should take reduced damage"
	)
	_assert(
		is_equal_approx(_enemy_tank.hp, enemy_hp_before - incoming_damage),
		"enemy unit inside the aura should take full damage"
	)

	projector.disable_by_emp(0.6)
	await get_tree().create_timer(0.05).timeout
	var shielded_until = _friendly_tank._support_shield_until
	await get_tree().create_timer(0.25).timeout
	_assert(
		is_equal_approx(_friendly_tank._support_shield_until, shielded_until),
		"EMP-disabled projector should stop refreshing shields"
	)
	get_tree().quit()


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
