extends "res://tests/manual/Match.gd"

const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const CommandCenterMenuScene = preload("res://source/match/hud/unit-menus/CommandCenterMenu.tscn")
const GenericMenuScene = preload("res://source/match/hud/unit-menus/GenericMenu.tscn")
const PowerReactorUnit = preload("res://source/match/units/PowerReactor.tscn")
const SoundEffectsControllerScript = preload("res://source/match/players/human/SoundEffectsController.gd")
const TankUnit = preload("res://source/match/units/Tank.tscn")

var _sold_units_count = 0

@onready var _player = $Players/Human
@onready var _command_center = $Players/Human/CommandCenter
@onready var _vehicle_factory = $Players/Human/VehicleFactory
@onready var _sound_effects = $Players/Human/SoundEffectsController


func _ready():
	super()
	await get_tree().process_frame
	MatchSignals.unit_sold.connect(func(_unit): _sold_units_count += 1)
	_player.resource_a = 20
	_player.resource_b = 20

	await _test_construction_started_and_canceled_sfx()
	await _test_manual_repair_spends_resources_and_restores_hp()
	await _test_manual_repair_rejects_unaffordable_work()
	await _test_structure_repair_buttons()
	await _test_selling_refunds_queued_units()
	_test_damaged_structure_refund_is_scaled()
	await get_tree().process_frame

	assert(_sold_units_count == 2, "selling two constructed structures should emit two notifications")
	assert(not is_instance_valid(_command_center), "sold command center should leave the tree")
	assert(not is_instance_valid(_vehicle_factory), "sold vehicle factory should leave the tree")
	get_tree().quit()


func _test_construction_started_and_canceled_sfx():
	var starting_resource_a = _player.resource_a
	var starting_resource_b = _player.resource_b
	var power_reactor = PowerReactorUnit.instantiate()

	_setup_and_spawn_unit(
		power_reactor,
		Transform3D(Basis(), Vector3(10.0, 0.0, 10.0)),
		_player,
		true
	)
	await get_tree().process_frame
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_CONSTRUCTION_STARTED,
		"starting construction should trigger construction-start SFX"
	)

	power_reactor.cancel_construction()
	await get_tree().process_frame
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_CONSTRUCTION_CANCELED,
		"canceling construction should trigger construction-cancel SFX"
	)
	_player.resource_a = starting_resource_a
	_player.resource_b = starting_resource_b


func _test_manual_repair_spends_resources_and_restores_hp():
	_command_center.hp = _command_center.hp_max - 4.0
	var repair_cost = _command_center.get_repair_cost()
	var starting_resource_a = _player.resource_a
	var starting_resource_b = _player.resource_b

	assert(_command_center.repair(), "damaged constructed structures should start manual repair")
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_REPAIR_STARTED,
		"manual repair should trigger repair-start SFX"
	)
	assert(_command_center.is_repairing(), "manual repair should stay active after starting")
	assert(
		_player.resource_a == starting_resource_a - repair_cost["resource_a"],
		"manual repair should spend resource A upfront"
	)
	assert(
		_player.resource_b == starting_resource_b - repair_cost["resource_b"],
		"manual repair should spend resource B upfront"
	)

	await _wait_until(
		func(): return not _command_center.is_repairing(), 4.0, "manual repair should complete"
	)
	assert(_command_center.hp == _command_center.hp_max, "manual repair should restore full HP")


func _test_manual_repair_rejects_unaffordable_work():
	_vehicle_factory.hp = _vehicle_factory.hp_max - 5.0
	var damaged_hp = _vehicle_factory.hp
	var previous_resource_a = _player.resource_a
	var previous_resource_b = _player.resource_b
	var previous_deficit_spending = FeatureFlags.allow_resources_deficit_spending
	var not_enough_resources_count = [0]
	var on_not_enough_resources = func(_player_arg): not_enough_resources_count[0] += 1

	FeatureFlags.allow_resources_deficit_spending = false
	_player.resource_a = 0
	_player.resource_b = 0
	MatchSignals.not_enough_resources_for_construction.connect(on_not_enough_resources)
	assert(
		not _vehicle_factory.repair(),
		"manual repair should reject damaged structures when resources are insufficient"
	)
	MatchSignals.not_enough_resources_for_construction.disconnect(on_not_enough_resources)

	assert(not _vehicle_factory.is_repairing(), "unaffordable repair should not start a timer")
	assert(_vehicle_factory.hp == damaged_hp, "unaffordable repair should leave HP unchanged")
	assert(
		not_enough_resources_count[0] == 1,
		"unaffordable repair should emit one not-enough-resources notification"
	)

	_player.resource_a = previous_resource_a
	_player.resource_b = previous_resource_b
	_vehicle_factory.hp = _vehicle_factory.hp_max
	FeatureFlags.allow_resources_deficit_spending = previous_deficit_spending


func _test_structure_repair_buttons():
	_command_center.hp = _command_center.hp_max - 2.0
	var command_center_menu = CommandCenterMenuScene.instantiate()
	add_child(command_center_menu)
	await get_tree().process_frame
	command_center_menu.unit = _command_center
	command_center_menu.refresh()

	var command_repair_button = command_center_menu.find_child("RepairStructureButton", true, false)
	assert(command_repair_button != null, "production structure menus should include repair")
	assert(not command_repair_button.disabled, "damaged production structures should enable repair")
	assert(
		command_repair_button.get_meta(CommandButtonHotkeys.META_DISPLAY) == "T",
		"appended production repair command should use the fifth compact-grid hotkey"
	)
	assert(
		command_repair_button.tooltip_text.contains(tr("REPAIR_COST")),
		"repair tooltip should show the repair cost"
	)
	command_center_menu.queue_free()
	_command_center.hp = _command_center.hp_max

	_vehicle_factory.hp = _vehicle_factory.hp_max - 2.0
	var generic_menu = GenericMenuScene.instantiate()
	add_child(generic_menu)
	await get_tree().process_frame
	generic_menu.units = [_vehicle_factory]
	generic_menu.refresh()

	var generic_repair_button = generic_menu.find_child("RepairStructureButton", true, false)
	assert(generic_repair_button != null, "generic menu should include repair")
	assert(not generic_repair_button.disabled, "damaged selected structures should enable generic repair")
	assert(
		generic_repair_button.get_meta(CommandButtonHotkeys.META_DISPLAY) == "Y",
		"generic repair command should occupy the Y grid slot"
	)
	assert(
		generic_menu.find_child("CancelActionButton", true, false).get_meta(
			CommandButtonHotkeys.META_DISPLAY
		) == "S",
		"generic repair should not move the stop-command S hotkey"
	)
	generic_menu.queue_free()
	_vehicle_factory.hp = _vehicle_factory.hp_max


func _test_selling_refunds_queued_units():
	var starting_resource_a = _player.resource_a
	var starting_resource_b = _player.resource_b
	var tank_cost = Constants.Match.Units.PRODUCTION_COSTS[TankUnit.resource_path]
	var sell_refund = _vehicle_factory.get_sell_refund()

	_vehicle_factory.production_queue.produce(TankUnit)
	assert(_vehicle_factory.production_queue.size() == 1, "vehicle factory should queue the tank")
	assert(
		_player.resource_a == starting_resource_a - tank_cost["resource_a"],
		"queued tank should spend resource A"
	)
	assert(
		_player.resource_b == starting_resource_b - tank_cost["resource_b"],
		"queued tank should spend resource B"
	)

	_vehicle_factory.sell()
	await get_tree().process_frame
	_assert_sound_effect(
		SoundEffectsControllerScript.SOUND_STRUCTURE_SOLD,
		"selling a structure should trigger structure-sold SFX"
	)
	assert(
		_player.resource_a == starting_resource_a + sell_refund["resource_a"],
		"selling should refund queued unit A cost plus structure A refund"
	)
	assert(
		_player.resource_b == starting_resource_b + sell_refund["resource_b"],
		"selling should refund queued unit B cost plus structure B refund"
	)


func _test_damaged_structure_refund_is_scaled():
	var full_refund = _command_center.get_sell_refund()
	_command_center.hp = int(floor(float(_command_center.hp_max) * 0.5))
	var damaged_refund = _command_center.get_sell_refund()
	assert(
		damaged_refund["resource_a"] < full_refund["resource_a"],
		"damaged structure should refund less resource A than full-health structure"
	)
	assert(
		damaged_refund["resource_b"] < full_refund["resource_b"],
		"damaged structure should refund less resource B than full-health structure"
	)

	var starting_resource_a = _player.resource_a
	var starting_resource_b = _player.resource_b
	_command_center.sell()
	assert(
		_player.resource_a == starting_resource_a + damaged_refund["resource_a"],
		"selling damaged structure should pay scaled resource A refund"
	)
	assert(
		_player.resource_b == starting_resource_b + damaged_refund["resource_b"],
		"selling damaged structure should pay scaled resource B refund"
	)


func _wait_until(condition, timeout_seconds, message):
	var elapsed_seconds = 0.0
	while elapsed_seconds < timeout_seconds:
		if condition.call():
			return
		await get_tree().create_timer(0.1).timeout
		elapsed_seconds += 0.1
	assert(condition.call(), message)


func _assert_sound_effect(expected_sound_tag, message):
	if _sound_effects._last_sound_tag == expected_sound_tag and _sound_effects._last_sound_stream != null:
		return
	push_error(message)
	get_tree().quit(1)
