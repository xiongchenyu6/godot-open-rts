extends "res://tests/manual/Match.gd"

const CollectingResourcesSequentially = preload(
	"res://source/match/units/actions/CollectingResourcesSequentially.gd"
)
const OrePurifierUnit = preload("res://source/match/units/OrePurifier.tscn")
const RefineryUnit = preload("res://source/match/units/Refinery.tscn")
const WorkerMenuScene = preload("res://source/match/hud/unit-menus/WorkerMenu.tscn")
const RA2_INSPIRED_ICON_SET = "imagegen-rts-ra2-inspired-20260616-01"

@onready var _human = $Players/Human
@onready var _worker = $Players/Human/Worker
@onready var _refinery = $Players/Human/Refinery
@onready var _power_reactor = $Players/Human/PowerReactor


func _ready():
	super()
	await _wait_frames(4)
	_worker.global_position = Vector3(12.5, 0.0, 14.8)
	_refinery.global_position = Vector3(10.5, 0.0, 14.5)
	_worker.find_child("Movement").stop()
	await get_tree().physics_frame

	_assert_ore_purifier_tech_and_constants()
	await _assert_worker_menu_exposes_ore_purifier()

	var ore_purifier = OrePurifierUnit.instantiate()
	_setup_and_spawn_unit(
		ore_purifier,
		Transform3D(Basis(), Vector3(15.0, 0.0, 14.5)),
		_human,
		false
	)
	await get_tree().process_frame
	_assert(not _human.is_low_power(), "test setup should keep the ore purifier powered")

	var initial_resource_a = _human.resource_a
	_worker.resource_a = _worker.resources_max
	_worker.action = CollectingResourcesSequentially.new(_refinery)
	var expected_powered_income = _worker.resources_max + _expected_bonus(_worker.resources_max)
	await _wait_until(
		func(): return _human.resource_a >= initial_resource_a + expected_powered_income,
		4.0,
		"powered ore purifier should increase resource A drop-off yield"
	)
	_assert(
		_human.resource_a == initial_resource_a + expected_powered_income,
		"powered ore purifier should add exactly the configured resource A bonus"
	)

	_power_reactor.queue_free()
	await get_tree().process_frame
	_assert(_human.is_low_power(), "removing power should put the purifier offline")
	var initial_resource_b = _human.resource_b
	_worker.resource_b = _worker.resources_max
	_worker.action = CollectingResourcesSequentially.new(_refinery)
	await _wait_until(
		func(): return _human.resource_b >= initial_resource_b + _worker.resources_max,
		4.0,
		"low-power ore purifier should not block normal resource B drop-off"
	)
	_assert(
		_human.resource_b == initial_resource_b + _worker.resources_max,
		"low-power ore purifier should not add the resource B bonus"
	)
	get_tree().quit()


func _assert_ore_purifier_tech_and_constants():
	var empty_player = Node.new()
	add_child(empty_player)
	_assert(
		not Utils.Match.Unit.Tech.can_construct(empty_player, OrePurifierUnit.resource_path),
		"ore purifier should require late economy tech"
	)
	empty_player.queue_free()
	_assert(
		Utils.Match.Unit.Tech.can_construct(_human, OrePurifierUnit.resource_path),
		"tech lab plus refinery should unlock ore purifier construction"
	)
	_assert(
		ResourceLoader.exists(Constants.Match.Units.STRUCTURE_BLUEPRINTS[
			OrePurifierUnit.resource_path
		]),
		"ore purifier should have a construction blueprint"
	)
	_assert(
		Constants.Match.Units.STRUCTURE_NAME_KEYS[OrePurifierUnit.resource_path] == "ORE_PURIFIER",
		"ore purifier should have a translated structure name key"
	)
	_assert(
		Constants.Match.Units.CONSTRUCTION_COSTS[OrePurifierUnit.resource_path]["resource_a"]
		> Constants.Match.Units.CONSTRUCTION_COSTS[RefineryUnit.resource_path]["resource_a"],
		"ore purifier should be a more expensive economy investment than a refinery"
	)
	_assert(
		Constants.Match.Units.POWER_DRAIN[OrePurifierUnit.resource_path] > 0,
		"ore purifier should drain base power"
	)
	_assert(
		Constants.Match.Units.DEFAULT_PROPERTIES[OrePurifierUnit.resource_path][
			"resource_bonus_ratio"
		]
		== Constants.Match.Resources.ORE_PURIFIER_BONUS_RATIO,
		"ore purifier properties should expose its configured resource bonus"
	)


func _assert_worker_menu_exposes_ore_purifier():
	var worker_menu = WorkerMenuScene.instantiate()
	worker_menu.unit = _worker
	add_child(worker_menu)
	await get_tree().process_frame
	worker_menu.refresh()
	var button = worker_menu.find_child("PlaceOrePurifierButton", true, false)
	_assert(button != null, "worker menu should expose ore purifier construction")
	_assert(not button.disabled, "ore purifier button should be enabled when tech is available")
	var icon = button.find_child("TextureRect").texture
	_assert(icon != null, "ore purifier button should have an icon")
	_assert(
		_icon_uses_canonical_or_marker(icon, RA2_INSPIRED_ICON_SET),
		"ore purifier should use a packaged root icon or generated RA2-inspired icon set"
	)
	_assert(
		button.tooltip_text.contains(tr("RESOURCE_BONUS"))
		and button.tooltip_text.contains(str(roundi(Constants.Match.Resources.ORE_PURIFIER_BONUS_RATIO * 100.0))),
		"ore purifier tooltip should show the resource bonus"
	)
	worker_menu.queue_free()


func _expected_bonus(amount):
	return int(ceil(float(amount) * Constants.Match.Resources.ORE_PURIFIER_BONUS_RATIO))


func _wait_until(condition, timeout_s, message):
	var started_at_msec = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at_msec < timeout_s * 1000.0:
		if condition.call():
			return
		await get_tree().process_frame
	_assert(false, message)


func _wait_frames(count):
	for _i in range(count):
		await get_tree().process_frame


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
