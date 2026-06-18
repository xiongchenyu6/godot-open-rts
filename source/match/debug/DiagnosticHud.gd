extends CanvasLayer

const REFRESH_INTERVAL_SECONDS = 0.25

var _refresh_elapsed = REFRESH_INTERVAL_SECONDS

@onready var _margin_container = find_child("MarginContainer")
@onready var _fps_label = find_child("FPSLabel")


func _ready():
	if not FeatureFlags.diagnostic_hud and not OS.has_feature("web"):
		queue_free()
		return
	layer = 100
	visible = OS.has_feature("web")
	if OS.has_feature("web"):
		_place_web_overlay()


func _unhandled_input(event):
	if event.is_action_pressed("toggle_diagnostic_mode"):
		visible = not visible


func _physics_process(delta):
	_refresh_elapsed += delta
	if _refresh_elapsed < REFRESH_INTERVAL_SECONDS:
		return
	_refresh_elapsed = 0.0
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var frame_ms = 1000.0 / maxf(1.0, fps)
	if OS.has_feature("web"):
		_fps_label.text = "{0} FPS  {1} ms  WebGL 2\n{2}".format(
			["%0.1f" % fps, "%0.1f" % frame_ms, _web_match_status()]
		)
		return
	_fps_label.text = (
		"{0} FPS  {1} ms\n".format(["%0.1f" % fps, "%0.1f" % frame_ms])
		+ str(RenderingServer.get_video_adapter_name())
		+ " "
		+ str(RenderingServer.get_video_adapter_vendor())
		+ " \n"
		+ "CPU: "
		+ str(OS.get_processor_name())
		+ "\n"
		+ str(OS.get_processor_count())
		+ " Threads\n"
		+ str(OS.get_static_memory_usage() / int(1000000))
		+ " MB Memory\n"
		+ str(OS.get_name())
	)


func _place_web_overlay():
	if _margin_container == null:
		return
	_margin_container.anchor_left = 0.5
	_margin_container.anchor_right = 0.5
	_margin_container.anchor_top = 0.0
	_margin_container.anchor_bottom = 0.0
	_margin_container.offset_left = -260.0
	_margin_container.offset_top = 48.0
	_margin_container.offset_right = 260.0
	_margin_container.offset_bottom = 118.0
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fps_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fps_label.custom_minimum_size = Vector2(520.0, 70.0)


func _web_match_status() -> String:
	var match_node = _find_match_node()
	if match_node != null and match_node.has_method("get_web_diagnostic_status"):
		return match_node.get_web_diagnostic_status()
	return "Match: pending"


func _find_match_node():
	var node = get_parent()
	while node != null:
		if node.has_method("get_web_diagnostic_status"):
			return node
		node = node.get_parent()
	return null
