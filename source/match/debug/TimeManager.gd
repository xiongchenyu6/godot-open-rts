extends PanelContainer


func _ready():
	if not FeatureFlags.god_mode:
		queue_free()


func _on_time_scale_spin_box_value_changed(value):
	if not FeatureFlags.god_mode:
		return
	Engine.time_scale = value
