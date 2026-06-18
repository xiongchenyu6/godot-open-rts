extends "res://source/match/units/actions/Action.gd"

var _target_position = null

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")
@onready var _movement_trait = _unit.find_child("Movement")


static func is_applicable(unit):
	return (
		unit.find_child("Movement") != null
		and (
			not unit.has_method("can_receive_movement_commands")
			or unit.can_receive_movement_commands()
		)
	)


func _init(target_position):
	_target_position = target_position


func _ready():
	_movement_trait.move(_target_position)
	_movement_trait.movement_finished.connect(_on_movement_finished)


func _exit_tree():
	if _movement_trait != null and is_instance_valid(_movement_trait):
		_movement_trait.stop()


func _on_movement_finished():
	queue_free()
