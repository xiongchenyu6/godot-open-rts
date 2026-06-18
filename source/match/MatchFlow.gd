extends RefCounted

const LoadingScene = preload("res://source/main-menu/Loading.tscn")
const SetupScene = preload("res://source/main-menu/Play.tscn")


static func restart_match_from(node):
	var match_node = node.find_parent("Match")
	if match_node == null:
		return false
	var map_path = match_node.map_path
	if map_path == null or map_path == "":
		return false
	var loading_scene = LoadingScene.instantiate()
	loading_scene.match_settings = match_node.settings.duplicate(true)
	loading_scene.map_path = map_path
	var tree = node.get_tree()
	_reset_runtime_state(tree)
	tree.root.add_child(loading_scene)
	tree.current_scene = loading_scene
	match_node.queue_free()
	return true


static func exit_to_main_menu(tree):
	_reset_runtime_state(tree)
	tree.change_scene_to_file("res://source/main-menu/Main.tscn")


static func exit_to_setup_menu(tree):
	_reset_runtime_state(tree)
	tree.change_scene_to_file("res://source/main-menu/Play.tscn")


static func exit_to_setup_menu_from(node):
	var match_node = node.find_parent("Match")
	if match_node == null:
		exit_to_setup_menu(node.get_tree())
		return false
	var setup_scene = SetupScene.instantiate()
	if match_node.settings != null:
		setup_scene.initial_match_settings = match_node.settings.duplicate(true)
	setup_scene.initial_map_path = match_node.map_path
	var tree = node.get_tree()
	_reset_runtime_state(tree)
	tree.root.add_child(setup_scene)
	tree.current_scene = setup_scene
	match_node.queue_free()
	return true


static func _reset_runtime_state(tree):
	tree.paused = false
	Engine.time_scale = 1.0
