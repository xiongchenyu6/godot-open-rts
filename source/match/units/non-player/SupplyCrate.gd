extends Area3D

const Unit = preload("res://source/match/units/Unit.gd")
const Structure = preload("res://source/match/units/Structure.gd")
const CombatVfx = preload("res://source/match/utils/CombatVfxUtils.gd")

const EFFECT_RESOURCES = "resources"
const EFFECT_REPAIR = "repair"
const EFFECT_VETERANCY = "veterancy"
const WEB_COLLECT_SCAN_INTERVAL_SECONDS = 0.12

@export_enum("resources", "repair", "veterancy") var effect_type = EFFECT_RESOURCES
@export var pickup_radius = 0.85
@export var resource_a_bonus = 6
@export var resource_b_bonus = 1
@export var repair_radius = 3.5
@export var repair_amount = 8.0

var radius:
	get:
		return pickup_radius
var global_position_yless:
	get:
		return global_position * Vector3(1, 0, 1)

var _collected = false
var _web_collect_scan_elapsed = 0.0

@onready var _geometry = find_child("Geometry")
@onready var _sparkling = find_child("Sparkling")


func _ready():
	set_process(true)
	set_physics_process(true)
	area_entered.connect(_on_area_entered)
	if _sparkling != null and _sparkling.has_method("enable"):
		_sparkling.enable()


func _process(delta):
	if _geometry != null:
		_geometry.rotate_y(delta * 1.35)
	if OS.has_feature("web"):
		_web_collect_scan_elapsed += delta
		if _web_collect_scan_elapsed < WEB_COLLECT_SCAN_INTERVAL_SECONDS:
			return
		_web_collect_scan_elapsed = 0.0
	_try_collect()


func _physics_process(_delta):
	if OS.has_feature("web"):
		return
	_try_collect()


func _on_area_entered(area):
	collect(area)


func _try_collect():
	if _collected:
		return
	for unit in get_tree().get_nodes_in_group("units"):
		if collect(unit):
			return


func collect(unit):
	if _collected or not _can_collect(unit):
		return false
	_collected = true
	match effect_type:
		EFFECT_REPAIR:
			_apply_repair(unit)
		EFFECT_VETERANCY:
			_apply_veterancy(unit)
		_:
			_apply_resources(unit)
	MatchSignals.supply_crate_collected.emit(self, unit, effect_type)
	CombatVfx.spawn_impact(get_parent(), global_position + Vector3(0.0, 0.35, 0.0), 0.7)
	queue_free()
	return true


func _can_collect(unit):
	if not unit is Unit or not unit.is_inside_tree():
		return false
	if unit is Structure:
		return false
	if unit.player == null:
		return false
	if "participates_in_match" in unit.player and not unit.player.participates_in_match:
		return false
	if unit.hp != null and unit.hp <= 0:
		return false
	if unit.movement_speed <= 0.0:
		return false
	var unit_radius = unit.radius if unit.radius != null else 0.0
	return global_position_yless.distance_to(unit.global_position_yless) <= pickup_radius + unit_radius


func _apply_resources(unit):
	unit.player.add_resources({
		"resource_a": resource_a_bonus,
		"resource_b": resource_b_bonus,
	})


func _apply_repair(unit):
	for target in get_tree().get_nodes_in_group("units"):
		if _can_repair(unit.player, target):
			target.hp = min(target.hp_max, target.hp + repair_amount)


func _can_repair(player, target):
	if not target is Unit or target is Structure:
		return false
	if target.player == null or not player.is_allied_with(target.player):
		return false
	if target.hp == null or target.hp_max == null or target.hp >= target.hp_max:
		return false
	var target_radius = target.radius if target.radius != null else 0.0
	return global_position_yless.distance_to(target.global_position_yless) <= repair_radius + target_radius


func _apply_veterancy(unit):
	if _try_promote(unit):
		return
	var nearby_allies = get_tree().get_nodes_in_group("units").filter(
		func(target): return (
			target is Unit
			and target.player != null
			and unit.player.is_allied_with(target.player)
			and global_position_yless.distance_to(target.global_position_yless) <= repair_radius
		)
	)
	nearby_allies.sort_custom(
		func(a, b):
			return (
				global_position_yless.distance_to(a.global_position_yless)
				< global_position_yless.distance_to(b.global_position_yless)
			)
	)
	for target in nearby_allies:
		if _try_promote(target):
			return


func _try_promote(unit):
	if not unit.has_method("grant_veterancy_rank"):
		return false
	return unit.grant_veterancy_rank(unit.veterancy_rank + 1)
