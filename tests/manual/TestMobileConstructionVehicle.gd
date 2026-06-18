extends "res://tests/manual/Match.gd"

const CollectingResourcesSequentially = preload(
	"res://source/match/units/actions/CollectingResourcesSequentially.gd"
)
const CollectingResourcesWhileInRange = preload(
	"res://source/match/units/actions/CollectingResourcesWhileInRange.gd"
)
const CommandCenterScript = preload("res://source/match/units/CommandCenter.gd")
const MobileConstructionVehicleUnit = preload(
	"res://source/match/units/MobileConstructionVehicle.tscn"
)

@onready var _mcv = $Players/Human/MobileConstructionVehicle
@onready var _command_center = $Players/Human/CommandCenter
@onready var _resource_a = $Map/Resources/ResourceA


func _ready():
	super()
	await get_tree().process_frame

	assert(
		Utils.Match.Unit.Tech.can_produce($Players/Human, MobileConstructionVehicleUnit.resource_path),
		"tech lab should satisfy mobile construction vehicle production requirements"
	)
	assert(_mcv.can_construct_structures(), "mobile construction vehicle should build structures")
	assert(not _mcv.can_collect_resources(), "mobile construction vehicle should not gather ore")
	assert(_mcv.is_full(), "mobile construction vehicle should be treated as non-collecting")
	assert(
		not CollectingResourcesSequentially.is_applicable(_mcv, _command_center),
		"mobile construction vehicle should not use drop-off resource actions"
	)
	assert(
		not CollectingResourcesSequentially.is_applicable(_mcv, _resource_a),
		"mobile construction vehicle should not use resource collection actions"
	)
	assert(
		not CollectingResourcesWhileInRange.is_applicable(_mcv, _resource_a),
		"mobile construction vehicle should not collect resources while in range"
	)

	_mcv.find_child("Selection").select()
	await get_tree().process_frame
	var unit_menus = $HUD.find_child("UnitMenus", true, false)
	var worker_menu = unit_menus.find_child("WorkerMenu", true, false)
	var generic_menu = unit_menus.find_child("GenericMenu", true, false)
	assert(worker_menu.visible, "selected mobile construction vehicle should open build menu")
	assert(worker_menu.unit == _mcv, "worker menu should target the selected mobile constructor")
	assert(not generic_menu.visible, "mobile construction vehicle should not fall back to generic menu")
	assert(
		worker_menu.find_child("PlaceCommandCenterButton", true, false) != null,
		"mobile construction vehicle build menu should expose base expansion structures"
	)
	var deploy_button = worker_menu.find_child("DeployMobileConstructionVehicleButton", true, false)
	assert(deploy_button != null, "mobile construction vehicle should expose a deploy button")
	assert(deploy_button.visible, "deploy button should be visible for mobile construction vehicles")
	assert(not deploy_button.disabled, "deploy button should be enabled for mobile construction vehicles")
	assert(
		deploy_button.tooltip_text.contains(tr("DEPLOY_MCV_DESCRIPTION")),
		"deploy button tooltip should describe command center deployment"
	)

	var command_centers_before = _command_centers()
	var resources_before = {
		"resource_a": $Players/Human.resource_a,
		"resource_b": $Players/Human.resource_b,
	}
	var deploy_position = _mcv.global_position
	deploy_button.emit_signal("pressed")
	await get_tree().process_frame
	var command_centers = _command_centers()
	assert(
		command_centers.size() == command_centers_before.size() + 1,
		"deploying a mobile construction vehicle should add a command center"
	)
	assert(
		$Players/Human.resource_a == resources_before["resource_a"]
		and $Players/Human.resource_b == resources_before["resource_b"],
		"deploying a mobile construction vehicle should not spend extra resources"
	)
	var deployed_command_center = _new_command_center(command_centers_before, command_centers)
	assert(deployed_command_center.is_constructed(), "deployed command center should be ready")
	var deployed_position_yless = deployed_command_center.global_position * Vector3(1, 0, 1)
	var deploy_position_yless = deploy_position * Vector3(1, 0, 1)
	assert(
		deployed_position_yless.distance_to(deploy_position_yless) < 0.01,
		"deployed command center should unpack at the mobile construction vehicle top-down position"
	)
	assert(
		not is_instance_valid(_mcv) or not _mcv.is_inside_tree(),
		"mobile construction vehicle should be consumed by deployment"
	)
	get_tree().quit()


func _command_centers():
	return $Players/Human.get_children().filter(func(unit): return unit is CommandCenterScript)


func _new_command_center(command_centers_before, command_centers_after):
	for command_center in command_centers_after:
		if not command_center in command_centers_before:
			return command_center
	return null
