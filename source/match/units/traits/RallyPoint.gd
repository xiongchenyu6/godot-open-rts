extends Node3D

var is_set = false
var target_unit = null:
	set(a_target_unit):
		if target_unit == a_target_unit:
			return
		var previous_target_unit = target_unit
		if (
			previous_target_unit != null
			and is_instance_valid(previous_target_unit)
			and previous_target_unit.tree_exited.is_connected(_on_target_unit_tree_exited)
		):
			previous_target_unit.tree_exited.disconnect(_on_target_unit_tree_exited)
		target_unit = a_target_unit
		if target_unit != null:
			is_set = true
			if not target_unit.tree_exited.is_connected(_on_target_unit_tree_exited):
				target_unit.tree_exited.connect(_on_target_unit_tree_exited)
			hide()
		else:
			is_set = false
			_reset_position_to_parent()
			hide()

@onready var _unit = get_parent()
@onready var _animation_player = find_child("AnimationPlayer")


func _ready():
	_animation_player.play("idle")
	_reset_position_to_parent()
	visible = false
	_unit.selected.connect(_show)
	_unit.deselected.connect(hide)


func _physics_process(_delta):
	if target_unit != null:
		global_position = target_unit.global_position


func set_target_position(target_position: Vector3):
	target_unit = null
	is_set = true
	global_position = target_position
	if _unit.is_in_group("selected_units"):
		show()


func set_target_unit(a_target_unit):
	target_unit = a_target_unit


func _show():
	if not is_set:
		hide()
		return
	if target_unit == null:
		show()
	else:
		var targetability = target_unit.find_child("Targetability")
		if targetability != null:
			targetability.animate()


func _reset_position_to_parent():
	if _unit.is_inside_tree():
		global_position = _unit.global_position
	else:
		position = Vector3.ZERO


func _on_target_unit_tree_exited():
	target_unit = null
