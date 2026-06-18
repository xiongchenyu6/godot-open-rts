extends PanelContainer

const Human = preload("res://source/match/players/human/Human.gd")
const SupportPowerEffects = preload("res://source/match/support-powers/SupportPowerEffects.gd")
const SupportPowerIcons = preload("res://source/match/hud/SupportPowerIcons.gd")

const HOTKEY_LABEL_NAME = "HotkeyLabel"
const META_HOTKEY_DISPLAY = "support_power_hotkey_display"
const META_HOTKEY_KEYCODE = "support_power_hotkey_keycode"
const READY_BUTTON_MODULATE = Color(1.0, 1.0, 1.0, 1.0)
const LOCKED_BUTTON_MODULATE = Color(0.48, 0.56, 0.56, 0.74)
const READY_LABEL_COLOR = Color(0.98, 0.84, 0.42, 1.0)
const LOCKED_LABEL_COLOR = Color(1.0, 0.56, 0.24, 1.0)
const WEB_REFRESH_INTERVAL_SECONDS = 0.2
const POWER_IDS = [
	Constants.Match.SupportPowers.RADAR_SWEEP,
	Constants.Match.SupportPowers.ORBITAL_STRIKE,
	Constants.Match.SupportPowers.EMP_PULSE,
	Constants.Match.SupportPowers.CHRONO_RELAY,
	Constants.Match.SupportPowers.SHIELD_OVERDRIVE,
	Constants.Match.SupportPowers.NANITE_REPAIR_SWARM,
	Constants.Match.SupportPowers.WEATHER_STORM,
	Constants.Match.SupportPowers.STRATEGIC_MISSILE,
	Constants.Match.SupportPowers.PARADROP,
]
const POWER_HOTKEYS = {
	Constants.Match.SupportPowers.RADAR_SWEEP: {"display": "F1", "keycode": KEY_F1},
	Constants.Match.SupportPowers.ORBITAL_STRIKE: {"display": "F2", "keycode": KEY_F2},
	Constants.Match.SupportPowers.EMP_PULSE: {"display": "F3", "keycode": KEY_F3},
	Constants.Match.SupportPowers.CHRONO_RELAY: {"display": "F4", "keycode": KEY_F4},
	Constants.Match.SupportPowers.SHIELD_OVERDRIVE: {"display": "F5", "keycode": KEY_F5},
	Constants.Match.SupportPowers.NANITE_REPAIR_SWARM: {"display": "F6", "keycode": KEY_F6},
	Constants.Match.SupportPowers.WEATHER_STORM: {"display": "F7", "keycode": KEY_F7},
	Constants.Match.SupportPowers.STRATEGIC_MISSILE: {"display": "F8", "keycode": KEY_F8},
	Constants.Match.SupportPowers.PARADROP: {"display": "F9", "keycode": KEY_F9},
}

var _armed_power_id = ""
var _cooldown_ready_at = {}
var _ready_notification_pending = {}
var _initial_charge_started = {}
var _buttons = {}
var _cooldown_labels = {}
var _web_refresh_elapsed = WEB_REFRESH_INTERVAL_SECONDS

@onready var _match = find_parent("Match")


func _ready():
	_buttons = {
		Constants.Match.SupportPowers.RADAR_SWEEP: find_child("RadarSweepButton"),
		Constants.Match.SupportPowers.ORBITAL_STRIKE: find_child("OrbitalStrikeButton"),
		Constants.Match.SupportPowers.EMP_PULSE: find_child("EmpPulseButton"),
		Constants.Match.SupportPowers.CHRONO_RELAY: find_child("ChronoRelayButton"),
		Constants.Match.SupportPowers.SHIELD_OVERDRIVE: find_child("ShieldOverdriveButton"),
		Constants.Match.SupportPowers.NANITE_REPAIR_SWARM: find_child("NaniteRepairSwarmButton"),
		Constants.Match.SupportPowers.WEATHER_STORM: find_child("WeatherStormButton"),
		Constants.Match.SupportPowers.STRATEGIC_MISSILE: find_child("StrategicMissileButton"),
		Constants.Match.SupportPowers.PARADROP: find_child("ParadropButton"),
	}
	_cooldown_labels = {
		Constants.Match.SupportPowers.RADAR_SWEEP: find_child("RadarSweepCooldownLabel"),
		Constants.Match.SupportPowers.ORBITAL_STRIKE: find_child("OrbitalStrikeCooldownLabel"),
		Constants.Match.SupportPowers.EMP_PULSE: find_child("EmpPulseCooldownLabel"),
		Constants.Match.SupportPowers.CHRONO_RELAY: find_child("ChronoRelayCooldownLabel"),
		Constants.Match.SupportPowers.SHIELD_OVERDRIVE: find_child("ShieldOverdriveCooldownLabel"),
		Constants.Match.SupportPowers.NANITE_REPAIR_SWARM: find_child("NaniteRepairSwarmCooldownLabel"),
		Constants.Match.SupportPowers.WEATHER_STORM: find_child("WeatherStormCooldownLabel"),
		Constants.Match.SupportPowers.STRATEGIC_MISSILE: find_child("StrategicMissileCooldownLabel"),
		Constants.Match.SupportPowers.PARADROP: find_child("ParadropCooldownLabel"),
	}
	for power_id in POWER_IDS:
		_cooldown_ready_at[power_id] = 0.0
		_ready_notification_pending[power_id] = false
		_initial_charge_started[power_id] = false
		SupportPowerIcons.apply(_buttons[power_id], power_id)
		_assign_hotkey(power_id)
	MatchSignals.unit_spawned.connect(func(_unit): refresh())
	MatchSignals.unit_construction_finished.connect(func(_unit): refresh())
	MatchSignals.unit_died.connect(func(_unit): refresh())
	MatchSignals.unit_sold.connect(func(_unit): refresh())
	MatchSignals.minimap_terrain_targeted.connect(_on_minimap_terrain_targeted)
	refresh()


func _process(delta):
	if OS.has_feature("web"):
		_web_refresh_elapsed += delta
		if _web_refresh_elapsed < WEB_REFRESH_INTERVAL_SECONDS:
			return
		_web_refresh_elapsed = 0.0
	refresh()


func _input(event):
	if _armed_power_id == "":
		return
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		var target_position = _screen_to_ground_position(event.position)
		if target_position != null:
			activate_power_at(_armed_power_id, target_position)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_LEFT:
		var button_rect = Rect2(global_position, size)
		if not button_rect.has_point(event.position):
			_disarm_power()


func _unhandled_key_input(event):
	if _try_activate_hotkey(event):
		get_viewport().set_input_as_handled()


func refresh():
	var player = _get_human_player()
	var has_player = player != null
	for power_id in POWER_IDS:
		_ensure_initial_charge_state(player, power_id)
		var button = _buttons[power_id]
		var cooldown_label = _cooldown_labels[power_id]
		SupportPowerIcons.ensure(button)
		var unlocked = _is_unlocked(player, power_id)
		var cooldown_remaining = get_cooldown_remaining(power_id)
		_refresh_button_state(button, cooldown_label, power_id, has_player, unlocked, cooldown_remaining)
		_emit_ready_notification_if_needed(player, power_id)
	visible = has_player


func _refresh_button_state(button, cooldown_label, power_id, has_player, unlocked, cooldown_remaining):
	button.visible = has_player
	cooldown_label.visible = has_player
	button.disabled = not can_activate(power_id)
	button.set_pressed_no_signal(_armed_power_id == power_id)
	button.tooltip_text = _build_tooltip(power_id)
	button.modulate = READY_BUTTON_MODULATE if unlocked else LOCKED_BUTTON_MODULATE
	if not has_player:
		cooldown_label.text = ""
		return
	if not unlocked:
		cooldown_label.text = tr("COMMAND_TECH_LOCK_SHORT")
		cooldown_label.add_theme_color_override("font_color", LOCKED_LABEL_COLOR)
		return
	cooldown_label.add_theme_color_override("font_color", READY_LABEL_COLOR)
	cooldown_label.text = str(ceili(cooldown_remaining)) if cooldown_remaining > 0.0 else ""


func can_activate(power_id):
	var player = _get_human_player()
	if player == null:
		return false
	_ensure_initial_charge_state(player, power_id)
	if not _is_unlocked(player, power_id):
		return false
	if _definition(power_id).get("requires_power", false) and player.is_low_power():
		return false
	return get_cooldown_remaining(power_id) <= 0.0


func get_cooldown_remaining(power_id):
	return maxf(0.0, _cooldown_ready_at.get(power_id, 0.0) - _now())


func reset_cooldowns():
	for power_id in POWER_IDS:
		_cooldown_ready_at[power_id] = 0.0
		_ready_notification_pending[power_id] = false
		_initial_charge_started[power_id] = true
	refresh()


func arm_power(power_id):
	if not can_activate(power_id):
		_disarm_power()
		return false
	if _armed_power_id == power_id:
		return true
	_disarm_power()
	_armed_power_id = power_id
	MatchSignals.support_power_targeting_started.emit(power_id)
	refresh()
	return true


func _try_activate_hotkey(event):
	if not visible:
		return false
	if not event is InputEventKey:
		return false
	if not event.pressed or event.echo:
		return false
	if event.alt_pressed or event.ctrl_pressed or event.meta_pressed:
		return false
	var keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	for power_id in POWER_IDS:
		var button = _buttons[power_id]
		if button.get_meta(META_HOTKEY_KEYCODE, -1) != keycode:
			continue
		if button.disabled:
			return false
		if _armed_power_id == power_id:
			_disarm_power()
			return true
		return arm_power(power_id)
	return false


func activate_power_at(power_id, target_position):
	if not can_activate(power_id):
		_disarm_power()
		return false
	var player = _get_human_player()
	var definition = _definition(power_id)
	if not SupportPowerEffects.activate(_match, power_id, player, target_position):
		return false
	_cooldown_ready_at[power_id] = _now() + definition["cooldown"]
	_ready_notification_pending[power_id] = true
	MatchSignals.support_power_activated.emit(power_id, player, target_position)
	_disarm_power()
	refresh()
	return true


func _definition(power_id):
	return Constants.Match.SupportPowers.DEFINITIONS[power_id]


func _missing_requirements(player, power_id):
	var missing_requirements = []
	for requirement_path in _definition(power_id)["requirements"]:
		if not Utils.Match.Unit.Tech.player_has_constructed_structure(player, requirement_path):
			missing_requirements.append(requirement_path)
	return missing_requirements


func _is_unlocked(player, power_id):
	return player != null and _missing_requirements(player, power_id).is_empty()


func _ensure_initial_charge_state(player, power_id):
	if player == null:
		return
	if not _missing_requirements(player, power_id).is_empty():
		_initial_charge_started[power_id] = false
		_ready_notification_pending[power_id] = false
		return
	if _initial_charge_started.get(power_id, false):
		return
	_initial_charge_started[power_id] = true
	var initial_cooldown = _definition(power_id).get("initial_cooldown", 0.0)
	if initial_cooldown <= 0.0:
		return
	if _cooldown_ready_at.get(power_id, 0.0) <= _now():
		_cooldown_ready_at[power_id] = _now() + initial_cooldown
		_ready_notification_pending[power_id] = true
		MatchSignals.support_power_charging.emit(power_id, player, initial_cooldown)


func _emit_ready_notification_if_needed(player, power_id):
	if not _ready_notification_pending.get(power_id, false):
		return
	if not can_activate(power_id):
		return
	_ready_notification_pending[power_id] = false
	MatchSignals.support_power_ready.emit(power_id, player)


func _build_tooltip(power_id):
	var definition = _definition(power_id)
	var text = "{0} - {1}".format([tr(definition["name_key"]), tr(definition["description_key"])])
	if POWER_HOTKEYS.has(power_id):
		text += "\n{0}: {1}".format([tr("COMMAND_HOTKEY"), POWER_HOTKEYS[power_id]["display"]])
	text += "\n{0}: {1}s".format([tr("COOLDOWN"), definition["cooldown"]])
	text += "\n{0}: {1}".format(
		[tr("REQUIRES"), Utils.Match.Unit.Tech.requirement_names(definition["requirements"])]
	)
	if definition.has("radius"):
		text += "\n{0}: {1}".format([tr("RADIUS"), definition["radius"]])
	if definition.has("damage"):
		text += ", {0}: {1}".format([tr("DAMAGE"), definition["damage"]])
	if definition.has("impact_delay"):
		text += ", {0}: {1}s".format([tr("IMPACT_DELAY"), definition["impact_delay"]])
	if definition.has("healing"):
		text += ", {0}: {1}".format([tr("HEALING"), definition["healing"]])
	if definition.has("speed_multiplier"):
		text += ", {0}: {1}%".format(
			[tr("SPEED"), roundi(definition["speed_multiplier"] * 100.0)]
		)
	if definition.has("damage_multiplier"):
		text += ", {0}: {1}%".format(
			[tr("DAMAGE_TAKEN"), roundi(definition["damage_multiplier"] * 100.0)]
		)
	if definition.has("duration"):
		text += ", {0}: {1}s".format([tr("DURATION"), definition["duration"]])
	var player = _get_human_player()
	if player != null:
		var missing_requirements = _missing_requirements(player, power_id)
		if not missing_requirements.is_empty():
			text += "\n{0}: {1}".format(
				[tr("MISSING_TECH"), Utils.Match.Unit.Tech.requirement_names(missing_requirements)]
			)
		elif definition.get("requires_power", false) and player.is_low_power():
			text += "\n{0}".format([tr("SUPPORT_POWER_LOW_POWER")])
		elif get_cooldown_remaining(power_id) > 0.0:
			text += "\n{0}: {1}s".format([tr("COOLDOWN"), ceili(get_cooldown_remaining(power_id))])
		elif _armed_power_id == power_id:
			text += "\n{0}".format([tr("SUPPORT_POWER_TARGETING")])
		else:
			text += "\n{0}".format([tr("SUPPORT_POWER_READY")])
	return text


func _assign_hotkey(power_id):
	var button = _buttons[power_id]
	var hotkey = POWER_HOTKEYS[power_id]
	button.set_meta(META_HOTKEY_DISPLAY, hotkey["display"])
	button.set_meta(META_HOTKEY_KEYCODE, hotkey["keycode"])
	_ensure_hotkey_label(button, hotkey["display"])


func _ensure_hotkey_label(button, display):
	var label = button.find_child(HOTKEY_LABEL_NAME, false, false)
	if label == null:
		label = Label.new()
		label.name = HOTKEY_LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 10
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.78, 0.96, 0.92, 1.0))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.add_theme_font_size_override("font_size", 11)
		button.add_child(label)
	label.text = display
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.offset_left = 3
	label.offset_top = 2
	label.offset_right = 29
	label.offset_bottom = 18
	button.move_child(label, button.get_child_count() - 1)


func _screen_to_ground_position(screen_position):
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return null
	return camera.get_ray_intersection(screen_position)


func _get_human_player():
	if _match != null and "visible_player" in _match and _match.visible_player is Human:
		return _match.visible_player
	for player in get_tree().get_nodes_in_group("players"):
		if player is Human:
			return player
	return null


func _disarm_power():
	if _armed_power_id == "":
		return
	var power_id = _armed_power_id
	_armed_power_id = ""
	MatchSignals.support_power_targeting_finished.emit(power_id)
	refresh()


func _now():
	return Time.get_ticks_msec() / 1000.0


func _on_minimap_terrain_targeted(target_position):
	if _armed_power_id == "":
		return
	activate_power_at(_armed_power_id, target_position)


func _on_radar_sweep_button_toggled(button_pressed):
	if button_pressed:
		arm_power(Constants.Match.SupportPowers.RADAR_SWEEP)
	else:
		_disarm_power()


func _on_orbital_strike_button_toggled(button_pressed):
	if button_pressed:
		arm_power(Constants.Match.SupportPowers.ORBITAL_STRIKE)
	else:
		_disarm_power()


func _on_emp_pulse_button_toggled(button_pressed):
	if button_pressed:
		arm_power(Constants.Match.SupportPowers.EMP_PULSE)
	else:
		_disarm_power()


func _on_chrono_relay_button_toggled(button_pressed):
	if button_pressed:
		arm_power(Constants.Match.SupportPowers.CHRONO_RELAY)
	else:
		_disarm_power()


func _on_shield_overdrive_button_toggled(button_pressed):
	if button_pressed:
		arm_power(Constants.Match.SupportPowers.SHIELD_OVERDRIVE)
	else:
		_disarm_power()


func _on_nanite_repair_swarm_button_toggled(button_pressed):
	if button_pressed:
		arm_power(Constants.Match.SupportPowers.NANITE_REPAIR_SWARM)
	else:
		_disarm_power()


func _on_weather_storm_button_toggled(button_pressed):
	if button_pressed:
		arm_power(Constants.Match.SupportPowers.WEATHER_STORM)
	else:
		_disarm_power()


func _on_strategic_missile_button_toggled(button_pressed):
	if button_pressed:
		arm_power(Constants.Match.SupportPowers.STRATEGIC_MISSILE)
	else:
		_disarm_power()


func _on_paradrop_button_toggled(button_pressed):
	if button_pressed:
		arm_power(Constants.Match.SupportPowers.PARADROP)
	else:
		_disarm_power()
