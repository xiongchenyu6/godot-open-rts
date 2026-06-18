extends CanvasLayer

const CommandButtonIcons = preload("res://source/match/hud/unit-menus/CommandButtonIcons.gd")
const CommandIconOverlay = preload("res://source/match/hud/unit-menus/CommandIconOverlay.gd")
const CommandIconMosaic = preload("res://source/match/hud/unit-menus/CommandIconMosaic.gd")

const PANEL_BG = Color(0.035, 0.055, 0.065, 0.92)
const PANEL_BORDER = Color(0.30, 0.42, 0.48, 1.0)
const SLOT_BG = Color(0.020, 0.030, 0.036, 0.94)
const SLOT_BORDER = Color(0.18, 0.25, 0.29, 1.0)
const BUTTON_BG = Color(0.055, 0.080, 0.095, 0.98)
const BUTTON_HOVER_BG = Color(0.090, 0.135, 0.155, 1.0)
const BUTTON_PRESSED_BG = Color(0.025, 0.040, 0.048, 1.0)
const BUTTON_DISABLED_BG = Color(0.025, 0.030, 0.034, 0.86)
const ACCENT = Color(0.42, 0.78, 0.76, 1.0)
const TEXT = Color(0.78, 0.91, 0.88, 1.0)
const TEXT_DIM = Color(0.40, 0.50, 0.50, 1.0)
const DISABLED_ICON = Color(0.76, 0.86, 0.86, 0.88)
const NORMAL_ICON = Color(1.0, 1.0, 1.0, 1.0)
const COMMAND_BUTTON_SIZE = Vector2(112, 112)
const COMMAND_ICON_MARGIN = 8
const COMMAND_ICON_BOTTOM_MARGIN = 8
const COMMAND_ICON_STATUS_BOTTOM_MARGIN = 26
const COMMAND_ICON_TOP_MARGIN = 8
const COMMAND_ICON_STATUS_TOP_MARGIN = 20
const COMMAND_SIDEBAR_MARGIN = 5.0
const COMMAND_VISIBLE_ICON_MAX_SIZE = 58.0
const ICON_BACKDROP_NAME = "CommandIconBackdrop"
const ICON_OVERLAY_NAME = "CommandIconOverlay"
const ICON_GLYPH_LABEL_NAME = "CommandIconGlyphLabel"
const MOSAIC_ICON_NAME = "CommandIconMosaic"
const VISIBLE_ICON_NAME = "CommandVisibleIcon"
const FLOATING_ICON_LAYER_NAME = "CommandFloatingIconLayer"
const FLOATING_ICON_PREFIX = "CommandFloatingIcon_"
const SCREEN_ICON_LAYER_NAME = "CommandScreenIconLayer"
const SCREEN_ICON_PREFIX = "CommandScreenIcon_"
const HOTKEY_LABEL_NAME = "HotkeyLabel"
const FALLBACK_LABEL_NAME = "FallbackIconLabel"
const COST_LABEL_NAME = "CostLabel"
const LOCK_LABEL_NAME = "TechLockLabel"
const NAME_LABEL_NAME = "NameLabel"
const QUEUE_LABEL_NAME = "QueueCountLabel"
const TIME_LABEL_NAME = "TimeLabel"
const STYLE_META = "rts_hud_styled"
const ICON_BACKDROP_COLOR = Color(0.055, 0.085, 0.100, 0.86)
const ICON_BACKDROP_DISABLED_COLOR = Color(0.035, 0.048, 0.055, 0.86)
const FLOATING_ICON_MAX_SIZE = 68.0
const SCREEN_ICON_MAX_SIZE = 68.0
const COMMAND_LABEL_NAMES = [
	ICON_GLYPH_LABEL_NAME,
	FALLBACK_LABEL_NAME,
	HOTKEY_LABEL_NAME,
	COST_LABEL_NAME,
	LOCK_LABEL_NAME,
	NAME_LABEL_NAME,
	QUEUE_LABEL_NAME,
	TIME_LABEL_NAME,
]
const WEB_HUD_SYNC_INTERVAL_SECONDS = 0.12
const DESKTOP_HUD_SYNC_INTERVAL_SECONDS = 0.0

var force_procedural_command_icons_for_tests = false
var enable_web_procedural_command_icons = false
var _hud_sync_elapsed = WEB_HUD_SYNC_INTERVAL_SECONDS
var _last_synced_viewport_size = Vector2.ZERO


func _ready():
	await get_tree().process_frame
	_apply_static_style()
	_sync_command_sidebar_layout()
	_sync_button_icons()


func _process(delta):
	if not _should_sync_hud_this_frame(delta):
		return
	_sync_command_sidebar_layout()
	_sync_button_icons()


func _should_sync_hud_this_frame(delta):
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size != _last_synced_viewport_size:
		_last_synced_viewport_size = viewport_size
		_hud_sync_elapsed = 0.0
		return true
	var sync_interval = (
		WEB_HUD_SYNC_INTERVAL_SECONDS
		if OS.has_feature("web")
		else DESKTOP_HUD_SYNC_INTERVAL_SECONDS
	)
	_hud_sync_elapsed += delta
	if _hud_sync_elapsed < sync_interval:
		return false
	_hud_sync_elapsed = 0.0
	return true


func _apply_static_style():
	for panel_container in find_children("*", "PanelContainer", true, false):
		panel_container.add_theme_stylebox_override("panel", _stylebox(PANEL_BG, PANEL_BORDER, 2, 3))

	for panel in find_children("*", "Panel", true, false):
		panel.add_theme_stylebox_override("panel", _stylebox(SLOT_BG, SLOT_BORDER, 1, 2))

	for button in find_children("*", "Button", true, false):
		_style_button(button)

	for label in find_children("*", "Label", true, false):
		if COMMAND_LABEL_NAMES.has(label.name):
			continue
		label.add_theme_color_override("font_color", TEXT)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)

	for grid in find_children("*", "GridContainer", true, false):
		grid.add_theme_constant_override("h_separation", 0)
		grid.add_theme_constant_override("v_separation", 0)

	for hbox in find_children("*", "HBoxContainer", true, false):
		hbox.add_theme_constant_override("separation", max(4, hbox.get_theme_constant("separation")))

	_style_minimap()


func _style_button(button):
	if button.get_meta(STYLE_META, false):
		return
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _stylebox(BUTTON_BG, PANEL_BORDER, 1, 2))
	button.add_theme_stylebox_override("hover", _stylebox(BUTTON_HOVER_BG, ACCENT, 2, 2))
	button.add_theme_stylebox_override("pressed", _stylebox(BUTTON_PRESSED_BG, ACCENT, 2, 2))
	button.add_theme_stylebox_override("disabled", _stylebox(BUTTON_DISABLED_BG, SLOT_BORDER, 1, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", ACCENT)
	button.add_theme_color_override("font_disabled_color", TEXT_DIM)
	if _is_unit_menu_button(button) and button.custom_minimum_size == Vector2.ZERO:
		button.custom_minimum_size = COMMAND_BUTTON_SIZE
	if _button_has_texture_icon(button):
		button.text = ""
		_sync_button_icon_layout(button)
	button.set_meta(STYLE_META, true)


func _style_minimap():
	var minimap = find_child("Minimap", true, false)
	if minimap != null:
		minimap.custom_minimum_size = Vector2(205, 205)
	var minimap_background = find_child("Background", true, false)
	if minimap_background != null and minimap_background is ColorRect:
		minimap_background.color = Color(0.055, 0.070, 0.070, 1.0)
	var camera_indicator = find_child("CameraIndicator", true, false)
	if camera_indicator != null:
		camera_indicator.default_color = ACCENT
		camera_indicator.width = 2.0


func _stylebox(bg_color, border_color, border_width, corner_radius):
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	return style


func _is_unit_menu_button(button):
	var parent = button.get_parent()
	while parent != null:
		if parent.name == "UnitMenus":
			return true
		parent = parent.get_parent()
	return false


func _sync_command_sidebar_layout():
	var command_anchor = find_child("MarginContainer3", true, false)
	if command_anchor == null:
		return
	var viewport_size = get_viewport().get_visible_rect().size
	var unit_menus = command_anchor.find_child("UnitMenus", true, false)
	if unit_menus != null and unit_menus.has_method("apply_command_panel_layout_for_viewport"):
		unit_menus.apply_command_panel_layout_for_viewport(viewport_size)
	var anchor_size = command_anchor.get_combined_minimum_size()
	if anchor_size == Vector2.ZERO:
		return
	command_anchor.offset_left = -min(anchor_size.x, max(0.0, viewport_size.x - COMMAND_SIDEBAR_MARGIN))
	command_anchor.offset_top = -min(anchor_size.y, max(0.0, viewport_size.y - COMMAND_SIDEBAR_MARGIN))
	command_anchor.offset_right = 0.0
	command_anchor.offset_bottom = 0.0


func _sync_button_icon_layout(button):
	var primary_icon = _primary_button_icon(button)
	var has_texture_icon = primary_icon != null and primary_icon.texture != null
	var should_show_command_icon = has_texture_icon or _is_unit_menu_button(button)
	var icon_rect = _button_icon_rect(button)
	_sync_builtin_button_icon(button, primary_icon, false)
	_sync_icon_backdrop(button, icon_rect, should_show_command_icon)
	for icon in button.find_children("*", "TextureRect", true, false):
		if icon.name == VISIBLE_ICON_NAME:
			continue
		icon.visible = false
		icon.show_behind_parent = false
		icon.z_index = 10
		icon.material = null
		icon.anchor_left = 0.0
		icon.anchor_top = 0.0
		icon.anchor_right = 0.0
		icon.anchor_bottom = 0.0
		icon.position = icon_rect.position
		icon.size = icon_rect.size
		icon.offset_left = icon_rect.position.x
		icon.offset_top = icon_rect.position.y
		icon.offset_right = icon_rect.position.x + icon_rect.size.x
		icon.offset_bottom = icon_rect.position.y + icon_rect.size.y
		icon.custom_minimum_size = icon_rect.size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sync_icon_mosaic(button, icon_rect, false)
	_sync_icon_overlay(button, primary_icon, icon_rect, false)
	_sync_visible_texture_icon(button, primary_icon, icon_rect, should_show_command_icon)
	_sync_floating_icon_overlay(button, primary_icon, icon_rect, false)
	_sync_command_label_layers(button)
	_sync_icon_glyph_label(button, primary_icon, icon_rect, false)


func _sync_builtin_button_icon(button, primary_icon, visible):
	if visible and primary_icon != null:
		button.icon = primary_icon.texture
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", int(_button_icon_rect(button).size.x))
		button.add_theme_constant_override("h_separation", 0)
	else:
		button.icon = null
		button.expand_icon = false


func _sync_icon_overlay(button, primary_icon, icon_rect, visible):
	var overlay = button.find_child(ICON_OVERLAY_NAME, false, false)
	if overlay == null:
		overlay = CommandIconOverlay.new()
		overlay.name = ICON_OVERLAY_NAME
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(overlay)
	overlay.visible = visible
	overlay.show_behind_parent = false
	overlay.z_index = 18
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 0.0
	overlay.anchor_bottom = 0.0
	overlay.position = icon_rect.position
	overlay.size = icon_rect.size
	overlay.offset_left = icon_rect.position.x
	overlay.offset_top = icon_rect.position.y
	overlay.offset_right = icon_rect.position.x + icon_rect.size.x
	overlay.offset_bottom = icon_rect.position.y + icon_rect.size.y
	var icon_color = primary_icon.modulate if primary_icon != null else NORMAL_ICON
	var fallback_key = str(button.get_meta(CommandButtonIcons.META_ICON_SCENE_PATH, button.name))
	overlay.set_icon(_overlay_display_texture(primary_icon, fallback_key), icon_color, fallback_key)
	button.move_child(overlay, button.get_child_count() - 1)


func _sync_icon_mosaic(button, icon_rect, visible):
	var mosaic = button.find_child(MOSAIC_ICON_NAME, false, false)
	if mosaic == null:
		mosaic = CommandIconMosaic.new()
		mosaic.name = MOSAIC_ICON_NAME
		mosaic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(mosaic)
	mosaic.visible = visible and _should_use_mosaic_command_icon()
	mosaic.show_behind_parent = false
	mosaic.z_index = 16
	mosaic.anchor_left = 0.0
	mosaic.anchor_top = 0.0
	mosaic.anchor_right = 0.0
	mosaic.anchor_bottom = 0.0
	mosaic.position = icon_rect.position
	mosaic.size = icon_rect.size
	mosaic.offset_left = icon_rect.position.x
	mosaic.offset_top = icon_rect.position.y
	mosaic.offset_right = icon_rect.position.x + icon_rect.size.x
	mosaic.offset_bottom = icon_rect.position.y + icon_rect.size.y
	var fallback_key = str(button.get_meta(CommandButtonIcons.META_ICON_SCENE_PATH, button.name))
	mosaic.set_icon(fallback_key, button.disabled)
	button.move_child(mosaic, button.get_child_count() - 1)


func _sync_visible_texture_icon(button, primary_icon, icon_rect, visible):
	var icon = button.find_child(VISIBLE_ICON_NAME, false, false)
	if icon == null:
		icon = TextureRect.new()
		icon.name = VISIBLE_ICON_NAME
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
	icon.visible = visible
	icon.show_behind_parent = false
	icon.z_index = 19
	var fallback_key = str(button.get_meta(CommandButtonIcons.META_ICON_SCENE_PATH, button.name))
	icon.texture = _visible_display_texture(primary_icon, fallback_key)
	var centered_rect = _centered_button_icon_rect(icon_rect)
	icon.anchor_left = 0.0
	icon.anchor_top = 0.0
	icon.anchor_right = 0.0
	icon.anchor_bottom = 0.0
	icon.position = centered_rect.position
	icon.size = centered_rect.size
	icon.offset_left = centered_rect.position.x
	icon.offset_top = centered_rect.position.y
	icon.offset_right = centered_rect.position.x + centered_rect.size.x
	icon.offset_bottom = centered_rect.position.y + centered_rect.size.y
	icon.custom_minimum_size = centered_rect.size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	button.move_child(icon, button.get_child_count() - 1)


func _sync_floating_icon_overlay(button, primary_icon, icon_rect, visible):
	var layer = _floating_icon_layer_for_button(button)
	if layer == null:
		return
	var overlay = layer.find_child(_floating_icon_name(button), false, false)
	if overlay == null:
		overlay = CommandIconOverlay.new()
		overlay.name = _floating_icon_name(button)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(overlay)
	overlay.visible = visible and button.is_visible_in_tree()
	overlay.show_behind_parent = false
	overlay.z_index = 0
	var centered_rect = _centered_floating_icon_rect(button, icon_rect, layer)
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 0.0
	overlay.anchor_bottom = 0.0
	overlay.position = centered_rect.position
	overlay.size = centered_rect.size
	overlay.offset_left = centered_rect.position.x
	overlay.offset_top = centered_rect.position.y
	overlay.offset_right = centered_rect.position.x + centered_rect.size.x
	overlay.offset_bottom = centered_rect.position.y + centered_rect.size.y
	var icon_color = primary_icon.modulate if primary_icon != null else NORMAL_ICON
	var fallback_key = str(button.get_meta(CommandButtonIcons.META_ICON_SCENE_PATH, button.name))
	overlay.set_icon(
		_overlay_display_texture(primary_icon, fallback_key),
		icon_color,
		fallback_key,
		false
	)


func _floating_icon_layer_for_button(button):
	var command_panel_viewport = _ancestor_named(button, "CommandPanelViewport")
	if command_panel_viewport == null:
		return null
	var layer = command_panel_viewport.find_child(FLOATING_ICON_LAYER_NAME, false, false)
	if layer == null:
		layer = Control.new()
		layer.name = FLOATING_ICON_LAYER_NAME
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		command_panel_viewport.add_child(layer)
	layer.visible = true
	layer.show_behind_parent = false
	layer.z_index = 100
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.offset_left = 0.0
	layer.offset_top = 0.0
	layer.offset_right = 0.0
	layer.offset_bottom = 0.0
	command_panel_viewport.move_child(layer, command_panel_viewport.get_child_count() - 1)
	return layer


func _centered_floating_icon_rect(button, icon_rect, layer):
	var button_global_position = button.global_position
	var layer_global_position = layer.global_position
	var local_position = button_global_position + icon_rect.position - layer_global_position
	var max_icon_size = minf(FLOATING_ICON_MAX_SIZE, minf(icon_rect.size.x, icon_rect.size.y))
	var floating_size = Vector2(max_icon_size, max_icon_size)
	return Rect2(
		local_position + (icon_rect.size - floating_size) * 0.5,
		floating_size
	)


func _centered_button_icon_rect(icon_rect):
	var max_icon_size = minf(COMMAND_VISIBLE_ICON_MAX_SIZE, minf(icon_rect.size.x, icon_rect.size.y))
	var visible_size = Vector2(max_icon_size, max_icon_size)
	return Rect2(icon_rect.position + (icon_rect.size - visible_size) * 0.5, visible_size)


func _floating_icon_name(button):
	return "{0}{1}".format([FLOATING_ICON_PREFIX, button.get_instance_id()])


func _ancestor_named(node, ancestor_name):
	var parent = node.get_parent()
	while parent != null:
		if parent.name == ancestor_name:
			return parent
		parent = parent.get_parent()
	return null


func _sync_icon_backdrop(button, icon_rect, visible):
	var backdrop = button.find_child(ICON_BACKDROP_NAME, false, false)
	if backdrop == null:
		backdrop = ColorRect.new()
		backdrop.name = ICON_BACKDROP_NAME
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(backdrop)
	backdrop.visible = visible
	backdrop.color = ICON_BACKDROP_DISABLED_COLOR if button.disabled else ICON_BACKDROP_COLOR
	backdrop.show_behind_parent = false
	backdrop.z_index = 5
	backdrop.anchor_left = 0.0
	backdrop.anchor_top = 0.0
	backdrop.anchor_right = 0.0
	backdrop.anchor_bottom = 0.0
	backdrop.position = icon_rect.position
	backdrop.size = icon_rect.size
	backdrop.offset_left = icon_rect.position.x
	backdrop.offset_top = icon_rect.position.y
	backdrop.offset_right = icon_rect.position.x + icon_rect.size.x
	backdrop.offset_bottom = icon_rect.position.y + icon_rect.size.y
	button.move_child(backdrop, 0)


func _primary_button_icon(button):
	for icon in button.find_children("*", "TextureRect", true, false):
		if icon.name == VISIBLE_ICON_NAME:
			continue
		if icon.texture != null:
			return icon
	return null


func _button_has_texture_icon(button):
	for icon in button.find_children("*", "TextureRect", true, false):
		if icon.name != VISIBLE_ICON_NAME:
			return true
	return false


func _button_icon_rect(button):
	var button_size = _button_size_for_icon_layout(button)
	var top_margin = _command_icon_top_margin(button, null)
	var bottom_margin = _command_icon_bottom_margin(button, null)
	if button.find_child("IconTextureRect", true, false) != null:
		bottom_margin = max(bottom_margin, COMMAND_ICON_STATUS_BOTTOM_MARGIN)
	var width = maxf(24.0, button_size.x - COMMAND_ICON_MARGIN * 2.0)
	var height = maxf(24.0, button_size.y - top_margin - bottom_margin)
	return Rect2(Vector2(COMMAND_ICON_MARGIN, top_margin), Vector2(width, height))


func _button_size_for_icon_layout(button):
	var minimum_size = button.custom_minimum_size
	if minimum_size.x < 1.0 or minimum_size.y < 1.0:
		minimum_size = COMMAND_BUTTON_SIZE
	return Vector2(
		maxf(button.size.x, minimum_size.x),
		maxf(button.size.y, minimum_size.y)
	)


func _sync_command_label_layers(button):
	for label in button.find_children("*", "Label", true, false):
		if label.get_parent() != button:
			continue
		if label.name == ICON_GLYPH_LABEL_NAME:
			continue
		label.z_index = 20
		button.move_child(label, button.get_child_count() - 1)


func _sync_icon_glyph_label(button, _primary_icon, icon_rect, visible):
	var label = button.find_child(ICON_GLYPH_LABEL_NAME, false, false)
	if not _should_show_icon_glyph_label(visible):
		if label != null:
			label.visible = false
		return
	if label == null:
		label = Label.new()
		label.name = ICON_GLYPH_LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(0.86, 0.98, 1.0, 0.96))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.98))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		button.add_child(label)
	var fallback_key = str(button.get_meta(CommandButtonIcons.META_ICON_SCENE_PATH, button.name))
	label.text = CommandButtonIcons.abbreviation_for_key(fallback_key)
	label.visible = true
	label.z_index = 24
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 0.0
	label.anchor_bottom = 0.0
	label.position = icon_rect.position + icon_rect.size * Vector2(0.5, 0.58) - Vector2(28, 12)
	label.size = Vector2(56, 24)
	label.offset_left = label.position.x
	label.offset_top = label.position.y
	label.offset_right = label.position.x + label.size.x
	label.offset_bottom = label.position.y + label.size.y
	button.move_child(label, button.get_child_count() - 1)


func _should_show_icon_glyph_label(visible):
	return false


func _overlay_texture_for_icon(primary_icon):
	if _should_use_procedural_command_overlay():
		return null
	return primary_icon.texture if primary_icon != null else null


func _overlay_display_texture(primary_icon, fallback_key):
	if _should_use_procedural_command_overlay():
		return null
	return CommandButtonIcons.display_texture(_overlay_texture_for_icon(primary_icon), fallback_key)


func _visible_display_texture(primary_icon, fallback_key):
	var texture = primary_icon.texture if primary_icon != null else null
	return CommandButtonIcons.display_texture(texture, fallback_key)


func _should_use_procedural_command_overlay():
	return _should_use_procedural_command_overlay_for_platform(OS.has_feature("web"))


func _should_use_mosaic_command_icon():
	return false


func _should_use_procedural_command_overlay_for_platform(has_web_feature):
	return false


func _command_icon_top_margin(button, _icon):
	var queue_label = button.find_child(QUEUE_LABEL_NAME, false, false)
	var lock_label = button.find_child(LOCK_LABEL_NAME, false, false)
	if (
		(queue_label != null and queue_label.visible)
		or (lock_label != null and lock_label.visible)
	):
		return COMMAND_ICON_STATUS_TOP_MARGIN
	return COMMAND_ICON_TOP_MARGIN


func _command_icon_bottom_margin(button, _icon):
	var name_label = button.find_child(NAME_LABEL_NAME, false, false)
	var bottom_margin = COMMAND_ICON_BOTTOM_MARGIN
	var time_label = button.find_child(TIME_LABEL_NAME, false, false)
	if time_label != null and time_label.visible:
		bottom_margin = max(bottom_margin, COMMAND_ICON_STATUS_BOTTOM_MARGIN + 18)
	if name_label != null and name_label.visible:
		bottom_margin = max(bottom_margin, COMMAND_ICON_STATUS_BOTTOM_MARGIN + 18)
	var cost_label = button.find_child(COST_LABEL_NAME, false, false)
	if cost_label != null and cost_label.visible:
		bottom_margin = max(bottom_margin, COMMAND_ICON_STATUS_BOTTOM_MARGIN)
	return bottom_margin


func _sync_button_icons():
	for button in find_children("*", "Button", true, false):
		if not button.get_meta(STYLE_META, false):
			_style_button(button)
		if _is_unit_menu_button(button):
			CommandButtonIcons.ensure_for_button(button)
			_ensure_command_button_icon_rect(button)
			_fill_missing_command_icon_textures(button)
		var icon_modulate = DISABLED_ICON if button.disabled else NORMAL_ICON
		for icon in button.find_children("*", "TextureRect", true, false):
			icon.modulate = icon_modulate
		if _button_has_texture_icon(button):
			button.text = ""
			_sync_button_icon_layout(button)
			_apply_button_icon_color(button, icon_modulate)
	_hide_screen_icon_overlays()


func _ensure_command_button_icon_rect(button):
	if _button_has_texture_icon(button):
		return
	var icon = TextureRect.new()
	icon.name = "TextureRect"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	button.add_child(icon)


func _fill_missing_command_icon_textures(button):
	var fallback_key = str(button.get_meta(CommandButtonIcons.META_ICON_SCENE_PATH, button.name))
	for icon in button.find_children("*", "TextureRect", true, false):
		if icon.name == VISIBLE_ICON_NAME:
			continue
		if icon.texture == null:
			icon.texture = CommandButtonIcons.fallback_texture_for_key(fallback_key)


func _apply_button_icon_color(button, icon_color):
	for color_name in [
		"icon_normal_color",
		"icon_pressed_color",
		"icon_hover_color",
		"icon_hover_pressed_color",
		"icon_disabled_color",
		"icon_focus_color",
	]:
		button.add_theme_color_override(color_name, icon_color)


func _sync_screen_icon_overlays(buttons):
	var layer = _screen_icon_layer()
	if layer == null:
		return
	var active_overlay_names = {}
	for button in buttons:
		if button == null or not button.is_visible_in_tree():
			continue
		var primary_icon = _primary_button_icon(button)
		if primary_icon == null:
			continue
		var icon_rect = _button_icon_rect(button)
		var overlay_name = _screen_icon_name(button)
		active_overlay_names[overlay_name] = true
		var overlay = layer.find_child(overlay_name, false, false)
		if overlay == null:
			overlay = CommandIconOverlay.new()
			overlay.name = overlay_name
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.add_child(overlay)
		overlay.visible = true
		overlay.show_behind_parent = false
		overlay.z_index = 0
		var centered_rect = _centered_screen_icon_rect(button, icon_rect, layer)
		overlay.anchor_left = 0.0
		overlay.anchor_top = 0.0
		overlay.anchor_right = 0.0
		overlay.anchor_bottom = 0.0
		overlay.position = centered_rect.position
		overlay.size = centered_rect.size
		overlay.offset_left = centered_rect.position.x
		overlay.offset_top = centered_rect.position.y
		overlay.offset_right = centered_rect.position.x + centered_rect.size.x
		overlay.offset_bottom = centered_rect.position.y + centered_rect.size.y
		var fallback_key = str(button.get_meta(CommandButtonIcons.META_ICON_SCENE_PATH, button.name))
		overlay.set_icon(
			_overlay_display_texture(primary_icon, fallback_key),
			primary_icon.modulate,
			fallback_key,
			false
		)
	for child in layer.get_children():
		if not str(child.name).begins_with(SCREEN_ICON_PREFIX):
			continue
		child.visible = active_overlay_names.has(str(child.name))


func _screen_icon_layer():
	var layer = find_child(SCREEN_ICON_LAYER_NAME, false, false)
	if layer == null:
		layer = Control.new()
		layer.name = SCREEN_ICON_LAYER_NAME
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(layer)
	layer.visible = true
	layer.show_behind_parent = false
	layer.z_index = 1024
	layer.anchor_left = 0.0
	layer.anchor_top = 0.0
	layer.anchor_right = 0.0
	layer.anchor_bottom = 0.0
	layer.position = Vector2.ZERO
	layer.size = get_viewport().get_visible_rect().size
	layer.custom_minimum_size = layer.size
	layer.offset_left = 0.0
	layer.offset_top = 0.0
	layer.offset_right = 0.0
	layer.offset_bottom = 0.0
	move_child(layer, get_child_count() - 1)
	return layer


func _centered_screen_icon_rect(button, icon_rect, layer):
	var local_position = button.global_position + icon_rect.position - layer.global_position
	var max_icon_size = minf(SCREEN_ICON_MAX_SIZE, minf(icon_rect.size.x, icon_rect.size.y))
	var screen_icon_size = Vector2(max_icon_size, max_icon_size)
	return Rect2(
		local_position + (icon_rect.size - screen_icon_size) * 0.5,
		screen_icon_size
	)


func _screen_icon_name(button):
	return "{0}{1}".format([SCREEN_ICON_PREFIX, button.get_instance_id()])


func _hide_screen_icon_overlays():
	var layer = find_child(SCREEN_ICON_LAYER_NAME, false, false)
	if layer == null:
		return
	layer.visible = false
	for child in layer.get_children():
		child.visible = false
