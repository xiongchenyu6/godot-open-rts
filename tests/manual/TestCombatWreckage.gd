extends "res://tests/manual/Match.gd"

@onready var _target = $Players/Human/Tank


func _ready():
	super()
	await get_tree().process_frame

	var initial_wreckage_count = get_tree().get_nodes_in_group("combat_wreckage").size()
	_target.hp = 0
	await get_tree().process_frame
	await get_tree().process_frame

	var wreckage = _newest_wreckage(initial_wreckage_count)
	if wreckage == null:
		push_error("destroyed visible units should leave temporary combat wreckage")
		get_tree().quit(1)
		return
	if wreckage.find_child("ScorchMark", true, false) == null:
		push_error("combat wreckage should include a scorch mark")
		get_tree().quit(1)
		return
	if wreckage.get_child_count() < 4:
		push_error("combat wreckage should include visible debris pieces")
		get_tree().quit(1)
		return

	wreckage.lifetime = 0.05
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(wreckage):
		push_error("combat wreckage should clean itself up after its lifetime")
		get_tree().quit(1)
		return
	get_tree().quit()


func _newest_wreckage(initial_count):
	var wreckage_nodes = get_tree().get_nodes_in_group("combat_wreckage")
	if wreckage_nodes.size() <= initial_count:
		return null
	return wreckage_nodes[wreckage_nodes.size() - 1]
