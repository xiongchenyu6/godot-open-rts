extends Node

const MatchSettings = preload("res://source/data-model/MatchSettings.gd")
const PlayScene = preload("res://source/main-menu/Play.tscn")

const PLAIN_AND_SIMPLE_MAP_PATH = "res://source/match/maps/PlainAndSimple.tscn"
const FOUR_CORNERS_MAP_PATH = "res://source/match/maps/FourCorners.tscn"
const TECH_DIVIDE_MAP_PATH = "res://source/match/maps/TechDivide.tscn"
const BIG_ARENA_MAP_PATH = "res://source/match/maps/BigArena.tscn"
const POPUP_MARKER_ICON_ITEMS = [
	"checked",
	"unchecked",
	"radio_checked",
	"radio_unchecked",
	"visibility_checked",
	"visibility_unchecked",
]
const STRATEGIC_MAP_PREVIEW_COUNTS = {
	FOUR_CORNERS_MAP_PATH: {"neutral_tech": 10, "supply_crates": 4},
	TECH_DIVIDE_MAP_PATH: {"neutral_tech": 14, "supply_crates": 6},
	BIG_ARENA_MAP_PATH: {"neutral_tech": 14, "supply_crates": 5},
}


func _ready():
	var play_menu = PlayScene.instantiate()
	add_child(play_menu)
	await get_tree().process_frame

	_test_default_match_setup(play_menu)
	_test_skirmish_menu_copy_is_localized(play_menu)
	_test_map_preview_tracks_selected_map(play_menu)
	_test_random_map_selects_compatible_real_maps(play_menu)
	_test_rich_starting_resources_are_applied(play_menu)
	_test_hidden_slots_are_ignored_after_map_shrink(play_menu)
	_test_map_selection_repairs_empty_visible_slots(play_menu)
	_test_ai_vs_ai_setup_is_allowed(play_menu)
	_test_player_slot_labels_use_player_colors(play_menu)
	_test_player_color_options_write_match_settings(play_menu)
	_test_player_team_options_write_match_settings(play_menu)
	_test_start_requires_opposing_teams(play_menu)
	_test_operation_summary_tracks_skirmish_setup(play_menu)
	await _test_play_menu_fits_common_web_viewport(play_menu)
	await _test_skirmish_map_names_are_localized()

	play_menu.queue_free()
	get_tree().quit()


func _test_default_match_setup(play_menu):
	var match_settings = play_menu._create_match_settings()
	assert(match_settings.players.size() == 2, "default skirmish should start Human vs AI")
	assert(
		match_settings.starting_resource_a == 8 and match_settings.starting_resource_b == 4,
		"default skirmish should use standard starting resources"
	)
	assert(
		match_settings.players[0].controller == Constants.PlayerType.HUMAN,
		"default first visible player should be human"
	)
	assert(
		match_settings.players[1].controller == Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI,
		"default visible opponent should be AI"
	)
	assert(
		match_settings.players[1].spawn_index_offset == 1,
		"default opponent should keep its selected map spawn slot"
	)
	assert(match_settings.visible_player == 0, "default skirmish should focus the human player")


func _test_skirmish_menu_copy_is_localized(play_menu):
	assert(
		play_menu.find_child("MapHeaderLabel", true, false).text == play_menu.tr("MAP"),
		"skirmish map header should use translated text"
	)
	assert(
		play_menu.find_child("PlayersHeaderLabel", true, false).text == play_menu.tr("PLAYERS"),
		"skirmish players header should use translated text"
	)
	assert(
		play_menu.find_child("StartButton", true, false).text == play_menu.tr("START"),
		"skirmish start button should use translated text"
	)
	assert(
		play_menu.find_child("BackButton", true, false).text == play_menu.tr("BACK"),
		"skirmish back button should use translated text"
	)

	var map_details = play_menu.find_child("MapDetailsLabel", true, false)
	assert(
		map_details.text.contains("[u]{0}:[/u]".format([play_menu.tr("MAP_DETAILS_PLAYERS")])),
		"selected map details should use translated player label"
	)
	assert(
		map_details.text.contains("[u]{0}:[/u]".format([play_menu.tr("MAP_DETAILS_SIZE")])),
		"selected map details should use translated size label"
	)

	var random_map_index = _map_index_by_path(play_menu, play_menu.RANDOM_MAP_PATH)
	_select_map(play_menu, random_map_index)
	var map_list = play_menu.find_child("MapList", true, false)
	assert(
		map_list.get_item_text(random_map_index) == play_menu.tr("RANDOM_MAP"),
		"random map list item should use translated text"
	)
	assert(
		map_details.text.contains("[u]{0}:[/u]".format([play_menu.tr("MAP_DETAILS_MAPS")])),
		"random map details should use translated map-count label"
	)
	assert(
		map_details.text.contains(play_menu.tr("MAP_DETAILS_RANDOM")),
		"random map details should describe size as translated random text"
	)

	_select_player_color(play_menu, 0, 4)
	assert(
		play_menu._get_player_color_option_nodes()[0].tooltip_text
		== play_menu.tr("PLAYER_COLOR_TOOLTIP").format([5]),
		"player color option tooltip should use translated text"
	)
	_select_player_color(play_menu, 0, 0)
	_select_map(play_menu, 0)


func _test_hidden_slots_are_ignored_after_map_shrink(play_menu):
	_select_map(play_menu, _map_index_by_player_count(play_menu, 8))
	_select_player_controller(play_menu, 0, Constants.PlayerType.HUMAN)
	_select_player_controller(play_menu, 1, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)
	_select_player_controller(play_menu, 2, Constants.PlayerType.NONE)
	_select_player_controller(play_menu, 3, Constants.PlayerType.NONE)
	_select_player_controller(play_menu, 6, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)
	_select_player_controller(play_menu, 7, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)

	_select_map(play_menu, 0)
	var match_settings = play_menu._create_match_settings()
	assert(
		match_settings.players.size() == 2,
		"players hidden by the selected map should not be added to match settings"
	)
	assert(
		match_settings.players[0].controller == Constants.PlayerType.HUMAN
		and match_settings.players[1].controller == Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI,
		"visible player slots should define the actual match players"
	)


func _test_map_preview_tracks_selected_map(play_menu):
	assert(play_menu._map_paths.size() >= 5, "skirmish menu should expose several map choices")
	var preview = play_menu.find_child("MapPreview", true, false)
	assert(preview != null, "skirmish menu should show a map preview")

	for map_index in range(play_menu._map_paths.size()):
		_select_map(play_menu, map_index)
		if play_menu._is_random_map_path(play_menu._map_paths[map_index]):
			assert(
				preview._map_size == Vector2(Constants.Match.MAPS[BIG_ARENA_MAP_PATH]["size"]),
				"random map preview should use the largest battlefield as a readable overview"
			)
			continue
		var selected_map = Constants.Match.MAPS[play_menu._map_paths[map_index]]
		assert(
			preview._map_size == Vector2(selected_map["size"]),
			"map preview should track the selected map size"
		)
		assert(
			preview._spawn_points.size() == selected_map["players"],
			"map preview should draw one spawn marker per player slot"
		)
		assert(
			preview._resource_a_points.size() + preview._resource_b_points.size()
			>= selected_map["players"] * 3,
			"map preview should include resource markers"
		)
		if STRATEGIC_MAP_PREVIEW_COUNTS.has(play_menu._map_paths[map_index]):
			var expected = STRATEGIC_MAP_PREVIEW_COUNTS[play_menu._map_paths[map_index]]
			assert(
				preview._neutral_tech_points.size() == expected["neutral_tech"],
				"strategic map preview should include neutral tech markers"
			)
			assert(
				preview._supply_crate_points.size() == expected["supply_crates"],
				"strategic map preview should include supply crate markers"
			)


func _test_random_map_selects_compatible_real_maps(play_menu):
	_select_map(play_menu, _map_index_by_path(play_menu, play_menu.RANDOM_MAP_PATH))
	assert(
		play_menu._map_paths[play_menu.find_child("MapList").get_selected_items()[0]]
		== play_menu.RANDOM_MAP_PATH,
		"skirmish menu should expose an explicit random map choice"
	)
	assert(
		Constants.Match.MAPS.has(play_menu._get_selected_map_path()),
		"random map selection should resolve to a real map path"
	)

	_select_player_controller(play_menu, 7, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI_HARD)
	var candidates = play_menu._random_map_candidates_for_current_slots()
	assert(candidates.size() == 1, "eighth-slot setups should only choose eight-player maps")
	assert(
		candidates[0] == BIG_ARENA_MAP_PATH,
		"random map should preserve high slot selections instead of shrinking the setup"
	)
	for _attempt in range(8):
		assert(
			play_menu._get_selected_map_path() == BIG_ARENA_MAP_PATH,
			"random map should resolve to a compatible eight-player map"
		)


func _test_map_selection_repairs_empty_visible_slots(play_menu):
	_select_map(play_menu, 0)
	for slot_index in range(4):
		_select_player_controller(play_menu, slot_index, Constants.PlayerType.NONE)

	_select_map(play_menu, 0)
	var match_settings = play_menu._create_match_settings()
	assert(match_settings.players.size() == 2, "map selection should keep at least two active players")
	assert(
		match_settings.players[0].controller == Constants.PlayerType.HUMAN,
		"empty visible slots should recover a human player"
	)
	assert(
		match_settings.players[1].controller == Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI,
		"empty visible slots should recover an AI opponent"
	)
	assert(not play_menu.find_child("StartButton").disabled, "valid repaired setup should enable Start")


func _test_ai_vs_ai_setup_is_allowed(play_menu):
	_select_map(play_menu, 0)
	_select_player_controller(play_menu, 0, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)
	_select_player_controller(play_menu, 1, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)
	_select_player_controller(play_menu, 2, Constants.PlayerType.NONE)
	_select_player_controller(play_menu, 3, Constants.PlayerType.NONE)
	play_menu._update_start_button_state()

	var match_settings = play_menu._create_match_settings()
	assert(match_settings.players.size() == 2, "AI vs AI should create two players")
	assert(match_settings.visible_player == -1, "AI vs AI should not force a human visible player")
	assert(
		match_settings.visibility == MatchSettings.Visibility.ALL_PLAYERS,
		"AI vs AI should show all players when no human is present"
	)
	assert(not play_menu.find_child("StartButton").disabled, "AI vs AI should be startable")


func _test_player_slot_labels_use_player_colors(play_menu):
	var player_labels = play_menu._get_player_label_nodes()
	var color_options = play_menu._get_player_color_option_nodes()
	var team_options = play_menu._get_player_team_option_nodes()
	assert(
		player_labels.size() <= Constants.Player.COLORS.size(),
		"skirmish menu should have a player color for every visible slot"
	)
	assert(
		color_options.size() == player_labels.size(),
		"skirmish menu should expose one color option per player slot"
	)
	assert(
		team_options.size() == player_labels.size(),
		"skirmish menu should expose one team option per player slot"
	)
	for label_id in range(player_labels.size()):
		var label = player_labels[label_id]
		var color_option = color_options[label_id]
		var team_option = team_options[label_id]
		assert(
			color_option.get_item_count() == Constants.Player.COLORS.size(),
			"player color option should expose the full player palette"
		)
		assert(
			team_option.get_item_count() == play_menu.MAX_TEAM_OPTIONS,
			"player team option should expose the available skirmish teams"
		)
		assert(
			label.has_theme_color_override("font_color"),
			"player slot label should show the assigned player color"
		)
		assert(
			label.get_theme_color("font_color") == Constants.Player.COLORS[label_id],
			"player slot label should use its matching player color"
		)


func _test_player_color_options_write_match_settings(play_menu):
	_select_map(play_menu, 0)
	_select_player_controller(play_menu, 0, Constants.PlayerType.HUMAN)
	_select_player_controller(play_menu, 1, Constants.PlayerType.NONE)
	_select_player_controller(play_menu, 2, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)
	_select_player_controller(play_menu, 3, Constants.PlayerType.NONE)
	_select_player_color(play_menu, 0, 4)
	_select_player_color(play_menu, 2, 7)

	var match_settings = play_menu._create_match_settings()
	assert(match_settings.players.size() == 2, "custom player colors should keep valid players")
	assert(
		match_settings.players[0].color == Constants.Player.COLORS[4],
		"human slot should use the selected custom color"
	)
	assert(
		match_settings.players[1].color == Constants.Player.COLORS[7],
		"AI slot should use the selected custom color"
	)
	assert(
		play_menu._get_player_label_nodes()[0].get_theme_color("font_color")
		== Constants.Player.COLORS[4],
		"player label should update when the custom color changes"
	)


func _test_player_team_options_write_match_settings(play_menu):
	_select_map(play_menu, 0)
	_select_player_controller(play_menu, 0, Constants.PlayerType.HUMAN)
	_select_player_controller(play_menu, 1, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)
	_select_player_controller(play_menu, 2, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)
	_select_player_controller(play_menu, 3, Constants.PlayerType.NONE)
	_select_player_team(play_menu, 0, 0)
	_select_player_team(play_menu, 1, 0)
	_select_player_team(play_menu, 2, 1)

	var match_settings = play_menu._create_match_settings()
	assert(match_settings.players.size() == 3, "team setup should keep all active players")
	assert(match_settings.players[0].team_id == 0, "human should use selected team")
	assert(match_settings.players[1].team_id == 0, "ally AI should use the matching selected team")
	assert(match_settings.players[2].team_id == 1, "enemy AI should use its selected team")


func _test_start_requires_opposing_teams(play_menu):
	_select_map(play_menu, 0)
	_select_player_controller(play_menu, 0, Constants.PlayerType.HUMAN)
	_select_player_controller(play_menu, 1, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)
	_select_player_controller(play_menu, 2, Constants.PlayerType.NONE)
	_select_player_controller(play_menu, 3, Constants.PlayerType.NONE)
	_select_player_team(play_menu, 0, 0)
	_select_player_team(play_menu, 1, 0)
	play_menu._update_start_button_state()

	var start_button = play_menu.find_child("StartButton")
	assert(start_button.disabled, "same-team skirmish setup should not be startable")
	assert(
		start_button.tooltip_text == play_menu.tr("START_DISABLED_NEEDS_OPPONENT"),
		"disabled same-team setup should explain that an opposing team is required"
	)

	_select_player_team(play_menu, 1, 1)
	play_menu._update_start_button_state()
	assert(not start_button.disabled, "opposing-team skirmish setup should be startable")
	assert(start_button.tooltip_text == "", "valid skirmish setup should clear the disabled reason")


func _test_operation_summary_tracks_skirmish_setup(play_menu):
	_select_map(play_menu, 0)
	_select_player_controller(play_menu, 0, Constants.PlayerType.HUMAN)
	_select_player_controller(play_menu, 1, Constants.PlayerType.SIMPLE_CLAIRVOYANT_AI)
	_select_player_controller(play_menu, 2, Constants.PlayerType.NONE)
	_select_player_controller(play_menu, 3, Constants.PlayerType.NONE)
	_select_player_team(play_menu, 0, 0)
	_select_player_team(play_menu, 1, 1)
	var starting_resources_option = play_menu.find_child("StartingResourcesOptionButton", true, false)
	starting_resources_option.select(1)
	play_menu._on_starting_resources_selected(1)
	play_menu._update_start_button_state()

	var summary = play_menu.find_child("OperationSummaryLabel", true, false)
	assert(summary != null, "skirmish setup should show an operation summary")
	assert(
		summary.text.contains(play_menu.tr("OPERATION_SUMMARY_TITLE")),
		"operation summary should show a translated title"
	)
	assert(
		summary.text.contains(play_menu._selected_map_display_name()),
		"operation summary should show the selected map name"
	)
	assert(
		summary.text.contains(play_menu.tr("PLAYER_HUMAN"))
		and summary.text.contains(play_menu.tr("PLAYER_AI_NORMAL")),
		"operation summary should list active forces"
	)
	assert(
		summary.text.contains("A 8 / B 4"),
		"operation summary should show standard starting resources"
	)
	assert(
		summary.text.contains(play_menu.tr("OPERATION_SUMMARY_OBJECTIVE_ELIMINATION")),
		"operation summary should show the victory objective"
	)
	assert(
		summary.text.contains(play_menu.tr("OPERATION_SUMMARY_READY")),
		"valid opposing teams should mark the setup ready"
	)

	starting_resources_option.select(3)
	play_menu._on_starting_resources_selected(3)
	assert(
		summary.text.contains("A 32 / B 16"),
		"operation summary should update when starting resources change"
	)

	_select_player_team(play_menu, 1, 0)
	play_menu._update_start_button_state()
	assert(
		summary.text.contains(play_menu.tr("OPERATION_SUMMARY_NOT_READY")),
		"same-team setup should mark the operation summary not ready"
	)


func _test_skirmish_map_names_are_localized():
	var original_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("zh_CN")

	var localized_menu = PlayScene.instantiate()
	add_child(localized_menu)
	await get_tree().process_frame
	await get_tree().process_frame

	var map_list = localized_menu.find_child("MapList", true, false)
	var map_index = _map_index_by_path(localized_menu, PLAIN_AND_SIMPLE_MAP_PATH)
	assert(
		map_list.get_item_text(map_index) == localized_menu.tr("MAP_NAME_PLAIN_AND_SIMPLE"),
		"Chinese skirmish map list should translate map names"
	)
	_select_map(localized_menu, map_index)
	var summary = localized_menu.find_child("OperationSummaryLabel", true, false)
	assert(
		summary.text.contains(localized_menu.tr("MAP_NAME_PLAIN_AND_SIMPLE")),
		"Chinese operation summary should translate the selected map name"
	)
	assert(
		not summary.text.contains(Constants.Match.MAPS[PLAIN_AND_SIMPLE_MAP_PATH]["name"]),
		"Chinese operation summary should not fall back to the English map name"
	)
	await _assert_option_popup_uses_cjk_font(
		localized_menu._get_player_option_nodes()[0],
		localized_menu.tr("PLAYER_AI_EASY")
	)
	await _assert_option_popup_uses_cjk_font(
		localized_menu._get_player_team_option_nodes()[0],
		localized_menu.tr("TEAM_SHORT").format([1])
	)

	localized_menu.queue_free()
	TranslationServer.set_locale(original_locale)


func _test_play_menu_fits_common_web_viewport(play_menu):
	var previous_size = get_window().size
	var viewport_size = Vector2(1280, 720)
	get_window().size = Vector2i(viewport_size)
	play_menu._apply_responsive_layout_for_viewport(viewport_size)
	await get_tree().process_frame

	var panel = play_menu.find_child("PanelContainer", true, false)
	var start_button = play_menu.find_child("StartButton", true, false)
	var back_button = play_menu.find_child("BackButton", true, false)
	var map_preview = play_menu.find_child("MapPreview", true, false)
	var grid = play_menu.find_child("GridContainer", true, false)
	assert(panel != null, "skirmish menu should expose the setup panel")
	assert(start_button != null, "skirmish menu should expose the start button")
	assert(back_button != null, "skirmish menu should expose the back button")
	_assert_rect_inside_viewport(panel.get_global_rect(), viewport_size, "setup panel")
	_assert_rect_inside_viewport(start_button.get_global_rect(), viewport_size, "start button")
	_assert_rect_inside_viewport(back_button.get_global_rect(), viewport_size, "back button")
	assert(
		map_preview.custom_minimum_size.y <= play_menu.COMPACT_MAP_PREVIEW_SIZE.y,
		"compact web layout should reduce the map preview height"
	)
	assert(
		grid.custom_minimum_size.y < play_menu.DEFAULT_PLAYER_GRID_HEIGHT,
		"compact web layout should reduce the player grid height"
	)

	get_window().size = previous_size
	play_menu._apply_responsive_layout()
	await get_tree().process_frame


func _assert_rect_inside_viewport(rect, viewport_size, label):
	assert(rect.position.x >= 0.0, "{0} should not extend past the left viewport edge".format([label]))
	assert(rect.position.y >= 0.0, "{0} should not extend above the viewport".format([label]))
	assert(
		rect.position.x + rect.size.x <= viewport_size.x + 0.5,
		"{0} should not extend past the right viewport edge".format([label])
	)
	assert(
		rect.position.y + rect.size.y <= viewport_size.y + 0.5,
		"{0} should not extend below the viewport".format([label])
	)


func _test_rich_starting_resources_are_applied(play_menu):
	var starting_resources_option = play_menu.find_child("StartingResourcesOptionButton", true, false)
	starting_resources_option.select(3)
	var match_settings = play_menu._create_match_settings()
	assert(
		match_settings.starting_resource_a == 32 and match_settings.starting_resource_b == 16,
		"starting resource option should be written to match settings"
	)


func _select_map(play_menu, map_index):
	play_menu.find_child("MapList").select(map_index)
	play_menu._on_map_list_item_selected(map_index)


func _select_player_controller(play_menu, slot_index, controller):
	play_menu._select_player_controller(play_menu._get_player_option_nodes()[slot_index], controller)


func _select_player_color(play_menu, slot_index, color_id):
	play_menu._select_player_color(play_menu._get_player_color_option_nodes()[slot_index], color_id)


func _select_player_team(play_menu, slot_index, team_id):
	play_menu._select_player_team(play_menu._get_player_team_option_nodes()[slot_index], team_id)


func _assert_option_popup_uses_cjk_font(option_button, expected_item_text):
	var popup = option_button.get_popup()
	assert(popup != null, "{0} should expose a popup menu".format([option_button.name]))
	option_button.show_popup()
	await get_tree().process_frame
	assert(
		popup.has_method("has_theme_font_override"),
		"{0} popup should support theme font overrides".format([option_button.name])
	)
	assert(
		popup.has_theme_font_override("font"),
		"{0} popup should use the packaged CJK font".format([option_button.name])
	)
	assert(
		popup.has_theme_font_override("font_separator"),
		"{0} popup separators should use the packaged CJK font".format([option_button.name])
	)
	assert(
		popup.get_theme_font("font") == option_button.get_theme_font("font"),
		"{0} popup should render item text with the same CJK font as the closed button".format(
			[option_button.name]
		)
	)
	assert(
		popup.get_theme_font("font_separator") == option_button.get_theme_font("font"),
		"{0} popup separators should render with the packaged CJK font".format([option_button.name])
	)
	for item_id in range(popup.get_item_count()):
		assert(
			not popup.is_item_radio_checkable(item_id),
			"{0} popup item {1} should not show the default radio marker".format(
				[option_button.name, item_id]
			)
		)
		assert(
			not popup.is_item_checkable(item_id),
			"{0} popup item {1} should not show the default check marker".format(
				[option_button.name, item_id]
			)
		)
		assert(
			not popup.is_item_checked(item_id),
			"{0} popup item {1} should not draw a selected marker over localized text".format(
				[option_button.name, item_id]
			)
		)
		assert(
			popup.get_item_text(item_id) == option_button.get_item_text(item_id),
			"{0} popup item {1} should use the same localized text as the closed button".format(
				[option_button.name, item_id]
			)
		)
		assert(
			not popup.get_item_text(item_id).contains("�"),
			"{0} popup item {1} should not contain replacement characters".format(
				[option_button.name, item_id]
			)
		)
	_assert_popup_marker_icons_are_blank(popup, option_button.name)
	var found_expected_item = false
	for item_id in range(option_button.item_count):
		if option_button.get_item_text(item_id) == expected_item_text:
			found_expected_item = true
			break
	assert(
		found_expected_item,
		"{0} should include localized popup item '{1}'".format(
			[option_button.name, expected_item_text]
		)
	)
	popup.hide()


func _assert_popup_marker_icons_are_blank(popup, option_button_name):
	for icon_name in POPUP_MARKER_ICON_ITEMS:
		assert(
			popup.has_theme_icon_override(icon_name),
			"{0} popup should override {1} so default marker glyphs cannot cover Chinese text".format(
				[option_button_name, icon_name]
			)
		)
		var icon = popup.get_theme_icon(icon_name, "PopupMenu")
		assert(icon != null, "{0} popup {1} icon should resolve".format([option_button_name, icon_name]))
		assert(
			icon.get_width() <= 1 and icon.get_height() <= 1,
			"{0} popup {1} marker should be a blank 1px icon".format(
				[option_button_name, icon_name]
			)
		)


func _map_index_by_player_count(play_menu, player_count):
	for map_index in range(play_menu._map_paths.size()):
		if play_menu._is_random_map_path(play_menu._map_paths[map_index]):
			continue
		if Constants.Match.MAPS[play_menu._map_paths[map_index]]["players"] == player_count:
			return map_index
	assert(false, "expected a skirmish map for {0} players".format([player_count]))
	return 0


func _map_index_by_path(play_menu, map_path):
	for map_index in range(play_menu._map_paths.size()):
		if play_menu._map_paths[map_index] == map_path:
			return map_index
	assert(false, "expected skirmish map path {0}".format([map_path]))
	return 0
