extends "res://tests/manual/Match.gd"

const AttackMoving = preload("res://source/match/units/actions/AttackMoving.gd")
const AutoAttacking = preload("res://source/match/units/actions/AutoAttacking.gd")
const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const Moving = preload("res://source/match/units/actions/Moving.gd")

@onready var _drill = $Players/Human/SiegeDrillTank
@onready var _enemy_command_center = $Players/Enemy/CommandCenter
@onready var _generic_menu = get_node(
	"HUD/MarginContainer3/VBoxContainer/UnitMenus/MarginContainer"
	+ "/CommandPanelViewport/MenuScroll/MenuStack/GenericMenu"
)
@onready var _selection_info = $HUD/SelectionInfoAnchor/SelectionInfo


func _ready():
	super()
	await get_tree().process_frame

	var base_attack_range = _drill.attack_range
	var base_attack_interval = _drill.attack_interval
	var base_structure_damage_multiplier = _drill.structure_damage_multiplier
	var base_sight_range = _drill.sight_range
	var base_movement_speed = _drill.movement_speed
	_enemy_command_center.global_position = _drill.global_position + Vector3(16.0, 0.0, 0.0)

	_drill.find_child("Selection").select()
	await get_tree().process_frame

	var deploy_button = _generic_menu.find_child("DeployModeButton", true, false)
	assert(deploy_button != null, "generic command menu should expose deploy mode")
	assert(not deploy_button.disabled, "deploy mode should be available for siege drill tanks")
	assert(
		deploy_button.get_meta(CommandButtonHotkeys.META_DISPLAY) == "T",
		"deploy mode should occupy the fifth visible command slot"
	)
	assert(
		deploy_button.tooltip_text.contains(tr("DEPLOY_MODE_DESCRIPTION")),
		"deploy mode tooltip should explain the deployed stance"
	)
	assert(Moving.is_applicable(_drill), "undeployed siege drill tanks should accept move orders")
	assert(AttackMoving.is_applicable(_drill), "undeployed siege drill tanks should attack-move")

	assert(CommandButtonHotkeys.press_button(deploy_button), "deploy button should toggle on")
	await get_tree().process_frame

	assert(_drill.is_deployed_mode(), "siege drill tank should enter deployed mode")
	assert(deploy_button.button_pressed, "deploy button should show the active deployed state")
	assert(_drill.hold_position, "deployed siege drill tanks should hold position")
	assert(_drill.movement_speed == 0.0, "deployed siege drill tanks should stop moving")
	assert(not Moving.is_applicable(_drill), "deployed siege drill tanks should reject move orders")
	assert(
		not AttackMoving.is_applicable(_drill),
		"deployed siege drill tanks should reject attack-move orders"
	)
	assert(_drill.attack_range > base_attack_range, "deployed mode should increase attack range")
	assert(
		_drill.attack_interval < base_attack_interval,
		"deployed mode should increase attack cadence"
	)
	assert(
		_drill.structure_damage_multiplier > base_structure_damage_multiplier,
		"deployed mode should improve anti-structure damage"
	)
	assert(_drill.sight_range > base_sight_range, "deployed mode should increase sight range")
	await get_tree().create_timer(0.2).timeout
	assert(
		_selection_info.find_child("StatsLabel", true, false).text.contains(
			tr("SELECTION_DEPLOYED")
		),
		"selection info should show deployed state"
	)

	var position_before_move_order = _drill.global_position
	MatchSignals.terrain_targeted.emit(_drill.global_position + Vector3(5.0, 0.0, 0.0))
	await get_tree().create_timer(0.25).timeout
	assert(
		_drill.global_position.distance_to(position_before_move_order) < 0.05,
		"deployed siege drill tanks should stay anchored after a move order"
	)

	assert(
		not AutoAttacking.is_applicable(_drill, _enemy_command_center),
		"deployed siege drill tanks should not chase out-of-range targets"
	)
	MatchSignals.unit_targeted.emit(_enemy_command_center)
	await get_tree().process_frame
	assert(
		not (_drill.action is AutoAttacking),
		"manual target orders should not create a chasing attack while deployed"
	)

	assert(CommandButtonHotkeys.press_button(deploy_button), "deploy button should toggle off")
	await get_tree().process_frame
	assert(not _drill.is_deployed_mode(), "siege drill tank should leave deployed mode")
	assert(not deploy_button.button_pressed, "deploy button should show the packed state")
	assert(not _drill.hold_position, "undeploy should restore the previous hold-position state")
	assert(_drill.movement_speed == base_movement_speed, "undeploy should restore movement speed")
	assert(_drill.attack_range == base_attack_range, "undeploy should restore attack range")
	assert(_drill.attack_interval == base_attack_interval, "undeploy should restore attack cadence")
	assert(
		_drill.structure_damage_multiplier == base_structure_damage_multiplier,
		"undeploy should restore structure damage multiplier"
	)
	assert(_drill.sight_range == base_sight_range, "undeploy should restore sight range")
	assert(Moving.is_applicable(_drill), "undeployed siege drill tanks should move again")

	MatchSignals.terrain_targeted.emit(_drill.global_position + Vector3(2.0, 0.0, 0.0))
	await get_tree().process_frame
	assert(_drill.action is Moving, "undeployed siege drill tanks should accept move orders again")
	get_tree().quit()
