extends Node3D

var player = null
var sight_range = 0.0
var lifetime = 0.0


func _ready():
	add_to_group("temporary_revealers")
	if lifetime > 0.0:
		await get_tree().create_timer(lifetime).timeout
		queue_free()


func is_revealing():
	return visible and sight_range > 0.0
