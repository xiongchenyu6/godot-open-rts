extends Node3D

const DynamicCircle2D = preload("res://source/generic-scenes-and-nodes/2d/DynamicCircle2D.tscn")

const DEFAULT_SIZE = Vector2i(100, 100)
const WEB_SYNC_INTERVAL_SECONDS = 0.15

@export_range(1, 10) var texture_units_per_world_unit = 2  # px/m
@export var fog_circle_color = Color(0.25, 0.25, 0.25)
@export var shroud_circle_color = Color(1.0, 1.0, 1.0)

var _unit_to_circles_mapping = {}
var _sync_elapsed = WEB_SYNC_INTERVAL_SECONDS

@onready var _revealer = find_child("Revealer")
@onready var _fog_viewport = find_child("FogViewport")
@onready var _fog_viewport_container = find_child("FogViewportContainer")
@onready var _combined_viewport = find_child("CombinedViewport")
@onready var _screen_overlay = find_child("ScreenOverlay")


func _ready():
	if _fog_viewport.size == DEFAULT_SIZE:
		resize(find_parent("Match").find_child("Map").size)
	if OS.has_feature("web"):
		_disable_screen_overlay_for_web()
	else:
		_apply_visibility_texture()
		_screen_overlay.material_override.set_shader_parameter(
			"texture_units_per_world_unit", texture_units_per_world_unit
		)
	_revealer.hide()
	find_child("EditorOnlyCircle").queue_free()


func _disable_screen_overlay_for_web():
	if _screen_overlay != null:
		_screen_overlay.hide()


func is_screen_overlay_enabled():
	return _screen_overlay != null and _screen_overlay.visible


func _physics_process(delta):
	if OS.has_feature("web"):
		_sync_elapsed += delta
		if _sync_elapsed < WEB_SYNC_INTERVAL_SECONDS:
			return
		_sync_elapsed = 0.0
	var units_synced = {}
	var units_to_sync = (
		get_tree().get_nodes_in_group("revealed_units")
		+ get_tree().get_nodes_in_group("temporary_revealers")
	)
	for unit in units_to_sync:
		if not unit.is_revealing():
			continue
		units_synced[unit] = 1
		if not _unit_is_mapped(unit):
			_map_unit_to_new_circles(unit)
		_sync_circles_to_unit(unit)
	for mapped_unit in _unit_to_circles_mapping.keys():
		if not mapped_unit in units_synced:
			_cleanup_mapping(mapped_unit)


func reveal():
	_revealer.show()


func set_texture_density_for_runtime(texture_density):
	texture_units_per_world_unit = max(1, int(texture_density))
	if _screen_overlay != null and _screen_overlay.material_override != null:
		_screen_overlay.material_override.set_shader_parameter(
			"texture_units_per_world_unit", texture_units_per_world_unit
		)
		_apply_visibility_texture()
	for unit in _unit_to_circles_mapping.keys():
		var circles = _unit_to_circles_mapping[unit]
		circles[0].radius = unit.sight_range * texture_units_per_world_unit
		circles[1].radius = unit.sight_range * texture_units_per_world_unit


func get_visibility_texture():
	return _combined_viewport.get_texture()


func resize(map_size: Vector2):
	_fog_viewport.size = map_size * texture_units_per_world_unit
	_combined_viewport.size = map_size * texture_units_per_world_unit
	_apply_visibility_texture()


func _apply_visibility_texture():
	if _screen_overlay == null or _screen_overlay.material_override == null:
		return
	_screen_overlay.material_override.set_shader_parameter(
		"world_visibility_texture", get_visibility_texture()
	)


func _unit_is_mapped(unit):
	return unit in _unit_to_circles_mapping


func _map_unit_to_new_circles(unit):
	var shroud_circle = DynamicCircle2D.instantiate()
	shroud_circle.color = fog_circle_color
	shroud_circle.radius = unit.sight_range * texture_units_per_world_unit
	_fog_viewport.add_child(shroud_circle)
	var fow_circle = DynamicCircle2D.instantiate()
	fow_circle.color = shroud_circle_color
	fow_circle.radius = unit.sight_range * texture_units_per_world_unit
	_fog_viewport_container.add_sibling(fow_circle)
	_unit_to_circles_mapping[unit] = [shroud_circle, fow_circle]


func _sync_circles_to_unit(unit):
	var unit_pos_3d = unit.global_transform.origin
	var unit_pos_2d = Vector2(unit_pos_3d.x, unit_pos_3d.z) * texture_units_per_world_unit
	_unit_to_circles_mapping[unit][0].position = unit_pos_2d
	_unit_to_circles_mapping[unit][1].position = unit_pos_2d


func _cleanup_mapping(unit):
	_unit_to_circles_mapping[unit][0].queue_free()
	_unit_to_circles_mapping[unit][1].queue_free()
	_unit_to_circles_mapping.erase(unit)
