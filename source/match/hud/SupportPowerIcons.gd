extends RefCounted

const CommandButtonIcons = preload("res://source/match/hud/unit-menus/CommandButtonIcons.gd")
const CommandIconOverlay = preload("res://source/match/hud/unit-menus/CommandIconOverlay.gd")

const ICON_RECT_NAME = "IconTextureRect"
const ICON_OVERLAY_NAME = "SupportPowerIconOverlay"
const META_SUPPORT_POWER_ID = "support_power_icon_id"

static var force_procedural_support_power_icons_for_tests = false
static var enable_web_procedural_support_power_icons = false


static func apply(button, power_id):
	if button == null:
		return
	button.set_meta(META_SUPPORT_POWER_ID, power_id)
	var icon_rect = button.find_child(ICON_RECT_NAME, false, false)
	if icon_rect == null:
		icon_rect = TextureRect.new()
		icon_rect.name = ICON_RECT_NAME
		button.add_child(icon_rect)
	var source_texture = icon_rect.texture if icon_rect.texture != null else button.icon
	var display_texture = CommandButtonIcons.display_texture(source_texture, power_id)
	icon_rect.texture = display_texture
	icon_rect.visible = true
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 6.0
	icon_rect.offset_top = 8.0
	icon_rect.offset_right = -6.0
	icon_rect.offset_bottom = -8.0
	icon_rect.z_index = max(icon_rect.z_index, 2)
	icon_rect.modulate = Color(1, 1, 1, 1)
	button.icon = null
	button.expand_icon = false
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 54)
	button.add_theme_constant_override("h_separation", 0)
	_sync_overlay(button, icon_rect, display_texture, power_id)


static func ensure(button):
	if button == null or not button.has_meta(META_SUPPORT_POWER_ID):
		return
	var icon_rect = button.find_child(ICON_RECT_NAME, false, false)
	if icon_rect == null or icon_rect.texture == null:
		apply(button, button.get_meta(META_SUPPORT_POWER_ID, ""))
	else:
		_sync_overlay(button, icon_rect, icon_rect.texture, button.get_meta(META_SUPPORT_POWER_ID, ""))


static func _sync_overlay(button, icon_rect, display_texture, power_id):
	var overlay = button.find_child(ICON_OVERLAY_NAME, false, false)
	if overlay == null:
		overlay = CommandIconOverlay.new()
		overlay.name = ICON_OVERLAY_NAME
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(overlay)
	var procedural = _should_use_procedural_overlay()
	overlay.visible = false
	overlay.show_behind_parent = false
	overlay.z_index = 4
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.offset_left = 6.0
	overlay.offset_top = 14.0
	overlay.offset_right = -6.0
	overlay.offset_bottom = -18.0
	var icon_color = icon_rect.modulate if icon_rect != null else Color.WHITE
	overlay.set_icon(null if procedural else display_texture, icon_color, power_id, false)


static func _should_use_procedural_overlay():
	return _should_use_procedural_overlay_for_platform(OS.has_feature("web"))


static func _should_use_procedural_overlay_for_platform(has_web_feature):
	return false
