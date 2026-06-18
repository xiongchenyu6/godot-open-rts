extends Node

@export var camera_path: NodePath = NodePath("../../IsometricCamera3D")

var _latest_event_position = null

@onready var _camera = get_node_or_null(camera_path)


func _ready():
	MatchSignals.battle_event_recorded.connect(_on_battle_event_recorded)


func _unhandled_input(event):
	if event.is_action_pressed("focus_latest_battle_event") and focus_latest_event():
		get_viewport().set_input_as_handled()


func focus_latest_event():
	if _camera == null or _latest_event_position == null:
		return false
	_camera.set_position_safely(_latest_event_position)
	return true


func get_latest_event_position():
	return _latest_event_position


func _on_battle_event_recorded(position):
	_latest_event_position = position
