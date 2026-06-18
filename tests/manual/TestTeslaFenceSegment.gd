extends "res://tests/manual/Match.gd"

const PowerReactorUnit = preload("res://source/match/units/PowerReactor.tscn")
const TeslaFenceSegmentUnit = preload("res://source/match/units/TeslaFenceSegment.tscn")
const WorkerMenuScene = preload("res://source/match/hud/unit-menus/WorkerMenu.tscn")
const DEFENSE_SUPPORT_ICON_SET = "imagegen-rts-ra2-pack-20260615-01"

@onready var _human = $Players/Human
@onready var _tesla_fence = $Players/Human/TeslaFenceSegment
@onready var _enemy_worker = $Players/Enemy/Worker
@onready var _enemy_drone = $Players/Enemy/Drone


func _ready():
	super()
	await get_tree().process_frame
	await get_tree().physics_frame

	await _assert_tesla_fence_constants_and_menu()

	_assert(_human.is_low_power(), "test setup should start the human player in low power")
	_assert(
		_tesla_fence.is_powered_combat_offline(),
		"tesla fence should report offline while the base is in low power"
	)
	var worker_hp_before_low_power = _enemy_worker.hp
	await get_tree().create_timer(0.65).timeout
	_assert(
		is_equal_approx(_enemy_worker.hp, worker_hp_before_low_power),
		"tesla fence should not shock enemies while low power"
	)

	var drone_hp_before_power = _enemy_drone.hp
	var power_reactor = PowerReactorUnit.instantiate()
	_setup_and_spawn_unit(
		power_reactor,
		Transform3D(Basis(), Vector3(7.0, 0.0, 11.8)),
		_human,
		false
	)
	await get_tree().process_frame
	_assert(not _human.is_low_power(), "adding a power reactor should restore base power")

	await _wait_until(
		func(): return _enemy_worker.hp < worker_hp_before_low_power,
		2.0,
		"powered tesla fence should shock nearby enemy ground units"
	)
	await get_tree().create_timer(0.4).timeout
	_assert(
		is_equal_approx(_enemy_drone.hp, drone_hp_before_power),
		"tesla fence should not damage nearby air units"
	)
	get_tree().quit()


func _assert_tesla_fence_constants_and_menu():
	var empty_player = Node.new()
	add_child(empty_player)
	_assert(
		not Utils.Match.Unit.Tech.can_construct(empty_player, TeslaFenceSegmentUnit.resource_path),
		"tesla fence should require robotics bay"
	)
	empty_player.queue_free()
	_assert(
		Utils.Match.Unit.Tech.can_construct(_human, TeslaFenceSegmentUnit.resource_path),
		"robotics bay should unlock tesla fence construction"
	)
	_assert(
		ResourceLoader.exists(
			Constants.Match.Units.STRUCTURE_BLUEPRINTS[TeslaFenceSegmentUnit.resource_path]
		),
		"tesla fence should have a construction blueprint"
	)
	_assert(
		Constants.Match.Units.STRUCTURE_NAME_KEYS[TeslaFenceSegmentUnit.resource_path]
		== "TESLA_FENCE_SEGMENT",
		"tesla fence should have a translated structure name key"
	)
	_assert(
		Constants.Match.Units.POWER_DRAIN[TeslaFenceSegmentUnit.resource_path] > 0,
		"tesla fence should drain base power"
	)
	_assert(
		Constants.Match.Units.DEFAULT_PROPERTIES[TeslaFenceSegmentUnit.resource_path][
			"attack_range"
		]
		< Constants.Match.Units.DEFAULT_PROPERTIES[
			"res://source/match/units/AntiGroundTurret.tscn"
		]["attack_range"],
		"tesla fence should be a short-range perimeter defense"
	)

	var worker_menu = WorkerMenuScene.instantiate()
	add_child(worker_menu)
	await get_tree().process_frame
	var button = worker_menu.find_child("PlaceTeslaFenceSegmentButton", true, false)
	_assert(button != null, "worker menu should expose tesla fence construction")
	var icon = button.find_child("TextureRect").texture
	_assert(icon != null, "tesla fence button should have an icon")
	_assert(
		_icon_uses_canonical_or_marker(icon, DEFENSE_SUPPORT_ICON_SET),
		"tesla fence should use a packaged root icon or generated defense-support icon set"
	)
	_assert(
		button.tooltip_text.contains("-")
		and button.tooltip_text.contains(str(Constants.Match.Units.POWER_DRAIN[
			TeslaFenceSegmentUnit.resource_path
		])),
		"tesla fence tooltip should show its power drain"
	)
	worker_menu.queue_free()


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
