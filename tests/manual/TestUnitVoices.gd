extends "res://tests/manual/Match.gd"

const Moving = preload("res://source/match/units/actions/Moving.gd")
const SoundEffectsControllerScript = preload("res://source/match/players/human/SoundEffectsController.gd")
const UnitScript = preload("res://source/match/units/Unit.gd")

@onready var _command_center = $Players/Human/CommandCenter
@onready var _tank = $Players/Human/HumanTank
@onready var _enemy_tank = $Players/SimpleClairvoyantAI/Tank
@onready var _unit_voices = $Players/Human/UnitVoicesController
@onready var _sound_effects = $Players/Human/SoundEffectsController


func _ready():
	super()
	await get_tree().process_frame
	_disable_ai_controllers()

	MatchSignals.unit_selected.emit(_enemy_tank)
	await get_tree().process_frame
	_assert_no_unit_voice("enemy unit selection should not trigger human unit voices")

	MatchSignals.unit_selected.emit(_command_center)
	await get_tree().process_frame
	_assert_no_unit_voice("structure selection should stay out of the unit voice channel")
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_SELECT,
		"structure selection should still trigger selection SFX"
	)

	_reset_voice_and_sound()
	_tank.find_child("Selection").select()
	await get_tree().process_frame
	_assert_voice_event(
		Constants.Match.VoiceNarrator.Events.UNIT_HELLO,
		"owned mobile unit selection should trigger a unit hello voice"
	)
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_SELECT,
		"owned mobile unit selection should trigger selection SFX"
	)

	_reset_voice_and_sound()
	MatchSignals.terrain_targeted.emit(Vector3(18.0, 0.0, 12.0))
	await get_tree().process_frame
	_assert_voice_event(
		Constants.Match.VoiceNarrator.Events.UNIT_ACK_1,
		"terrain orders should trigger the first unit acknowledgement"
	)
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_COMMAND,
		"terrain orders should trigger command SFX"
	)

	_reset_voice_and_sound()
	MatchSignals.unit_targeted.emit(_enemy_tank)
	await get_tree().process_frame
	_assert_voice_event(
		Constants.Match.VoiceNarrator.Events.UNIT_ACK_2,
		"unit target orders should alternate to the second acknowledgement"
	)
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_COMMAND,
		"unit target orders should trigger command SFX"
	)

	_reset_voice_and_sound()
	Utils.Match.UnitCommands.guard_area([_tank])
	await get_tree().process_frame
	_assert_voice_event(
		Constants.Match.VoiceNarrator.Events.UNIT_ACK_1,
		"direct guard commands should trigger unit acknowledgement voice"
	)
	_assert(_unit_voices._last_command_key == Utils.Match.UnitCommands.COMMAND_GUARD_AREA,
		"unit voice controller should record the direct command key")
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_COMMAND,
		"direct guard commands should trigger command SFX"
	)

	_reset_voice_and_sound()
	Utils.Match.UnitCommands.scatter_units([_tank])
	await get_tree().process_frame
	_assert_voice_event(
		Constants.Match.VoiceNarrator.Events.UNIT_ACK_2,
		"direct scatter commands should alternate acknowledgement voice"
	)
	_assert(_unit_voices._last_command_key == Utils.Match.UnitCommands.COMMAND_SCATTER,
		"unit voice controller should record scatter command confirmation")
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_COMMAND,
		"direct scatter commands should trigger command SFX"
	)

	_reset_voice_and_sound()
	_tank.action = Moving.new(Vector3(20.0, 0.0, 12.0))
	Utils.Match.UnitCommands.cancel_current_actions([_tank])
	await get_tree().process_frame
	_assert_voice_event(
		Constants.Match.VoiceNarrator.Events.UNIT_ACK_1,
		"direct cancel commands should trigger unit acknowledgement voice"
	)
	_assert(_unit_voices._last_command_key == Utils.Match.UnitCommands.COMMAND_CANCEL,
		"unit voice controller should record cancel command confirmation")
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_COMMAND,
		"direct cancel commands should trigger command SFX"
	)

	get_tree().quit()


func _reset_voice_and_sound():
	_unit_voices._audio_player.stop()
	_unit_voices._last_event_handled = null
	_unit_voices._last_command_key = ""
	_sound_effects._last_sound_tag = ""
	_sound_effects._last_sound_stream = null


func _assert_voice_event(expected_event, message):
	if _unit_voices._last_event_handled == expected_event:
		return
	_fail(message)


func _assert_no_unit_voice(message):
	if _unit_voices._last_event_handled == null:
		return
	_fail(message)


func _assert_sound_effect(expected_sound_tag, message):
	if _sound_effects._last_sound_tag == expected_sound_tag and _sound_effects._last_sound_stream != null:
		return
	_fail(message)


func _disable_ai_controllers():
	for child in $Players/SimpleClairvoyantAI.get_children():
		if not child is UnitScript:
			child.queue_free()


func _assert(condition, message):
	if condition:
		return
	_fail(message)


func _fail(message):
	push_error(message)
	get_tree().quit(1)
