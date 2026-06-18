extends "res://tests/manual/Match.gd"

const RadarUplinkUnit = preload("res://source/match/units/RadarUplink.tscn")
const TechLabUnit = preload("res://source/match/units/TechLab.tscn")

const MINIMAP_PIXELS_PER_WORLD_METER = 2.0

@onready var _player = $Players/Human
@onready var _minimap = $HUD/MarginContainer/Minimap
@onready var _test_camera = $IsometricCamera3D


func _ready():
	super()
	await _wait_for_radar_state(false, "RADAR_REQUIRES_UPLINK")
	assert(not _minimap.is_radar_online(), "minimap should start offline without radar")
	assert(
		_minimap.get_radar_offline_reason_key() == "RADAR_REQUIRES_UPLINK",
		"minimap should tell the player to build radar first"
	)
	_assert_radar_offline_art_visible("offline minimap should show radar construction art")

	var radar = RadarUplinkUnit.instantiate()
	_setup_and_spawn_unit(radar, Transform3D(Basis(), Vector3(13.0, 0.0, 10.0)), _player, false)
	await _wait_for_radar_state(true)
	assert(_minimap.is_radar_online(), "constructed powered radar should enable the minimap")
	_assert_radar_offline_art_hidden("online minimap should hide radar construction art")
	await _test_minimap_world_targeting()
	await _test_minimap_battle_event_pings()

	var tech_lab = TechLabUnit.instantiate()
	_setup_and_spawn_unit(tech_lab, Transform3D(Basis(), Vector3(16.0, 0.0, 10.0)), _player, false)
	await _wait_for_radar_state(false, "RADAR_LOW_POWER")
	assert(not _minimap.is_radar_online(), "low power should disable the minimap")
	assert(
		_minimap.get_radar_offline_reason_key() == "RADAR_LOW_POWER",
		"minimap should explain low-power radar outage"
	)
	assert(
		_minimap.get_battle_event_ping_count() == 0,
		"low power should clear active minimap battle-event pings"
	)
	_assert_radar_offline_art_visible("low-power minimap should keep visible offline art")
	MatchSignals.battle_event_ping_requested.emit(
		Vector3(20.0, 0.0, 20.0),
		Constants.Match.BattleEventPing.GENERIC
	)
	await get_tree().process_frame
	assert(
		_minimap.get_battle_event_ping_count() == 0,
		"offline radar should ignore new minimap battle-event pings"
	)

	tech_lab.queue_free()
	await _wait_for_radar_state(true)
	assert(_minimap.is_radar_online(), "restoring power margin should bring radar back online")
	_assert_radar_offline_art_hidden("restored radar should hide offline art")

	radar.queue_free()
	await _wait_for_radar_state(false, "RADAR_REQUIRES_UPLINK")
	assert(not _minimap.is_radar_online(), "removing radar should disable the minimap")
	assert(
		_minimap.get_radar_offline_reason_key() == "RADAR_REQUIRES_UPLINK",
		"missing radar should take precedence after the radar building is gone"
	)
	_assert_radar_offline_art_visible("removed radar should show radar construction art again")
	get_tree().quit()


func _test_minimap_world_targeting():
	_test_camera.screen_margin_for_movement = -1
	var target_position = Vector3(32.0, 0.0, 34.0)
	var minimap_position = _local_minimap_position_for_world_position(target_position)
	_test_camera.set_position_safely(Vector3(6.0, 0.0, 6.0))
	await get_tree().process_frame

	_minimap._try_teleporting_camera_based_on_local_texture_rect_position(minimap_position)
	await get_tree().process_frame
	assert(
		_camera_center_yless().distance_to(target_position * Vector3(1, 0, 1)) < 0.75,
		"left-clicking the minimap should center the camera on that world position"
	)

	var minimap_targets = []
	var target_callback = func(position): minimap_targets.append(position)
	MatchSignals.minimap_terrain_targeted.connect(target_callback)
	_minimap._issue_movement_action(minimap_position)
	await get_tree().process_frame
	MatchSignals.minimap_terrain_targeted.disconnect(target_callback)
	assert(not minimap_targets.is_empty(), "right-clicking minimap should emit a world target")
	assert(
		minimap_targets[0].distance_to(target_position) < 0.1,
		"minimap world target should match the clicked map position"
	)


func _test_minimap_battle_event_pings():
	assert(
		_minimap.get_battle_event_ping_count() == 0,
		"minimap should start without battle-event pings"
	)
	MatchSignals.battle_event_ping_requested.emit(
		Vector3(24.0, 0.0, 26.0),
		Constants.Match.BattleEventPing.GENERIC
	)
	await get_tree().process_frame
	assert(
		_minimap.get_battle_event_ping_count() == 1,
		"online radar should show a minimap battle-event ping"
	)
	assert(
		_minimap.get_latest_battle_event_ping_type() == Constants.Match.BattleEventPing.GENERIC,
		"generic battle events should use the generic minimap ping style"
	)
	var generic_ping_width = _minimap.get_latest_battle_event_ping_width()
	MatchSignals.battle_event_ping_requested.emit(
		Vector3(28.0, 0.0, 28.0),
		Constants.Match.BattleEventPing.SUPPORT_POWER
	)
	await get_tree().process_frame
	assert(
		_minimap.get_latest_battle_event_ping_type() == Constants.Match.BattleEventPing.SUPPORT_POWER,
		"friendly support powers should use the support-power minimap ping style"
	)
	MatchSignals.battle_event_ping_requested.emit(
		Vector3(30.0, 0.0, 30.0),
		Constants.Match.BattleEventPing.ENEMY_SUPPORT_POWER
	)
	await get_tree().process_frame
	assert(
		_minimap.get_latest_battle_event_ping_type()
		== Constants.Match.BattleEventPing.ENEMY_SUPPORT_POWER,
		"enemy support powers should use the enemy-support minimap ping style"
	)
	MatchSignals.battle_event_ping_requested.emit(
		Vector3(32.0, 0.0, 32.0),
		Constants.Match.BattleEventPing.ENEMY_SUPERWEAPON
	)
	await get_tree().process_frame
	assert(
		_minimap.get_latest_battle_event_ping_type()
		== Constants.Match.BattleEventPing.ENEMY_SUPERWEAPON,
		"enemy superweapons should use the superweapon minimap ping style"
	)
	assert(
		_minimap.get_latest_battle_event_ping_width() > generic_ping_width,
		"enemy superweapon minimap pings should be more prominent than generic pings"
	)


func _local_minimap_position_for_world_position(world_position):
	var texture_rect = _minimap.find_child("MinimapTextureRect", true, false)
	var texture_size = texture_rect.texture.get_size()
	var scaling_factor = min(
		texture_rect.size.x / texture_size.x, texture_rect.size.y / texture_size.y
	)
	var scaled_texture_size = texture_size * scaling_factor
	var texture_offset = (texture_rect.size - scaled_texture_size) / 2.0
	var minimap_position = (
		Vector2(world_position.x, world_position.z) * MINIMAP_PIXELS_PER_WORLD_METER
	)
	return texture_offset + minimap_position * scaling_factor


func _camera_center_yless():
	var center = _test_camera.get_ray_intersection(get_viewport().size / 2.0)
	return center * Vector3(1, 0, 1)


func _wait_for_radar_state(expected_online, expected_reason_key = "", max_frames = 20):
	for _i in range(max_frames):
		await get_tree().process_frame
		await get_tree().physics_frame
		if _minimap.is_radar_online() != expected_online:
			continue
		if expected_online or _minimap.get_radar_offline_reason_key() == expected_reason_key:
			return


func _assert_radar_offline_art_visible(message):
	var icon = _minimap.find_child("RadarOfflineIcon", true, false)
	assert(icon != null, "{0}: radar offline icon should exist".format([message]))
	assert(icon.visible, "{0}: radar offline icon should be visible".format([message]))
	assert(icon.texture != null, "{0}: radar offline icon should load a texture".format([message]))
	assert(icon.texture.get_image() != null, "{0}: radar offline icon should have image data".format([message]))


func _assert_radar_offline_art_hidden(message):
	var icon = _minimap.find_child("RadarOfflineIcon", true, false)
	assert(icon != null, "{0}: radar offline icon should exist".format([message]))
	assert(not icon.visible, "{0}: radar offline icon should be hidden".format([message]))
