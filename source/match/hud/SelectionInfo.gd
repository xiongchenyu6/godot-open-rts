extends PanelContainer

const Unit = preload("res://source/match/units/Unit.gd")
const Structure = preload("res://source/match/units/Structure.gd")
const CommandButtonIcons = preload("res://source/match/hud/unit-menus/CommandButtonIcons.gd")

const REFRESH_INTERVAL_SECONDS = 0.15
const CONTROL_GROUP_COUNT = 9
const CONTROL_GROUP_NAME_PREFIX = "unit_group_"
const HEALTH_HIGH_COLOR = Color(0.32, 0.86, 0.45, 1.0)
const HEALTH_MEDIUM_COLOR = Color(0.95, 0.78, 0.26, 1.0)
const HEALTH_LOW_COLOR = Color(0.95, 0.30, 0.24, 1.0)
const RANK_COLORS = [
	Color(0.52, 0.90, 0.58, 1.0),
	Color(1.0, 0.78, 0.16, 1.0),
	Color(0.18, 0.90, 1.0, 1.0),
]
const RANK_BADGE_TEXTS = ["", "V", "E"]

var _refresh_timer = 0.0

@onready var _name_label = find_child("NameLabel")
@onready var _count_label = find_child("CountLabel")
@onready var _group_label = find_child("GroupLabel")
@onready var _icon_rect = find_child("IconTextureRect")
@onready var _health_bar = find_child("HealthBar")
@onready var _health_label = find_child("HealthLabel")
@onready var _rank_row = find_child("RankRow")
@onready var _rank_badge = find_child("RankBadge")
@onready var _rank_label = find_child("RankLabel")
@onready var _stats_label = find_child("StatsLabel")
@onready var _summary_label = find_child("SummaryLabel")


func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_health_bar(1.0)
	_connect_signals()
	_refresh()


func _process(delta):
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = REFRESH_INTERVAL_SECONDS
		_refresh()


func _connect_signals():
	MatchSignals.unit_selected.connect(func(_unit): _refresh())
	MatchSignals.unit_deselected.connect(func(_unit): _refresh())
	MatchSignals.deselect_all_units.connect(_refresh)
	MatchSignals.unit_damaged.connect(func(_unit): _refresh())
	MatchSignals.unit_died.connect(func(_unit): _refresh())
	MatchSignals.unit_sold.connect(func(_unit): _refresh())
	MatchSignals.unit_captured.connect(func(_unit, _previous_player, _new_player): _refresh())
	MatchSignals.unit_construction_finished.connect(func(_unit): _refresh())
	MatchSignals.unit_promoted.connect(func(_unit, _rank): _refresh())
	MatchSignals.unit_group_assigned.connect(func(_group_id, _units): _refresh())
	MatchSignals.unit_group_cleared.connect(func(_group_id): _refresh())


func _refresh():
	var selected_units = _selected_units()
	if selected_units.is_empty():
		hide()
		return
	show()
	if selected_units.size() == 1:
		_show_single(selected_units[0])
	else:
		_show_multiple(selected_units)


func _show_single(unit):
	_update_icon_for_units([unit])
	_name_label.text = _display_name(unit)
	_count_label.text = ""
	_update_group_label([unit])
	_summary_label.text = _resource_summary(unit)
	var hp_summary = _hp_summary(unit)
	_health_bar.value = hp_summary["ratio"] * 100.0
	_health_label.text = hp_summary["label"]
	_style_health_bar(hp_summary["ratio"])
	if unit is Unit:
		_set_rank_display(
			unit.veterancy_rank,
			"{0}: {1}".format([tr("SELECTION_RANK"), _rank_name(unit.veterancy_rank)]),
			true
		)
		_stats_label.text = _single_unit_stats(unit)
	else:
		_set_rank_display(0, "", false)
		_stats_label.text = ""


func _show_multiple(units):
	_update_icon_for_units(units)
	_name_label.text = tr("SELECTION_SELECTED").format([units.size()])
	_count_label.text = tr("SELECTION_MULTIPLE_TYPES").format([_type_counts(units).size()])
	_update_group_label(units)
	var hp_summary = _aggregate_hp_summary(units)
	_health_bar.value = hp_summary["ratio"] * 100.0
	_health_label.text = hp_summary["label"]
	_style_health_bar(hp_summary["ratio"])
	var rank_summary = _rank_summary(units)
	_set_rank_display(rank_summary["rank"], rank_summary["label"], rank_summary["rank"] > 0)
	_stats_label.text = _multiple_unit_stats(units)
	_summary_label.text = _type_summary(units)


func _selected_units():
	return get_tree().get_nodes_in_group("selected_units").filter(
		func(unit): return unit != null and is_instance_valid(unit) and unit.visible
	)


func _update_icon_for_units(units):
	if _icon_rect == null:
		return
	for unit in units:
		var texture = CommandButtonIcons.texture_for_scene(_scene_path(unit))
		if texture == null:
			continue
		_icon_rect.texture = texture
		_icon_rect.visible = true
		_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return
	_icon_rect.texture = null
	_icon_rect.visible = false


func _display_name(unit):
	if unit.is_in_group("resource_units"):
		if "resource_a" in unit:
			return tr("RESOURCE_A")
		if "resource_b" in unit:
			return tr("RESOURCE_B")
	var scene_path = _scene_path(unit)
	if Constants.Match.Units.STRUCTURE_NAME_KEYS.has(scene_path):
		return tr(Constants.Match.Units.STRUCTURE_NAME_KEYS[scene_path])
	return tr(_camel_case_to_key(unit.type if "type" in unit else unit.name))


func _resource_summary(unit):
	if unit.is_in_group("resource_units"):
		if "resource_a" in unit:
			return "{0}: {1}".format([tr("SELECTION_RESOURCES"), unit.resource_a])
		if "resource_b" in unit:
			return "{0}: {1}".format([tr("SELECTION_RESOURCES"), unit.resource_b])
	if unit is Structure and unit.is_under_construction():
		return tr("SELECTION_CONSTRUCTING")
	return ""


func _single_unit_stats(unit):
	var stats = []
	if unit.attack_damage != null:
		stats.append("{0} {1}".format([tr("SELECTION_ATK"), _format_number(unit.attack_damage)]))
	if unit.attack_range != null:
		stats.append("{0} {1}".format([tr("SELECTION_RANGE"), _format_number(unit.attack_range)]))
	if unit.sight_range != null:
		stats.append("{0} {1}".format([tr("SELECTION_SIGHT"), _format_number(unit.sight_range)]))
	if unit.movement_speed > 0.0:
		stats.append("{0} {1}".format([tr("SELECTION_SPEED"), _format_number(unit.movement_speed)]))
	if unit.repair_rate != null:
		if "repair_radius" in unit and unit.repair_radius > 0.0:
			stats.append("{0} {1}{2}   {3} {4}".format(
				[
					tr("SELECTION_REPAIR"),
					_format_number(unit.repair_rate),
					tr("REPAIR_RATE"),
					tr("RADIUS"),
					_format_number(unit.repair_radius),
				]
			))
		else:
			stats.append("{0} {1}{2}".format(
				[tr("SELECTION_REPAIR"), _format_number(unit.repair_rate), tr("REPAIR_RATE")]
			))
	if "healing_rate" in unit and "healing_radius" in unit and unit.healing_rate > 0.0:
		stats.append("{0} +{1}{2}   {3} {4}".format(
			[
				tr("HEALING"),
				_format_number(unit.healing_rate),
				tr("REPAIR_RATE"),
				tr("RADIUS"),
				_format_number(unit.healing_radius),
			]
		))
	if unit.capture_time != null:
		stats.append("{0} {1}s".format(
			[tr("SELECTION_CAPTURE"), _format_number(unit.capture_time)]
		))
	if unit.hold_position:
		stats.append(tr("SELECTION_HOLD_POSITION"))
	if unit.has_method("is_deployed_mode") and unit.is_deployed_mode():
		stats.append(tr("SELECTION_DEPLOYED"))
	if unit.is_emp_disabled():
		stats.append(tr("SELECTION_EMP_DISABLED"))
	if unit is Structure:
		var scene_path = _scene_path(unit)
		var supply = Constants.Match.Units.POWER_SUPPLY.get(scene_path, 0)
		var drain = Constants.Match.Units.POWER_DRAIN.get(scene_path, 0)
		if supply > 0:
			stats.append("{0} +{1}".format([tr("SELECTION_POWER"), supply]))
		if drain > 0:
			stats.append("{0} -{1}".format([tr("SELECTION_POWER"), drain]))
	if "resource_income_a" in unit and "income_interval_s" in unit:
		var income_parts = []
		if unit.resource_income_a > 0:
			income_parts.append("{0} +{1}".format([tr("RESOURCE_A"), unit.resource_income_a]))
		if unit.resource_income_b > 0:
			income_parts.append("{0} +{1}".format([tr("RESOURCE_B"), unit.resource_income_b]))
		if not income_parts.is_empty():
			stats.append("{0} {1}/{2}s".format(
				[tr("SELECTION_INCOME"), ", ".join(income_parts), _format_number(unit.income_interval_s)]
			))
	return "   ".join(stats)


func _multiple_unit_stats(units):
	var combat_units = 0
	var structures = 0
	var air_units = 0
	for unit in units:
		if unit is Structure:
			structures += 1
		elif unit is Unit:
			combat_units += 1
		if "movement_domain" in unit and unit.movement_domain == Constants.Match.Navigation.Domain.AIR:
			air_units += 1
	var parts = []
	if combat_units > 0:
		parts.append("{0} {1}".format([tr("SELECTION_UNITS"), combat_units]))
	if structures > 0:
		parts.append("{0} {1}".format([tr("SELECTION_STRUCTURES"), structures]))
	if air_units > 0:
		parts.append("{0} {1}".format([tr("SELECTION_AIR"), air_units]))
	return "   ".join(parts)


func _update_group_label(units):
	var group_ids = _matching_control_group_ids(units)
	if group_ids.is_empty():
		_group_label.text = ""
		_group_label.hide()
		return
	_group_label.show()
	if group_ids.size() == 1:
		_group_label.text = tr("SELECTION_CONTROL_GROUP").format([group_ids[0]])
	else:
		_group_label.text = tr("SELECTION_CONTROL_GROUPS").format([_join_group_ids(group_ids)])


func _matching_control_group_ids(units):
	var selected_controlled_units = units.filter(
		func(unit): return _is_valid_controlled_group_unit(unit)
	)
	if selected_controlled_units.size() != units.size():
		return []
	var group_ids = []
	for group_id in range(1, CONTROL_GROUP_COUNT + 1):
		var group_units = _units_in_control_group(group_id)
		if _same_units(selected_controlled_units, group_units):
			group_ids.append(group_id)
	return group_ids


func _units_in_control_group(group_id):
	return get_tree().get_nodes_in_group(
		"{0}{1}".format([CONTROL_GROUP_NAME_PREFIX, group_id])
	).filter(func(unit): return _is_valid_controlled_group_unit(unit))


func _is_valid_controlled_group_unit(unit):
	return (
		unit != null
		and is_instance_valid(unit)
		and unit.visible
		and unit.is_inside_tree()
		and unit.is_in_group("controlled_units")
	)


func _same_units(left_units, right_units):
	if left_units.size() != right_units.size() or left_units.is_empty():
		return false
	for unit in left_units:
		if not right_units.has(unit):
			return false
	return true


func _join_group_ids(group_ids):
	var parts = group_ids.map(func(group_id): return str(group_id))
	return ", ".join(parts)


func _type_summary(units):
	var counts = _type_counts(units)
	var entries = []
	for name in counts.keys():
		entries.append("{0} x{1}".format([name, counts[name]]))
	entries.sort()
	return ", ".join(entries)


func _type_counts(units):
	var counts = {}
	for unit in units:
		var name = _display_name(unit)
		counts[name] = counts.get(name, 0) + 1
	return counts


func _hp_summary(unit):
	if "hp" in unit and "hp_max" in unit and unit.hp_max != null and unit.hp_max > 0:
		var ratio = clampf(float(unit.hp) / float(unit.hp_max), 0.0, 1.0)
		return {
			"ratio": ratio,
			"label": "{0} {1}/{2}".format([tr("SELECTION_HP"), unit.hp, unit.hp_max]),
		}
	return {
		"ratio": 1.0,
		"label": "",
	}


func _aggregate_hp_summary(units):
	var hp = 0.0
	var hp_max = 0.0
	for unit in units:
		if "hp" in unit and "hp_max" in unit and unit.hp_max != null:
			hp += unit.hp
			hp_max += unit.hp_max
	if hp_max <= 0.0:
		return {
			"ratio": 1.0,
			"label": "",
		}
	var ratio = clampf(hp / hp_max, 0.0, 1.0)
	return {
		"ratio": ratio,
		"label": "{0} {1}%".format([tr("SELECTION_AVG_HP"), int(round(ratio * 100.0))]),
	}


func _rank_name(rank):
	match clampi(rank, 0, Constants.Match.Veterancy.MAX_RANK):
		1:
			return tr("SELECTION_VETERAN")
		2:
			return tr("SELECTION_ELITE")
		_:
			return tr("SELECTION_GREEN")


func _rank_summary(units):
	var counts = {}
	for unit in units:
		if not (unit is Unit):
			continue
		var rank = clampi(unit.veterancy_rank, 0, Constants.Match.Veterancy.MAX_RANK)
		if rank <= 0:
			continue
		counts[rank] = counts.get(rank, 0) + 1
	if counts.is_empty():
		return {
			"rank": 0,
			"label": "",
		}
	var highest_rank = 0
	var parts = []
	for rank in range(Constants.Match.Veterancy.MAX_RANK, 0, -1):
		if not counts.has(rank):
			continue
		highest_rank = max(highest_rank, rank)
		parts.append("{0} x{1}".format([_rank_name(rank), counts[rank]]))
	return {
		"rank": highest_rank,
		"label": "{0}: {1}".format([tr("SELECTION_RANK"), ", ".join(parts)]),
	}


func _set_rank_display(rank, label, show_badge):
	if _rank_label != null:
		_rank_label.text = label
	if _rank_row != null:
		_rank_row.visible = label != ""
	if _rank_badge == null:
		return
	var safe_rank = clampi(rank, 0, min(Constants.Match.Veterancy.MAX_RANK, RANK_COLORS.size() - 1))
	_rank_badge.visible = show_badge and safe_rank > 0
	_rank_badge.text = RANK_BADGE_TEXTS[safe_rank]
	_rank_badge.add_theme_color_override("font_color", RANK_COLORS[safe_rank])
	_rank_badge.add_theme_stylebox_override("normal", _rank_badge_style(safe_rank))


func _rank_badge_style(rank):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.06, 0.95)
	style.border_color = RANK_COLORS[rank]
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style


func _scene_path(unit):
	if unit == null or unit.get_script() == null:
		return ""
	return unit.get_script().resource_path.replace(".gd", ".tscn")


func _camel_case_to_key(value):
	var key = ""
	for index in range(value.length()):
		var character = value[index]
		var previous = value[index - 1] if index > 0 else ""
		if index > 0 and character == character.to_upper() and character != character.to_lower():
			if previous != previous.to_upper() or (
				index + 1 < value.length()
				and value[index + 1] != value[index + 1].to_upper()
			):
				key += "_"
		key += character.to_upper()
	return key


func _format_number(value):
	if is_equal_approx(float(value), round(value)):
		return str(int(round(value)))
	return str(snappedf(float(value), 0.1))


func _style_health_bar(ratio):
	var background = StyleBoxFlat.new()
	background.bg_color = Color(0.02, 0.03, 0.035, 0.95)
	background.border_color = Color(0.18, 0.25, 0.29, 1.0)
	background.border_width_left = 1
	background.border_width_top = 1
	background.border_width_right = 1
	background.border_width_bottom = 1
	background.corner_radius_top_left = 2
	background.corner_radius_top_right = 2
	background.corner_radius_bottom_right = 2
	background.corner_radius_bottom_left = 2
	var fill = StyleBoxFlat.new()
	fill.bg_color = _health_color(ratio)
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_right = 2
	fill.corner_radius_bottom_left = 2
	_health_bar.add_theme_stylebox_override("background", background)
	_health_bar.add_theme_stylebox_override("fill", fill)


func _health_color(ratio):
	if ratio >= 0.66:
		return HEALTH_HIGH_COLOR
	if ratio >= 0.33:
		return HEALTH_MEDIUM_COLOR
	return HEALTH_LOW_COLOR
