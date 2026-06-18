extends Node

const MainMenuScene = preload("res://source/main-menu/Main.tscn")
const OptionsScene = preload("res://source/main-menu/Options.tscn")
const CreditsScene = preload("res://source/main-menu/Credits.tscn")
const OptionsData = preload("res://source/data-model/Options.gd")
const CJK_PROBE_TEXT = "简体中文玩家队伍系统在线"
const POPUP_MARKER_ICON_ITEMS = [
	"checked",
	"unchecked",
	"radio_checked",
	"radio_unchecked",
	"visibility_checked",
	"visibility_unchecked",
]

var _original_locale = ""


func _ready():
	_original_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	FeatureFlags.save_user_files_in_tmp = true
	Globals.options = OptionsData.new()
	Globals.options.locale = "en"

	await _assert_desktop_main_menu()
	await _assert_web_main_menu()
	await _assert_options_language_selector()
	await _assert_chinese_main_and_credits_copy()
	_assert_audio_volume_scaling()

	TranslationServer.set_locale(_original_locale)
	get_tree().quit()


func _assert_desktop_main_menu():
	var main_menu = MainMenuScene.instantiate()
	add_child(main_menu)
	await get_tree().process_frame

	assert(main_menu.find_child("TitleLabel", true, false).text == "Open RTS", "main menu should show title")
	assert(
		main_menu.find_child("RosterPreview", true, false).texture != null,
			"main menu should show generated roster art"
		)
	for button_name in ["PlayButton", "OptionsButton", "CreditsButton", "QuitButton"]:
		var button = main_menu.find_child(button_name, true, false)
		assert(button != null, "{0} should exist".format([button_name]))
		assert(button.custom_minimum_size.y >= 58, "{0} should be easy to hit".format([button_name]))
	assert(
		main_menu.find_child("QuitButton", true, false).text == tr("QUIT"),
		"desktop main menu should keep the quit command"
	)
	assert(
		main_menu.find_child("StatusStrip", true, false).text == tr("MAIN_SYSTEMS_ONLINE"),
		"desktop main menu should localize the status strip"
	)

	main_menu.queue_free()


func _assert_options_language_selector():
	var options = OptionsScene.instantiate()
	add_child(options)
	await get_tree().process_frame

	var language = options.find_child("Language", true, false)
	var audio_label = options.find_child("AudioLabel", true, false)
	var master_slider = options.find_child("MasterVolumeSlider", true, false)
	var music_slider = options.find_child("MusicVolumeSlider", true, false)
	var sfx_slider = options.find_child("SfxVolumeSlider", true, false)
	var voice_slider = options.find_child("VoiceVolumeSlider", true, false)
	var master_value = options.find_child("MasterVolumeValueLabel", true, false)
	assert(language != null, "options menu should expose a language selector")
	assert(language.item_count == 4, "language selector should include system, zh_CN, en, and pl")
	assert(
		language.get_item_text(1) == "Simplified Chinese",
		"language selector should show the Chinese option in English before switching"
	)
	assert(options.find_child("VideoLabel", true, false).text == "Video", "options menu should start localized")
	assert(audio_label != null and audio_label.text == "Audio", "options menu should expose audio controls")
	for slider in [master_slider, music_slider, sfx_slider, voice_slider]:
		assert(slider != null, "options menu should expose every volume slider")
		assert(slider.min_value == 0.0 and slider.max_value == 100.0, "volume sliders should use percent values")
		assert(slider.value == 100.0, "volume sliders should default to 100 percent")
	assert(master_value != null and master_value.text == "100%", "volume labels should show percent text")

	options._on_master_volume_value_changed(65.0)
	options._on_music_volume_value_changed(40.0)
	options._on_sfx_volume_value_changed(55.0)
	options._on_voice_volume_value_changed(75.0)

	assert(is_equal_approx(Globals.options.master_volume, 0.65), "master volume should persist from slider")
	assert(is_equal_approx(Globals.options.music_volume, 0.4), "music volume should persist from slider")
	assert(is_equal_approx(Globals.options.sfx_volume, 0.55), "SFX volume should persist from slider")
	assert(is_equal_approx(Globals.options.voice_volume, 0.75), "voice volume should persist from slider")
	assert(master_value.text == "65%", "volume labels should refresh after slider changes")

	options._on_language_item_selected(1)
	await get_tree().process_frame

	assert(Globals.options.locale == "zh_CN", "language selector should persist zh_CN")
	assert(
		TranslationServer.get_locale() == "zh_CN",
		"language selector should apply zh_CN immediately"
		)
	assert(options.find_child("VideoLabel", true, false).text == "视频", "video label should switch to Chinese")
	var language_label = options.find_child("LanguageLabel", true, false)
	assert(language_label.text == "语言", "language label should switch to Chinese")
	assert(
		language_label.has_theme_font_override("font"),
		"Chinese UI controls should use the packaged CJK-capable font"
	)
	assert(options.find_child("AudioLabel", true, false).text == "音频", "audio label should switch to Chinese")
	assert(
		options.find_child("MasterVolumeLabel", true, false).text == "主音量",
		"master volume label should switch to Chinese"
	)
	assert(options.find_child("MouseLabel", true, false).text == "鼠标", "mouse label should switch to Chinese")
	assert(options.find_child("BackButton", true, false).text == "返回", "back button should switch to Chinese")
	assert(language.get_item_text(1) == "简体中文", "language option text should refresh after switching")
	assert(language.get_item_text(2) == "英语", "English option text should refresh after switching")
	assert(language.get_item_text(3) == "波兰语", "Polish option text should refresh after switching")
	await _assert_option_popup_uses_cjk_font(language, "简体中文")
	await _assert_option_popup_uses_cjk_font(options.find_child("Screen", true, false), "全屏")

	options.queue_free()
	Globals.options.locale = "en"
	Globals.options.master_volume = 1.0
	Globals.options.music_volume = 1.0
	Globals.options.sfx_volume = 1.0
	Globals.options.voice_volume = 1.0


func _assert_web_main_menu():
	var main_menu = MainMenuScene.instantiate()
	main_menu.force_web_platform_for_tests = true
	add_child(main_menu)
	await get_tree().process_frame

	var quit_button = main_menu.find_child("QuitButton", true, false)
	assert(quit_button != null, "web main menu should keep the fourth command button")
	assert(
		quit_button.text == tr("FULLSCREEN"),
		"web main menu should use fullscreen instead of a no-op quit command"
	)
	assert(
		quit_button.tooltip_text == tr("FULLSCREEN_TOOLTIP"),
		"web fullscreen command should describe the browser action"
	)
	assert(not quit_button.disabled, "web fullscreen command should be clickable")

	main_menu.queue_free()


func _assert_chinese_main_and_credits_copy():
	TranslationServer.set_locale("zh_CN")
	var main_menu = MainMenuScene.instantiate()
	add_child(main_menu)
	await get_tree().process_frame

	assert(
		main_menu.find_child("StatusStrip", true, false).text == "系统：在线",
		"Chinese main menu should translate the systems status strip"
	)
	var expected_main_text = {
		"SubtitleLabel": "前线指挥",
		"OperationLabel": "行动：遭遇战指挥",
		"StatusLabel": "扩展武备已上线。选择战区并部署。",
		"RosterLabel": "可用战斗群",
		"CommandLabel": "指挥菜单",
		"PlayButton": "开始游戏",
		"OptionsButton": "设置",
		"CreditsButton": "制作人员",
		"QuitButton": "退出",
		"StatusStrip": "系统：在线",
	}
	for node_name in expected_main_text:
		var control = main_menu.find_child(node_name, true, false)
		assert(control != null, "{0} should exist in the Chinese main menu".format([node_name]))
		assert(
			control.text == expected_main_text[node_name],
			"{0} should show Chinese text without falling back: {1}".format([node_name, control.text])
		)
		_assert_control_uses_cjk_font(control, "font")
	main_menu.queue_free()

	var credits = CreditsScene.instantiate()
	add_child(credits)
	await get_tree().process_frame
	var credits_text = credits.find_child("RichTextLabel", true, false)

	assert(
		credits_text.text.contains("核心贡献者"),
		"Chinese credits should translate the contributors heading"
	)
	assert(
		credits_text.text.contains("素材"),
		"Chinese credits should translate the assets heading"
	)
	_assert_control_uses_cjk_font(credits_text, "normal_font")
	assert(
		credits.find_child("Button", true, false).text == "返回",
		"Chinese credits should translate the back button"
	)
	_assert_control_uses_cjk_font(credits.find_child("Button", true, false), "font")
	credits.queue_free()
	TranslationServer.set_locale("en")


func _assert_audio_volume_scaling():
	var options = OptionsData.new()
	options.master_volume = 0.5
	options.music_volume = 0.5
	options.sfx_volume = 0.25
	options.voice_volume = 1.0

	assert(
		is_equal_approx(options.music_volume_db(-19.0), -19.0 + linear_to_db(0.25)),
		"music volume should combine master and channel volume"
	)
	assert(
		is_equal_approx(options.sfx_volume_db(-4.0), -4.0 + linear_to_db(0.125)),
		"SFX volume should combine master and channel volume"
	)
	assert(
		is_equal_approx(options.voice_volume_db(0.0), linear_to_db(0.5)),
		"voice volume should combine master and channel volume"
	)

	options.master_volume = 0.0
	assert(options.music_volume_db(-19.0) == options.MUTE_DB, "zero master volume should mute music")
	options.master_volume = 1.0
	options.sfx_volume = 0.0
	assert(options.sfx_volume_db(-4.0) == options.MUTE_DB, "zero channel volume should mute SFX")


func _assert_control_uses_cjk_font(control, theme_item):
	assert(
		control.has_theme_font_override(theme_item),
		"{0} should use the packaged CJK-capable font".format([control.name])
	)
	var font = control.get_theme_font(theme_item)
	assert(font != null, "{0} should resolve a font for {1}".format([control.name, theme_item]))
	for index in range(CJK_PROBE_TEXT.length()):
		var codepoint = CJK_PROBE_TEXT.unicode_at(index)
		assert(
			font.has_char(codepoint),
			"{0} font should include CJK codepoint {1}".format([control.name, codepoint])
		)


func _assert_option_popup_uses_cjk_font(option_button, expected_item_text):
	assert(option_button != null, "option button should exist before checking its popup")
	var popup = option_button.get_popup()
	assert(popup != null, "{0} should expose a popup menu".format([option_button.name]))
	option_button.show_popup()
	await get_tree().process_frame
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
		"{0} popup should render items with the same CJK font as the closed button".format(
			[option_button.name]
		)
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
