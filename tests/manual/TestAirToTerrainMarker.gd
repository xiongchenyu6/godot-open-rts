extends Node

const AirToTerrainMarkerScene = preload("res://source/match/units/traits/AirToTerrainMarker.tscn")
const CONTROLLED_UNIT_MATERIAL = preload(
	"res://source/match/resources/materials/controlled_unit_air_to_terrain_marker.material.tres"
)
const ADVERSARY_UNIT_MATERIAL = preload(
	"res://source/match/resources/materials/adversary_unit_air_to_terrain_marker.material.tres"
)


class FakeAirUnit:
	extends Node3D

	signal selected
	signal deselected


func _ready():
	await _assert_selected_controlled_unit_uses_controlled_material()
	await _assert_selected_adversary_unit_uses_adversary_material()
	await _assert_ungrouped_unit_selection_hides_marker_without_crashing()
	get_tree().quit()


func _new_marker_for_unit(group_names):
	var unit = FakeAirUnit.new()
	unit.name = "FakeAirUnit"
	for group_name in group_names:
		unit.add_to_group(group_name)
	add_child(unit)
	var marker = AirToTerrainMarkerScene.instantiate()
	unit.add_child(marker)
	return marker


func _marker_mesh(marker):
	var mesh = marker.find_child("MeshInstance3D", true, false)
	assert(mesh != null, "air-to-terrain marker should include a mesh instance")
	return mesh


func _assert_selected_controlled_unit_uses_controlled_material():
	var marker = _new_marker_for_unit(["selected_units", "controlled_units"])
	await get_tree().process_frame
	var mesh = _marker_mesh(marker)
	assert(mesh.visible, "selected controlled air unit marker should be visible")
	assert(
		mesh.material_override == CONTROLLED_UNIT_MATERIAL,
		"selected controlled air unit marker should use the controlled material"
	)
	marker.get_parent().queue_free()
	await get_tree().process_frame


func _assert_selected_adversary_unit_uses_adversary_material():
	var marker = _new_marker_for_unit(["selected_units", "adversary_units"])
	await get_tree().process_frame
	var mesh = _marker_mesh(marker)
	assert(mesh.visible, "selected adversary air unit marker should be visible")
	assert(
		mesh.material_override == ADVERSARY_UNIT_MATERIAL,
		"selected adversary air unit marker should use the adversary material"
	)
	marker.get_parent().queue_free()
	await get_tree().process_frame


func _assert_ungrouped_unit_selection_hides_marker_without_crashing():
	var marker = _new_marker_for_unit(["selected_units"])
	await get_tree().process_frame
	var mesh = _marker_mesh(marker)
	assert(
		not mesh.visible,
		"selected air unit without a player visibility group should hide its terrain marker"
	)

	var unit = marker.get_parent()
	unit.add_to_group("controlled_units")
	unit.selected.emit()
	await get_tree().process_frame
	assert(mesh.visible, "air marker should recover after the unit receives a visibility group")
	assert(
		mesh.material_override == CONTROLLED_UNIT_MATERIAL,
		"recovered air marker should use the controlled material"
	)
	unit.deselected.emit()
	await get_tree().process_frame
	assert(not mesh.visible, "air marker should hide on deselection")
	unit.queue_free()
	await get_tree().process_frame
