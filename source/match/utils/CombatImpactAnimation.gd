extends Node3D

@export var ttl = 1.2

@onready var _timer = find_child("Timer")


func _ready():
	await get_tree().physics_frame
	for particles in find_children("*", "GPUParticles3D"):
		particles.emitting = true
	_timer.timeout.connect(queue_free)
	_timer.start(ttl)
