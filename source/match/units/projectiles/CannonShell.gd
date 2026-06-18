extends Node3D

const CombatVfx = preload("res://source/match/utils/CombatVfxUtils.gd")
const CombatDamage = preload("res://source/match/utils/CombatDamageUtils.gd")

var target_unit = null

@onready var _unit = get_parent()
@onready var _unit_particles = find_child("OriginParticles")
@onready var _timer = find_child("Timer")


func _ready():
	if not _has_target_unit():
		queue_free()
		return
	_unit_particles.visible = _unit.visible
	_setup_unit_particles()
	_setup_timer()
	if not _has_target_unit():
		queue_free()
		return
	CombatVfx.spawn_impact_at_unit(target_unit)
	CombatDamage.apply_projectile_damage(_unit, target_unit)


func _setup_timer():
	if _timer == null or _unit_particles == null:
		queue_free()
		return
	_timer.timeout.connect(queue_free)
	_timer.start(_unit_particles.lifetime)


func _setup_unit_particles():
	await get_tree().physics_frame  # wait for rotation to kick in if remote transform is used
	if _unit == null or not is_instance_valid(_unit) or _unit_particles == null:
		queue_free()
		return
	var a_global_transform = (
		_unit.global_transform
		if _unit.find_child("ProjectileOrigin") == null
		else _unit.find_child("ProjectileOrigin").global_transform
	)
	_unit_particles.global_transform = a_global_transform
	if _unit.splash_radius > 0.0:
		_unit_particles.scale = Vector3.ONE * max(1.0, _unit.splash_radius * 0.4)
	_unit_particles.emitting = true


func _has_target_unit():
	return target_unit != null and is_instance_valid(target_unit) and target_unit.is_inside_tree()
