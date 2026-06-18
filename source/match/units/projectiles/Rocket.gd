extends Node3D

const CombatVfx = preload("res://source/match/utils/CombatVfxUtils.gd")
const CombatDamage = preload("res://source/match/utils/CombatDamageUtils.gd")

var target_unit = null

@onready var _unit = get_parent()
@onready var _visuals = find_child("Visuals")
@onready var _path = find_child("Path3D")
@onready var _animation_player = find_child("AnimationPlayer")
@onready var _rocket = find_child("MeshInstance3D")
@onready var _particles = find_child("GPUParticles3D")


func _ready():
	if not _has_target_unit():
		queue_free()
		return
	_visuals.visible = _unit.visible
	_rocket.hide()
	_particles.hide()
	target_unit.tree_exited.connect(queue_free)
	_animation_player.animation_finished.connect(func(_animation): queue_free())
	if not _setup_path():
		queue_free()
		return
	# wait 2 frames for path curve setup so that path follow has correct transform
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not _has_target_unit():
		queue_free()
		return
	_animation_player.play("animate")


func _physics_process(_delta):
	if not _has_target_unit():
		queue_free()
		return
	_path.curve.set_point_position(1, target_unit.global_position)


func _setup_path():
	if _unit == null or not is_instance_valid(_unit) or _path == null:
		return false
	if not _has_target_unit():
		return false
	if _path.curve == null:
		_path.curve = Curve3D.new()
	_path.curve.clear_points()
	var projectile_origin = (
		_unit.global_position
		if _unit.find_child("ProjectileOrigin") == null
		else _unit.find_child("ProjectileOrigin").global_position
	)
	_path.curve.add_point(projectile_origin)
	_path.curve.add_point(target_unit.global_position)
	return true


func _perform_hit():
	if not _has_target_unit():
		queue_free()
		return
	CombatVfx.spawn_impact_at_unit(target_unit, max(1.2, _unit.splash_radius * 0.55))
	CombatDamage.apply_projectile_damage(_unit, target_unit)


func _has_target_unit():
	return target_unit != null and is_instance_valid(target_unit) and target_unit.is_inside_tree()
