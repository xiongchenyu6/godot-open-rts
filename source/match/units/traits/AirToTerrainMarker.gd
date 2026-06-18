extends Node3D

const CONTROLLED_UNIT_MATERIAL = preload(
	"res://source/match/resources/materials/controlled_unit_air_to_terrain_marker.material.tres"
)
const ADVERSARY_UNIT_MATERIAL = preload(
	"res://source/match/resources/materials/adversary_unit_air_to_terrain_marker.material.tres"
)

@onready var _unit = get_parent()
@onready var _mesh_instance = find_child("MeshInstance3D")


func _ready():
	if _mesh_instance == null or _unit == null:
		push_warning("Air-to-terrain marker is missing its unit or mesh instance")
		return
	_mesh_instance.hide()
	if _unit.has_signal("selected"):
		_unit.selected.connect(_on_unit_selected)
	else:
		push_warning("Air-to-terrain marker parent has no selected signal: {0}".format([_unit.get_path()]))
	if _unit.has_signal("deselected"):
		_unit.deselected.connect(_mesh_instance.hide)
	if _unit.is_in_group("selected_units"):
		_on_unit_selected()


func _update_material():
	if _unit.is_in_group("controlled_units"):
		_mesh_instance.material_override = CONTROLLED_UNIT_MATERIAL
		return true
	elif _unit.is_in_group("adversary_units"):
		_mesh_instance.material_override = ADVERSARY_UNIT_MATERIAL
		return true
	else:
		push_warning(
			"Hiding air-to-terrain marker for unit without player visibility group: {0}".format(
				[_unit.get_path()]
			)
		)
		_mesh_instance.hide()
		return false


func _on_unit_selected():
	if _update_material():
		_mesh_instance.show()
