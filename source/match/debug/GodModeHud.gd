extends CanvasLayer


func _enter_tree():
	if not FeatureFlags.god_mode:
		queue_free()


func _ready():
	if is_queued_for_deletion():
		return
	if not Globals.god_mode:
		hide()
	Signals.god_mode_enabled.connect(show)
	Signals.god_mode_disabled.connect(hide)
