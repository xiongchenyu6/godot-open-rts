extends "res://source/match/units/Worker.gd"

const CommandCenterScene = preload("res://source/match/units/CommandCenter.tscn")


func can_collect_resources():
	return false


func is_full():
	return true


func can_deploy_as_command_center():
	return is_inside_tree() and player != null and _match != null and _match.has_method("_setup_and_spawn_unit")


func deploy_as_command_center():
	if not can_deploy_as_command_center():
		return null
	var deployed_transform = global_transform
	var deployed_player = player
	var command_center = CommandCenterScene.instantiate()
	var selection = find_child("Selection")
	if selection != null and selection.has_method("deselect"):
		selection.deselect()
	_match.call("_setup_and_spawn_unit", command_center, deployed_transform, deployed_player, false)
	queue_free()
	return command_center
