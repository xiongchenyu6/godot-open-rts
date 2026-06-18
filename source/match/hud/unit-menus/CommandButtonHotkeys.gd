extends RefCounted

const HOTKEY_LABEL_NAME = "HotkeyLabel"
const META_DISPLAY = "command_hotkey_display"
const META_KEYCODE = "command_hotkey_keycode"
const COMMAND_BUTTON_SIZE = Vector2(112, 112)
const HOTKEYS = [
	{"display": "Q", "keycode": KEY_Q},
	{"display": "W", "keycode": KEY_W},
	{"display": "E", "keycode": KEY_E},
	{"display": "R", "keycode": KEY_R},
	{"display": "T", "keycode": KEY_T},
	{"display": "Y", "keycode": KEY_Y},
	{"display": "A", "keycode": KEY_A},
	{"display": "S", "keycode": KEY_S},
	{"display": "D", "keycode": KEY_D},
	{"display": "F", "keycode": KEY_F},
	{"display": "G", "keycode": KEY_G},
	{"display": "H", "keycode": KEY_H},
	{"display": "Z", "keycode": KEY_Z},
	{"display": "X", "keycode": KEY_X},
	{"display": "C", "keycode": KEY_C},
	{"display": "V", "keycode": KEY_V},
	{"display": "B", "keycode": KEY_B},
	{"display": "N", "keycode": KEY_N},
	{"display": "1", "keycode": KEY_1},
	{"display": "2", "keycode": KEY_2},
	{"display": "3", "keycode": KEY_3},
	{"display": "4", "keycode": KEY_4},
	{"display": "5", "keycode": KEY_5},
	{"display": "6", "keycode": KEY_6},
	{"display": "7", "keycode": KEY_7},
	{"display": "8", "keycode": KEY_8},
	{"display": "9", "keycode": KEY_9},
	{"display": "0", "keycode": KEY_0},
	{"display": "-", "keycode": KEY_MINUS},
	{"display": "=", "keycode": KEY_EQUAL},
]


static func assign_grid_hotkeys(menu):
	var slot_index = 0
	for child in menu.get_children():
		if child is Button and slot_index < HOTKEYS.size():
			_assign_button_hotkey(child, HOTKEYS[slot_index])
		slot_index += 1


static func assign_button_hotkey(button, display, keycode):
	_assign_button_hotkey(button, {"display": display, "keycode": keycode})


static func try_activate(menu, event):
	if not menu.visible:
		return false
	if not event is InputEventKey:
		return false
	if not event.pressed or event.echo:
		return false
	if event.alt_pressed or event.ctrl_pressed or event.meta_pressed:
		return false
	var keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	for button in menu.find_children("*", "Button", true, false):
		if button.get_meta(META_KEYCODE, -1) == keycode:
			return press_button(button)
	return false


static func press_button(button):
	if button == null or button.disabled or not button.visible:
		return false
	if button.toggle_mode:
		var next_pressed = not button.button_pressed
		button.set_pressed_no_signal(next_pressed)
		button.emit_signal("toggled", next_pressed)
	else:
		button.emit_signal("pressed")
	return true


static func tooltip(button, base_text):
	var display = button.get_meta(META_DISPLAY, "")
	if display == "":
		return base_text
	return "{0}\n{1}: {2}".format([base_text, button.tr("COMMAND_HOTKEY"), display])


static func _assign_button_hotkey(button, hotkey):
	button.custom_minimum_size = Vector2(
		max(button.custom_minimum_size.x, COMMAND_BUTTON_SIZE.x),
		max(button.custom_minimum_size.y, COMMAND_BUTTON_SIZE.y)
	)
	button.set_meta(META_DISPLAY, hotkey["display"])
	button.set_meta(META_KEYCODE, hotkey["keycode"])
	_ensure_hotkey_label(button, hotkey["display"])


static func _ensure_hotkey_label(button, display):
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
		label.add_theme_font_size_override("font_size", 13)
		button.add_child(label)
	label.text = display
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.offset_left = 3
	label.offset_top = 2
	label.offset_right = 24
	label.offset_bottom = 19
	button.move_child(label, button.get_child_count() - 1)
