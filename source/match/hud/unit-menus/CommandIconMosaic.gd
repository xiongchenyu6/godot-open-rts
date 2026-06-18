extends Control

const BLOCK_COUNT = 9
const BLOCK_PREFIX = "Block"
const PANEL = Color(0.025, 0.050, 0.060, 0.92)
const TRIM = Color(0.90, 0.98, 1.0, 0.96)

var icon_key = ""
var disabled = false
var _blocks = []


func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_blocks()
	_layout_blocks()


func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_layout_blocks()


func set_icon(next_icon_key, next_disabled = false):
	icon_key = str(next_icon_key)
	disabled = bool(next_disabled)
	_ensure_blocks()
	_layout_blocks()


func visible_block_count():
	var count = 0
	for block in _blocks:
		if block.visible:
			count += 1
	return count


func _ensure_blocks():
	while _blocks.size() < BLOCK_COUNT:
		var block = ColorRect.new()
		block.name = "{0}{1}".format([BLOCK_PREFIX, _blocks.size()])
		block.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(block)
		_blocks.append(block)


func _layout_blocks():
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var specs = _shape_specs()
	for index in range(_blocks.size()):
		var block = _blocks[index]
		if index >= specs.size():
			block.visible = false
			continue
		var spec = specs[index]
		var rel_rect = spec[0]
		block.visible = true
		block.color = _disabled_color(spec[1])
		block.position = Vector2(
			round(rel_rect.position.x * size.x),
			round(rel_rect.position.y * size.y)
		)
		block.size = Vector2(
			max(2.0, round(rel_rect.size.x * size.x)),
			max(2.0, round(rel_rect.size.y * size.y))
		)
		block.z_index = index


func _shape_specs():
	var key = icon_key.to_lower()
	if _is_structure_key(key):
		return _structure_specs()
	if _is_air_key(key):
		return _air_specs()
	if _is_infantry_key(key):
		return _infantry_specs()
	return _vehicle_specs()


func _structure_specs():
	var accent = _accent_color()
	return [
		[Rect2(0.12, 0.58, 0.76, 0.22), PANEL],
		[Rect2(0.18, 0.50, 0.64, 0.12), TRIM],
		[Rect2(0.28, 0.40, 0.44, 0.12), accent],
		[Rect2(0.40, 0.24, 0.20, 0.18), TRIM],
		[Rect2(0.46, 0.12, 0.08, 0.14), accent.lightened(0.14)],
		[Rect2(0.24, 0.68, 0.52, 0.06), accent.darkened(0.08)],
		[Rect2(0.70, 0.46, 0.08, 0.10), accent.lightened(0.18)],
	]


func _air_specs():
	var accent = _accent_color()
	return [
		[Rect2(0.45, 0.12, 0.10, 0.58), accent],
		[Rect2(0.36, 0.20, 0.28, 0.16), TRIM],
		[Rect2(0.14, 0.42, 0.72, 0.13), TRIM],
		[Rect2(0.24, 0.54, 0.20, 0.08), accent.lightened(0.12)],
		[Rect2(0.56, 0.54, 0.20, 0.08), accent.lightened(0.12)],
		[Rect2(0.40, 0.70, 0.20, 0.10), accent.darkened(0.12)],
	]


func _infantry_specs():
	var accent = _accent_color()
	return [
		[Rect2(0.42, 0.14, 0.16, 0.16), TRIM],
		[Rect2(0.36, 0.36, 0.28, 0.24), accent],
		[Rect2(0.22, 0.42, 0.56, 0.08), TRIM],
		[Rect2(0.32, 0.60, 0.12, 0.24), TRIM],
		[Rect2(0.56, 0.60, 0.12, 0.24), TRIM],
		[Rect2(0.40, 0.42, 0.20, 0.08), accent.lightened(0.16)],
	]


func _vehicle_specs():
	var accent = _accent_color()
	return [
		[Rect2(0.16, 0.50, 0.68, 0.22), TRIM],
		[Rect2(0.34, 0.36, 0.30, 0.16), accent],
		[Rect2(0.58, 0.32, 0.28, 0.07), TRIM],
		[Rect2(0.24, 0.72, 0.14, 0.10), accent.darkened(0.22)],
		[Rect2(0.62, 0.72, 0.14, 0.10), accent.darkened(0.22)],
		[Rect2(0.38, 0.56, 0.24, 0.06), accent.lightened(0.12)],
	]


func _accent_color():
	var hash_value = absi(icon_key.hash())
	var hue = float(hash_value % 360) / 360.0
	return Color.from_hsv(hue, 0.58, 0.94, 0.96)


func _disabled_color(color):
	if not disabled:
		return color
	return Color(color.r * 0.72, color.g * 0.72, color.b * 0.72, min(color.a, 0.82))


func _is_structure_key(key):
	for token in [
		"center",
		"factory",
		"turret",
		"tower",
		"reactor",
		"refinery",
		"barracks",
		"uplink",
		"bay",
		"lab",
		"pad",
		"spire",
		"fence",
		"bunker",
		"obelisk",
		"purifier",
	]:
		if key.contains(token):
			return true
	return false


func _is_air_key(key):
	for token in ["air", "helicopter", "vtol", "gunship", "bomber"]:
		if key.contains(token):
			return true
	return false


func _is_infantry_key(key):
	for token in [
		"worker",
		"engineer",
		"infantry",
		"trooper",
		"team",
		"medic",
		"sprayer",
		"sniper",
		"saboteur",
		"commando",
		"officer",
	]:
		if key.contains(token):
			return true
	return false
