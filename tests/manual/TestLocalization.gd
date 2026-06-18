extends Node

const TRANSLATION_CSV_PATHS = [
	"res://assets/translations/main_menu.csv",
	"res://assets/translations/match.csv",
]
const TRANSLATION_LOCALES = ["en", "pl", "zh_CN"]
const SOURCE_ROOT = "res://source"
const SOURCE_EXTENSIONS = ["gd", "tscn"]
const SCENE_LITERAL_PLACEHOLDERS = {
	"0": true,
	"1": true,
	"2": true,
	"V": true,
	"X": true,
	"Y": true,
	"PWR": true,
}
const SAME_AS_KEY_TRANSLATIONS = {
	"DPS": true,
}

var _original_locale = ""


func _ready():
	_original_locale = TranslationServer.get_locale()
	var translation_rows = _load_translation_rows()

	_assert_translation_files_are_complete(translation_rows)
	_assert_source_translation_keys_are_registered(translation_rows)
	_assert_translations_resolve_for_all_release_locales(translation_rows)
	_assert_key_chinese_translations()
	_assert_key_chinese_strings_do_not_fall_back_to_english()

	TranslationServer.set_locale(_original_locale)
	get_tree().quit()


func _assert_key_chinese_translations():
	TranslationServer.set_locale("zh_CN")
	var checks = {
		"SELECTION_SELECTED": "已选择 {0}",
		"SELECTION_MULTIPLE_TYPES": "{0} 类",
		"SELECTION_RANK": "等级",
		"SELECTION_POWER": "电力",
		"POWER_SHORT": "电力",
		"COMMAND_TECH_LOCK_SHORT": "科技",
		"PRODUCTION_QUEUE_FULL_SHORT": "满",
		"PRODUCTION_QUEUE_WAITING": "等待",
		"SELECTION_CONSTRUCTING": "建造中",
		"RESUME_MATCH": "继续战斗",
		"MATCH_STATUS_TITLE": "战斗状态",
		"CANCEL_CURRENT_ACTION": "取消当前命令",
		"ATTACK_MOVE_DESCRIPTION": "选择目的地并沿途攻击敌人",
		"HOLD_POSITION_DESCRIPTION": "不会自动追击附近敌人",
		"RALLY_POINT": "集结点",
		"DEPLOY_MCV": "部署基地车",
		"BRIEFING_TITLE": "战斗简报",
		"BRIEFING_OPENING_TITLE": "推荐开局",
		"OBJECTIVE_TRACKER_TITLE": "目标",
		"MATCH_VICTORY_TITLE": "任务完成",
		"MATCH_DEFEAT_TITLE": "任务失败",
		"MATCH_FINISH_TITLE": "战场已控制",
		"MATCH_RESULT_TITLE": "战斗结果",
		"MATCH_RESULT_REMAINING_ANCHORS": "指挥锚点",
		"MATCH_STATS_TITLE": "战斗统计",
		"RESTART_MATCH": "重新开始",
		"RETURN_TO_SETUP": "返回设置",
		"EXIT_TO_MENU": "退出到主菜单",
		"OPTIONS_LANGUAGE_ENGLISH": "英语",
		"OPTIONS_LANGUAGE_POLISH": "波兰语",
		"MAIN_SYSTEMS_ONLINE": "系统：在线",
		"PLAYER_NONE": "无 / None",
		"PLAYER_HUMAN": "玩家 / Human",
		"PLAYER_AI_BEGINNER": "傻瓜 AI / AI Beginner",
		"PLAYER_AI_EASY": "简单 AI / AI Easy",
		"PLAYER_AI_NORMAL": "普通 AI / AI Normal",
		"PLAYER_AI_HARD": "困难 AI / AI Hard",
		"MAP_NAME_PLAIN_AND_SIMPLE": "简明战场",
		"MAP_NAME_FOUR_CORNERS": "四角战场",
		"MAP_NAME_TECH_DIVIDE": "科技分界线",
		"MAP_NAME_BIG_ARENA": "大型竞技场",
	}

	for key in checks:
		_assert_translation(key, checks[key])


func _assert_key_chinese_strings_do_not_fall_back_to_english():
	TranslationServer.set_locale("zh_CN")
	var no_english_fallback_keys = [
		"SELECTION_SELECTED",
		"SELECTION_RANK",
		"SELECTION_POWER",
		"POWER_SHORT",
		"COMMAND_TECH_LOCK_SHORT",
		"PRODUCTION_QUEUE_FULL_SHORT",
		"PRODUCTION_QUEUE_WAITING",
		"SELECTION_CONSTRUCTING",
		"RESUME_MATCH",
		"MATCH_STATUS_TITLE",
		"CANCEL_CURRENT_ACTION",
		"ATTACK_MOVE_DESCRIPTION",
		"HOLD_POSITION_DESCRIPTION",
		"RALLY_POINT",
		"DEPLOY_MCV",
		"BRIEFING_TITLE",
		"BRIEFING_OPENING_TITLE",
		"OBJECTIVE_TRACKER_TITLE",
		"MATCH_VICTORY_TITLE",
		"MATCH_DEFEAT_TITLE",
		"MATCH_FINISH_TITLE",
		"MATCH_RESULT_TITLE",
		"MATCH_RESULT_REMAINING_ANCHORS",
		"MATCH_STATS_TITLE",
		"RESTART_MATCH",
		"RETURN_TO_SETUP",
		"EXIT_TO_MENU",
		"OPTIONS_LANGUAGE_ENGLISH",
		"OPTIONS_LANGUAGE_POLISH",
		"MAIN_SYSTEMS_ONLINE",
		"MAP_NAME_PLAIN_AND_SIMPLE",
		"MAP_NAME_FOUR_CORNERS",
		"MAP_NAME_TECH_DIVIDE",
		"MAP_NAME_BIG_ARENA",
	]

	for key in no_english_fallback_keys:
		_assert(
			not _contains_ascii_word(tr(key)),
			"{0} should not fall back to English in zh_CN: {1}".format([key, tr(key)])
		)


func _load_translation_rows():
	var rows = {}
	for csv_path in TRANSLATION_CSV_PATHS:
		var file = FileAccess.open(csv_path, FileAccess.READ)
		_assert(file != null, "translation CSV should open: {0}".format([csv_path]))
		var header = file.get_csv_line()
		_assert(
			header.size() == 4
			and header[0] == "keys"
			and header[1] == "en"
			and header[2] == "pl"
			and header[3] == "zh_CN",
			"{0} should keep the expected translation header".format([csv_path])
		)
		while not file.eof_reached():
			var columns = file.get_csv_line()
			if columns.size() == 0 or (columns.size() == 1 and columns[0] == ""):
				continue
			var key = str(columns[0])
			_assert(key != "", "{0} should not contain an empty translation key".format([csv_path]))
			_assert(not rows.has(key), "duplicate translation key: {0}".format([key]))
			rows[key] = {
				"path": csv_path,
				"columns": columns,
			}
	return rows


func _assert_translation_files_are_complete(rows):
	for key in rows:
		var row = rows[key]
		var columns = row["columns"]
		_assert(
			columns.size() == 4,
			"{0} in {1} should have key,en,pl,zh_CN columns".format([key, row["path"]])
		)
		for column_id in range(1, columns.size()):
			var value = str(columns[column_id])
			_assert(value.strip_edges() != "", "{0} should not have an empty translation".format([key]))
			_assert(
				not _contains_broken_glyph(value),
				"{0} should not contain replacement-box glyphs: {1}".format([key, value])
			)


func _assert_source_translation_keys_are_registered(rows):
	var source_files = []
	_collect_source_files(SOURCE_ROOT, source_files)
	var used_keys = {}
	for source_path in source_files:
		var content = FileAccess.get_file_as_string(source_path)
		_collect_regex_keys(content, "tr\\(\"([A-Z0-9_]+)\"\\)", source_path, used_keys)
		if source_path.ends_with(".tscn"):
			_collect_regex_keys(
				content,
				"(?:text|tooltip_text) = \"([A-Z0-9_]+)\"",
				source_path,
				used_keys,
				true
			)

	for key in used_keys.keys():
		_assert(
			rows.has(key),
			"source uses untranslated key {0} at {1}".format([key, used_keys[key]])
		)


func _assert_translations_resolve_for_all_release_locales(rows):
	for locale in TRANSLATION_LOCALES:
		TranslationServer.set_locale(locale)
		for key in rows:
			var translated = tr(key)
			_assert(
				translated != key or SAME_AS_KEY_TRANSLATIONS.has(key),
				"{0} should resolve in locale {1}".format([key, locale])
			)
			_assert(
				not _contains_broken_glyph(translated),
				"{0} should not resolve to broken glyphs in {1}: {2}".format([key, locale, translated])
			)


func _collect_source_files(directory_path, files):
	var directory = DirAccess.open(directory_path)
	_assert(directory != null, "source directory should open: {0}".format([directory_path]))
	directory.list_dir_begin()
	var entry_name = directory.get_next()
	while entry_name != "":
		if entry_name.begins_with("."):
			entry_name = directory.get_next()
			continue
		var entry_path = "{0}/{1}".format([directory_path, entry_name])
		if directory.current_is_dir():
			_collect_source_files(entry_path, files)
		elif _has_source_extension(entry_name):
			files.append(entry_path)
		entry_name = directory.get_next()
	directory.list_dir_end()


func _has_source_extension(filename):
	for extension in SOURCE_EXTENSIONS:
		if filename.ends_with(".{0}".format([extension])):
			return true
	return false


func _collect_regex_keys(content, pattern, source_path, used_keys, ignore_scene_literals = false):
	var regex = RegEx.new()
	var error = regex.compile(pattern)
	_assert(error == OK, "localization key regex should compile: {0}".format([pattern]))
	for result in regex.search_all(content):
		var key = result.get_string(1)
		if ignore_scene_literals and SCENE_LITERAL_PLACEHOLDERS.has(key):
			continue
		if not used_keys.has(key):
			used_keys[key] = source_path


func _assert_translation(key, expected):
	var actual = tr(key)
	_assert(
		actual == expected,
		"{0} should translate to '{1}' but was '{2}'".format([key, expected, actual])
	)


func _contains_ascii_word(value):
	var regex = RegEx.new()
	regex.compile("[A-Za-z]{3,}")
	return regex.search(str(value)) != null


func _contains_broken_glyph(value):
	var text = str(value)
	return text.contains("�") or text.contains("□") or text.contains("�")


func _assert(condition, message):
	if condition:
		return
	TranslationServer.set_locale(_original_locale)
	push_error(message)
	get_tree().quit(1)
