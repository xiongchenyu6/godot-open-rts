extends RefCounted

const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const CommandButtonStatus = preload("res://source/match/hud/unit-menus/CommandButtonStatus.gd")
const ProductionMenuActions = preload("res://source/match/hud/unit-menus/ProductionMenuActions.gd")

const LONG_RANGE_THRESHOLD = 7.0
const SIEGE_RANGE_THRESHOLD = 8.0
const SCOUT_SIGHT_THRESHOLD = 11.0
const HEAVY_HP_THRESHOLD = 14.0


static func apply(
	button,
	unit_scene,
	name_key,
	description_key,
	missing_requirements = [],
	player = null,
	production_queue = null,
	production_queues = []
):
	if button == null or unit_scene == null:
		return
	var unit_scene_path = unit_scene.resource_path
	var properties = Constants.Match.Units.DEFAULT_PROPERTIES[unit_scene_path]
	var costs = Constants.Match.Units.PRODUCTION_COSTS[unit_scene_path]
	var time = Constants.Match.Units.PRODUCTION_TIMES[unit_scene_path]
	var tooltip_text = "{0} - {1}".format([button.tr(name_key), button.tr(description_key)])
	var roles = _role_labels(button, unit_scene_path, properties)
	if not roles.is_empty():
		tooltip_text += "\n{0}: {1}".format([button.tr("PRODUCTION_ROLES"), " / ".join(roles)])
	tooltip_text += "\n{0}: {1}".format(
		[button.tr("PRODUCTION_USE"), _usage_hint(button, unit_scene_path, properties)]
	)
	tooltip_text += "\n{0}: {1}, {2}s".format(
		[button.tr("PRODUCTION_STATS"), _stats_text(button, properties), _format_number(time)]
	)
	tooltip_text += "\n{0}: {1}, {2}: {3}".format(
		[
			button.tr("RESOURCE_A"),
			costs["resource_a"],
			button.tr("RESOURCE_B"),
			costs["resource_b"]
		]
	)
	tooltip_text += _format_production_requirements(button, unit_scene_path, missing_requirements)
	tooltip_text += CommandButtonStatus.production_queue_full_tooltip(button, production_queue, production_queues)
	tooltip_text += ProductionMenuActions.batch_tooltip(button)
	button.tooltip_text = CommandButtonHotkeys.tooltip(button, tooltip_text)
	CommandButtonStatus.apply_production(
		button,
		unit_scene,
		missing_requirements,
		player,
		production_queue,
		production_queues,
		name_key
	)


static func is_queue_full(production_queue):
	if production_queue == null:
		return false
	if production_queue is Array:
		if production_queue.is_empty():
			return false
		for queue in production_queue:
			if queue.size() < Constants.Match.Units.PRODUCTION_QUEUE_LIMIT:
				return false
		return true
	return production_queue.size() >= Constants.Match.Units.PRODUCTION_QUEUE_LIMIT


static func _stats_text(button, properties):
	var stats = ["{0} HP".format([properties["hp_max"]])]
	if properties.has("attack_damage"):
		var dps = float(properties["attack_damage"]) / float(properties["attack_interval"])
		stats.append(
			"{0} {1}, {2} {3}".format(
				[
					_format_number(dps),
					button.tr("DPS"),
					_format_number(properties["attack_range"]),
					button.tr("SELECTION_RANGE")
				]
			)
		)
	if properties.has("sight_range"):
		stats.append(
			"{0} {1}".format(
				[button.tr("SELECTION_SIGHT"), _format_number(properties["sight_range"])]
			)
		)
	if properties.has("repair_rate"):
		stats.append(
			"{0} {1}".format([_format_number(properties["repair_rate"]), button.tr("REPAIR_RATE")])
		)
	if properties.has("capture_time"):
		stats.append(
			"{0} {1}s".format([button.tr("CAPTURE"), _format_number(properties["capture_time"])])
		)
	if properties.get("splash_radius", 0.0) > 0.0:
		stats.append(
			"{0} {1}".format(
				[button.tr("SPLASH_RADIUS"), _format_number(properties["splash_radius"])]
			)
		)
	if properties.has("structure_damage_multiplier"):
		stats.append(
			"{0} x{1}".format(
				[
					button.tr("STRUCTURE_DAMAGE"),
					_format_number(properties["structure_damage_multiplier"])
				]
			)
		)
	if properties.has("support_shield_radius"):
		stats.append(
			"{0} {1}, {2}% {3}".format(
				[
					button.tr("SHIELD_RADIUS"),
					_format_number(properties["support_shield_radius"]),
					int(properties["support_shield_damage_multiplier"] * 100.0),
					button.tr("DAMAGE_TAKEN")
				]
			)
		)
	if properties.has("resources_max"):
		stats.append(
			"{0} {1}".format([properties["resources_max"], button.tr("RESOURCE_CAPACITY")])
		)
	if properties.has("mine_damage"):
		stats.append(
			"{0} {1}, {2} {3}, {4}s {5}".format(
				[
					properties["mine_damage"],
					button.tr("DAMAGE"),
					properties.get("mine_limit", 1),
					button.tr("MINE_LIMIT"),
					_format_number(properties.get("mine_deploy_interval", 0.0)),
					button.tr("COOLDOWN")
				]
			)
		)
	if properties.has("infiltration_resource_steal_ratio"):
		stats.append(
			"{0}% {1} ({2} {3})".format(
				[
					roundi(properties["infiltration_resource_steal_ratio"] * 100.0),
					button.tr("RESOURCE_STEAL"),
					button.tr("RESOURCE_CAP"),
					properties["infiltration_resource_steal_cap"]
				]
			)
		)
	return ", ".join(stats)


static func _role_labels(button, unit_scene_path, properties):
	var role_keys = []
	_add_role(role_keys, _domain_role_key(unit_scene_path))
	if properties.has("resources_max"):
		_add_role(role_keys, "ROLE_ECONOMY")
	if unit_scene_path.contains("MobileConstructionVehicle"):
		_add_role(role_keys, "ROLE_BASE_EXPANSION")
	if properties.has("repair_rate"):
		_add_role(role_keys, "ROLE_REPAIR")
	if properties.has("capture_time"):
		_add_role(role_keys, "ROLE_CAPTURE")
	if properties.has("support_shield_radius"):
		_add_role(role_keys, "ROLE_SHIELD_SUPPORT")
	if properties.has("mine_damage"):
		_add_role(role_keys, "ROLE_AREA_DENIAL")
	if _is_scout(unit_scene_path, properties):
		_add_role(role_keys, "ROLE_SCOUT")
	if _attacks_terrain(properties):
		_add_role(role_keys, "ROLE_ANTI_GROUND")
	if _attacks_air(properties):
		_add_role(role_keys, "ROLE_ANTI_AIR")
	if properties.get("splash_radius", 0.0) > 0.0:
		_add_role(role_keys, "ROLE_AREA_DAMAGE")
	if properties.get("attack_range", 0.0) >= LONG_RANGE_THRESHOLD:
		_add_role(role_keys, "ROLE_LONG_RANGE")
	if _is_siege(properties):
		_add_role(role_keys, "ROLE_SIEGE")
	if properties.get("structure_damage_multiplier", 1.0) > 1.1:
		_add_role(role_keys, "ROLE_STRUCTURE_BREAKER")
	if properties.get("hp_max", 0.0) >= HEAVY_HP_THRESHOLD:
		_add_role(role_keys, "ROLE_HEAVY_ARMOR")
	return role_keys.map(func(role_key): return button.tr(role_key))


static func _usage_hint(button, unit_scene_path, properties):
	if unit_scene_path.contains("MobileConstructionVehicle"):
		return button.tr("TACTIC_BASE_EXPANSION")
	if properties.has("resources_max"):
		return button.tr("TACTIC_ECONOMY")
	if properties.has("support_shield_radius"):
		return button.tr("TACTIC_SHIELD_SUPPORT")
	if properties.has("mine_damage"):
		return button.tr("TACTIC_AREA_DENIAL")
	if properties.has("repair_rate") and properties.has("capture_time"):
		return button.tr("TACTIC_REPAIR_CAPTURE")
	if properties.has("repair_rate"):
		return button.tr("TACTIC_REPAIR")
	if properties.has("capture_time") or properties.has("infiltration_resource_steal_ratio"):
		return button.tr("TACTIC_INFILTRATION")
	if _is_siege(properties):
		return button.tr("TACTIC_SIEGE")
	if properties.get("structure_damage_multiplier", 1.0) > 1.1:
		return button.tr("TACTIC_STRUCTURE_BREAKER")
	if _attacks_air(properties) and not _attacks_terrain(properties):
		return button.tr("TACTIC_ANTI_AIR")
	if _attacks_air(properties) and _attacks_terrain(properties):
		return button.tr("TACTIC_FLEX_COMBAT")
	if properties.get("splash_radius", 0.0) > 0.0:
		return button.tr("TACTIC_AREA_DAMAGE")
	if _is_scout(unit_scene_path, properties):
		return button.tr("TACTIC_SCOUT")
	if properties.has("attack_damage"):
		return button.tr("TACTIC_LINE_COMBAT")
	return button.tr("TACTIC_UTILITY")


static func _format_production_requirements(button, unit_scene_path, missing_requirements):
	var requirements = Constants.Match.Units.PRODUCTION_REQUIREMENTS.get(unit_scene_path, [])
	if requirements.is_empty():
		return ""
	var text = "\n{0}: {1}".format(
		[button.tr("REQUIRES"), Utils.Match.Unit.Tech.requirement_names(requirements)]
	)
	if not missing_requirements.is_empty():
		text += "\n{0}: {1}".format(
			[button.tr("MISSING_TECH"), Utils.Match.Unit.Tech.requirement_names(missing_requirements)]
		)
	return text


static func _domain_role_key(unit_scene_path):
	if (
		unit_scene_path.contains("VTOL")
		or unit_scene_path.contains("Airship")
		or unit_scene_path.contains("Gunship")
		or unit_scene_path.contains("Helicopter")
		or unit_scene_path.ends_with("/Drone.tscn")
	):
		return "ROLE_AIR"
	if (
		unit_scene_path.contains("Infantry")
		or unit_scene_path.contains("Trooper")
		or unit_scene_path.contains("Team")
		or unit_scene_path.contains("Saboteur")
		or unit_scene_path.contains("Commando")
		or unit_scene_path.contains("Officer")
		or unit_scene_path.contains("Medic")
		or unit_scene_path.contains("Sprayer")
	):
		return "ROLE_INFANTRY"
	return "ROLE_VEHICLE"


static func _attacks_terrain(properties):
	return properties.get("attack_domains", []).has(Constants.Match.Navigation.Domain.TERRAIN)


static func _attacks_air(properties):
	return properties.get("attack_domains", []).has(Constants.Match.Navigation.Domain.AIR)


static func _is_scout(unit_scene_path, properties):
	return (
		unit_scene_path.contains("Scout")
		or unit_scene_path.contains("Radar")
		or properties.get("sight_range", 0.0) >= SCOUT_SIGHT_THRESHOLD
	)


static func _is_siege(properties):
	return (
		properties.get("attack_range", 0.0) >= SIEGE_RANGE_THRESHOLD
		and (
			properties.get("splash_radius", 0.0) > 0.0
			or properties.get("structure_damage_multiplier", 1.0) > 1.1
		)
	)


static func _add_role(role_keys, role_key):
	if role_key != "" and not role_keys.has(role_key):
		role_keys.append(role_key)


static func _format_number(value):
	if is_equal_approx(float(value), round(value)):
		return str(int(round(value)))
	return str(snappedf(float(value), 0.1))
