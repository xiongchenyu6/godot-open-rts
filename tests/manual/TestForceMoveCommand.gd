extends "res://tests/manual/Match.gd"

const AutoAttacking = preload("res://source/match/units/actions/AutoAttacking.gd")
const Following = preload("res://source/match/units/actions/Following.gd")

@onready var _attacker = $Players/Human/Tank
@onready var _target = $Players/Player/Tank


func _ready():
	super()
	await get_tree().process_frame
	await get_tree().process_frame

	_attacker.find_child("Selection").select()
	await get_tree().process_frame

	MatchSignals.unit_targeted.emit(_target)
	await get_tree().process_frame
	_assert(_attacker.action is AutoAttacking, "normal right-click should attack enemy targets")

	_attacker.action = null
	await get_tree().process_frame
	_press_alt(true)
	await get_tree().process_frame
	MatchSignals.unit_targeted.emit(_target)
	await get_tree().process_frame
	_press_alt(false)

	_assert(_attacker.action is Following, "Alt right-click should force movement to enemy targets")
	_assert(not (_attacker.action is AutoAttacking), "Alt force-move should not issue an attack order")
	get_tree().quit()


func _press_alt(pressed):
	var event = InputEventKey.new()
	event.keycode = KEY_ALT
	event.physical_keycode = KEY_ALT
	event.pressed = pressed
	Input.parse_input_event(event)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)
