extends "res://source/match/units/CombatUnit.gd"

const PASSIVE_SHIELD_DURATION_S = 3600.0
const PASSIVE_SHIELD_DAMAGE_MULTIPLIER = 0.65


func _ready():
	await super()
	apply_support_shield(PASSIVE_SHIELD_DURATION_S, PASSIVE_SHIELD_DAMAGE_MULTIPLIER)
