extends Node

const BOOKMARK_COUNT = 4

@export var camera_path: NodePath = NodePath("../../IsometricCamera3D")

var _set_action_names = [null]
var _access_action_names = [null]
var _bookmarks = [null]

@onready var _camera = get_node_or_null(camera_path)


func _ready():
	for bookmark_id in range(1, BOOKMARK_COUNT + 1):
		_set_action_names.append("camera_bookmarks_set_{0}".format([bookmark_id]))
		_access_action_names.append("camera_bookmarks_access_{0}".format([bookmark_id]))
		_bookmarks.append(null)


func _input(event):
	for bookmark_id in range(1, BOOKMARK_COUNT + 1):
		if event.is_action_pressed(_set_action_names[bookmark_id], false, true):
			set_bookmark(bookmark_id)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(_access_action_names[bookmark_id], false, true):
			access_bookmark(bookmark_id)
			get_viewport().set_input_as_handled()
			return


func set_bookmark(bookmark_id: int) -> bool:
	if not _is_valid_bookmark_id(bookmark_id) or _camera == null:
		return false
	_bookmarks[bookmark_id] = _camera.get_view_state()
	return true


func access_bookmark(bookmark_id: int) -> bool:
	if not has_bookmark(bookmark_id) or _camera == null:
		return false
	_camera.restore_view_state(_bookmarks[bookmark_id])
	return true


func has_bookmark(bookmark_id: int) -> bool:
	return _is_valid_bookmark_id(bookmark_id) and _bookmarks[bookmark_id] != null


func _is_valid_bookmark_id(bookmark_id: int) -> bool:
	return bookmark_id >= 1 and bookmark_id <= BOOKMARK_COUNT
