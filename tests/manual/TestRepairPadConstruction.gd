extends "res://tests/manual/Match.gd"

const PowerReactorUnit = preload("res://source/match/units/PowerReactor.tscn")
const RepairPadUnit = preload("res://source/match/units/RepairPad.tscn")
const WorkerMenuScene = preload("res://source/match/hud/unit-menus/WorkerMenu.tscn")
const RA2_ICON_SET = "imagegen-rts-ra2-inspired-20260616-01"

@onready var _human = $Players/Human
@onready var _human_worker = $Players/Human/Worker
@onready var _enemy_worker = $Players/Enemy/Worker


func _ready():
	super()
	await get_tree().process_frame
	await get_tree().physics_frame

	_assert_repair_pad_tech_and_constants()
	await _assert_worker_menu_exposes_repair_pad()

	var repair_pad = RepairPadUnit.instantiate()
	_setup_and_spawn_unit(
		repair_pad,
		Transform3D(Basis(), Vector3(12.0, 0.0, 10.0)),
		_human,
		false
	)
	await get_tree().process_frame

	_human_worker.hp = _human_worker.hp_max - 3.0
	_enemy_worker.hp = _enemy_worker.hp_max - 3.0
	var human_hp_before_power = _human_worker.hp
	var enemy_hp_before_power = _enemy_worker.hp

	_assert(_human.is_low_power(), "test setup should start in low power")
	_assert(
		repair_pad.is_powered_repair_offline(),
		"repair pad should report offline while base power is low"
	)
	await get_tree().create_timer(0.5).timeout
	_assert(
		_human_worker.hp == human_hp_before_power,
		"repair pad should not repair while base power is low"
	)

	var power_reactor = PowerReactorUnit.instantiate()
	_setup_and_spawn_unit(
		power_reactor,
		Transform3D(Basis(), Vector3(7.0, 0.0, 15.0)),
		_human,
		false
	)
	await get_tree().process_frame
	_assert(not _human.is_low_power(), "adding a power reactor should restore base power")
	await _wait_until(
		func(): return _human_worker.hp > human_hp_before_power,
		2.0,
		"powered repair pad should automatically repair nearby friendly ground units"
	)
	_assert(
		_enemy_worker.hp == enemy_hp_before_power,
		"repair pad should not repair enemy units inside its service radius"
	)

	_human_worker.global_position = Vector3(18.0, 0.0, 10.0)
	_human_worker.hp = _human_worker.hp_max - 3.0
	var human_hp_before_construction = _human_worker.hp
	var unfinished_pad = RepairPadUnit.instantiate()
	_setup_and_spawn_unit(
		unfinished_pad,
		Transform3D(Basis(), Vector3(18.0, 0.0, 12.0)),
		_human,
		true
	)
	await get_tree().create_timer(0.5).timeout
	_assert(
		_human_worker.hp == human_hp_before_construction,
		"repair pad should not repair before construction completes"
	)
	unfinished_pad.construct(1.0)
	await get_tree().process_frame
	await _wait_until(
		func(): return _human_worker.hp > human_hp_before_construction,
		2.0,
		"repair pad should start repairing after construction completes"
	)
	get_tree().quit()


func _assert_repair_pad_tech_and_constants():
	var empty_player = Node.new()
	add_child(empty_player)
	_assert(
		not Utils.Match.Unit.Tech.can_construct(empty_player, RepairPadUnit.resource_path),
		"repair pad should require robotics bay"
	)
	empty_player.queue_free()
	_assert(
		Utils.Match.Unit.Tech.can_construct(_human, RepairPadUnit.resource_path),
		"robotics bay should unlock repair pad construction"
	)
	_assert(
		ResourceLoader.exists(Constants.Match.Units.STRUCTURE_BLUEPRINTS[RepairPadUnit.resource_path]),
		"repair pad should have a construction blueprint"
	)
	_assert(
		Constants.Match.Units.STRUCTURE_NAME_KEYS[RepairPadUnit.resource_path] == "REPAIR_PAD",
		"repair pad should have a translated structure name key"
	)
	_assert(
		Constants.Match.Units.CONSTRUCTION_COSTS[RepairPadUnit.resource_path]["resource_a"] > 0,
		"repair pad should cost resource A"
	)
	_assert(
		Constants.Match.Units.CONSTRUCTION_COSTS[RepairPadUnit.resource_path]["resource_b"] > 0,
		"repair pad should cost resource B"
	)
	_assert(
		Constants.Match.Units.POWER_DRAIN[RepairPadUnit.resource_path] > 0,
		"repair pad should drain base power"
	)
	_assert(
		Constants.Match.Units.DEFAULT_PROPERTIES[RepairPadUnit.resource_path]["repair_rate"]
		> Constants.Match.Repair.HITPOINTS_PER_SECOND,
		"repair pad should repair faster than baseline field repairs"
	)


func _assert_worker_menu_exposes_repair_pad():
	var worker_menu = WorkerMenuScene.instantiate()
	add_child(worker_menu)
	await get_tree().process_frame
	var button = worker_menu.find_child("PlaceRepairPadButton", true, false)
	_assert(button != null, "worker menu should expose repair pad construction")
	var icon = button.find_child("TextureRect").texture
	_assert(icon != null, "repair pad button should have an icon")
	_assert(
		_icon_uses_canonical_or_marker(icon, RA2_ICON_SET),
		"repair pad should use a packaged root icon or generated RA2 icon set"
	)
	_assert(
		button.tooltip_text.contains(tr("REPAIR_RATE")),
		"repair pad tooltip should show the repair rate"
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
