extends RefCounted

const ProductionQueueElement = preload("res://source/match/hud/ProductionQueueElement.gd")
const ICON_DIRECTORY = "res://assets/ui/icons"
const FALLBACK_LABEL_NAME = "FallbackIconLabel"
const META_FALLBACK_ICON = "command_fallback_icon"
const META_ICON_SCENE_PATH = "command_icon_scene_path"
const FALLBACK_TEXTURE_SIZE = 72
const FALLBACK_PALETTE = [
	Color(0.14, 0.55, 0.95, 1.0),
	Color(0.11, 0.74, 0.56, 1.0),
	Color(0.95, 0.70, 0.16, 1.0),
	Color(0.86, 0.28, 0.24, 1.0),
	Color(0.56, 0.64, 0.78, 1.0),
	Color(0.75, 0.47, 0.18, 1.0),
]
const CANONICAL_ICON_ALIASES = {}

static var _fallback_textures = {}
static var _web_display_textures = {}


static func texture_for_scene(scene_path):
	if scene_path == "":
		return null
	var icon_path = _existing_icon_path_for_scene(scene_path)
	if icon_path == "":
		return _fallback_texture_for_scene(scene_path)
	var icon_texture = load(icon_path)
	if icon_texture == null:
		return _fallback_texture_for_scene(scene_path)
	return display_texture(icon_texture, scene_path)


static func fallback_texture_for_key(key):
	return _fallback_texture_for_scene(key)


static func canonical_icon_path_for_scene(scene_path):
	return _canonical_icon_path_for_scene(scene_path)


static func abbreviation_for_key(key):
	return _scene_abbreviation(str(key))


static func display_texture(source_texture, fallback_key):
	if source_texture == null:
		return _fallback_texture_for_scene(fallback_key)
	var image = source_texture.get_image()
	if image == null or image.is_empty() or not _image_has_visible_content(image):
		var fallback_texture = _fallback_texture_for_scene(fallback_key)
		return fallback_texture
	if not OS.has_feature("web"):
		return source_texture
	var cache_key = source_texture.resource_path
	if cache_key == "":
		cache_key = str(source_texture.get_rid().get_id())
	if _web_display_textures.has(cache_key):
		return _web_display_textures[cache_key]
	var runtime_texture = ImageTexture.create_from_image(image)
	_web_display_textures[cache_key] = runtime_texture
	return runtime_texture


static func apply_for_scene(button, scene_path):
	if button == null or scene_path == "":
		return
	button.set_meta(META_ICON_SCENE_PATH, scene_path)
	var icon_path = _existing_icon_path_for_scene(scene_path)
	var texture = texture_for_scene(scene_path)
	if texture == null:
		return
	var icon_rect = _ensure_icon_rect(button)
	icon_rect.texture = texture
	icon_rect.visible = true
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.icon = null
	button.expand_icon = false
	button.add_theme_constant_override("icon_max_width", 78)
	button.add_theme_constant_override("h_separation", 0)
	button.text = ""
	var is_fallback = icon_path == ""
	button.set_meta(META_FALLBACK_ICON, is_fallback)
	_update_fallback_label(button, scene_path, false)


static func ensure_for_button(button):
	if button == null or not button.has_meta(META_ICON_SCENE_PATH):
		return
	var icon_rect = _ensure_icon_rect(button)
	if icon_rect.texture != null:
		return
	apply_for_scene(button, button.get_meta(META_ICON_SCENE_PATH, ""))


static func _icon_path_for_scene(scene_path):
	var canonical_icon_path = _canonical_icon_path_for_scene(scene_path)
	if canonical_icon_path != "":
		return canonical_icon_path
	if ProductionQueueElement.SCENE_ICON_PATHS.has(scene_path):
		return ProductionQueueElement.SCENE_ICON_PATHS[scene_path]
	return ""


static func _canonical_icon_path_for_scene(scene_path):
	var scene_name = _scene_name(scene_path)
	if scene_name == "":
		return ""
	var icon_path = "{0}/{1}.png".format([ICON_DIRECTORY, scene_name])
	if _asset_exists(icon_path):
		return icon_path
	var alias_name = CANONICAL_ICON_ALIASES.get(scene_name, "")
	if alias_name == "":
		return ""
	var alias_icon_path = "{0}/{1}.png".format([ICON_DIRECTORY, alias_name])
	return alias_icon_path if _asset_exists(alias_icon_path) else ""


static func _existing_icon_path_for_scene(scene_path):
	var icon_path = _icon_path_for_scene(scene_path)
	if icon_path != "" and _asset_exists(icon_path):
		return icon_path
	return ""


static func _asset_exists(path):
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


static func _fallback_texture_for_scene(scene_path):
	if _fallback_textures.has(scene_path):
		return _fallback_textures[scene_path]
	var image = Image.create(FALLBACK_TEXTURE_SIZE, FALLBACK_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.020, 0.045, 0.055, 1.0))
	var accent = _accent_color_for_scene(scene_path)
	var trim = Color(0.86, 0.96, 1.0, 1.0)
	_draw_rect(image, 0, 0, FALLBACK_TEXTURE_SIZE, 3, accent)
	_draw_rect(image, 0, FALLBACK_TEXTURE_SIZE - 3, FALLBACK_TEXTURE_SIZE, 3, accent)
	_draw_rect(image, 0, 0, 3, FALLBACK_TEXTURE_SIZE, accent)
	_draw_rect(image, FALLBACK_TEXTURE_SIZE - 3, 0, 3, FALLBACK_TEXTURE_SIZE, accent)
	_draw_rect(image, 5, 5, FALLBACK_TEXTURE_SIZE - 10, FALLBACK_TEXTURE_SIZE - 10, Color(0.05, 0.09, 0.10, 1.0))
	var key = scene_path.to_lower()
	if _is_structure_key(key):
		_draw_structure_image(image, accent, trim)
	elif _is_air_key(key):
		_draw_air_image(image, accent, trim)
	elif _is_infantry_key(key):
		_draw_infantry_image(image, accent, trim)
	else:
		_draw_vehicle_image(image, accent, trim)
	var texture = ImageTexture.create_from_image(image)
	_fallback_textures[scene_path] = texture
	return texture


static func _accent_color_for_scene(scene_path):
	var hash_value = absi(scene_path.hash())
	return FALLBACK_PALETTE[hash_value % FALLBACK_PALETTE.size()]


static func _draw_rect(image, left, top, width, height, color):
	for x in range(left, min(left + width, image.get_width())):
		for y in range(top, min(top + height, image.get_height())):
			image.set_pixel(x, y, color)


static func _draw_structure_image(image, accent, trim):
	_draw_rect(image, 16, 39, 40, 17, trim)
	_draw_rect(image, 20, 35, 32, 6, accent.lightened(0.10))
	_draw_rect(image, 27, 25, 18, 12, accent)
	_draw_rect(image, 33, 15, 6, 14, trim)
	_draw_circle(image, 36, 14, 5, accent.lightened(0.10))
	_draw_rect(image, 22, 46, 28, 4, accent.darkened(0.10))


static func _draw_air_image(image, accent, trim):
	_draw_triangle(image, Vector2i(36, 12), Vector2i(46, 52), Vector2i(36, 62), accent)
	_draw_triangle(image, Vector2i(36, 12), Vector2i(26, 52), Vector2i(36, 62), accent.lightened(0.06))
	_draw_triangle(image, Vector2i(10, 36), Vector2i(62, 36), Vector2i(36, 48), trim)
	_draw_rect(image, 33, 21, 6, 28, trim)
	_draw_rect(image, 28, 55, 16, 4, accent.darkened(0.16))


static func _draw_infantry_image(image, accent, trim):
	_draw_circle(image, 36, 22, 8, trim)
	_draw_rect(image, 28, 32, 16, 19, accent)
	_draw_rect(image, 18, 34, 36, 6, trim)
	_draw_rect(image, 25, 51, 7, 12, trim)
	_draw_rect(image, 40, 51, 7, 12, trim)
	_draw_rect(image, 31, 37, 10, 6, accent.lightened(0.16))


static func _draw_vehicle_image(image, accent, trim):
	_draw_rect(image, 15, 35, 42, 17, trim)
	_draw_rect(image, 25, 25, 22, 13, accent)
	_draw_rect(image, 45, 23, 17, 5, trim)
	_draw_circle(image, 22, 55, 6, accent.darkened(0.25))
	_draw_circle(image, 50, 55, 6, accent.darkened(0.25))
	_draw_rect(image, 29, 39, 18, 4, accent.lightened(0.10))


static func _draw_circle(image, center_x, center_y, radius, color):
	var radius_squared = radius * radius
	for x in range(max(0, center_x - radius), min(image.get_width(), center_x + radius + 1)):
		for y in range(max(0, center_y - radius), min(image.get_height(), center_y + radius + 1)):
			var dx = x - center_x
			var dy = y - center_y
			if dx * dx + dy * dy <= radius_squared:
				image.set_pixel(x, y, color)


static func _draw_triangle(image, point_a, point_b, point_c, color):
	var min_x = max(0, min(point_a.x, min(point_b.x, point_c.x)))
	var max_x = min(image.get_width() - 1, max(point_a.x, max(point_b.x, point_c.x)))
	var min_y = max(0, min(point_a.y, min(point_b.y, point_c.y)))
	var max_y = min(image.get_height() - 1, max(point_a.y, max(point_b.y, point_c.y)))
	var area = _edge(point_a, point_b, point_c)
	if area == 0:
		return
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var point = Vector2i(x, y)
			var w0 = _edge(point_b, point_c, point)
			var w1 = _edge(point_c, point_a, point)
			var w2 = _edge(point_a, point_b, point)
			if (
				(w0 >= 0 and w1 >= 0 and w2 >= 0)
				or (w0 <= 0 and w1 <= 0 and w2 <= 0)
			):
				image.set_pixel(x, y, color)


static func _edge(point_a, point_b, point_c):
	return (
		(point_c.x - point_a.x) * (point_b.y - point_a.y)
		- (point_c.y - point_a.y) * (point_b.x - point_a.x)
	)


static func _is_structure_key(key):
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


static func _is_air_key(key):
	for token in ["air", "helicopter", "vtol", "gunship", "bomber"]:
		if key.contains(token):
			return true
	return false


static func _is_infantry_key(key):
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


static func _image_has_visible_content(image):
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


static func _ensure_icon_rect(button):
	var icon_rect = button.find_child("TextureRect", true, false)
	if icon_rect != null:
		return icon_rect
	icon_rect = TextureRect.new()
	icon_rect.name = "TextureRect"
	button.add_child(icon_rect)
	return icon_rect


static func _update_fallback_label(button, scene_path, visible):
	var label = button.find_child(FALLBACK_LABEL_NAME, false, false)
	if not visible:
		if label != null:
			label.visible = false
		return
	if label == null:
		label = Label.new()
		label.name = FALLBACK_LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 24
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 19)
		label.add_theme_color_override("font_color", Color(0.90, 0.99, 1.0, 1.0))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		button.add_child(label)
	label.visible = true
	label.z_index = 24
	label.text = _scene_abbreviation(scene_path)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -34
	label.offset_top = -13
	label.offset_right = 34
	label.offset_bottom = 14
	button.move_child(label, button.get_child_count() - 1)


static func _scene_abbreviation(scene_path):
	var scene_name = _scene_name(scene_path)
	var abbreviation = ""
	for index in range(scene_name.length()):
		var character = scene_name[index]
		if character == character.to_upper() and character != character.to_lower():
			abbreviation += character
	if abbreviation.length() <= 1:
		abbreviation = scene_name.substr(0, min(scene_name.length(), 3))
	return abbreviation.substr(0, min(abbreviation.length(), 3)).to_upper()


static func _scene_name(scene_path):
	var file_name = scene_path.substr(scene_path.rfind("/") + 1)
	var dot_index = file_name.rfind(".")
	return file_name.substr(0, dot_index) if dot_index >= 0 else file_name
