extends MarginContainer

const ProductionQueueElement = preload("res://source/match/hud/ProductionQueueElement.tscn")

var _production_queues = []

@onready var _queue_elements = find_child("QueueElements")


func _ready():
	_reset()
	MatchSignals.unit_selected.connect(func(_unit): _reset())
	MatchSignals.unit_deselected.connect(func(_unit): _reset())


func _reset():
	if not is_inside_tree():
		return
	_detach_observed_production_queues()
	_try_observing_production_queues()
	_remove_queue_element_nodes()
	_try_rendering_queue()
	_sync_visibility()


func _remove_queue_element_nodes():
	for child in _queue_elements.get_children():
		_queue_elements.remove_child(child)
		child.free()


func _is_observing_production_queue():
	return not _production_queues.is_empty()


func _detach_observed_production_queues():
	for production_queue in _production_queues:
		if production_queue == null or not is_instance_valid(production_queue):
			continue
		if production_queue.element_enqueued.is_connected(_on_production_queue_changed):
			production_queue.element_enqueued.disconnect(_on_production_queue_changed)
		if production_queue.element_removed.is_connected(_on_production_queue_changed):
			production_queue.element_removed.disconnect(_on_production_queue_changed)
	_production_queues = []


func _try_observing_production_queues():
	var selected_controlled_units = get_tree().get_nodes_in_group("selected_units").filter(
		func(unit): return (
			is_instance_valid(unit)
			and unit.is_inside_tree()
			and unit.is_in_group("controlled_units")
		)
	)
	if selected_controlled_units.is_empty():
		return
	selected_controlled_units.sort_custom(func(a, b): return str(a.get_path()) < str(b.get_path()))
	var queues = []
	for selected_unit in selected_controlled_units:
		if not "production_queue" in selected_unit or selected_unit.production_queue == null:
			return
		if selected_unit.production_queue in queues:
			continue
		queues.append(selected_unit.production_queue)
	_observe(queues)


func _observe(production_queues):
	_production_queues = production_queues
	for production_queue in _production_queues:
		if not production_queue.element_enqueued.is_connected(_on_production_queue_changed):
			production_queue.element_enqueued.connect(_on_production_queue_changed)
		if not production_queue.element_removed.is_connected(_on_production_queue_changed):
			production_queue.element_removed.connect(_on_production_queue_changed)


func _try_rendering_queue():
	if not _is_observing_production_queue():
		_sync_visibility()
		return
	for production_queue in _production_queues:
		var queue_elements = production_queue.get_elements()
		for local_index in range(queue_elements.size()):
			_add_queue_element_node(production_queue, queue_elements[local_index], local_index)
	_update_queue_element_nodes()
	_sync_visibility()


func _add_queue_element_node(production_queue, queue_element, local_index):
	var queue_element_node = ProductionQueueElement.instantiate()
	queue_element_node.queue = production_queue
	queue_element_node.queue_element = queue_element
	queue_element_node.queue_local_index = local_index
	_queue_elements.add_child(queue_element_node)
	_update_queue_element_nodes()


func _update_queue_element_nodes():
	var queue_element_nodes = _queue_elements.get_children().filter(
		func(child): return "queue_element" in child
	)
	for index in range(queue_element_nodes.size()):
		var queue_element_node = queue_element_nodes[index]
		if queue_element_node.has_method("set_queue_indices"):
			queue_element_node.set_queue_indices(index, queue_element_node.queue_local_index)
		elif queue_element_node.has_method("set_queue_index"):
			queue_element_node.set_queue_index(index)


func _on_production_queue_changed(_element):
	_remove_queue_element_nodes()
	_try_rendering_queue()
	_sync_visibility()


func _sync_visibility():
	visible = _queue_element_count() > 0


func _queue_element_count():
	var count = 0
	for production_queue in _production_queues:
		if production_queue == null or not is_instance_valid(production_queue):
			continue
		for _queue_element in production_queue.get_elements():
			count += 1
	return count
