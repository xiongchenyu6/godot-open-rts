extends Control

@onready var _rich_text_label = find_child("RichTextLabel")
@onready var _back_button = find_child("Button")


func _ready():
	_rich_text_label.text = (
		_rich_text_label
		. text
		. replace("CORE_CONTRIBUTORS", tr("CORE_CONTRIBUTORS"))
		. replace("ASSETS", tr("ASSETS"))
	)
	_back_button.text = tr("BACK")


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://source/main-menu/Main.tscn")
