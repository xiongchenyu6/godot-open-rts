const Structure = preload("res://source/match/units/Structure.gd")
const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const CommandButtonStatus = preload("res://source/match/hud/unit-menus/CommandButtonStatus.gd")
const RepairIcon = preload("res://assets/ui/icons/Repair.png")

const REPAIR_BUTTON_NAME = "RepairStructureButton"


static func ensure_repair_button(menu, placeholder_name = ""):
	var existing_button = menu.find_child(REPAIR_BUTTON_NAME, false, false)
	if existing_button != null:
		return existing_button
	var button = Button.new()
	button.name = REPAIR_BUTTON_NAME
	button.custom_minimum_size = CommandButtonHotkeys.COMMAND_BUTTON_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.icon = RepairIcon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("h_separation", 0)
	var icon = TextureRect.new()
	icon.name = "TextureRect"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = RepairIcon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.grow_horizontal = Control.GROW_DIRECTION_BOTH
	icon.grow_vertical = Control.GROW_DIRECTION_BOTH
	button.add_child(icon)
	button.pressed.connect(Callable(menu, "_on_repair_structure_button_pressed"))
	if placeholder_name != "":
		var placeholder = menu.find_child(placeholder_name, false, false)
		if placeholder != null:
			var index = placeholder.get_index()
			menu.remove_child(placeholder)
			placeholder.queue_free()
			menu.add_child(button)
			menu.move_child(button, index)
			return button
	menu.add_child(button)
	return button


static func refresh_sell_button(button, units_or_unit):
	if button == null:
		return
	var structures = _sellable_structures(units_or_unit)
	button.disabled = structures.is_empty()
	CommandButtonStatus.apply_action(button, "SELL_STRUCTURE")
	button.tooltip_text = CommandButtonHotkeys.tooltip(button, _sell_tooltip(button, structures))


static func refresh_repair_button(button, units_or_unit):
	if button == null:
		return
	var candidates = _repair_candidate_structures(units_or_unit)
	var structures = _repairable_structures(candidates)
	button.disabled = structures.is_empty()
	CommandButtonStatus.apply_action(button, "REPAIR_STRUCTURE")
	button.tooltip_text = CommandButtonHotkeys.tooltip(
		button, _repair_tooltip(button, candidates, structures)
	)


static func refresh_rally_point_button(button, units_or_unit):
	if button == null:
		return
	var structures = _rally_point_structures(units_or_unit)
	button.disabled = structures.is_empty()
	CommandButtonStatus.apply_action(button, "RALLY_POINT")
	button.tooltip_text = CommandButtonHotkeys.tooltip(button, _rally_point_tooltip(button, structures))


static func sell(units_or_unit):
	for structure in _sellable_structures(units_or_unit).duplicate():
		structure.sell()


static func repair(units_or_unit):
	var repaired = false
	for structure in _repairable_structures(_repair_candidate_structures(units_or_unit)):
		if structure.repair():
			repaired = true
	return repaired


static func request_rally_point(units_or_unit):
	if _rally_point_structures(units_or_unit).is_empty():
		return false
	MatchSignals.rally_point_requested.emit()
	return true


static func _sellable_structures(units_or_unit):
	var structures = []
	for unit in _normalize_units(units_or_unit):
		if unit == null or not is_instance_valid(unit):
			continue
		if not unit is Structure:
			continue
		if not unit.is_constructed():
			continue
		if not unit.is_in_group("controlled_units"):
			continue
		structures.append(unit)
	return structures


static func _repair_candidate_structures(units_or_unit):
	var structures = []
	for unit in _normalize_units(units_or_unit):
		if unit == null or not is_instance_valid(unit):
			continue
		if not unit is Structure:
			continue
		if not unit.is_constructed():
			continue
		if not unit.is_in_group("controlled_units"):
			continue
		if unit.hp == null or unit.hp_max == null or unit.hp <= 0:
			continue
		if unit.hp >= unit.hp_max and not unit.is_repairing():
			continue
		structures.append(unit)
	return structures


static func _repairable_structures(candidates):
	return candidates.filter(
		func(structure):
			return (
				structure.can_repair()
				and structure.player.has_resources(structure.get_repair_cost())
			)
	)


static func _rally_point_structures(units_or_unit):
	var structures = []
	for unit in _normalize_units(units_or_unit):
		if unit == null or not is_instance_valid(unit):
			continue
		if not unit is Node:
			continue
		if unit.find_child("RallyPoint", true, false) == null:
			continue
		structures.append(unit)
	return structures


static func _normalize_units(units_or_unit):
	if units_or_unit == null:
		return []
	if units_or_unit is Array:
		return units_or_unit
	return [units_or_unit]


static func _sell_tooltip(button, structures):
	if structures.is_empty():
		return "{0} - {1}".format([button.tr("SELL_STRUCTURE"), button.tr("SELL_STRUCTURE_DISABLED")])
	var refund = {"resource_a": 0, "resource_b": 0}
	for structure in structures:
		var structure_refund = structure.get_sell_refund()
		refund["resource_a"] += structure_refund.get("resource_a", 0)
		refund["resource_b"] += structure_refund.get("resource_b", 0)
	return "{0} - {1}\n{2}: {3}: {4}, {5}: {6}".format(
		[
			button.tr("SELL_STRUCTURE"),
			button.tr("SELL_STRUCTURE_DESCRIPTION"),
			button.tr("REFUND"),
			button.tr("RESOURCE_A"),
			refund["resource_a"],
			button.tr("RESOURCE_B"),
			refund["resource_b"]
		]
	)


static func _repair_tooltip(button, candidates, structures):
	if candidates.is_empty():
		return "{0} - {1}".format(
			[button.tr("REPAIR_STRUCTURE"), button.tr("REPAIR_STRUCTURE_DISABLED")]
		)
	if structures.is_empty() and candidates.any(func(structure): return structure.is_repairing()):
		return "{0} - {1}".format(
			[button.tr("REPAIR_STRUCTURE"), button.tr("REPAIR_STRUCTURE_IN_PROGRESS")]
		)
	var repair_cost = {"resource_a": 0, "resource_b": 0}
	var cost_sources = structures if not structures.is_empty() else candidates
	for structure in cost_sources:
		var structure_cost = structure.get_repair_cost()
		repair_cost["resource_a"] += structure_cost.get("resource_a", 0)
		repair_cost["resource_b"] += structure_cost.get("resource_b", 0)
	var tooltip = "{0} - {1}\n{2}: {3}: {4}, {5}: {6}\n{7}: {8}".format(
		[
			button.tr("REPAIR_STRUCTURE"),
			button.tr("REPAIR_STRUCTURE_DESCRIPTION"),
			button.tr("REPAIR_COST"),
			button.tr("RESOURCE_A"),
			repair_cost["resource_a"],
			button.tr("RESOURCE_B"),
			repair_cost["resource_b"],
			button.tr("REPAIR_RATE"),
			"{0} HP/s".format([Constants.Match.Structure.MANUAL_REPAIR_HITPOINTS_PER_SECOND]),
		]
	)
	if structures.is_empty():
		tooltip += "\n{0}".format([button.tr("NOT_ENOUGH_RESOURCES")])
	return tooltip


static func _rally_point_tooltip(button, structures):
	if structures.is_empty():
		return "{0} - {1}".format([button.tr("RALLY_POINT"), button.tr("RALLY_POINT_DISABLED")])
	return "{0} - {1}".format([button.tr("RALLY_POINT"), button.tr("RALLY_POINT_DESCRIPTION")])
