extends RefCounted

const CommandButtonIcons = preload("res://source/match/hud/unit-menus/CommandButtonIcons.gd")

const COST_LABEL_NAME = "CostLabel"
const LOCK_LABEL_NAME = "TechLockLabel"
const NAME_LABEL_NAME = "NameLabel"
const QUEUE_LABEL_NAME = "QueueCountLabel"
const STATUS_STRIP_NAME = "CommandStatusStrip"
const TIME_LABEL_NAME = "TimeLabel"
const META_COST_TEXT = "command_cost_text"
const META_NAME_TEXT = "command_name_text"
const META_TECH_LOCKED = "command_tech_locked"
const META_AFFORDABLE = "command_affordable"
const META_QUEUE_COUNT = "command_queue_count"
const META_QUEUE_FULL = "command_queue_full"
const META_TIME_TEXT = "command_time_text"
const META_PRODUCTION_QUEUE = "command_production_queue"
const META_PRODUCTION_QUEUES = "command_production_queues"
const META_UNIT_SCENE_PATH = "command_unit_scene_path"
const META_CANCEL_INPUT_CONNECTED = "command_cancel_input_connected"

const COST_COLOR = Color(0.86, 0.96, 0.90, 1.0)
const COST_DISABLED_COLOR = Color(0.45, 0.56, 0.54, 1.0)
const COST_UNAFFORDABLE_COLOR = Color(1.0, 0.36, 0.26, 1.0)
const LOCK_COLOR = Color(1.0, 0.72, 0.28, 1.0)
const NAME_COLOR = Color(0.82, 0.94, 0.91, 1.0)
const NAME_DISABLED_COLOR = Color(0.40, 0.50, 0.50, 1.0)
const QUEUE_COLOR = Color(0.50, 0.86, 1.0, 1.0)
const QUEUE_FULL_COLOR = Color(1.0, 0.46, 0.28, 1.0)
const STATUS_STRIP_COLOR = Color(0.015, 0.026, 0.032, 0.82)
const TIME_COLOR = Color(0.98, 0.84, 0.42, 1.0)
const SURFACE_NAME_OVERRIDES = {
	"AA_TURRET": "AA Gun",
	"ADVANCED_REACTOR_PLANT": "Adv Power",
	"AG_TURRET": "Gun",
	"AIRCRAFT_FACTORY": "Air Pad",
	"ANTI_AIR_WALKER": "AA Walker",
	"ARC_COIL_DEFENSE_TOWER": "Arc Coil",
	"BARRACKS": "Barracks",
	"BOMBER_VTOL": "Bomber",
	"CC": "Command",
	"CRYO_SPRAYER": "Cryo",
	"DRONE": "Drone",
	"DRONE_MINE_LAYER": "Mines",
	"ENGINEER_DRONE": "Engineer",
	"FIELD_MEDIC": "Medic",
	"FLAK_HOVER_TANK": "Flak",
	"FLAK_ROCKET_TEAM": "Flak",
	"FLAK_ROCKET_TEAM_MK2": "Flak Mk2",
	"FLAME_ASSAULT_BUGGY": "Flame",
	"GRENADIER_TROOPER": "Grenadier",
	"HAMMER_SIEGE_TANK": "Hammer",
	"HEAVY_BOMBARDMENT_AIRSHIP": "Airship",
	"HEAVY_MACHINEGUN_TROOPER": "MG",
	"HEAVY_SIEGE_WALKER": "Siege",
	"HELICOPTER": "Heli",
	"INTERCEPTOR_VTOL": "Fighter",
	"JAMMER_VEHICLE": "Jammer",
	"LANCE_BEAM_DEFENSE_TOWER": "Lance",
	"LANCE_BEAM_TANK": "Lance",
	"LIGHT_RIFLE_INFANTRY": "Rifle",
	"LONGBOW_MISSILE_CRAWLER": "Longbow",
	"MIRAGE_SCOUT_TANK": "Mirage",
	"MOBILE_CONSTRUCTION_VEHICLE": "MCV",
	"MOBILE_REPAIR_CRAWLER": "Repair",
	"MOBILE_SHIELD_PROJECTOR": "Shield",
	"MODULAR_MISSILE_CARRIER": "Missiles",
	"MORTAR_TEAM": "Mortar",
	"ORE_HARVESTER": "Harvester",
	"ORE_PURIFIER": "Purifier",
	"PHASE_SABOTEUR": "Phase",
	"POWER_REACTOR": "Power",
	"PRISM_DEFENSE_OBELISK": "Prism",
	"PULSE_RIFLE_COMMANDO": "Commando",
	"RADAR_UPLINK": "Radar",
	"RAILGUN_TANK": "Railgun",
	"RAIL_ARTILLERY_WALKER": "Rail Art",
	"RAIL_CANNON_BUNKER": "Rail Gun",
	"RAIL_SNIPER_TEAM": "Rail Sniper",
	"REFINERY": "Refinery",
	"REPAIR_PAD": "Repair",
	"ROBOTICS_BAY": "Robotics",
	"ROCKET_GUNSHIP": "Gunship",
	"ROCKET_INFANTRY": "Rocket",
	"ROCKET_TROOPER_ROBOT": "Rocket Bot",
	"SABOTEUR_INFILTRATOR": "Saboteur",
	"SCOUT_ROVER": "Scout",
	"SHIELD_TROOPER": "Shield",
	"SHOCK_TROOPER": "Shock",
	"SIEGE_AIRSHIP": "Siege Air",
	"SIEGE_ARTILLERY_VEHICLE": "Artillery",
	"SIEGE_DRILL_TANK": "Drill",
	"SNIPER_SCOUT": "Sniper",
	"TACTICAL_OFFICER": "Officer",
	"TANK": "Tank",
	"TECH_LAB": "Tech Lab",
	"TESLA_CRAWLER_MK2": "Tesla Mk2",
	"TESLA_FENCE_SEGMENT": "Fence",
	"VEHICLE_FACTORY": "Factory",
	"WEATHER_CONTROL_SPIRE": "Weather",
	"WORKER": "Worker",
	"HOLD_POSITION": "Hold",
	"ATTACK_MOVE": "Attack",
	"PATROL": "Patrol",
	"GUARD_AREA": "Guard",
	"SCATTER": "Scatter",
	"DEPLOY_MODE": "Deploy",
	"CANCEL_CURRENT_ACTION": "Cancel",
	"SELL_STRUCTURE": "Sell",
	"REPAIR_STRUCTURE": "Repair",
	"RALLY_POINT": "Rally",
	"DEPLOY_MCV": "Deploy",
}


static func apply_production(
	button,
	unit_scene,
	missing_requirements = [],
	player = null,
	production_queue = null,
	production_queues = [],
	name_key = ""
):
	CommandButtonIcons.apply_for_scene(button, unit_scene.resource_path)
	var costs = Constants.Match.Units.PRODUCTION_COSTS.get(unit_scene.resource_path, {})
	_apply(button, costs, missing_requirements, player)
	_update_time_label(
		button,
		Constants.Match.Units.PRODUCTION_TIMES.get(unit_scene.resource_path, 0.0)
	)
	var active_queues = _normalize_production_queues(production_queue, production_queues)
	var queue_count = _queue_count_for(active_queues, unit_scene.resource_path)
	var queue_full = _queues_are_full(active_queues)
	button.set_meta(META_QUEUE_COUNT, queue_count)
	button.set_meta(META_QUEUE_FULL, queue_full)
	button.set_meta(META_PRODUCTION_QUEUE, active_queues[0] if not active_queues.is_empty() else null)
	button.set_meta(META_PRODUCTION_QUEUES, active_queues)
	button.set_meta(META_UNIT_SCENE_PATH, unit_scene.resource_path)
	_update_queue_label(button, queue_count, queue_full)
	_update_name_label(button, name_key)
	_ensure_cancel_input_handler(button)


static func apply_construction(
	button,
	structure_scene,
	missing_requirements = [],
	player = null,
	name_key = ""
):
	CommandButtonIcons.apply_for_scene(button, structure_scene.resource_path)
	var costs = Constants.Match.Units.CONSTRUCTION_COSTS.get(structure_scene.resource_path, {})
	_apply(button, costs, missing_requirements, player)
	_update_time_label(button, 0.0)
	_update_name_label(button, name_key)
	button.remove_meta(META_PRODUCTION_QUEUE)
	button.remove_meta(META_PRODUCTION_QUEUES)
	button.remove_meta(META_UNIT_SCENE_PATH)


static func apply_action(button, name_key):
	if button == null or name_key == "":
		return
	_update_name_label(button, name_key)


static func production_queue_full_tooltip(button, production_queue = null, production_queues = []):
	if not _queues_are_full(_normalize_production_queues(production_queue, production_queues)):
		return ""
	return "\n{0}".format([button.tr("PRODUCTION_QUEUE_FULL")])


static func clear(button):
	if button == null:
		return
	button.remove_meta(META_COST_TEXT)
	button.remove_meta(META_NAME_TEXT)
	button.remove_meta(META_TECH_LOCKED)
	button.remove_meta(META_AFFORDABLE)
	button.remove_meta(META_QUEUE_COUNT)
	button.remove_meta(META_QUEUE_FULL)
	button.remove_meta(META_TIME_TEXT)
	button.remove_meta(META_PRODUCTION_QUEUE)
	button.remove_meta(META_PRODUCTION_QUEUES)
	button.remove_meta(META_UNIT_SCENE_PATH)
	var cost_label = button.find_child(COST_LABEL_NAME, false, false)
	if cost_label != null:
		cost_label.queue_free()
	var lock_label = button.find_child(LOCK_LABEL_NAME, false, false)
	if lock_label != null:
		lock_label.queue_free()
	var name_label = button.find_child(NAME_LABEL_NAME, false, false)
	if name_label != null:
		name_label.queue_free()
	var queue_label = button.find_child(QUEUE_LABEL_NAME, false, false)
	if queue_label != null:
		queue_label.queue_free()
	var status_strip = button.find_child(STATUS_STRIP_NAME, false, false)
	if status_strip != null:
		status_strip.queue_free()
	var time_label = button.find_child(TIME_LABEL_NAME, false, false)
	if time_label != null:
		time_label.queue_free()


static func _apply(button, costs, missing_requirements, player):
	if button == null:
		return
	var cost_text = _format_cost_text(costs)
	var affordable = player == null or player.has_resources(costs)
	button.set_meta(META_COST_TEXT, cost_text)
	button.set_meta(META_TECH_LOCKED, not missing_requirements.is_empty())
	button.set_meta(META_AFFORDABLE, affordable)
	_update_cost_label(button, cost_text, affordable)
	_update_lock_label(button, not missing_requirements.is_empty())


static func _format_cost_text(costs):
	var resource_a = int(costs.get("resource_a", 0))
	var resource_b = int(costs.get("resource_b", 0))
	if resource_b <= 0:
		return "A {0}".format([resource_a])
	return "A {0}  B {1}".format([resource_a, resource_b])


static func _update_cost_label(button, text, affordable):
	var label = button.find_child(COST_LABEL_NAME, false, false)
	if label == null:
		label = Label.new()
		label.name = COST_LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 9
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		button.add_child(label)
	label.text = text
	label.add_theme_color_override("font_color", _cost_color(button, affordable))
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_left = 3
	label.offset_top = -20
	label.offset_right = -3
	label.offset_bottom = -2
	_sync_status_strip(button)
	button.move_child(label, button.get_child_count() - 1)


static func _update_name_label(button, name_key):
	if button == null or name_key == "":
		return
	var text = _surface_name(button, name_key)
	button.set_meta(META_NAME_TEXT, text)
	var label = button.find_child(NAME_LABEL_NAME, false, false)
	if label == null:
		label = Label.new()
		label.name = NAME_LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 10
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		button.add_child(label)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", _name_font_size(button))
	label.visible = text != ""
	label.text = text
	label.add_theme_color_override(
		"font_color", NAME_DISABLED_COLOR if button.disabled else NAME_COLOR
	)
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_left = 4
	label.offset_top = _name_label_top(button)
	label.offset_right = _name_label_right(button)
	label.offset_bottom = _name_label_bottom(button)
	_sync_status_strip(button)
	button.move_child(label, button.get_child_count() - 1)


static func _name_label_top(button):
	if _button_has_cost_or_time(button):
		return -42
	return -30


static func _name_label_bottom(button):
	if _button_has_cost_or_time(button):
		return -22
	return -7


static func _name_label_right(button):
	var time_label = button.find_child(TIME_LABEL_NAME, false, false)
	if time_label != null and time_label.visible:
		return -35
	return -4


static func _name_font_size(button):
	var cost_label = button.find_child(COST_LABEL_NAME, false, false)
	return 11 if cost_label != null and cost_label.visible else 12


static func _button_has_cost_or_time(button):
	var cost_label = button.find_child(COST_LABEL_NAME, false, false)
	if cost_label != null and cost_label.visible:
		return true
	var time_label = button.find_child(TIME_LABEL_NAME, false, false)
	return time_label != null and time_label.visible


static func _sync_status_strip(button):
	if button == null:
		return
	var strip = button.find_child(STATUS_STRIP_NAME, false, false)
	if strip == null:
		strip = ColorRect.new()
		strip.name = STATUS_STRIP_NAME
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.z_index = 8
		button.add_child(strip)
	var has_status = false
	for label_name in [COST_LABEL_NAME, NAME_LABEL_NAME, TIME_LABEL_NAME]:
		var label = button.find_child(label_name, false, false)
		if label != null and label.visible and str(label.text).strip_edges() != "":
			has_status = true
			break
	strip.visible = has_status
	strip.color = STATUS_STRIP_COLOR
	strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_left = 2
	strip.offset_top = -45 if _button_has_cost_or_time(button) else -32
	strip.offset_right = -2
	strip.offset_bottom = -1
	button.move_child(strip, 0)


static func _surface_name(button, name_key):
	if _uses_english_surface_name_overrides() and SURFACE_NAME_OVERRIDES.has(name_key):
		return SURFACE_NAME_OVERRIDES[name_key]
	var translated_name = button.tr(name_key).strip_edges()
	return _compact_surface_name(translated_name)


static func _uses_english_surface_name_overrides():
	var locale = TranslationServer.get_locale()
	return locale == "" or locale.begins_with("en")


static func _compact_surface_name(translated_name):
	if translated_name.length() <= 10:
		return translated_name
	var words = Array(translated_name.split(" ", false))
	if words.is_empty():
		return translated_name.substr(0, min(translated_name.length(), 10))
	if words.size() == 1:
		return words[0].substr(0, min(words[0].length(), 10))
	return "{0} {1}".format([words[0], words[1]]).substr(0, 10).strip_edges()


static func _cost_color(button, affordable):
	if button.disabled:
		return COST_DISABLED_COLOR
	if not affordable:
		return COST_UNAFFORDABLE_COLOR
	return COST_COLOR


static func _queue_count_for(production_queues, unit_scene_path):
	var count = 0
	for production_queue in production_queues:
		for element in production_queue.get_elements():
			if element.unit_prototype.resource_path == unit_scene_path:
				count += 1
	return count


static func _queues_are_full(production_queues):
	if production_queues.is_empty():
		return false
	for production_queue in production_queues:
		if production_queue.size() < Constants.Match.Units.PRODUCTION_QUEUE_LIMIT:
			return false
	return true


static func _ensure_cancel_input_handler(button):
	if button == null or button.get_meta(META_CANCEL_INPUT_CONNECTED, false):
		return
	button.gui_input.connect(func(event): _try_cancel_queued_production(button, event))
	button.set_meta(META_CANCEL_INPUT_CONNECTED, true)


static func _try_cancel_queued_production(button, event):
	if not event is InputEventMouseButton:
		return false
	if not event.pressed or event.button_index != MOUSE_BUTTON_RIGHT:
		return false
	var production_queues = button.get_meta(META_PRODUCTION_QUEUES, [])
	var unit_scene_path = button.get_meta(META_UNIT_SCENE_PATH, "")
	if production_queues.is_empty() or unit_scene_path == "":
		return false
	var cancellation = _newest_queue_element_for(production_queues, unit_scene_path)
	if cancellation.is_empty():
		return false
	var production_queue = cancellation[0]
	var element = cancellation[1]
	production_queue.cancel(element)
	var queue_count = _queue_count_for(production_queues, unit_scene_path)
	var queue_full = _queues_are_full(production_queues)
	button.set_meta(META_QUEUE_COUNT, queue_count)
	button.set_meta(META_QUEUE_FULL, queue_full)
	_update_queue_label(button, queue_count, queue_full)
	button.accept_event()
	return true


static func _newest_queue_element_for(production_queues, unit_scene_path):
	for queue_index in range(production_queues.size() - 1, -1, -1):
		var production_queue = production_queues[queue_index]
		var elements = production_queue.get_elements()
		for element_index in range(elements.size() - 1, -1, -1):
			var element = elements[element_index]
			if element.unit_prototype.resource_path == unit_scene_path:
				return [production_queue, element]
	return []


static func _normalize_production_queues(production_queue = null, production_queues = []):
	var normalized_queues = []
	for queue_candidate in production_queues:
		if queue_candidate == null:
			continue
		if queue_candidate in normalized_queues:
			continue
		normalized_queues.append(queue_candidate)
	if production_queue != null and not production_queue in normalized_queues:
		normalized_queues.push_front(production_queue)
	return normalized_queues


static func _update_queue_label(button, count, is_full):
	var label = button.find_child(QUEUE_LABEL_NAME, false, false)
	if label == null:
		label = Label.new()
		label.name = QUEUE_LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 11
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		button.add_child(label)
	label.visible = is_full or count > 0
	label.text = button.tr("PRODUCTION_QUEUE_FULL_SHORT") if is_full else "x{0}".format([count])
	label.add_theme_color_override(
		"font_color", QUEUE_FULL_COLOR if is_full else QUEUE_COLOR
	)
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -43
	label.offset_top = 2
	label.offset_right = -3
	label.offset_bottom = 18
	button.move_child(label, button.get_child_count() - 1)


static func _update_time_label(button, seconds):
	var label = button.find_child(TIME_LABEL_NAME, false, false)
	var time_text = _format_time_text(seconds)
	button.set_meta(META_TIME_TEXT, time_text)
	if label == null:
		label = Label.new()
		label.name = TIME_LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 10
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		button.add_child(label)
	label.visible = time_text != ""
	label.text = time_text
	label.add_theme_color_override("font_color", TIME_COLOR)
	label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	label.offset_left = -48
	label.offset_top = -38
	label.offset_right = -3
	label.offset_bottom = -21
	_sync_status_strip(button)
	button.move_child(label, button.get_child_count() - 1)


static func _format_time_text(seconds):
	if seconds == null or seconds <= 0.0:
		return ""
	if is_equal_approx(seconds, roundf(seconds)):
		return "{0}s".format([int(roundf(seconds))])
	return "{0}s".format([snappedf(seconds, 0.1)])


static func _update_lock_label(button, is_locked):
	var label = button.find_child(LOCK_LABEL_NAME, false, false)
	if label == null:
		label = Label.new()
		label.name = LOCK_LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 11
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", LOCK_COLOR)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		button.add_child(label)
	label.text = button.tr("COMMAND_TECH_LOCK_SHORT")
	label.visible = is_locked
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -43
	label.offset_top = 2
	label.offset_right = -3
	label.offset_bottom = 18
	button.move_child(label, button.get_child_count() - 1)
