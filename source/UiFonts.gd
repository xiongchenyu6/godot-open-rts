extends Node

const APPLIED_META = "rts_ui_font_applied"
const POPUP_REFRESH_CONNECTED_META = "rts_ui_font_popup_refresh_connected"
const UI_FONT_PATH = "res://assets/fonts/wqy-microhei-ui.ttf"
const FONT_THEME_ITEMS = [
	"font",
	"font_separator",
	"normal_font",
	"bold_font",
	"italics_font",
	"bold_italics_font",
	"mono_font",
]
const POPUP_MARKER_ICON_ITEMS = [
	"checked",
	"unchecked",
	"radio_checked",
	"radio_unchecked",
	"visibility_checked",
	"visibility_unchecked",
]

var _ui_font = null
var _blank_popup_marker_icon = null


func _ready():
	_ui_font = load(UI_FONT_PATH)
	_blank_popup_marker_icon = _create_blank_popup_marker_icon()
	_apply_theme_fallback_font()
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_apply_to_tree", get_tree().root)


func _on_node_added(node):
	call_deferred("_apply_to_tree", node)


func _apply_to_tree(node):
	if node == null or not is_instance_valid(node):
		return
	_apply_to_node(node)
	for child in node.get_children():
		_apply_to_tree(child)


func _apply_to_node(node):
	if _ui_font == null:
		return
	_apply_theme_font_overrides(node, node is PopupMenu)
	if node is PopupMenu:
		_apply_popup_menu_theme(node)
	if node is OptionButton:
		_apply_to_option_button_popup(node)


func _apply_theme_fallback_font():
	if _ui_font == null:
		return
	ThemeDB.set_fallback_font(_ui_font)
	var default_theme = ThemeDB.get_default_theme()
	if default_theme != null:
		default_theme.default_font = _ui_font
	var project_theme = ThemeDB.get_project_theme()
	if project_theme != null:
		project_theme.default_font = _ui_font


func _apply_theme_font_overrides(node, force = false):
	if not force and node.get_meta(APPLIED_META, false):
		return
	if not node.has_method("add_theme_font_override"):
		return
	for theme_item in FONT_THEME_ITEMS:
		node.add_theme_font_override(theme_item, _ui_font)
	node.set_meta(APPLIED_META, true)


func _apply_popup_menu_theme(popup):
	if popup.has_method("set_prefer_native_menu"):
		popup.prefer_native_menu = false
	var popup_theme = popup.theme
	if popup_theme == null:
		popup_theme = Theme.new()
		popup.theme = popup_theme
	popup_theme.default_font = _ui_font
	popup_theme.set_font("font", "PopupMenu", _ui_font)
	popup_theme.set_font("font_separator", "PopupMenu", _ui_font)
	for icon_item in POPUP_MARKER_ICON_ITEMS:
		popup_theme.set_icon(icon_item, "PopupMenu", _blank_popup_marker_icon)
	popup.add_theme_font_override("font", _ui_font)
	popup.add_theme_font_override("font_separator", _ui_font)
	for icon_item in POPUP_MARKER_ICON_ITEMS:
		popup.add_theme_icon_override(icon_item, _blank_popup_marker_icon)
	popup.add_theme_constant_override("item_start_padding", 8)
	popup.add_theme_constant_override("item_end_padding", 8)


func _apply_to_option_button_popup(option_button):
	var popup = option_button.get_popup()
	if popup == null:
		return
	_apply_to_tree(popup)
	_normalize_option_popup_items(popup)
	if not popup.get_meta(POPUP_REFRESH_CONNECTED_META, false):
		popup.about_to_popup.connect(_refresh_option_popup_fonts.bind(popup))
		popup.set_meta(POPUP_REFRESH_CONNECTED_META, true)


func _refresh_option_popup_fonts(popup):
	_apply_to_tree(popup)
	_normalize_option_popup_items(popup)
	call_deferred("_normalize_option_popup_items", popup)


func _normalize_option_popup_items(popup):
	if popup == null or not is_instance_valid(popup):
		return
	for item_index in range(popup.get_item_count()):
		popup.set_item_as_radio_checkable(item_index, false)
		popup.set_item_as_checkable(item_index, false)
		popup.set_item_checked(item_index, false)


func _create_blank_popup_marker_icon():
	var image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 0))
	return ImageTexture.create_from_image(image)
