extends Button

const ICON_DIRECTORY = "res://assets/ui/icons"
const QUEUE_ELEMENT_SIZE = Vector2(72, 72)
const CANONICAL_ICON_ALIASES = {}
const SCENE_ICON_PATHS = {}
const QUEUE_ORDER_LABEL_NAME = "QueueOrderLabel"
const STATUS_BACKDROP_NAME = "StatusBackdrop"
const PROGRESS_FILL_NAME = "ProgressFill"
const ACTIVE_BORDER_COLOR = Color(0.50, 0.86, 1.0, 1.0)
const WAITING_BORDER_COLOR = Color(0.18, 0.30, 0.34, 1.0)
const READY_BLOCKED_BORDER_COLOR = Color(1.0, 0.72, 0.18, 1.0)
const ACTIVE_BACKGROUND_COLOR = Color(0.05, 0.11, 0.14, 0.94)
const WAITING_BACKGROUND_COLOR = Color(0.025, 0.035, 0.045, 0.90)
const READY_BLOCKED_BACKGROUND_COLOR = Color(0.18, 0.11, 0.02, 0.96)
const ACTIVE_PROGRESS_COLOR = Color(0.44, 0.86, 1.0, 0.78)
const WAITING_PROGRESS_COLOR = Color(0.16, 0.25, 0.28, 0.62)
const READY_BLOCKED_PROGRESS_COLOR = Color(1.0, 0.72, 0.18, 0.82)
const STATUS_BACKDROP_COLOR = Color(0.015, 0.026, 0.030, 0.88)

var queue = null
var queue_element = null
var queue_index = -1
var queue_local_index = -1

@onready var _icon_texture_rect = find_child("IconTextureRect")
@onready var _progress_label = find_child("Label")
@onready var _status_backdrop = find_child(STATUS_BACKDROP_NAME)
@onready var _progress_fill = find_child(PROGRESS_FILL_NAME)


func _ready():
	custom_minimum_size = QUEUE_ELEMENT_SIZE
	if queue == null or queue_element == null:
		return
	queue_element.changed.connect(_on_queue_element_changed)
	pressed.connect(func(): queue.cancel(queue_element))
	text = ""
	_setup_icon()
	_setup_tooltip()
	_on_queue_element_changed()
	_apply_queue_position_style()


func set_queue_index(index):
	set_queue_indices(index, index)


func set_queue_indices(global_index, local_index):
	queue_index = global_index
	queue_local_index = local_index
	_refresh_queue_state()


func _on_queue_element_changed():
	_refresh_queue_state()


func _refresh_queue_state():
	_update_progress_status()
	_setup_tooltip()
	_apply_queue_position_style()


func _update_progress_status():
	if _progress_label == null or queue_element == null:
		return
	var progress = clampf(queue_element.progress(), 0.0, 1.0)
	var is_active = _is_active_queue_slot()
	var is_ready_blocked = _is_ready_blocked()
	if is_ready_blocked:
		_progress_label.text = tr("PRODUCTION_QUEUE_READY")
	elif is_active:
		_progress_label.text = "{0}%".format([int(progress * 100.0)])
	else:
		_progress_label.text = tr("PRODUCTION_QUEUE_WAITING")
	if _status_backdrop != null:
		_status_backdrop.color = STATUS_BACKDROP_COLOR
	if _progress_fill != null:
		_progress_fill.anchor_right = 1.0 if is_ready_blocked else progress if is_active else 0.0
		_progress_fill.color = (
			READY_BLOCKED_PROGRESS_COLOR
			if is_ready_blocked
			else ACTIVE_PROGRESS_COLOR if is_active else WAITING_PROGRESS_COLOR
		)


func _setup_icon():
	var unit_name = _unit_name()
	var icon_path = _find_icon_path(unit_name)
	var icon_texture = null
	if icon_path != "":
		icon_texture = load(icon_path)
		if icon_texture == null or not _texture_has_visible_content(icon_texture):
			icon_texture = _fallback_texture_for_unit(unit_name)
	else:
		icon_texture = _fallback_texture_for_unit(unit_name)
	_icon_texture_rect.texture = icon_texture
	_icon_texture_rect.show()
	icon = icon_texture
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_constant_override("h_separation", 0)


func _setup_tooltip():
	var unit_scene_path = _unit_scene_path()
	var costs = Constants.Match.Units.PRODUCTION_COSTS.get(
		unit_scene_path, {"resource_a": 0, "resource_b": 0}
	)
	tooltip_text = "{0}\n{1}\n{2}: {3} {4}, {5} {6}".format(
		[
			_display_name(),
			tr("PRODUCTION_QUEUE_CANCEL"),
			tr("REFUND"),
			tr("RESOURCE_A"),
			costs["resource_a"],
			tr("RESOURCE_B"),
			costs["resource_b"],
		]
	)
	if _is_ready_blocked():
		tooltip_text += "\n{0}".format([tr("PRODUCTION_QUEUE_BLOCKED")])


func _apply_queue_position_style():
	if not is_inside_tree():
		return
	var is_active = _is_active_queue_slot()
	var is_ready_blocked = _is_ready_blocked()
	var style = StyleBoxFlat.new()
	style.bg_color = (
		READY_BLOCKED_BACKGROUND_COLOR
		if is_ready_blocked
		else ACTIVE_BACKGROUND_COLOR if is_active else WAITING_BACKGROUND_COLOR
	)
	style.border_color = (
		READY_BLOCKED_BORDER_COLOR
		if is_ready_blocked
		else ACTIVE_BORDER_COLOR if is_active else WAITING_BORDER_COLOR
	)
	var border_width = 2 if is_active or is_ready_blocked else 1
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	_update_queue_order_label(is_active)


func _update_queue_order_label(is_active):
	var label = find_child(QUEUE_ORDER_LABEL_NAME, false, false)
	if label == null:
		label = Label.new()
		label.name = QUEUE_ORDER_LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 10
		label.anchor_left = 0.0
		label.anchor_top = 0.0
		label.anchor_right = 0.0
		label.anchor_bottom = 0.0
		label.offset_left = 4.0
		label.offset_top = 2.0
		label.offset_right = 24.0
		label.offset_bottom = 18.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		add_child(label)
	label.text = str(queue_index + 1) if queue_index >= 0 else ""
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override(
		"font_color", ACTIVE_BORDER_COLOR if is_active else Color(0.78, 0.86, 0.90, 1.0)
	)


func _is_ready_blocked():
	return queue_element != null and queue_element.progress() >= 1.0


func _is_active_queue_slot():
	return queue_local_index <= 0


func _find_icon_path(unit_name):
	var canonical_icon_path = _canonical_icon_path(unit_name)
	if canonical_icon_path != "":
		return canonical_icon_path
	var scene_icon_path = SCENE_ICON_PATHS.get(_unit_scene_path(), "")
	if scene_icon_path != "" and _asset_exists(scene_icon_path):
		return scene_icon_path
	return ""


func _canonical_icon_path(unit_name):
	var icon_path = "{0}/{1}.png".format([ICON_DIRECTORY, unit_name])
	if _asset_exists(icon_path):
		return icon_path
	var alias_name = CANONICAL_ICON_ALIASES.get(unit_name, "")
	if alias_name == "":
		return ""
	var alias_icon_path = "{0}/{1}.png".format([ICON_DIRECTORY, alias_name])
	return alias_icon_path if _asset_exists(alias_icon_path) else ""


func _asset_exists(path):
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


func _texture_has_visible_content(texture):
	var image = texture.get_image()
	if image == null or image.is_empty():
		return false
	var step_x = int(max(1, image.get_width() / 12))
	var step_y = int(max(1, image.get_height() / 12))
	var visible_pixels = 0
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.05 and max(pixel.r, max(pixel.g, pixel.b)) >= 0.18:
				visible_pixels += 1
				if visible_pixels >= 4:
					return true
	return false


func _fallback_texture_for_unit(unit_name):
	var image = Image.create(72, 72, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.020, 0.040, 0.050, 1.0))
	var accent = Color(0.42, 0.78, 0.96, 1.0)
	var trim = Color(0.90, 0.98, 1.0, 1.0)
	_draw_rect(image, 0, 0, 72, 3, accent)
	_draw_rect(image, 0, 69, 72, 3, accent)
	_draw_rect(image, 0, 0, 3, 72, accent)
	_draw_rect(image, 69, 0, 3, 72, accent)
	if _is_infantry_name(unit_name):
		_draw_circle(image, 36, 22, 8, trim)
		_draw_rect(image, 28, 32, 16, 19, accent)
		_draw_rect(image, 18, 35, 36, 6, trim)
	else:
		_draw_rect(image, 15, 36, 42, 16, trim)
		_draw_rect(image, 25, 25, 22, 13, accent)
		_draw_rect(image, 45, 23, 17, 5, trim)
		_draw_circle(image, 22, 55, 6, accent.darkened(0.25))
		_draw_circle(image, 50, 55, 6, accent.darkened(0.25))
	return ImageTexture.create_from_image(image)


func _is_infantry_name(unit_name):
	var key = unit_name.to_lower()
	for token in ["worker", "engineer", "infantry", "trooper", "team", "medic", "saboteur", "commando"]:
		if key.contains(token):
			return true
	return false


func _draw_rect(image, left, top, width, height, color):
	for x in range(left, min(left + width, image.get_width())):
		for y in range(top, min(top + height, image.get_height())):
			image.set_pixel(x, y, color)


func _draw_circle(image, center_x, center_y, radius, color):
	var radius_squared = radius * radius
	for x in range(max(0, center_x - radius), min(image.get_width(), center_x + radius + 1)):
		for y in range(max(0, center_y - radius), min(image.get_height(), center_y + radius + 1)):
			var dx = x - center_x
			var dy = y - center_y
			if dx * dx + dy * dy <= radius_squared:
				image.set_pixel(x, y, color)


func _display_name():
	var key = _camel_case_to_key(_unit_name())
	var translated = tr(key)
	return translated if translated != key else _unit_name()


func _unit_name():
	var path = _unit_scene_path()
	var file_name = path.substr(path.rfind("/") + 1)
	return file_name.split(".")[0]


func _unit_scene_path():
	return queue_element.unit_prototype.resource_path


func _camel_case_to_key(value):
	var key = ""
	for index in range(value.length()):
		var character = value[index]
		var previous = value[index - 1] if index > 0 else ""
		if index > 0 and character == character.to_upper() and character != character.to_lower():
			if previous != previous.to_upper() or (
				index + 1 < value.length()
				and value[index + 1] != value[index + 1].to_upper()
			):
				key += "_"
		key += character.to_upper()
	return key
