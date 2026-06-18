extends Node

const RtsHudStylerScript = preload("res://source/match/hud/RtsHudStyler.gd")
const UnitMenusScene = preload("res://source/match/hud/UnitMenus.tscn")
const CommandButtonIcons = preload("res://source/match/hud/unit-menus/CommandButtonIcons.gd")
const CommandButtonStatus = preload("res://source/match/hud/unit-menus/CommandButtonStatus.gd")
const CommandCenterMenuScript = preload("res://source/match/hud/unit-menus/CommandCenterMenu.gd")

const VIEWPORT_SIZE = Vector2(1280, 720)
const COMMAND_CENTER_BUTTONS = [
	"ProduceWorkerButton",
	"ProduceEngineerDroneButton",
	"SellStructureButton",
	"SetRallyPointButton",
]
const MENU_NAMES = [
	"CommandCenterMenu",
	"VehicleFactoryMenu",
	"AircraftFactoryMenu",
	"BarracksMenu",
	"WorkerMenu",
	"GenericMenu",
]
const ICON_OVERLAY_NAME = "CommandIconOverlay"
const ICON_GLYPH_LABEL_NAME = "CommandIconGlyphLabel"
const MOSAIC_ICON_NAME = "CommandIconMosaic"
const VISIBLE_ICON_NAME = "CommandVisibleIcon"
const FLOATING_ICON_LAYER_NAME = "CommandFloatingIconLayer"
const FLOATING_ICON_PREFIX = "CommandFloatingIcon_"
const SCREEN_ICON_LAYER_NAME = "CommandScreenIconLayer"
const SCREEN_ICON_PREFIX = "CommandScreenIcon_"
const COMMAND_STATUS_LABEL_NAMES = [
	"QueueCountLabel",
	"TechLockLabel",
	"NameLabel",
	"CostLabel",
	"TimeLabel",
]


class FakePlayer:
	extends Node

	signal changed

	func has_resources(_costs):
		return true


class FakeQueue:
	extends RefCounted

	signal element_enqueued(element)
	signal element_removed(element)

	func size():
		return 0

	func get_elements():
		return []

	func produce(_unit_scene):
		return null


class FakeCommandCenter:
	extends Node

	var player = null
	var production_queue = null

	func _init(fake_player):
		player = fake_player
		production_queue = FakeQueue.new()
		var rally_point = Node.new()
		rally_point.name = "RallyPoint"
		add_child(rally_point)


class FakeProducer:
	extends Node

	var player = null
	var production_queue = null

	func _init(fake_player):
		player = fake_player
		production_queue = FakeQueue.new()
		var rally_point = Node.new()
		rally_point.name = "RallyPoint"
		add_child(rally_point)


class FakeWorker:
	extends FakeProducer

	func can_deploy_as_command_center():
		return true

	func deploy_as_command_center():
		pass


func _ready():
	get_window().size = Vector2i(VIEWPORT_SIZE)

	var background = ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var hud_styler = RtsHudStylerScript.new()
	add_child(hud_styler)
	assert(
		not hud_styler._should_use_procedural_command_overlay_for_platform(true),
		"Web builds should avoid stacked procedural command overlays when texture icons are available"
	)
	assert(
		not hud_styler._should_use_procedural_command_overlay_for_platform(false),
		"native builds should keep packaged command icon textures by default"
	)
	hud_styler.enable_web_procedural_command_icons = true
	assert(
		not hud_styler._should_use_procedural_command_overlay_for_platform(true),
		"enabling legacy procedural command icons should not reintroduce stacked command art"
	)
	var unit_menus = UnitMenusScene.instantiate()
	hud_styler.add_child(unit_menus)

	await get_tree().process_frame
	unit_menus.apply_command_panel_layout_for_viewport(VIEWPORT_SIZE)
	await get_tree().process_frame

	var fake_player = FakePlayer.new()
	var fake_command_center = FakeCommandCenter.new(fake_player)
	var fake_vehicle_factory = FakeProducer.new(fake_player)
	var fake_aircraft_factory = FakeProducer.new(fake_player)
	var fake_barracks = FakeProducer.new(fake_player)
	var fake_worker = FakeWorker.new(fake_player)
	add_child(fake_player)
	add_child(fake_command_center)
	add_child(fake_vehicle_factory)
	add_child(fake_aircraft_factory)
	add_child(fake_barracks)
	add_child(fake_worker)

	var command_center_menu = unit_menus.find_child("CommandCenterMenu", true, false)
	assert(command_center_menu is CommandCenterMenuScript, "command center menu should load")
	var menu_units = {
		"CommandCenterMenu": fake_command_center,
		"VehicleFactoryMenu": fake_vehicle_factory,
		"AircraftFactoryMenu": fake_aircraft_factory,
		"BarracksMenu": fake_barracks,
		"WorkerMenu": fake_worker,
	}
	unit_menus.position = Vector2(40, 40)

	for menu_name in MENU_NAMES:
		var menu = unit_menus.find_child(menu_name, true, false)
		assert(menu != null, "{0} should load".format([menu_name]))
		_prepare_menu(menu, menu_units.get(menu_name, null))
		_show_menu_for_test(unit_menus, menu)
		for frame in range(6):
			await get_tree().process_frame
		var buttons = _visible_menu_buttons(menu)
		assert(buttons.size() > 0, "{0} should expose command buttons".format([menu_name]))
		for button in buttons:
			await _assert_button_has_packaged_icon(unit_menus, hud_styler, button)

	_show_menu_for_test(unit_menus, command_center_menu)
	for frame in range(4):
		await get_tree().process_frame
	for button_name in COMMAND_CENTER_BUTTONS:
		var button = command_center_menu.find_child(button_name, true, false)
		await _assert_button_has_packaged_icon(unit_menus, hud_styler, button)

	_show_menu_for_test(unit_menus, command_center_menu)
	for frame in range(4):
		await get_tree().process_frame

	var empty_button = Button.new()
	empty_button.name = "MissingTextureRectCommandButton"
	empty_button.custom_minimum_size = Vector2(112, 112)
	command_center_menu.add_child(empty_button)
	_show_menu_for_test(unit_menus, command_center_menu)
	for frame in range(4):
		await get_tree().process_frame
	var empty_icon = empty_button.find_child("TextureRect", true, false)
	assert(
		empty_icon != null and empty_icon.texture != null,
		"command buttons without authored TextureRect should get a generated fallback icon"
	)
	assert(
		empty_icon.texture.resource_path == "",
		"missing TextureRect command button fallback should be runtime-generated"
	)
	await _assert_button_has_packaged_icon(unit_menus, hud_styler, empty_button)

	var fallback_button = command_center_menu.find_child("ProduceWorkerButton", true, false)
	var fallback_icon = fallback_button.find_child("TextureRect", true, false)
	fallback_button.set_meta(
		CommandButtonIcons.META_ICON_SCENE_PATH,
		"res://source/match/units/MissingWebIconFixture.tscn"
	)
	fallback_icon.texture = null
	fallback_button.icon = null
	for frame in range(4):
		await get_tree().process_frame

	var fallback_overlay = fallback_button.find_child(ICON_OVERLAY_NAME, false, false)
	assert(fallback_icon.texture != null, "texture-less command buttons should get a generated fallback texture")
	assert(
		fallback_icon.texture.resource_path == "",
		"texture-less command button fallback should be runtime-generated instead of a missing asset"
	)
	assert(fallback_button.icon == null, "fallback command cells should avoid duplicate Button.icon drawing")
	assert(fallback_overlay == null or not fallback_overlay.visible, "fallback overlay should stay hidden")
	var fallback_floating_overlay = _optional_floating_overlay_for_button(unit_menus, fallback_button)
	assert(
		fallback_floating_overlay == null or not fallback_floating_overlay.visible,
		"fallback command icon should not draw a second command-panel-level icon"
	)
	var fallback_screen_overlay = _optional_screen_overlay_for_button(hud_styler, fallback_button)
	assert(
		fallback_screen_overlay == null or not fallback_screen_overlay.visible,
		"fallback command icon should not draw a duplicate HUD-level screen icon"
	)
	assert(
		_count_texture_bright_pixels(fallback_icon.texture) >= 120,
		"generated fallback command icon should be readable on dark cells"
	)
	var fallback_visible_icon = _visible_icon_for_button(fallback_button)
	assert(
		fallback_visible_icon.texture == fallback_icon.texture,
		"fallback visible icon layer should draw the generated icon"
	)
	CommandButtonStatus._update_queue_label(fallback_button, 2, false)
	CommandButtonStatus._update_lock_label(fallback_button, true)
	for frame in range(4):
		await get_tree().process_frame
	_assert_status_labels_do_not_overlap_visible_icon(
		fallback_button,
		_visible_icon_for_button(fallback_button)
	)

	get_tree().quit()


func _prepare_menu(menu, producer_unit):
	if producer_unit != null:
		if "unit" in menu:
			menu.unit = producer_unit
		if "units" in menu:
			menu.units = [producer_unit]
		if menu.has_method("refresh"):
			menu.refresh()


func _show_menu_for_test(unit_menus, menu):
	unit_menus._hide_all_menus()
	unit_menus._show_menu(menu)
	unit_menus.show()


func _visible_menu_buttons(menu):
	var buttons = []
	for button in menu.find_children("*", "Button", true, false):
		if button.visible and button.is_visible_in_tree():
			buttons.append(button)
	return buttons


func _assert_button_has_packaged_icon(unit_menus, hud_styler, button):
	var label = _button_label(button)
	assert(button != null, "command button should be present")
	var icon = button.find_child("TextureRect", true, false)
	assert(icon != null and icon.texture != null, "{0} should have a texture icon".format([label]))
	assert(not icon.visible, "{0} source texture node should stay hidden to avoid double drawing".format([label]))
	var visible_icon = _visible_icon_for_button(button)
	assert(
		visible_icon.texture != null,
		"{0} visible icon layer should draw a texture inside the button".format([label])
	)
	assert(
		visible_icon.texture == icon.texture,
		"{0} visible icon layer should be the only layer drawing the command texture".format([label])
	)
	assert(
		visible_icon.size.x >= 48.0 and visible_icon.size.y >= 48.0,
		"{0} visible icon layer should reserve a readable button area".format([label])
	)
	_assert_status_labels_do_not_overlap_visible_icon(button, visible_icon)
	assert(button.icon == null, "{0} should not double-draw through Button.icon".format([label]))
	assert(not button.expand_icon, "{0} should not expand a duplicate built-in icon".format([label]))
	_assert_extra_icon_layers_hidden(unit_menus, hud_styler, button)
	var bright_pixels = _count_texture_bright_pixels(icon.texture)
	assert(
		bright_pixels >= 120,
		"{0} should use a bright readable source texture, got {1}".format(
			[label, bright_pixels]
		)
	)
	await get_tree().process_frame
	var rendered_pixels = _count_rendered_icon_pixels(button, visible_icon)
	if rendered_pixels >= 0:
		assert(
			rendered_pixels >= 80,
			"{0} should visibly render icon pixels in the command cell, got {1}".format(
				[label, rendered_pixels]
			)
		)


func _assert_extra_icon_layers_hidden(unit_menus, hud_styler, button):
	var label = _button_label(button)
	var overlay = button.find_child(ICON_OVERLAY_NAME, false, false)
	assert(overlay == null or not overlay.visible, "{0} direct overlay should stay hidden".format([label]))
	var floating_overlay = _optional_floating_overlay_for_button(unit_menus, button)
	assert(
		floating_overlay == null or not floating_overlay.visible,
		"{0} floating overlay should stay hidden".format([label])
	)
	var screen_overlay = _optional_screen_overlay_for_button(hud_styler, button)
	assert(
		screen_overlay == null or not screen_overlay.visible,
		"{0} screen overlay should stay hidden".format([label])
	)
	var glyph_label = button.find_child(ICON_GLYPH_LABEL_NAME, false, false)
	assert(
		glyph_label == null or not glyph_label.visible,
		"{0} center glyph fallback should stay hidden".format([label])
	)
	var fallback_label = button.find_child(CommandButtonIcons.FALLBACK_LABEL_NAME, false, false)
	assert(
		fallback_label == null or not fallback_label.visible,
		"{0} fallback text label should stay hidden".format([label])
	)
	var mosaic = button.find_child(MOSAIC_ICON_NAME, false, false)
	assert(
		mosaic == null or not mosaic.visible,
		"{0} mosaic fallback should stay hidden when a texture icon is available".format([label])
	)


func _button_label(button):
	return "{0}/{1}".format([button.get_parent().name, button.name])


func _visible_icon_for_button(button):
	var visible_icon = button.find_child(VISIBLE_ICON_NAME, false, false)
	assert(
		visible_icon != null,
		"{0} should have a dedicated visible icon layer".format([_button_label(button)])
	)
	assert(
		visible_icon.visible,
		"{0} visible icon layer should be visible".format([_button_label(button)])
	)
	return visible_icon


func _assert_status_labels_do_not_overlap_visible_icon(button, visible_icon):
	var icon_rect = Rect2(visible_icon.position, visible_icon.size).grow(1.0)
	for label_name in COMMAND_STATUS_LABEL_NAMES:
		var label = button.find_child(label_name, false, false)
		if label == null or not label.visible:
			continue
		if str(label.text).strip_edges() == "":
			continue
		var label_rect = Rect2(label.position, label.size)
		assert(
			not icon_rect.intersects(label_rect),
			"{0}/{1} should not overlap the command icon".format(
				[_button_label(button), label_name]
			)
		)


func _count_texture_bright_pixels(texture):
	var image = texture.get_image()
	assert(image != null, "icon texture should expose image data")
	var count = 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.05 and max(pixel.r, max(pixel.g, pixel.b)) >= 0.35:
				count += 1
	return count


func _count_rendered_icon_pixels(button, visible_icon):
	if DisplayServer.get_name() == "headless":
		return -1
	var viewport_texture = get_viewport().get_texture()
	if viewport_texture == null:
		return -1
	var viewport_image = viewport_texture.get_image()
	if viewport_image == null or viewport_image.is_empty():
		return -1
	var rect = Rect2i(
		Vector2i(visible_icon.global_position.round()),
		Vector2i(visible_icon.size.round())
	)
	rect = rect.intersection(Rect2i(Vector2i.ZERO, viewport_image.get_size()))
	assert(rect.size.x > 0 and rect.size.y > 0, "{0} visible icon should be inside the viewport".format([button.name]))
	var flipped_rect = Rect2i(
		Vector2i(rect.position.x, viewport_image.get_height() - rect.position.y - rect.size.y),
		rect.size
	).intersection(Rect2i(Vector2i.ZERO, viewport_image.get_size()))
	return max(
		_count_rendered_icon_pixels_in_rect(viewport_image, rect),
		_count_rendered_icon_pixels_in_rect(viewport_image, flipped_rect)
	)


func _count_rendered_icon_pixels_in_rect(viewport_image, rect):
	var count = 0
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var pixel = viewport_image.get_pixel(x, y)
			if pixel.a > 0.05 and max(pixel.r, max(pixel.g, pixel.b)) >= 0.16:
				count += 1
	return count


func _optional_floating_overlay_for_button(root, button):
	var layer = root.find_child(FLOATING_ICON_LAYER_NAME, true, false)
	if layer == null:
		return null
	return layer.find_child(
		"{0}{1}".format([FLOATING_ICON_PREFIX, button.get_instance_id()]), false, false
	)


func _optional_screen_overlay_for_button(root, button):
	var layer = root.find_child(SCREEN_ICON_LAYER_NAME, true, false)
	if layer == null:
		return null
	return layer.find_child(
		"{0}{1}".format([SCREEN_ICON_PREFIX, button.get_instance_id()]), false, false
	)
