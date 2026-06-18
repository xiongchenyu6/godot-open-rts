extends Node

const MIN_PLAYER_COLOR_COUNT = 20
const MIN_CORE_COLOR_DISTANCE = 0.22
const MIN_EXTENDED_COLOR_DISTANCE = 0.18
const MIN_LUMINANCE = 0.20
const MAX_LUMINANCE = 0.82
const CORE_PLAYER_SLOTS = 8


func _ready():
	_assert_player_colors_are_distinct()
	get_tree().quit()


func _assert_player_colors_are_distinct():
	var colors = Constants.Player.COLORS
	assert(
		colors.size() >= MIN_PLAYER_COLOR_COUNT,
		"player palette should support large skirmish rosters"
	)

	var seen = {}
	for color_id in range(colors.size()):
		var color = colors[color_id]
		var color_key = color.to_html(false)
		assert(not seen.has(color_key), "player color {0} should be unique".format([color_key]))
		seen[color_key] = true
		assert(color.a == 1.0, "player color {0} should be opaque".format([color_key]))

		var luminance = _relative_luminance(color)
		assert(
			luminance >= MIN_LUMINANCE and luminance <= MAX_LUMINANCE,
			"player color {0} should stay readable on dark maps and minimaps".format([color_key])
		)

	for color_a_id in range(colors.size()):
		for color_b_id in range(color_a_id + 1, colors.size()):
			var minimum_distance = (
				MIN_CORE_COLOR_DISTANCE
				if color_a_id < CORE_PLAYER_SLOTS and color_b_id < CORE_PLAYER_SLOTS
				else MIN_EXTENDED_COLOR_DISTANCE
			)
			assert(
				_color_distance(colors[color_a_id], colors[color_b_id]) >= minimum_distance,
				"player colors {0} and {1} should be visually distinct".format(
					[colors[color_a_id].to_html(false), colors[color_b_id].to_html(false)]
				)
			)


func _relative_luminance(color):
	return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b


func _color_distance(color_a, color_b):
	var red_difference = color_a.r - color_b.r
	var green_difference = color_a.g - color_b.g
	var blue_difference = color_a.b - color_b.b
	return sqrt(
		red_difference * red_difference
		+ green_difference * green_difference
		+ blue_difference * blue_difference
	)
