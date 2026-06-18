extends Control

var texture = null
var icon_modulate = Color.WHITE
var fallback_key = ""
var accent_color = Color(0.38, 0.78, 0.96, 1.0)
var draw_backdrop = true


func set_icon(next_texture, next_modulate, next_fallback_key = "", next_draw_backdrop = true):
	texture = next_texture
	icon_modulate = next_modulate
	fallback_key = next_fallback_key
	accent_color = _accent_color_for_key(fallback_key)
	draw_backdrop = next_draw_backdrop
	queue_redraw()


func _draw():
	var has_texture = texture != null
	_draw_procedural_icon(true, 0.48 if has_texture else 1.0)
	if not has_texture:
		return
	var texture_size = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale = minf(size.x / texture_size.x, size.y / texture_size.y)
	var draw_size = texture_size * scale
	var draw_position = (size - draw_size) * 0.5
	draw_texture_rect(texture, Rect2(draw_position, draw_size), false, icon_modulate)
	_draw_procedural_icon(false, 0.78)


func _draw_procedural_icon(draw_background = true, alpha = 1.0):
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var icon_size = minf(size.x, size.y)
	var center = size * 0.5
	var half = icon_size * 0.5
	var rect = Rect2(center - Vector2(half, half), Vector2(icon_size, icon_size))
	if draw_background and draw_backdrop:
		var bg = Color(0.025, 0.050, 0.060, 0.88 * alpha)
		draw_rect(rect.grow(-1.0), bg, true)
		draw_rect(rect.grow(-1.0), _with_alpha(accent_color.darkened(0.22), alpha), false, 2.0)
	var key = fallback_key.to_lower()
	if _is_support_power_key(key):
		_draw_support_power_icon(rect, key, alpha)
	elif _is_structure_key(key):
		_draw_structure_icon(rect, alpha)
	elif _is_air_key(key):
		_draw_air_icon(rect, alpha)
	elif _is_infantry_key(key):
		_draw_infantry_icon(rect, alpha)
	else:
		_draw_vehicle_icon(rect, alpha)


func _draw_structure_icon(rect, alpha = 1.0):
	var accent = _with_alpha(accent_color, alpha)
	var trim = _with_alpha(Color(0.86, 0.96, 1.0, 0.96), alpha) * icon_modulate
	var base = Rect2(
		rect.position + rect.size * Vector2(0.20, 0.54),
		rect.size * Vector2(0.60, 0.22)
	)
	var roof = PackedVector2Array([
		rect.position + rect.size * Vector2(0.25, 0.54),
		rect.position + rect.size * Vector2(0.50, 0.32),
		rect.position + rect.size * Vector2(0.75, 0.54),
	])
	draw_rect(base, trim, true)
	draw_polygon(roof, PackedColorArray([accent, accent.lightened(0.08), accent]))
	draw_rect(
		Rect2(rect.position + rect.size * Vector2(0.28, 0.61), rect.size * Vector2(0.44, 0.06)),
		accent,
		true
	)
	draw_rect(
		Rect2(rect.position + rect.size * Vector2(0.46, 0.22), rect.size * Vector2(0.08, 0.18)),
		trim,
		true
	)
	draw_circle(rect.position + rect.size * Vector2(0.50, 0.20), rect.size.x * 0.055, accent)


func _draw_air_icon(rect, alpha = 1.0):
	var accent = _with_alpha(accent_color, alpha)
	var trim = _with_alpha(Color(0.90, 0.98, 1.0, 0.96), alpha) * icon_modulate
	var body = PackedVector2Array([
		rect.position + rect.size * Vector2(0.50, 0.18),
		rect.position + rect.size * Vector2(0.60, 0.60),
		rect.position + rect.size * Vector2(0.50, 0.78),
		rect.position + rect.size * Vector2(0.40, 0.60),
	])
	var wings = PackedVector2Array([
		rect.position + rect.size * Vector2(0.14, 0.48),
		rect.position + rect.size * Vector2(0.86, 0.48),
		rect.position + rect.size * Vector2(0.58, 0.62),
		rect.position + rect.size * Vector2(0.50, 0.56),
		rect.position + rect.size * Vector2(0.42, 0.62),
	])
	draw_polygon(wings, PackedColorArray([trim, trim, trim, trim, trim]))
	draw_polygon(body, PackedColorArray([accent.lightened(0.12), accent, accent.darkened(0.10), accent]))
	draw_rect(
		Rect2(rect.position + rect.size * Vector2(0.46, 0.26), rect.size * Vector2(0.08, 0.30)),
		trim,
		true
	)


func _draw_infantry_icon(rect, alpha = 1.0):
	var accent = _with_alpha(accent_color, alpha)
	var trim = _with_alpha(Color(0.92, 0.96, 1.0, 0.96), alpha) * icon_modulate
	draw_circle(rect.position + rect.size * Vector2(0.50, 0.30), rect.size.x * 0.11, trim)
	draw_rect(
		Rect2(rect.position + rect.size * Vector2(0.38, 0.42), rect.size * Vector2(0.24, 0.24)),
		accent,
		true
	)
	draw_line(
		rect.position + rect.size * Vector2(0.30, 0.47),
		rect.position + rect.size * Vector2(0.70, 0.47),
		trim,
		rect.size.x * 0.07
	)
	draw_line(
		rect.position + rect.size * Vector2(0.43, 0.66),
		rect.position + rect.size * Vector2(0.34, 0.82),
		trim,
		rect.size.x * 0.06
	)
	draw_line(
		rect.position + rect.size * Vector2(0.57, 0.66),
		rect.position + rect.size * Vector2(0.66, 0.82),
		trim,
		rect.size.x * 0.06
	)


func _draw_vehicle_icon(rect, alpha = 1.0):
	var accent = _with_alpha(accent_color, alpha)
	var trim = _with_alpha(Color(0.90, 0.98, 1.0, 0.96), alpha) * icon_modulate
	draw_rect(
		Rect2(rect.position + rect.size * Vector2(0.20, 0.47), rect.size * Vector2(0.60, 0.22)),
		trim,
		true
	)
	draw_rect(
		Rect2(rect.position + rect.size * Vector2(0.34, 0.36), rect.size * Vector2(0.28, 0.16)),
		accent,
		true
	)
	draw_line(
		rect.position + rect.size * Vector2(0.56, 0.40),
		rect.position + rect.size * Vector2(0.78, 0.28),
		trim,
		rect.size.x * 0.055
	)
	draw_circle(rect.position + rect.size * Vector2(0.30, 0.72), rect.size.x * 0.075, accent.darkened(0.22))
	draw_circle(rect.position + rect.size * Vector2(0.70, 0.72), rect.size.x * 0.075, accent.darkened(0.22))


func _draw_support_power_icon(rect, key, alpha = 1.0):
	var accent = _with_alpha(accent_color, alpha)
	var trim = _with_alpha(Color(0.92, 0.98, 1.0, 0.96), alpha) * icon_modulate
	var center = rect.position + rect.size * 0.5
	if key.contains("radar"):
		draw_arc(center, rect.size.x * 0.24, 0.0, TAU, 28, trim, rect.size.x * 0.035)
		draw_arc(center, rect.size.x * 0.38, -0.10, 1.35, 20, accent, rect.size.x * 0.045)
		draw_line(center, center + rect.size * Vector2(0.34, -0.20), accent, rect.size.x * 0.045)
	elif key.contains("orbital") or key.contains("strike"):
		draw_line(
			rect.position + rect.size * Vector2(0.50, 0.12),
			rect.position + rect.size * Vector2(0.50, 0.78),
			accent,
			rect.size.x * 0.10
		)
		draw_polygon(PackedVector2Array([
			rect.position + rect.size * Vector2(0.30, 0.70),
			rect.position + rect.size * Vector2(0.70, 0.70),
			rect.position + rect.size * Vector2(0.50, 0.88),
		]), PackedColorArray([trim, trim, accent]))
	elif key.contains("emp"):
		draw_arc(center, rect.size.x * 0.34, 0.0, TAU, 28, accent, rect.size.x * 0.045)
		draw_arc(center, rect.size.x * 0.20, 0.0, TAU, 24, trim, rect.size.x * 0.035)
		draw_line(
			rect.position + rect.size * Vector2(0.42, 0.20),
			rect.position + rect.size * Vector2(0.56, 0.50),
			trim,
			rect.size.x * 0.045
		)
		draw_line(
			rect.position + rect.size * Vector2(0.56, 0.50),
			rect.position + rect.size * Vector2(0.42, 0.80),
			accent,
			rect.size.x * 0.045
		)
	elif key.contains("chrono"):
		draw_arc(center, rect.size.x * 0.34, 0.15, TAU * 0.78, 28, trim, rect.size.x * 0.045)
		draw_line(center, center + rect.size * Vector2(0.02, -0.22), accent, rect.size.x * 0.045)
		draw_line(center, center + rect.size * Vector2(0.21, 0.10), accent, rect.size.x * 0.045)
		draw_circle(center, rect.size.x * 0.055, trim)
	elif key.contains("shield"):
		draw_polygon(PackedVector2Array([
			rect.position + rect.size * Vector2(0.50, 0.13),
			rect.position + rect.size * Vector2(0.75, 0.24),
			rect.position + rect.size * Vector2(0.70, 0.64),
			rect.position + rect.size * Vector2(0.50, 0.86),
			rect.position + rect.size * Vector2(0.30, 0.64),
			rect.position + rect.size * Vector2(0.25, 0.24),
		]), PackedColorArray([accent, trim, accent, trim, accent, trim]))
	elif key.contains("nanite") or key.contains("repair"):
		draw_rect(
			Rect2(rect.position + rect.size * Vector2(0.43, 0.20), rect.size * Vector2(0.14, 0.58)),
			trim,
			true
		)
		draw_rect(
			Rect2(rect.position + rect.size * Vector2(0.22, 0.42), rect.size * Vector2(0.56, 0.14)),
			trim,
			true
		)
		for offset in [Vector2(-0.28, -0.20), Vector2(0.30, -0.18), Vector2(-0.24, 0.26), Vector2(0.28, 0.27)]:
			draw_circle(center + rect.size * offset, rect.size.x * 0.045, accent)
	elif key.contains("weather"):
		draw_circle(rect.position + rect.size * Vector2(0.38, 0.38), rect.size.x * 0.13, trim)
		draw_circle(rect.position + rect.size * Vector2(0.55, 0.34), rect.size.x * 0.16, trim)
		draw_rect(
			Rect2(rect.position + rect.size * Vector2(0.25, 0.42), rect.size * Vector2(0.50, 0.13)),
			trim,
			true
		)
		draw_polygon(PackedVector2Array([
			rect.position + rect.size * Vector2(0.54, 0.49),
			rect.position + rect.size * Vector2(0.42, 0.72),
			rect.position + rect.size * Vector2(0.55, 0.70),
			rect.position + rect.size * Vector2(0.45, 0.90),
			rect.position + rect.size * Vector2(0.73, 0.58),
			rect.position + rect.size * Vector2(0.58, 0.60),
		]), PackedColorArray([accent, accent, trim, trim, accent, accent]))
	elif key.contains("missile"):
		draw_polygon(PackedVector2Array([
			rect.position + rect.size * Vector2(0.54, 0.12),
			rect.position + rect.size * Vector2(0.68, 0.66),
			rect.position + rect.size * Vector2(0.50, 0.86),
			rect.position + rect.size * Vector2(0.32, 0.66),
			rect.position + rect.size * Vector2(0.46, 0.12),
		]), PackedColorArray([trim, accent, trim, accent, trim]))
		draw_line(
			rect.position + rect.size * Vector2(0.37, 0.72),
			rect.position + rect.size * Vector2(0.25, 0.88),
			accent,
			rect.size.x * 0.055
		)
		draw_line(
			rect.position + rect.size * Vector2(0.63, 0.72),
			rect.position + rect.size * Vector2(0.75, 0.88),
			accent,
			rect.size.x * 0.055
		)
	elif key.contains("paradrop"):
		draw_arc(center + rect.size * Vector2(0.0, -0.14), rect.size.x * 0.32, PI, TAU, 24, trim, rect.size.x * 0.05)
		draw_line(
			rect.position + rect.size * Vector2(0.28, 0.43),
			rect.position + rect.size * Vector2(0.42, 0.66),
			trim,
			rect.size.x * 0.035
		)
		draw_line(
			rect.position + rect.size * Vector2(0.72, 0.43),
			rect.position + rect.size * Vector2(0.58, 0.66),
			trim,
			rect.size.x * 0.035
		)
		draw_rect(
			Rect2(rect.position + rect.size * Vector2(0.40, 0.62), rect.size * Vector2(0.20, 0.16)),
			accent,
			true
		)
	else:
		_draw_vehicle_icon(rect, alpha)


func _accent_color_for_key(key):
	var hash_value = absi(str(key).hash())
	var hue = float(hash_value % 360) / 360.0
	return Color.from_hsv(hue, 0.58, 0.94, 1.0)


func _with_alpha(color, alpha):
	return Color(color.r, color.g, color.b, color.a * alpha)


func _is_structure_key(key):
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


func _is_air_key(key):
	for token in ["air", "helicopter", "vtol", "gunship", "bomber"]:
		if key.contains(token):
			return true
	return false


func _is_infantry_key(key):
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


func _is_support_power_key(key):
	for token in [
		"radar_sweep",
		"orbital_strike",
		"emp_pulse",
		"chrono_relay",
		"shield_overdrive",
		"nanite_repair_swarm",
		"weather_storm",
		"strategic_missile",
		"paradrop",
	]:
		if key.contains(token):
			return true
	return false
