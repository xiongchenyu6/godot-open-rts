extends PanelContainer

const POWER_OK_COLOR = Color(0.72, 1.0, 0.74)
const POWER_LOW_COLOR = Color(1.0, 0.42, 0.32)
const WEB_POWER_REFRESH_INTERVAL_SECONDS = 0.2

var player = null
var _web_power_refresh_elapsed = WEB_POWER_REFRESH_INTERVAL_SECONDS

@onready var _resource_a_label = find_child("ResourceALabel")
@onready var _resource_b_label = find_child("ResourceBLabel")
@onready var _resource_a_color_rect = find_child("ResourceAColorRect")
@onready var _resource_b_color_rect = find_child("ResourceBColorRect")
@onready var _power_container = find_child("PowerContainer")
@onready var _power_caption_label = find_child("PowerCaptionLabel")
@onready var _power_label = find_child("PowerLabel")
@onready var _low_power_label = find_child("LowPowerLabel")


func _ready():
	_resource_a_color_rect.color = Constants.Match.Resources.A.COLOR
	_resource_b_color_rect.color = Constants.Match.Resources.B.COLOR
	_power_caption_label.text = tr("POWER_SHORT")


func setup(a_player):
	assert(player == null, "player cannot be null")
	player = a_player
	_on_player_resource_changed()
	player.changed.connect(_on_player_resource_changed)


func _process(delta):
	if player == null:
		return
	if OS.has_feature("web"):
		_web_power_refresh_elapsed += delta
		if _web_power_refresh_elapsed < WEB_POWER_REFRESH_INTERVAL_SECONDS:
			return
		_web_power_refresh_elapsed = 0.0
	_update_power()


func _on_player_resource_changed():
	_resource_a_label.text = str(player.resource_a)
	_resource_b_label.text = str(player.resource_b)
	_update_power()


func _update_power():
	var supply = player.get_power_supply()
	var drain = player.get_power_drain()
	var is_low_power = player.is_low_power()
	_power_caption_label.text = tr("POWER_SHORT")
	_power_label.text = "{0}/{1}".format([supply, drain])
	var color = POWER_LOW_COLOR if is_low_power else POWER_OK_COLOR
	_power_caption_label.modulate = color
	_power_label.modulate = color
	_low_power_label.visible = is_low_power
	_low_power_label.text = tr("LOW_POWER_STATUS")
	_low_power_label.modulate = color
	_power_container.tooltip_text = _build_power_tooltip(supply, drain, is_low_power)


func _build_power_tooltip(supply, drain, is_low_power):
	var text = "{0}: {1}/{2}".format([tr("POWER"), supply, drain])
	if is_low_power:
		text += "\n{0}".format([tr("LOW_POWER_EFFECTS")])
	return text
