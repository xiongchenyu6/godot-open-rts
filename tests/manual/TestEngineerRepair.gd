extends "res://tests/manual/Match.gd"

const Repairing = preload("res://source/match/units/actions/Repairing.gd")

@onready var _engineer_drone = $Players/Human/EngineerDrone
@onready var _tank = $Players/Human/Tank


func _ready():
	super()
	await get_tree().process_frame
	_tank.hp = max(1.0, _tank.hp_max - 4.0)
	var damaged_hp = _tank.hp
	_engineer_drone.action = Repairing.new(_tank)
	await get_tree().create_timer(1.5).timeout
	assert(_tank.hp > damaged_hp, "engineer drone should repair damaged friendly units")
	assert(_tank.hp <= _tank.hp_max, "repair should not exceed max hit points")
	get_tree().quit()
