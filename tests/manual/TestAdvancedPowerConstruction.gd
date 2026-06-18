extends "res://tests/manual/Match.gd"

const AdvancedReactorPlantUnit = preload("res://source/match/units/AdvancedReactorPlant.tscn")
const PowerReactorUnit = preload("res://source/match/units/PowerReactor.tscn")
const WorkerMenuScene = preload("res://source/match/hud/unit-menus/WorkerMenu.tscn")
const NEW_ASSET_ICON_SET = "imagegen-rts-new-assets-20260616-01"

@onready var _human = $Players/Human


func _ready():
	super()
	await get_tree().process_frame
	await get_tree().physics_frame

	_assert_advanced_reactor_tech_and_constants()
	await _assert_worker_menu_exposes_advanced_reactor()

	_assert(_human.is_low_power(), "test setup should start in low power")
	var supply_before = _human.get_power_supply()
	var under_construction = AdvancedReactorPlantUnit.instantiate()
	_setup_and_spawn_unit(
		under_construction,
		Transform3D(Basis(), Vector3(10.0, 0.0, 15.0)),
		_human,
		true
	)
	await get_tree().process_frame
	_assert(
		_human.get_power_supply() == supply_before,
		"advanced reactor should not supply power before construction completes"
	)
	_assert(
		_human.get_power_supply(true) > supply_before,
		"AI planning can count under-construction advanced reactor supply"
	)
	under_construction.construct(1.0)
	await get_tree().process_frame
	_assert(not _human.is_low_power(), "advanced reactor should restore a high-drain base")
	_assert(
		_human.get_power_supply() - supply_before
		== Constants.Match.Units.POWER_SUPPLY[AdvancedReactorPlantUnit.resource_path],
		"constructed advanced reactor should add its configured power supply"
	)
	get_tree().quit()


func _assert_advanced_reactor_tech_and_constants():
	var empty_player = Node.new()
	add_child(empty_player)
	_assert(
		not Utils.Match.Unit.Tech.can_construct(empty_player, AdvancedReactorPlantUnit.resource_path),
		"advanced reactor should require tech lab"
	)
	empty_player.queue_free()
	_assert(
		Utils.Match.Unit.Tech.can_construct(_human, AdvancedReactorPlantUnit.resource_path),
		"tech lab should unlock advanced reactor construction"
	)
	_assert(
		ResourceLoader.exists(
			Constants.Match.Units.STRUCTURE_BLUEPRINTS[AdvancedReactorPlantUnit.resource_path]
		),
		"advanced reactor should have a construction blueprint"
	)
	_assert(
		Constants.Match.Units.STRUCTURE_NAME_KEYS[AdvancedReactorPlantUnit.resource_path]
		== "ADVANCED_REACTOR_PLANT",
		"advanced reactor should have a translated structure name key"
	)
	_assert(
		Constants.Match.Units.CONSTRUCTION_COSTS[AdvancedReactorPlantUnit.resource_path]
		["resource_a"]
		> Constants.Match.Units.CONSTRUCTION_COSTS[PowerReactorUnit.resource_path]["resource_a"],
		"advanced reactor should cost more resource A than the basic reactor"
	)
	_assert(
		Constants.Match.Units.CONSTRUCTION_COSTS[AdvancedReactorPlantUnit.resource_path]
		["resource_b"]
		> Constants.Match.Units.CONSTRUCTION_COSTS[PowerReactorUnit.resource_path]["resource_b"],
		"advanced reactor should cost more resource B than the basic reactor"
	)
	_assert(
		Constants.Match.Units.POWER_SUPPLY[AdvancedReactorPlantUnit.resource_path]
		> Constants.Match.Units.POWER_SUPPLY[PowerReactorUnit.resource_path],
		"advanced reactor should supply more power than the basic reactor"
	)
	_assert(
		Constants.Match.Units.DEFAULT_PROPERTIES[AdvancedReactorPlantUnit.resource_path]["hp_max"]
		> Constants.Match.Units.DEFAULT_PROPERTIES[PowerReactorUnit.resource_path]["hp_max"],
		"advanced reactor should be tougher than the basic reactor"
	)


func _assert_worker_menu_exposes_advanced_reactor():
	var worker_menu = WorkerMenuScene.instantiate()
	add_child(worker_menu)
	await get_tree().process_frame
	var button = worker_menu.find_child("PlaceAdvancedReactorPlantButton", true, false)
	_assert(button != null, "worker menu should expose advanced reactor construction")
	var icon = button.find_child("TextureRect").texture
	_assert(icon != null, "advanced reactor button should have an icon")
	_assert(
		_icon_uses_canonical_or_marker(icon, NEW_ASSET_ICON_SET),
		"advanced reactor should use a packaged root icon or generated new asset icon set"
	)
	_assert(
		button.tooltip_text.contains("+")
		and button.tooltip_text.contains(str(Constants.Match.Units.POWER_SUPPLY[
			AdvancedReactorPlantUnit.resource_path
		])),
		"advanced reactor tooltip should show its power supply"
	)
	worker_menu.queue_free()


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
