extends "res://source/match/units/actions/Action.gd"

enum State { NULL, MOVING_TO_RESOURCE, COLLECTING, MOVING_TO_DROPOFF }

const CommandCenter = preload("res://source/match/units/CommandCenter.gd")
const Refinery = preload("res://source/match/units/Refinery.gd")
const CollectingResourcesWhileInRange = preload(
	"res://source/match/units/actions/CollectingResourcesWhileInRange.gd"
)
const MovingToUnit = preload("res://source/match/units/actions/MovingToUnit.gd")
const Worker = preload("res://source/match/units/Worker.gd")
const ResourceUnit = preload("res://source/match/units/non-player/ResourceUnit.gd")

var _state := State.NULL
var _state_locked = false
var _queued_state = null
var _resource_unit = null
var _dropoff_unit = null
var _sub_action = null

@onready var _unit = Utils.NodeEx.find_parent_with_group(self, "units")


static func is_applicable(source_unit, target_unit):
	return (
		(source_unit is Worker and target_unit is ResourceUnit)
		or (source_unit is Worker and _is_resource_dropoff(target_unit))
	) and source_unit.can_collect_resources()


func _init(unit):
	if unit is ResourceUnit:
		_set_resource_unit(unit)
	elif _is_resource_dropoff(unit):
		_set_dropoff_unit(unit)


func _ready():
	if _resource_unit != null:
		_change_state_to(State.MOVING_TO_RESOURCE)
	elif _dropoff_unit != null:
		_change_state_to(State.MOVING_TO_DROPOFF)


func _to_string():
	return "{0}({1})".format([super(), str(_sub_action) if _sub_action != null else ""])


func get_resource_unit():
	return _resource_unit


func _change_state_to(new_state):
	if _state_locked:
		_queued_state = new_state
		return
	_state_locked = true
	_exit_state(_state)
	_enter_state(new_state)
	_state = new_state
	_state_locked = false
	_apply_queued_state_transition()


func _apply_queued_state_transition():
	if _state_locked or _queued_state == null:
		return
	var queued_state = _queued_state
	_queued_state = null
	if queued_state != _state and is_inside_tree():
		_change_state_to(queued_state)


func _exit_state(_a_state):
	if _sub_action == null or not is_instance_valid(_sub_action):
		_sub_action = null
		return
	var sub_action = _sub_action
	_sub_action = null
	if sub_action.tree_exited.is_connected(_on_sub_action_finished):
		sub_action.tree_exited.disconnect(_on_sub_action_finished)
	sub_action.queue_free()


func _enter_state(state):
	match state:
		State.MOVING_TO_RESOURCE:
			if (
				_resource_unit == null
				and not _set_resource_unit(_find_closest_resource_unit_in_nearby_area())
			):
				return
			_sub_action = MovingToUnit.new(_resource_unit)
			_sub_action.tree_exited.connect(_on_sub_action_finished, CONNECT_DEFERRED)
			add_child(_sub_action)
			_unit.action_updated.emit()
		State.COLLECTING:
			assert(
				CollectingResourcesWhileInRange.is_applicable(_unit, _resource_unit),
				"the action should apply at this point"
			)
			_sub_action = CollectingResourcesWhileInRange.new(_resource_unit)
			_sub_action.tree_exited.connect(_on_sub_action_finished, CONNECT_DEFERRED)
			add_child(_sub_action)
			_unit.action_updated.emit()
		State.MOVING_TO_DROPOFF:
			if not _set_dropoff_unit(_find_dropoff_closest_to_unit(_unit)):
				return
			_sub_action = MovingToUnit.new(_dropoff_unit)
			_sub_action.tree_exited.connect(_on_sub_action_finished, CONNECT_DEFERRED)
			add_child(_sub_action)
			_unit.action_updated.emit()


func _set_resource_unit(resource_unit):
	if resource_unit == null:
		queue_free()
		return false
	assert(resource_unit != _resource_unit, "it's not possible to set the same unit")
	_resource_unit = resource_unit
	_resource_unit.tree_exited.connect(_on_resource_unit_removed)
	return true


func _set_dropoff_unit(dropoff_unit):
	if dropoff_unit == null:
		queue_free()
		return false
	if dropoff_unit != _dropoff_unit:
		dropoff_unit.tree_exited.connect(_on_dropoff_unit_removed)
	_dropoff_unit = dropoff_unit
	return true


func _transfer_collected_resources_to_player():
	_unit.player.resource_a += _amount_after_dropoff_bonus(_unit.player, _unit.resource_a)
	_unit.player.resource_b += _amount_after_dropoff_bonus(_unit.player, _unit.resource_b)
	_unit.resource_a = 0
	_unit.resource_b = 0


func _find_closest_resource_unit_in_nearby_area():
	return Utils.Match.Resources.find_resource_unit_closest_to_unit_yet_no_further_than(
		_unit, Constants.Match.Units.NEW_RESOURCE_SEARCH_RADIUS_M
	)


static func _is_resource_dropoff(unit):
	return unit != null and (unit is CommandCenter or unit is Refinery) and unit.is_constructed()


static func _find_dropoff_closest_to_unit(unit):
	var dropoffs_of_the_same_player = unit.get_tree().get_nodes_in_group("units").filter(
		func(a_unit):
			return (
				_is_resource_dropoff(a_unit) and a_unit.player == unit.player
			)
	)
	if dropoffs_of_the_same_player.is_empty():
		return null
	var dropoffs_sorted_by_distance = dropoffs_of_the_same_player.map(
		func(a_unit):
			return {
				"distance":
				(unit.global_position * Vector3(1, 0, 1)).distance_to(
					a_unit.global_position * Vector3(1, 0, 1)
				),
				"dropoff": a_unit
			}
	)
	dropoffs_sorted_by_distance.sort_custom(func(a, b): return a["distance"] < b["distance"])
	return dropoffs_sorted_by_distance[0]["dropoff"]


static func _amount_after_dropoff_bonus(player, amount):
	if amount <= 0:
		return amount
	if player == null or player.is_low_power():
		return amount
	if not Utils.Match.Unit.Tech.player_has_constructed_structure(
		player, Constants.Match.Resources.ORE_PURIFIER_STRUCTURE_PATH
	):
		return amount
	return amount + int(ceil(float(amount) * Constants.Match.Resources.ORE_PURIFIER_BONUS_RATIO))


func _handle_sub_action_finished_while_moving_to_resource():
	# react to resource removal
	if _resource_unit == null:
		if _set_resource_unit(_find_closest_resource_unit_in_nearby_area()):
			_change_state_to(State.MOVING_TO_RESOURCE)
		return
	# resource reached
	if not _unit.is_full():
		_change_state_to(State.COLLECTING)
	else:
		_change_state_to(State.MOVING_TO_DROPOFF)


func _handle_sub_action_finished_while_collecting():
	# react to resource not being in range anymore
	if (
		_resource_unit != null
		and not _unit.is_full()
		and not Utils.Match.Unit.Movement.units_adhere(_unit, _resource_unit)
	):
		_change_state_to(State.MOVING_TO_RESOURCE)
		return
	# finished collecting
	_change_state_to(State.MOVING_TO_DROPOFF)


func _handle_sub_action_finished_while_moving_to_dropoff():
	if not _is_resource_dropoff(_dropoff_unit):
		if _set_dropoff_unit(_find_dropoff_closest_to_unit(_unit)):
			_change_state_to(State.MOVING_TO_DROPOFF)
		return
	_transfer_collected_resources_to_player()
	_change_state_to(State.MOVING_TO_RESOURCE)


func _on_sub_action_finished():
	if not is_inside_tree():
		return
	_sub_action = null
	_unit.action_updated.emit()
	match _state:
		State.MOVING_TO_RESOURCE:
			_handle_sub_action_finished_while_moving_to_resource()
		State.COLLECTING:
			_handle_sub_action_finished_while_collecting()
		State.MOVING_TO_DROPOFF:
			_handle_sub_action_finished_while_moving_to_dropoff()


func _on_resource_unit_removed():
	_resource_unit = null


func _on_dropoff_unit_removed():
	_dropoff_unit = null
