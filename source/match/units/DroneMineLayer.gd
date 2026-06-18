extends "res://source/match/units/Unit.gd"

const LandMine = preload("res://source/match/units/LandMine.gd")
const LandMineScene = preload("res://source/match/units/LandMine.tscn")

const DEPLOY_OFFSETS = [
	Vector3(-1, 0, -1),
	Vector3(1, 0, -1),
	Vector3(-1, 0, 1),
	Vector3(1, 0, 1),
	Vector3(0, 0, -1),
	Vector3(1, 0, 0),
	Vector3(0, 0, 1),
	Vector3(-1, 0, 0),
]

var mine_damage = 4.0
var mine_deploy_interval = 2.2
var mine_deploy_radius = 1.1
var mine_spacing = 1.15
var mine_limit = 4

var _deploy_cooldown = 0.0
var _deploy_index = 0


func _ready():
	await super()
	_deploy_cooldown = 0.2


func _process(delta):
	if hp == null or hp <= 0 or is_emp_disabled():
		return
	_deploy_cooldown -= delta
	if _deploy_cooldown > 0.0:
		return
	if _active_mines().size() >= mine_limit:
		return
	_deploy_cooldown = mine_deploy_interval
	_deploy_mine()


func _can_deploy_mines():
	return (
		hp != null
		and hp > 0
		and not is_emp_disabled()
		and _active_mines().size() < mine_limit
	)


func _active_mines():
	return get_tree().get_nodes_in_group("units").filter(
		func(unit):
			return unit is LandMine and unit.source_unit == self and unit.player == player
	)


func _deploy_mine():
	var deploy_position = _next_deploy_position()
	if _nearby_friendly_mine_exists(deploy_position):
		return
	var mine = LandMineScene.instantiate()
	mine.source_unit = self
	mine.mine_damage = mine_damage
	MatchSignals.setup_and_spawn_unit.emit(mine, Transform3D(Basis(), deploy_position), player)


func _next_deploy_position():
	var offset = DEPLOY_OFFSETS[_deploy_index % DEPLOY_OFFSETS.size()].normalized()
	_deploy_index += 1
	return global_position_yless + offset * mine_deploy_radius


func _nearby_friendly_mine_exists(position):
	for unit in get_tree().get_nodes_in_group("units"):
		if not unit is LandMine or unit.player != player:
			continue
		if unit.global_position_yless.distance_to(position * Vector3(1, 0, 1)) <= mine_spacing:
			return true
	return false
