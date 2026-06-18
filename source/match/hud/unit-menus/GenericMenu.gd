extends GridContainer

const StructureMenuActions = preload("res://source/match/hud/unit-menus/StructureMenuActions.gd")
const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")

var units = []

@onready var _hold_position_button = find_child("HoldPositionButton")
@onready var _attack_move_button = find_child("AttackMoveButton")
@onready var _patrol_button = find_child("PatrolButton")
@onready var _sell_structure_button = find_child("SellStructureButton")
@onready var _deploy_mode_button = find_child("DeployModeButton")
var _repair_structure_button = null
@onready var _cancel_action_button = find_child("CancelActionButton")
@onready var _guard_area_button = find_child("GuardAreaButton")
@onready var _scatter_button = find_child("ScatterButton")


func _ready():
	_repair_structure_button = StructureMenuActions.ensure_repair_button(
		self, "RepairStructureButtonSlot"
	)
	CommandButtonHotkeys.assign_grid_hotkeys(self)
	CommandButtonHotkeys.assign_button_hotkey(_cancel_action_button, "S", KEY_S)
	CommandButtonHotkeys.assign_button_hotkey(_guard_area_button, "G", KEY_G)
	CommandButtonHotkeys.assign_button_hotkey(_scatter_button, "X", KEY_X)


func refresh():
	Utils.Match.UnitCommands.refresh_hold_position_button(_hold_position_button, units)
	Utils.Match.UnitCommands.refresh_attack_move_button(_attack_move_button, units)
	Utils.Match.UnitCommands.refresh_patrol_button(_patrol_button, units)
	StructureMenuActions.refresh_sell_button(_sell_structure_button, units)
	Utils.Match.UnitCommands.refresh_deploy_mode_button(_deploy_mode_button, units)
	StructureMenuActions.refresh_repair_button(_repair_structure_button, units)
	Utils.Match.UnitCommands.refresh_cancel_action_button(_cancel_action_button, units)
	Utils.Match.UnitCommands.refresh_guard_area_button(_guard_area_button, units)
	Utils.Match.UnitCommands.refresh_scatter_button(_scatter_button, units)


func _on_cancel_action_button_pressed():
	Utils.Match.UnitCommands.cancel_current_actions(units)
	refresh()


func _on_hold_position_button_toggled(button_pressed):
	Utils.Match.UnitCommands.set_hold_position(units, button_pressed)
	refresh()


func _on_attack_move_button_pressed():
	Utils.Match.UnitCommands.request_attack_move(units)


func _on_patrol_button_pressed():
	Utils.Match.UnitCommands.request_patrol(units)


func _on_sell_structure_button_pressed():
	StructureMenuActions.sell(units)


func _on_repair_structure_button_pressed():
	StructureMenuActions.repair(units)
	refresh()


func _on_deploy_mode_button_toggled(button_pressed):
	Utils.Match.UnitCommands.set_deploy_mode(units, button_pressed)
	refresh()


func _on_guard_area_button_pressed():
	Utils.Match.UnitCommands.guard_area(units)
	refresh()


func _on_scatter_button_pressed():
	Utils.Match.UnitCommands.scatter_units(units)
	refresh()
