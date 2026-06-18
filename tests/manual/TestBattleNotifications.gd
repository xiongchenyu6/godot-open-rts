extends "res://tests/manual/Match.gd"

const SoundEffectsControllerScript = preload("res://source/match/players/human/SoundEffectsController.gd")
const UnitScript = preload("res://source/match/units/Unit.gd")


class FakePowerPlayer:
	var low_power = false

	func is_low_power():
		return low_power

@onready var _player = $Players/Human
@onready var _enemy = $Players/SimpleClairvoyantAI
@onready var _command_center = $Players/Human/CommandCenter
@onready var _human_tank = $Players/Human/HumanTank
@onready var _enemy_tank = $Players/SimpleClairvoyantAI/Tank
@onready var _notifications = $HUD/BattleNotificationsAnchor/BattleNotifications
@onready var _voice_narrator = $Players/Human/VoiceNarratorController
@onready var _sound_effects = $Players/Human/SoundEffectsController


func _ready():
	super()
	_camera.screen_margin_for_movement = -1
	await get_tree().process_frame
	_disable_ai_controllers()
	_notifications.clear_messages()
	var recorded_positions = []
	var record_position = func(position): recorded_positions.append(position)
	var recorded_pings = []
	var record_ping = func(position, event_type):
		recorded_pings.append({"position": position, "event_type": event_type})
	MatchSignals.battle_event_recorded.connect(record_position)
	MatchSignals.battle_event_ping_requested.connect(record_ping)

	MatchSignals.unit_promoted.emit(_enemy_tank, 1)
	MatchSignals.unit_production_blocked.emit(null, _enemy_tank)
	MatchSignals.not_enough_resources_for_production.emit(_enemy)
	await get_tree().process_frame
	if not _notification_texts().is_empty():
		_fail("enemy notifications should not be shown")
		return

	MatchSignals.not_enough_resources_for_production.emit(_player)
	await get_tree().process_frame
	_assert_has_message(tr("BATTLE_NOTIFICATION_INSUFFICIENT_FUNDS"))
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_ERROR,
		"insufficient funds should trigger the error SFX"
	)
	_assert_low_power_warning_sound()

	MatchSignals.unit_captured.emit(_command_center, _enemy, _player)
	await get_tree().process_frame
	_assert_has_message(tr("BATTLE_NOTIFICATION_STRUCTURE_CAPTURED"))
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_STRUCTURE_CAPTURED,
		"capturing a structure should trigger captured SFX"
	)
	_assert_recorded_position(
		recorded_positions,
		_command_center.global_position,
		"structure capture notification should record the captured structure position"
	)

	MatchSignals.unit_captured.emit(_command_center, _player, _enemy)
	await get_tree().process_frame
	_assert_has_message(tr("BATTLE_NOTIFICATION_STRUCTURE_LOST"))
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_STRUCTURE_LOST,
		"losing a structure should trigger lost-structure SFX"
	)
	_assert_recorded_position(
		recorded_positions,
		_command_center.global_position,
		"structure lost notification should record the lost structure position"
	)

	MatchSignals.unit_damaged.emit(_command_center)
	await get_tree().process_frame
	_assert_has_message(tr("BATTLE_NOTIFICATION_BASE_UNDER_ATTACK"))
	_assert_recorded_position(
		recorded_positions,
		_command_center.global_position,
		"under attack notification should record a focus position"
	)

	var support_power_position = Vector3(12.0, 0.0, 18.0)
	MatchSignals.support_power_activated.emit(
		Constants.Match.SupportPowers.RADAR_SWEEP, _player, support_power_position
	)
	await get_tree().process_frame
	_assert_has_message(
		tr("BATTLE_NOTIFICATION_SUPPORT_POWER_USED").format([tr("RADAR_SWEEP")])
	)
	_assert_voice_event(
		Constants.Match.VoiceNarrator.Events.SUPPORT_POWER_FIRED,
		"human support power use should trigger the tactical narrator"
	)
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_SUPPORT_POWER_FIRE,
		"human support power use should trigger support fire SFX"
	)
	_assert_recorded_position(
		recorded_positions,
		support_power_position,
		"support power notification should record its target focus position"
	)
	_assert_recorded_ping(
		recorded_pings,
		support_power_position,
		Constants.Match.BattleEventPing.SUPPORT_POWER,
		"human support power notification should request a friendly support minimap ping"
	)
	await _assert_notification_click_focuses_event(
		tr("BATTLE_NOTIFICATION_SUPPORT_POWER_USED").format([tr("RADAR_SWEEP")]),
		support_power_position
	)

	var enemy_support_power_position = Vector3(16.0, 0.0, 20.0)
	MatchSignals.support_power_activated.emit(
		Constants.Match.SupportPowers.ORBITAL_STRIKE, _enemy, enemy_support_power_position
	)
	await get_tree().process_frame
	_assert_has_message(
		tr("BATTLE_NOTIFICATION_ENEMY_SUPPORT_POWER_USED").format([tr("ORBITAL_STRIKE")])
	)
	_assert_voice_event(
		Constants.Match.VoiceNarrator.Events.ENEMY_SUPPORT_POWER_FIRED,
		"enemy support power use should trigger the tactical narrator"
	)
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_ENEMY_SUPPORT_POWER,
		"enemy support power use should trigger enemy support SFX"
	)
	_assert_recorded_position(
		recorded_positions,
		enemy_support_power_position,
		"enemy support power notification should record its target focus position"
	)
	_assert_recorded_ping(
		recorded_pings,
		enemy_support_power_position,
		Constants.Match.BattleEventPing.ENEMY_SUPPORT_POWER,
		"enemy support power notification should request an enemy support minimap ping"
	)

	var enemy_superweapon_position = Vector3(20.0, 0.0, 24.0)
	MatchSignals.support_power_charging.emit(
		Constants.Match.SupportPowers.WEATHER_STORM, _player, 90.0
	)
	await get_tree().process_frame
	_assert_has_message(
		tr("BATTLE_NOTIFICATION_SUPERWEAPON_CHARGING").format([tr("WEATHER_STORM"), 90])
	)
	MatchSignals.support_power_charging.emit(
		Constants.Match.SupportPowers.STRATEGIC_MISSILE, _enemy, 105.0
	)
	await get_tree().process_frame
	_assert_has_message(
		tr("BATTLE_NOTIFICATION_ENEMY_SUPERWEAPON_CHARGING").format(
			[tr("STRATEGIC_MISSILE"), 105]
		)
	)
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_ENEMY_SUPERWEAPON_CHARGING,
		"enemy superweapon charging should trigger warning SFX"
	)
	MatchSignals.support_power_ready.emit(Constants.Match.SupportPowers.WEATHER_STORM, _enemy)
	await get_tree().process_frame
	_assert_has_message(
		tr("BATTLE_NOTIFICATION_ENEMY_SUPERWEAPON_READY").format([tr("WEATHER_STORM")])
	)
	_assert_voice_event(
		Constants.Match.VoiceNarrator.Events.ENEMY_SUPERWEAPON_READY,
		"enemy superweapon ready should trigger the tactical narrator"
	)
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_ENEMY_SUPERWEAPON_READY,
		"enemy superweapon ready should trigger warning SFX"
	)
	MatchSignals.support_power_activated.emit(
		Constants.Match.SupportPowers.WEATHER_STORM, _enemy, enemy_superweapon_position
	)
	await get_tree().process_frame
	_assert_has_message(
		tr("BATTLE_NOTIFICATION_ENEMY_SUPERWEAPON_USED").format([tr("WEATHER_STORM")])
	)
	_assert_voice_event(
		Constants.Match.VoiceNarrator.Events.ENEMY_SUPERWEAPON_LAUNCHED,
		"enemy superweapon launch should trigger the tactical narrator"
	)
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_ENEMY_SUPERWEAPON_LAUNCHED,
		"enemy superweapon launch should trigger warning SFX"
	)
	_assert_recorded_position(
		recorded_positions,
		enemy_superweapon_position,
		"enemy superweapon notification should record its target focus position"
	)
	_assert_recorded_ping(
		recorded_pings,
		enemy_superweapon_position,
		Constants.Match.BattleEventPing.ENEMY_SUPERWEAPON,
		"enemy superweapon notification should request a superweapon minimap ping"
	)

	MatchSignals.unit_promoted.emit(_human_tank, 1)
	await get_tree().process_frame
	_assert_has_message(
		tr("BATTLE_NOTIFICATION_UNIT_PROMOTED").format([tr("SELECTION_VETERAN")])
	)
	_assert_recorded_position(
		recorded_positions,
		_human_tank.global_position,
		"promotion notification should record the promoted unit position"
	)
	_assert_recorded_ping(
		recorded_pings,
		_human_tank.global_position,
		Constants.Match.BattleEventPing.GENERIC,
		"generic battle notifications should request generic minimap pings"
	)
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_UNIT_PROMOTED,
		"unit promotion should trigger promotion SFX"
	)

	MatchSignals.unit_production_blocked.emit(null, _command_center)
	await get_tree().process_frame
	_assert_has_message(tr("BATTLE_NOTIFICATION_PRODUCTION_BLOCKED"))
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_PRODUCTION_BLOCKED,
		"blocked production should trigger the blocked-production SFX"
	)
	_assert_recorded_position(
		recorded_positions,
		_command_center.global_position,
		"blocked production notification should record the producer position"
	)

	MatchSignals.unit_group_assigned.emit(2, [_human_tank])
	await get_tree().process_frame
	_assert_has_message(
		tr("BATTLE_NOTIFICATION_CONTROL_GROUP_ASSIGNED").format([2, 1])
	)
	_assert_recorded_position(
		recorded_positions,
		_human_tank.global_position,
		"control group assignment notification should record the group position"
	)

	MatchSignals.unit_group_cleared.emit(2)
	await get_tree().process_frame
	_assert_has_message(tr("BATTLE_NOTIFICATION_CONTROL_GROUP_CLEARED").format([2]))

	MatchSignals.support_power_ready.emit(Constants.Match.SupportPowers.RADAR_SWEEP, _player)
	await get_tree().process_frame
	_assert_has_message(
		tr("BATTLE_NOTIFICATION_SUPPORT_POWER_READY").format([tr("RADAR_SWEEP")])
	)
	_assert_voice_event(
		Constants.Match.VoiceNarrator.Events.SUPPORT_POWER_READY,
		"human support power ready should trigger the tactical narrator"
	)
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_SUPPORT_POWER_READY,
		"human support power ready should trigger ready SFX"
	)

	var crate = Node3D.new()
	add_child(crate)
	crate.global_position = Vector3(18.0, 0.0, 18.0)
	MatchSignals.supply_crate_collected.emit(crate, _human_tank, "resources")
	await get_tree().process_frame
	_assert_has_message(tr("BATTLE_NOTIFICATION_SUPPLY_CRATE_RESOURCES"))
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_SUPPLY_CRATE,
		"supply crate pickup should trigger pickup SFX"
	)
	_assert_recorded_position(
		recorded_positions,
		crate.global_position,
		"supply crate notification should record the crate position"
	)
	crate.queue_free()

	_notifications.clear_messages()
	for _i in range(6):
		_notifications.push_message("BATTLE_NOTIFICATION_UNIT_READY")
	if _notification_texts().size() != 5:
		_fail("notification feed should cap visible messages")
		return

	_notifications.message_lifetime_seconds = 0.05
	_notifications.clear_messages()
	_notifications.push_message("BATTLE_NOTIFICATION_UNIT_READY")
	await get_tree().create_timer(0.12).timeout
	if not _notification_texts().is_empty():
		_fail("expired notifications should be removed")
		return

	MatchSignals.battle_event_recorded.disconnect(record_position)
	MatchSignals.battle_event_ping_requested.disconnect(record_ping)
	get_tree().quit()


func _assert_has_message(expected_text):
	if not _notification_texts().has(expected_text):
		_fail("notification feed should include '{0}'".format([expected_text]))


func _assert_notification_click_focuses_event(expected_text, expected_position):
	_camera.set_position_safely(Vector3(2.0, 0.0, 2.0))
	await get_tree().process_frame
	var label = _notification_label(expected_text)
	if label == null:
		_fail("focusable notification should exist: {0}".format([expected_text]))
		return
	if label.mouse_filter != Control.MOUSE_FILTER_STOP:
		_fail("focusable notification should accept pointer input")
		return
	if label.tooltip_text != tr("BATTLE_NOTIFICATION_FOCUS_TOOLTIP"):
		_fail("focusable notification should explain its click target")
		return
	label.gui_input.emit(_left_click_event())
	await get_tree().process_frame
	var expected_center = expected_position * Vector3(1, 0, 1)
	var camera_center = _camera_center_yless()
	if camera_center.distance_to(expected_center) > 0.75:
		_fail(
			"clicking a battlefield notification should focus the event: {0} vs {1}".format(
				[camera_center, expected_center]
			)
		)


func _assert_recorded_position(recorded_positions, expected_position, message):
	for position in recorded_positions:
		if position.distance_to(expected_position) < 0.1:
			return
	_fail(message)


func _assert_recorded_ping(recorded_pings, expected_position, expected_event_type, message):
	for ping in recorded_pings:
		if (
			ping["event_type"] == expected_event_type
			and ping["position"].distance_to(expected_position) < 0.1
		):
			return
	_fail(message)


func _assert_voice_event(expected_event, message):
	if _voice_narrator._last_event_handled == expected_event:
		return
	_fail(message)


func _assert_sound_effect(expected_sound_tag, message):
	if _sound_effects._last_sound_tag == expected_sound_tag and _sound_effects._last_sound_stream != null:
		return
	_fail(message)


func _assert_low_power_warning_sound():
	var real_player = _sound_effects._player
	var fake_player = FakePowerPlayer.new()
	_sound_effects._player = fake_player
	_sound_effects._was_low_power = null
	_sound_effects._refresh_power_state(false)
	fake_player.low_power = true
	_sound_effects._refresh_power_state()
	_sound_effects._player = real_player
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_LOW_POWER,
		"entering low power should trigger warning SFX"
	)


func _fail(message):
	push_error(message)
	get_tree().quit(1)


func _notification_texts():
	var texts = []
	var messages_box = _notifications.find_child("Messages", true, false)
	for label in messages_box.find_children("*", "Label", false, false):
		texts.append(label.text)
	return texts


func _notification_label(expected_text):
	var messages_box = _notifications.find_child("Messages", true, false)
	for label in messages_box.find_children("*", "Label", false, false):
		if label.text == expected_text:
			return label
	return null


func _left_click_event():
	var event = InputEventMouseButton.new()
	event.pressed = true
	event.button_index = MOUSE_BUTTON_LEFT
	return event


func _camera_center_yless():
	return _camera.get_ray_intersection(get_viewport().size / 2.0) * Vector3(1, 0, 1)


func _disable_ai_controllers():
	for child in _enemy.get_children():
		if not child is UnitScript:
			child.queue_free()
