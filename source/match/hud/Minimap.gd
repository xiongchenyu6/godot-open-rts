extends PanelContainer

const Unit = preload("res://source/match/units/Unit.gd")
const RadarUplink = preload("res://source/match/units/RadarUplink.gd")
const Moving = preload("res://source/match/units/actions/Moving.gd")
const CommandButtonIcons = preload("res://source/match/hud/unit-menus/CommandButtonIcons.gd")

const RADAR_UPLINK_SCENE_PATH = "res://source/match/units/RadarUplink.tscn"
const GROUND_LEVEL_PLANE = Plane(Vector3.UP, 0)
const MINIMAP_PIXELS_PER_WORLD_METER = 2
const BATTLE_EVENT_PING_LIFETIME_SECONDS = 4.0
const BATTLE_EVENT_PING_RADIUS_MIN = 5.0
const BATTLE_EVENT_PING_RADIUS_MAX = 18.0
const BATTLE_EVENT_PING_WIDTH = 2.0
const BATTLE_EVENT_PING_COLOR = Color(1.0, 0.32, 0.16, 1.0)
const SUPPORT_POWER_PING_COLOR = Color(0.25, 0.9, 1.0, 1.0)
const ENEMY_SUPPORT_POWER_PING_COLOR = Color(1.0, 0.68, 0.15, 1.0)
const ENEMY_SUPERWEAPON_PING_COLOR = Color(1.0, 0.06, 0.04, 1.0)
const SUPPORT_POWER_PING_RADIUS_MAX = 21.0
const ENEMY_SUPPORT_POWER_PING_RADIUS_MAX = 24.0
const ENEMY_SUPERWEAPON_PING_RADIUS_MAX = 32.0
const WEB_MINIMAP_SYNC_INTERVAL_SECONDS = 0.15

var _unit_to_corresponding_node_mapping = {}
var _battle_event_pings = []
var _camera_movement_active = false
var _radar_online = false
var _radar_offline_reason_key = "RADAR_REQUIRES_UPLINK"
var _offline_icon = null
var _minimap_sync_elapsed = WEB_MINIMAP_SYNC_INTERVAL_SECONDS

@onready var _match = find_parent("Match")
@onready var _camera_indicator = find_child("CameraIndicator")
@onready var _viewport_background = find_child("Background")
@onready var _texture_rect = find_child("MinimapTextureRect")
@onready var _offline_overlay = find_child("RadarOfflineOverlay")
@onready var _offline_label = find_child("RadarOfflineLabel")


func _ready():
	if not FeatureFlags.show_minimap:
		queue_free()
		return
	_remove_dummy_nodes()
	if _match != null:
		await _match.ready  # make sure Match is ready as it may change map on setup
	else:
		await get_tree().process_frame
	find_child("MinimapViewport").size = (
		_minimap_map_size() * MINIMAP_PIXELS_PER_WORLD_METER
	)
	_texture_rect.texture = find_child("MinimapViewport").get_texture()
	_apply_fog_mask_texture()
	_texture_rect.gui_input.connect(_on_gui_input)
	MatchSignals.battle_event_ping_requested.connect(_on_battle_event_ping_requested)
	_setup_radar_offline_art()
	_update_radar_state(true)


func _process(_delta):
	_update_battle_event_pings()


func _physics_process(delta):
	if _match != null and not _match.is_node_ready():
		return
	if OS.has_feature("web"):
		_minimap_sync_elapsed += delta
		if _minimap_sync_elapsed < WEB_MINIMAP_SYNC_INTERVAL_SECONDS:
			return
		_minimap_sync_elapsed = 0.0
	_update_radar_state()
	if not _radar_online:
		_clear_mapped_units()
		return
	_sync_real_units_with_minimap_representations()
	_update_camera_indicator()


func is_radar_online():
	return _radar_online


func get_radar_offline_reason_key():
	return _radar_offline_reason_key


func get_battle_event_ping_count():
	return _battle_event_pings.size()


func get_latest_battle_event_ping_type():
	if _battle_event_pings.is_empty():
		return ""
	return _battle_event_pings.back()["event_type"]


func get_latest_battle_event_ping_width():
	if _battle_event_pings.is_empty():
		return 0.0
	return _battle_event_pings.back()["node"].width


func _remove_dummy_nodes():
	for dummy_node in find_children("EditorOnlyDummy*"):
		dummy_node.queue_free()


func _apply_fog_mask_texture():
	var fog_mask = find_child("FogOfWarMask", true, false)
	if fog_mask == null or fog_mask.material == null:
		return
	if _match == null or _match.fog_of_war == null:
		return
	fog_mask.material.set_shader_parameter(
		"reference_texture", _match.fog_of_war.get_visibility_texture()
	)


func _sync_real_units_with_minimap_representations():
	var units_synced = {}
	var units_to_sync = (
		get_tree().get_nodes_in_group("units") + get_tree().get_nodes_in_group("resource_units")
	)
	for unit in units_to_sync:
		if not unit.visible:
			continue
		units_synced[unit] = 1
		if not _unit_is_mapped(unit):
			_map_unit(unit)
		_sync_unit(unit)
	for mapped_unit in _unit_to_corresponding_node_mapping.keys():
		if not mapped_unit in units_synced:
			_cleanup_mapping(mapped_unit)


func _unit_is_mapped(unit):
	return unit in _unit_to_corresponding_node_mapping


func _map_unit(unit):
	var node_representing_unit = ColorRect.new()
	node_representing_unit.size = Vector2(3, 3)
	if not unit is Unit:
		node_representing_unit.rotation_degrees = 45
	_viewport_background.add_sibling(node_representing_unit)
	node_representing_unit.pivot_offset = node_representing_unit.size / 2.0
	_unit_to_corresponding_node_mapping[unit] = node_representing_unit


func _sync_unit(unit):
	var unit_pos_3d = unit.global_transform.origin
	var unit_pos_2d = _world_position_to_minimap_position(unit_pos_3d)
	_unit_to_corresponding_node_mapping[unit].position = unit_pos_2d
	_unit_to_corresponding_node_mapping[unit].color = _unit_marker_color(unit)


func _unit_marker_color(unit):
	if unit is Unit:
		return unit.player.color
	if "color" in unit:
		return unit.color
	return Constants.Match.DEFAULT_CIRCLE_COLOR


func _cleanup_mapping(unit):
	if not unit in _unit_to_corresponding_node_mapping:
		return
	if is_instance_valid(_unit_to_corresponding_node_mapping[unit]):
		_unit_to_corresponding_node_mapping[unit].queue_free()
	_unit_to_corresponding_node_mapping.erase(unit)


func _clear_mapped_units():
	for minimap_node in _unit_to_corresponding_node_mapping.values():
		if is_instance_valid(minimap_node):
			minimap_node.queue_free()
	_unit_to_corresponding_node_mapping.clear()


func _setup_radar_offline_art():
	if _texture_rect == null:
		return
	if _offline_overlay != null:
		_offline_overlay.z_index = 1
	_offline_icon = _texture_rect.find_child("RadarOfflineIcon", false, false)
	if _offline_icon == null:
		_offline_icon = TextureRect.new()
		_offline_icon.name = "RadarOfflineIcon"
		_texture_rect.add_child(_offline_icon)
	_offline_icon.texture = CommandButtonIcons.texture_for_scene(RADAR_UPLINK_SCENE_PATH)
	_offline_icon.visible = false
	_offline_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_offline_icon.z_index = 2
	_offline_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_offline_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_offline_icon.set_anchors_preset(Control.PRESET_CENTER)
	_offline_icon.offset_left = -38.0
	_offline_icon.offset_top = -62.0
	_offline_icon.offset_right = 38.0
	_offline_icon.offset_bottom = 14.0
	if _offline_label != null:
		_offline_label.z_index = 3
		_offline_label.set_anchors_preset(Control.PRESET_CENTER)
		_offline_label.offset_left = -92.0
		_offline_label.offset_top = 18.0
		_offline_label.offset_right = 92.0
		_offline_label.offset_bottom = 44.0


func _update_radar_state(force_update = false):
	var player = _get_minimap_player()
	var radar_online = false
	var offline_reason_key = "RADAR_REQUIRES_UPLINK"
	if player == null:
		offline_reason_key = "RADAR_OFFLINE"
	elif not _has_constructed_radar_uplink(player):
		offline_reason_key = "RADAR_REQUIRES_UPLINK"
	elif player.is_low_power():
		offline_reason_key = "RADAR_LOW_POWER"
	else:
		radar_online = true
		offline_reason_key = ""
	_set_radar_state(radar_online, offline_reason_key, force_update)


func _get_minimap_player():
	if _match != null and "visible_player" in _match and _match.visible_player != null:
		return _match.visible_player
	var controlled_units = get_tree().get_nodes_in_group("controlled_units")
	if not controlled_units.is_empty():
		return controlled_units[0].player
	var players = get_tree().get_nodes_in_group("players")
	if not players.is_empty():
		return players[0]
	return null


func _minimap_map_size():
	if _match != null:
		var map = _match.find_child("Map")
		if map != null and "size" in map:
			return map.size
	var map = find_parent("Match").find_child("Map") if find_parent("Match") != null else null
	if map != null and "size" in map:
		return map.size
	return Vector2(100, 100)


func _has_constructed_radar_uplink(player):
	for unit in get_tree().get_nodes_in_group("units"):
		if (
			unit is RadarUplink
			and unit.player == player
			and unit.is_constructed()
			and (unit.hp == null or unit.hp > 0)
		):
			return true
	return false


func _set_radar_state(radar_online, offline_reason_key, force_update):
	if (
		not force_update
		and _radar_online == radar_online
		and _radar_offline_reason_key == offline_reason_key
	):
		return
	_radar_online = radar_online
	_radar_offline_reason_key = offline_reason_key
	_camera_movement_active = false if not _radar_online else _camera_movement_active
	_camera_indicator.visible = _radar_online
	_texture_rect.modulate = Color.WHITE if _radar_online else Color(0.55, 0.65, 0.65, 1.0)
	if _offline_overlay != null:
		_offline_overlay.visible = not _radar_online
	if _offline_icon != null:
		_offline_icon.visible = not _radar_online
	if _offline_label != null:
		_offline_label.visible = not _radar_online
		if not _radar_online:
			_offline_label.text = tr(_radar_offline_reason_key)
	if not _radar_online:
		_clear_mapped_units()
		_clear_battle_event_pings()


func _update_camera_indicator():
	var viewport = get_viewport()
	var camera = viewport.get_camera_3d()
	var camera_corners = [
		Vector2.ZERO,
		Vector2(0, viewport.size.y),
		viewport.size,
		Vector2(viewport.size.x, 0),
		Vector2.ZERO
	]
	for index in range(camera_corners.size()):
		var corner_mapped_to_3d_position_on_ground_level = (
			GROUND_LEVEL_PLANE.intersects_ray(
				camera.project_ray_origin(camera_corners[index]),
				camera.project_ray_normal(camera_corners[index])
			)
			* MINIMAP_PIXELS_PER_WORLD_METER
		)
		_camera_indicator.set_point_position(
			index,
			Vector2(
				corner_mapped_to_3d_position_on_ground_level.x,
				corner_mapped_to_3d_position_on_ground_level.z
			)
		)


func _texture_rect_position_to_world_position(position_2d_within_texture_rect):
	assert(
		_texture_rect.stretch_mode == _texture_rect.STRETCH_KEEP_ASPECT_CENTERED,
		"world 3d position retrieval algorithm assumes 'STRETCH_KEEP_ASPECT_CENTERED'"
	)
	var texture_rect_size = _texture_rect.size
	var texture_size = _texture_rect.texture.get_size()
	var proportions = texture_rect_size / texture_size
	var scaling_factor = proportions.x if proportions.x < proportions.y else proportions.y
	var scaled_texture_size = texture_size * scaling_factor
	var scaled_texture_position_within_texture_rect = (
		(texture_rect_size - scaled_texture_size) / 2.0
	)
	var rect_containing_scaled_texture = Rect2(
		scaled_texture_position_within_texture_rect, scaled_texture_size
	)
	if rect_containing_scaled_texture.has_point(position_2d_within_texture_rect):
		var position_2d_within_minimap = (
			(position_2d_within_texture_rect - rect_containing_scaled_texture.position)
			/ scaling_factor
		)
		return position_2d_within_minimap / MINIMAP_PIXELS_PER_WORLD_METER
	return null


func _try_teleporting_camera_based_on_local_texture_rect_position(position_2d_within_texture_rect):
	var world_position_3d = _texture_rect_position_to_world_position_3d(
		position_2d_within_texture_rect
	)
	if world_position_3d == null:
		return
	get_viewport().get_camera_3d().set_position_safely(world_position_3d)


func _issue_movement_action(position_2d_within_texture_rect):
	var world_position_3d = _texture_rect_position_to_world_position_3d(
		position_2d_within_texture_rect
	)
	if world_position_3d == null:
		return
	MatchSignals.minimap_terrain_targeted.emit(world_position_3d)
	MatchSignals.terrain_targeted.emit(world_position_3d)


func _texture_rect_position_to_world_position_3d(position_2d_within_texture_rect):
	var world_position_2d = _texture_rect_position_to_world_position(
		position_2d_within_texture_rect
	)
	if world_position_2d == null:
		return null
	return Vector3(world_position_2d.x, 0, world_position_2d.y)


func _world_position_to_minimap_position(world_position):
	return Vector2(world_position.x, world_position.z) * MINIMAP_PIXELS_PER_WORLD_METER


func _on_battle_event_ping_requested(position, event_type):
	if not _radar_online:
		return
	if not position is Vector3:
		return
	var ping = Line2D.new()
	ping.closed = true
	var style = _battle_event_ping_style(event_type)
	ping.width = style["width"]
	ping.default_color = style["color"]
	ping.z_index = 20
	_viewport_background.add_sibling(ping)
	var ping_state = {
		"node": ping,
		"event_type": _battle_event_ping_type(event_type),
		"position": _world_position_to_minimap_position(position),
		"started_at": _get_current_time_seconds()
	}
	_battle_event_pings.append(ping_state)
	_sync_battle_event_ping(ping_state, 0.0)


func _update_battle_event_pings():
	if _battle_event_pings.is_empty():
		return
	if not _radar_online:
		_clear_battle_event_pings()
		return
	var current_time = _get_current_time_seconds()
	for index in range(_battle_event_pings.size() - 1, -1, -1):
		var ping_state = _battle_event_pings[index]
		var ping_node = ping_state["node"]
		if not is_instance_valid(ping_node):
			_battle_event_pings.remove_at(index)
			continue
		var age = current_time - ping_state["started_at"]
		var progress = clampf(age / BATTLE_EVENT_PING_LIFETIME_SECONDS, 0.0, 1.0)
		if progress >= 1.0:
			ping_node.queue_free()
			_battle_event_pings.remove_at(index)
			continue
		_sync_battle_event_ping(ping_state, progress)


func _sync_battle_event_ping(ping_state, progress):
	var ping_node = ping_state["node"]
	var center = ping_state["position"]
	var style = _battle_event_ping_style(ping_state["event_type"])
	var radius = lerpf(
		style["radius_min"],
		style["radius_max"],
		progress
	)
	var alpha = 1.0 - progress
	var color = style["color"]
	ping_node.default_color = Color(
		color.r,
		color.g,
		color.b,
		alpha
	)
	ping_node.points = PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius, 0)
	])


func _battle_event_ping_type(event_type):
	match event_type:
		Constants.Match.BattleEventPing.SUPPORT_POWER:
			return Constants.Match.BattleEventPing.SUPPORT_POWER
		Constants.Match.BattleEventPing.ENEMY_SUPPORT_POWER:
			return Constants.Match.BattleEventPing.ENEMY_SUPPORT_POWER
		Constants.Match.BattleEventPing.ENEMY_SUPERWEAPON:
			return Constants.Match.BattleEventPing.ENEMY_SUPERWEAPON
		_:
			return Constants.Match.BattleEventPing.GENERIC


func _battle_event_ping_style(event_type):
	match _battle_event_ping_type(event_type):
		Constants.Match.BattleEventPing.SUPPORT_POWER:
			return {
				"color": SUPPORT_POWER_PING_COLOR,
				"radius_min": BATTLE_EVENT_PING_RADIUS_MIN,
				"radius_max": SUPPORT_POWER_PING_RADIUS_MAX,
				"width": BATTLE_EVENT_PING_WIDTH + 0.5,
			}
		Constants.Match.BattleEventPing.ENEMY_SUPPORT_POWER:
			return {
				"color": ENEMY_SUPPORT_POWER_PING_COLOR,
				"radius_min": BATTLE_EVENT_PING_RADIUS_MIN + 1.0,
				"radius_max": ENEMY_SUPPORT_POWER_PING_RADIUS_MAX,
				"width": BATTLE_EVENT_PING_WIDTH + 1.0,
			}
		Constants.Match.BattleEventPing.ENEMY_SUPERWEAPON:
			return {
				"color": ENEMY_SUPERWEAPON_PING_COLOR,
				"radius_min": BATTLE_EVENT_PING_RADIUS_MIN + 2.0,
				"radius_max": ENEMY_SUPERWEAPON_PING_RADIUS_MAX,
				"width": BATTLE_EVENT_PING_WIDTH + 2.0,
			}
		_:
			return {
				"color": BATTLE_EVENT_PING_COLOR,
				"radius_min": BATTLE_EVENT_PING_RADIUS_MIN,
				"radius_max": BATTLE_EVENT_PING_RADIUS_MAX,
				"width": BATTLE_EVENT_PING_WIDTH,
			}


func _clear_battle_event_pings():
	for ping_state in _battle_event_pings:
		var ping_node = ping_state["node"]
		if is_instance_valid(ping_node):
			ping_node.queue_free()
	_battle_event_pings.clear()


func _get_current_time_seconds():
	return Time.get_ticks_msec() / 1000.0


func _on_gui_input(event):
	if not _radar_online:
		_camera_movement_active = false
		accept_event()
		return
	var handled = false
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			_try_teleporting_camera_based_on_local_texture_rect_position(event.position)
			_camera_movement_active = true
			handled = true
		if not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			_camera_movement_active = false
			handled = true
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
			_issue_movement_action(event.position)
			handled = true
	elif event is InputEventMouseMotion and _camera_movement_active:
		_try_teleporting_camera_based_on_local_texture_rect_position(event.position)
		handled = true
	if handled:
		accept_event()
