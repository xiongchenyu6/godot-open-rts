extends RefCounted

const BATCH_TOOLTIP_KEY = "PRODUCTION_BATCH_QUEUE"


static func produce(production_queue, unit_scene, batch_to_limit = false):
	if production_queue == null:
		return []
	var requested_count = 1
	if batch_to_limit or _shift_pressed():
		requested_count = _remaining_queue_capacity(production_queue)
	var produced_elements = []
	for _index in range(requested_count):
		var before_size = production_queue.size()
		var produced_element = production_queue.produce(unit_scene)
		var after_size = production_queue.size()
		if produced_element == null and after_size <= before_size:
			break
		produced_elements.append(produced_element)
	return produced_elements


static func produce_for_units(producer_units, unit_scene, batch_to_limit = false):
	var produced_elements = []
	for producer_unit in _valid_producer_units(producer_units):
		produced_elements.append_array(
			produce(producer_unit.production_queue, unit_scene, batch_to_limit)
		)
	return produced_elements


static func has_available_queue(producer_units):
	for producer_unit in _valid_producer_units(producer_units):
		if producer_unit.production_queue.size() < Constants.Match.Units.PRODUCTION_QUEUE_LIMIT:
			return true
	return false


static func primary_queue(producer_units):
	for producer_unit in _valid_producer_units(producer_units):
		return producer_unit.production_queue
	return null


static func batch_tooltip(button):
	return "\n{0}".format([button.tr(BATCH_TOOLTIP_KEY)])


static func _remaining_queue_capacity(production_queue):
	return max(0, Constants.Match.Units.PRODUCTION_QUEUE_LIMIT - production_queue.size())


static func _shift_pressed():
	return Input.is_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_SHIFT)


static func _valid_producer_units(producer_units):
	var valid_producer_units = []
	for producer_unit in _normalize_units(producer_units):
		if producer_unit == null or not is_instance_valid(producer_unit):
			continue
		if not "production_queue" in producer_unit or producer_unit.production_queue == null:
			continue
		valid_producer_units.append(producer_unit)
	return valid_producer_units


static func _normalize_units(units_or_unit):
	if units_or_unit == null:
		return []
	if units_or_unit is Array:
		return units_or_unit
	return [units_or_unit]
