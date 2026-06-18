extends PanelContainer

@onready var _match = find_parent("Match")


func _ready():
	if not FeatureFlags.god_mode:
		queue_free()


func _on_toggle_button_pressed():
	if not FeatureFlags.god_mode or _match == null:
		return
	_match.fog_of_war.visible = not _match.fog_of_war.visible
	_match.find_child("UnitVisibilityHandler").visible = not (
		_match.find_child("UnitVisibilityHandler").visible
	)
