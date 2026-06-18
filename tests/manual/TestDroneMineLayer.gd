extends "res://tests/manual/Match.gd"

const DroneMineLayerUnit = preload("res://source/match/units/DroneMineLayer.tscn")
const LandMine = preload("res://source/match/units/LandMine.gd")
const VehicleFactoryMenuScene = preload("res://source/match/hud/unit-menus/VehicleFactoryMenu.tscn")
const RA2_ICON_SET = "imagegen-rts-ra2-inspired-20260616-01"

@onready var _human = $Players/Human
@onready var _mine_layer = $Players/Human/DroneMineLayer
@onready var _enemy_tank = $Players/Enemy/Tank
@onready var _enemy_drone = $Players/Enemy/Drone


func _ready():
	super()
	await get_tree().process_frame
	await get_tree().physics_frame
	_place_and_stop(_enemy_tank, Vector3(26.0, 0.0, 26.0))
	await get_tree().physics_frame

	await _assert_drone_mine_layer_constants_and_menu()
	_assert(
		Utils.Match.Unit.Tech.can_produce(_human, DroneMineLayerUnit.resource_path),
		"robotics bay should unlock drone mine layer production"
	)

	var mine = await _wait_for_mine(1.5)
	_assert(mine != null, "drone mine layer should deploy a mine automatically")
	_assert(mine.source_unit == _mine_layer, "deployed mine should track the mine layer as source")

	var drone_hp_before = _enemy_drone.hp
	_enemy_drone.global_position = mine.global_position
	await get_tree().create_timer(0.35).timeout
	_assert(
		is_equal_approx(_enemy_drone.hp, drone_hp_before),
		"land mine should not trigger on air units"
	)
	_assert(is_instance_valid(mine) and mine.is_inside_tree(), "air unit should not consume the mine")

	var tank_hp_before = _enemy_tank.hp
	_place_and_stop(_enemy_tank, mine.global_position)
	await _wait_until(
		func(): return _enemy_tank.hp < tank_hp_before,
		1.0,
		"land mine should damage enemy ground units"
	)
	await get_tree().process_frame
	_assert(not is_instance_valid(mine), "land mine should be consumed by detonation")
	get_tree().quit()


func _assert_drone_mine_layer_constants_and_menu():
	var empty_player = Node.new()
	add_child(empty_player)
	_assert(
		not Utils.Match.Unit.Tech.can_produce(empty_player, DroneMineLayerUnit.resource_path),
		"drone mine layer should require robotics bay"
	)
	empty_player.queue_free()
	var properties = Constants.Match.Units.DEFAULT_PROPERTIES[DroneMineLayerUnit.resource_path]
	_assert(properties["mine_damage"] > 0.0, "drone mine layer should define mine damage")
	_assert(properties["mine_limit"] > 0, "drone mine layer should define an active mine limit")
	_assert(
		Constants.Match.Units.PRODUCTION_COSTS[DroneMineLayerUnit.resource_path]["resource_b"] > 0,
		"drone mine layer should cost advanced resources"
	)

	var vehicle_menu = VehicleFactoryMenuScene.instantiate()
	add_child(vehicle_menu)
	await get_tree().process_frame
	var button = vehicle_menu.find_child("ProduceDroneMineLayerButton", true, false)
	_assert(button != null, "vehicle factory menu should expose drone mine layer")
	var icon = button.find_child("TextureRect").texture
	_assert(icon != null, "drone mine layer button should have an icon")
	_assert(
		_icon_uses_canonical_or_marker(icon, RA2_ICON_SET),
		"drone mine layer should use a packaged root icon or generated RA2 icon"
	)
	_assert(
		button.tooltip_text.contains(tr("MINE_LIMIT")),
		"drone mine layer tooltip should expose mine capacity"
	)
	vehicle_menu.queue_free()


func _wait_for_mine(timeout_s):
	var started_at_msec = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at_msec < timeout_s * 1000.0:
		var mines = get_tree().get_nodes_in_group("units").filter(func(unit): return unit is LandMine)
		if not mines.is_empty():
			return mines[0]
		await get_tree().process_frame
	return null


func _place_and_stop(unit, position):
	unit.hold_position = true
	unit.action = null
	unit.global_position = position
	var movement = unit.find_child("Movement")
	if movement != null:
		movement.stop()


func _wait_until(condition, timeout_s, message):
	var started_at_msec = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at_msec < timeout_s * 1000.0:
		if condition.call():
			return
		await get_tree().process_frame
	_assert(false, message)


func _assert(condition, message):
	if condition:
		return
	push_error(message)
	get_tree().quit(1)


func _icon_uses_canonical_or_marker(icon, marker):
	return (
		icon.resource_path.begins_with("res://assets/ui/icons/")
		and not icon.resource_path.contains("/generated/")
	) or marker in icon.resource_path
