extends Node

const CommandButtonHotkeys = preload("res://source/match/hud/unit-menus/CommandButtonHotkeys.gd")
const CommandButtonStatus = preload("res://source/match/hud/unit-menus/CommandButtonStatus.gd")
const ProductionMenuActions = preload("res://source/match/hud/unit-menus/ProductionMenuActions.gd")
const CommandCenterMenuScene = preload("res://source/match/hud/unit-menus/CommandCenterMenu.tscn")
const GenericMenuScene = preload("res://source/match/hud/unit-menus/GenericMenu.tscn")
const VehicleFactoryMenuScene = preload("res://source/match/hud/unit-menus/VehicleFactoryMenu.tscn")
const WorkerMenuScene = preload("res://source/match/hud/unit-menus/WorkerMenu.tscn")
const TankUnit = preload("res://source/match/units/Tank.tscn")
const PowerReactorUnit = preload("res://source/match/units/PowerReactor.tscn")
const RadarUplinkUnit = preload("res://source/match/units/RadarUplink.tscn")


class FakeQueueElement:
	var unit_prototype = null

	func _init(unit_scene):
		unit_prototype = unit_scene


class FakePlayer:
	var resource_a = 0
	var resource_b = 0

	func _init(resource_a_value, resource_b_value):
		resource_a = resource_a_value
		resource_b = resource_b_value

	func has_resources(costs):
		return (
			resource_a >= int(costs.get("resource_a", 0))
			and resource_b >= int(costs.get("resource_b", 0))
		)

	func get_children():
		return []


class FakeProductionQueue:
	var produced_paths = []
	var elements = []
	var canceled_elements = []

	func _init(unit_scenes = []):
		for unit_scene in unit_scenes:
			elements.append(FakeQueueElement.new(unit_scene))

	func produce(unit_scene):
		if elements.size() >= Constants.Match.Units.PRODUCTION_QUEUE_LIMIT:
			return null
		produced_paths.append(unit_scene.resource_path)
		var element = FakeQueueElement.new(unit_scene)
		elements.append(element)
		return element

	func cancel(element):
		canceled_elements.append(element)
		elements.erase(element)

	func size():
		return elements.size()

	func get_elements():
		return elements


class FakeProductionUnit:
	var production_queue = null
	var player = null

	func _init(queue = null, fake_player = null):
		production_queue = queue if queue != null else FakeProductionQueue.new()
		player = fake_player if fake_player != null else FakePlayer.new(99, 99)


class FakeProductionStructure:
	extends Node

	var production_queue = null
	var player = null

	func _init(queue = null, fake_player = null):
		production_queue = queue if queue != null else FakeProductionQueue.new()
		player = fake_player if fake_player != null else FakePlayer.new(99, 99)
		var rally_point = Node.new()
		rally_point.name = "RallyPoint"
		add_child(rally_point)


func _ready():
	var original_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	await _test_vehicle_factory_hotkey_produces_first_unit()
	await _test_shift_batch_production_fills_remaining_queue_slots()
	await _test_multi_producer_actions_queue_each_available_structure()
	await _test_command_buttons_show_cost_and_lock_state()
	await _test_production_buttons_show_queue_state()
	await _test_multi_producer_buttons_show_aggregate_queue_state()
	await _test_chinese_command_status_badges_are_localized()
	await _test_chinese_command_surface_names_are_localized()
	await _test_right_click_production_button_cancels_latest_matching_queue_item()
	await _test_worker_build_buttons_show_costs()
	await _test_disabled_hotkey_does_not_fire()
	await _test_generic_attack_move_hotkey_requests_targeting()
	await _test_generic_patrol_hotkey_requests_targeting()
	await _test_generic_scatter_button_shows_hotkey()
	await _test_command_center_rally_point_hotkey_requests_targeting()
	await _test_generic_menu_uses_visual_grid_hotkeys()
	await _test_expanded_grid_hotkeys_cover_all_visible_slots()
	TranslationServer.set_locale(original_locale)
	get_tree().quit()


func _test_vehicle_factory_hotkey_produces_first_unit():
	var menu = VehicleFactoryMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var fake_unit = FakeProductionUnit.new()
	menu.unit = fake_unit
	var tank_button = menu.find_child("ProduceTankButton", true, false)
	assert(tank_button.get_meta(CommandButtonHotkeys.META_DISPLAY) == "Q", "tank hotkey should be Q")
	assert(
		tank_button.find_child(CommandButtonHotkeys.HOTKEY_LABEL_NAME, true, false).text == "Q",
		"tank button should show the Q hotkey corner label"
	)
	assert(
		tank_button.tooltip_text.contains(tr("COMMAND_HOTKEY")),
		"tank tooltip should mention the hotkey"
	)
	assert(
		tank_button.tooltip_text.contains(tr("PRODUCTION_BATCH_QUEUE")),
		"production tooltips should mention Shift batch queueing"
	)

	assert(CommandButtonHotkeys.try_activate(menu, _key_event(KEY_Q)), "Q should activate tank production")
	assert(
		fake_unit.production_queue.produced_paths == [TankUnit.resource_path],
		"Q should queue the first vehicle factory unit"
	)
	menu.queue_free()


func _test_shift_batch_production_fills_remaining_queue_slots():
	var queue = FakeProductionQueue.new([TankUnit, TankUnit])
	var produced_elements = ProductionMenuActions.produce(queue, TankUnit, true)

	assert(
		produced_elements.size() == 3,
		"Shift batch production should fill the remaining queue capacity"
	)
	assert(
		queue.size() == Constants.Match.Units.PRODUCTION_QUEUE_LIMIT,
		"Shift batch production should stop at the production queue limit"
	)
	assert(
		queue.produced_paths == [TankUnit.resource_path, TankUnit.resource_path, TankUnit.resource_path],
		"Shift batch production should queue the selected unit type repeatedly"
	)

	produced_elements = ProductionMenuActions.produce(queue, TankUnit, true)
	assert(
		produced_elements.is_empty(),
		"Shift batch production should do nothing when the queue is already full"
	)


func _test_multi_producer_actions_queue_each_available_structure():
	var queue_a = FakeProductionQueue.new()
	var queue_b = FakeProductionQueue.new([TankUnit])
	var producer_a = FakeProductionUnit.new(queue_a)
	var producer_b = FakeProductionUnit.new(queue_b)

	var produced_elements = ProductionMenuActions.produce_for_units(
		[producer_a, producer_b], TankUnit
	)
	assert(
		produced_elements.size() == 2,
		"multi-producer actions should queue one unit per selected producer"
	)
	assert(queue_a.produced_paths == [TankUnit.resource_path], "first producer should receive the unit")
	assert(queue_b.produced_paths == [TankUnit.resource_path], "second producer should receive the unit")

	var full_queue = FakeProductionQueue.new([TankUnit, TankUnit, TankUnit, TankUnit, TankUnit])
	var full_producer = FakeProductionUnit.new(full_queue)
	assert(
		ProductionMenuActions.has_available_queue([full_producer, producer_a]),
		"multi-producer buttons should stay enabled while any selected producer has capacity"
	)
	produced_elements = ProductionMenuActions.produce_for_units([full_producer, producer_a], TankUnit)
	assert(
		produced_elements.size() == 1,
		"multi-producer actions should skip full queues and use available queues"
	)
	assert(full_queue.produced_paths.is_empty(), "full producer should not receive more queued units")
	assert(queue_a.produced_paths.size() == 2, "available producer should receive the extra queued unit")


func _test_command_buttons_show_cost_and_lock_state():
	var menu = VehicleFactoryMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var tank_button = menu.find_child("ProduceTankButton", true, false)
	var cost_label = tank_button.find_child(CommandButtonStatus.COST_LABEL_NAME, true, false)
	assert(cost_label != null, "production buttons should show a compact cost label")
	assert(
		cost_label.text == "A 3  B 1",
		"tank button should show resource A/B cost on the button"
	)
	var name_label = tank_button.find_child(CommandButtonStatus.NAME_LABEL_NAME, true, false)
	assert(name_label != null, "production buttons should show a compact surface name")
	assert(name_label.visible, "production button surface names should be visible")
	assert(name_label.text == "Tank", "tank button should show its unit name on the button")
	assert(
		tank_button.get_meta(CommandButtonStatus.META_NAME_TEXT) == "Tank",
		"production surface name should be mirrored in button metadata"
	)

	CommandButtonStatus.apply_production(
		tank_button, TankUnit, [RadarUplinkUnit.resource_path]
	)
	var lock_label = tank_button.find_child(CommandButtonStatus.LOCK_LABEL_NAME, true, false)
	assert(lock_label != null, "tech-locked buttons should have a lock badge node")
	assert(lock_label.visible, "tech-locked buttons should show the lock badge")
	assert(
		lock_label.text == tr("COMMAND_TECH_LOCK_SHORT"),
		"tech-locked buttons should use the translated lock badge"
	)
	assert(tank_button.get_meta(CommandButtonStatus.META_TECH_LOCKED), "locked meta should be true")

	CommandButtonStatus.apply_production(tank_button, TankUnit, [])
	assert(not lock_label.visible, "available buttons should hide the lock badge")
	assert(not tank_button.get_meta(CommandButtonStatus.META_TECH_LOCKED), "locked meta should clear")

	CommandButtonStatus.apply_production(tank_button, TankUnit, [], FakePlayer.new(0, 0))
	assert(
		not tank_button.get_meta(CommandButtonStatus.META_AFFORDABLE),
		"buttons should mark production as unaffordable when resources are too low"
	)

	CommandButtonStatus.apply_production(tank_button, TankUnit, [], FakePlayer.new(3, 1))
	assert(
		tank_button.get_meta(CommandButtonStatus.META_AFFORDABLE),
		"buttons should mark production as affordable when resources cover the cost"
	)
	menu.queue_free()


func _test_production_buttons_show_queue_state():
	var menu = VehicleFactoryMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var tank_button = menu.find_child("ProduceTankButton", true, false)
	var two_tank_queue = FakeProductionQueue.new([TankUnit, TankUnit])
	CommandButtonStatus.apply_production(
		tank_button, TankUnit, [], FakePlayer.new(99, 99), two_tank_queue
	)
	var queue_label = tank_button.find_child(CommandButtonStatus.QUEUE_LABEL_NAME, true, false)
	assert(queue_label != null, "production buttons should have a queue count label")
	assert(queue_label.visible, "queued unit count should be visible")
	assert(queue_label.text == "x2", "queued unit count should show as xN")
	assert(
		tank_button.get_meta(CommandButtonStatus.META_QUEUE_COUNT) == 2,
		"queued count should be mirrored in button metadata"
	)
	assert(
		not tank_button.get_meta(CommandButtonStatus.META_QUEUE_FULL),
		"queue full metadata should stay false while there is queue capacity"
	)

	var full_queue = FakeProductionQueue.new([TankUnit, TankUnit, TankUnit, TankUnit, TankUnit])
	CommandButtonStatus.apply_production(
		tank_button, TankUnit, [], FakePlayer.new(99, 99), full_queue
	)
	assert(queue_label.visible, "queue full status should be visible")
	assert(
		queue_label.text == tr("PRODUCTION_QUEUE_FULL_SHORT"),
		"queue full status should replace the count label"
	)
	assert(
		tank_button.get_meta(CommandButtonStatus.META_QUEUE_FULL),
		"queue full metadata should be true at the queue limit"
	)

	menu.unit = FakeProductionUnit.new(full_queue, FakePlayer.new(99, 99))
	menu.refresh()
	assert(tank_button.disabled, "production buttons should disable while the queue is full")
	menu.queue_free()


func _test_multi_producer_buttons_show_aggregate_queue_state():
	var menu = VehicleFactoryMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var tank_button = menu.find_child("ProduceTankButton", true, false)
	var queue_a = FakeProductionQueue.new([TankUnit])
	var queue_b = FakeProductionQueue.new([TankUnit, TankUnit])
	CommandButtonStatus.apply_production(
		tank_button, TankUnit, [], FakePlayer.new(99, 99), null, [queue_a, queue_b]
	)
	var queue_label = tank_button.find_child(CommandButtonStatus.QUEUE_LABEL_NAME, true, false)
	assert(queue_label.visible, "multi-producer queued unit count should be visible")
	assert(queue_label.text == "x3", "multi-producer queued count should aggregate all selected queues")
	assert(
		tank_button.get_meta(CommandButtonStatus.META_QUEUE_COUNT) == 3,
		"multi-producer queued count should be mirrored in metadata"
	)
	assert(
		not tank_button.get_meta(CommandButtonStatus.META_QUEUE_FULL),
		"multi-producer full metadata should stay false while any queue has capacity"
	)

	var right_click = InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	tank_button.emit_signal("gui_input", right_click)
	assert(queue_a.size() == 1, "multi-producer right-click should prefer the latest selected queue")
	assert(queue_b.size() == 1, "multi-producer right-click should cancel one matching queued unit")
	assert(queue_label.text == "x2", "multi-producer right-click should refresh aggregate count")

	var full_a = FakeProductionQueue.new([TankUnit, TankUnit, TankUnit, TankUnit, TankUnit])
	var full_b = FakeProductionQueue.new([TankUnit, TankUnit, TankUnit, TankUnit, TankUnit])
	CommandButtonStatus.apply_production(
		tank_button, TankUnit, [], FakePlayer.new(99, 99), null, [full_a, full_b]
	)
	assert(queue_label.visible, "multi-producer full state should be visible")
	assert(
		queue_label.text == tr("PRODUCTION_QUEUE_FULL_SHORT"),
		"multi-producer full state should require all queues to be full"
	)
	assert(
		tank_button.get_meta(CommandButtonStatus.META_QUEUE_FULL),
		"multi-producer full metadata should be true when every selected queue is full"
	)

	menu.queue_free()


func _test_chinese_command_status_badges_are_localized():
	var original_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("zh_CN")
	var menu = VehicleFactoryMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var tank_button = menu.find_child("ProduceTankButton", true, false)
	CommandButtonStatus.apply_production(
		tank_button, TankUnit, [RadarUplinkUnit.resource_path]
	)
	var lock_label = tank_button.find_child(CommandButtonStatus.LOCK_LABEL_NAME, true, false)
	assert(lock_label.text == "科技", "Chinese tech lock badge should not stay as TECH")

	var full_queue = FakeProductionQueue.new([TankUnit, TankUnit, TankUnit, TankUnit, TankUnit])
	CommandButtonStatus.apply_production(
		tank_button, TankUnit, [], FakePlayer.new(99, 99), full_queue
	)
	var queue_label = tank_button.find_child(CommandButtonStatus.QUEUE_LABEL_NAME, true, false)
	assert(queue_label.text == "满", "Chinese queue-full badge should not stay as FULL")

	menu.queue_free()
	TranslationServer.set_locale(original_locale)


func _test_chinese_command_surface_names_are_localized():
	var original_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("zh_CN")

	var vehicle_menu = VehicleFactoryMenuScene.instantiate()
	add_child(vehicle_menu)
	await get_tree().process_frame
	var tank_button = vehicle_menu.find_child("ProduceTankButton", true, false)
	CommandButtonStatus.apply_production(
		tank_button, TankUnit, [], FakePlayer.new(99, 99), null, [], "TANK"
	)
	_assert_surface_name(tank_button, tr("TANK"))
	assert(
		tank_button.get_meta(CommandButtonStatus.META_NAME_TEXT) != "Tank",
		"Chinese unit surface names should not use English short labels"
	)

	var worker_menu = WorkerMenuScene.instantiate()
	add_child(worker_menu)
	await get_tree().process_frame
	var power_button = worker_menu.find_child("PlacePowerReactorButton", true, false)
	CommandButtonStatus.apply_construction(
		power_button, PowerReactorUnit, [], FakePlayer.new(99, 99), "POWER_REACTOR"
	)
	_assert_surface_name(power_button, tr("POWER_REACTOR"))
	assert(
		power_button.get_meta(CommandButtonStatus.META_NAME_TEXT) != "Power",
		"Chinese construction surface names should not use English short labels"
	)

	var generic_menu = GenericMenuScene.instantiate()
	add_child(generic_menu)
	await get_tree().process_frame
	generic_menu.refresh()
	var attack_move_button = generic_menu.find_child("AttackMoveButton", true, false)
	CommandButtonStatus.apply_action(attack_move_button, "ATTACK_MOVE")
	_assert_surface_name(attack_move_button, tr("ATTACK_MOVE"))
	assert(
		attack_move_button.get_meta(CommandButtonStatus.META_NAME_TEXT) != "Attack",
		"Chinese action surface names should not use English short labels"
	)

	vehicle_menu.queue_free()
	worker_menu.queue_free()
	generic_menu.queue_free()
	TranslationServer.set_locale(original_locale)


func _test_right_click_production_button_cancels_latest_matching_queue_item():
	var menu = VehicleFactoryMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var queue = FakeProductionQueue.new([TankUnit, PowerReactorUnit, TankUnit])
	var tank_button = menu.find_child("ProduceTankButton", true, false)
	CommandButtonStatus.apply_production(
		tank_button, TankUnit, [], FakePlayer.new(99, 99), queue
	)
	var right_click = InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	tank_button.emit_signal("gui_input", right_click)

	assert(queue.canceled_elements.size() == 1, "right-click should cancel one queued unit")
	assert(
		queue.canceled_elements[0].unit_prototype.resource_path == TankUnit.resource_path,
		"right-click should cancel the matching queued unit type"
	)
	assert(
		queue.elements.size() == 2 and queue.elements[0].unit_prototype == TankUnit,
		"right-click should cancel the newest matching queued item first"
	)
	assert(
		queue.elements[1].unit_prototype == PowerReactorUnit,
		"right-click should leave other queued unit types intact"
	)
	assert(
		tank_button.get_meta(CommandButtonStatus.META_QUEUE_COUNT) == 1,
		"right-click cancellation should refresh the button queue count metadata"
	)
	var queue_label = tank_button.find_child(CommandButtonStatus.QUEUE_LABEL_NAME, true, false)
	assert(queue_label.visible and queue_label.text == "x1", "right-click cancellation should refresh the queue label")

	tank_button.emit_signal("gui_input", right_click)
	assert(queue.canceled_elements.size() == 2, "second right-click should cancel the remaining matching unit")
	assert(queue.elements.size() == 1, "second right-click should leave only nonmatching queued units")
	assert(
		tank_button.get_meta(CommandButtonStatus.META_QUEUE_COUNT) == 0,
		"button queue count metadata should clear when no matching queued units remain"
	)
	assert(not queue_label.visible, "button queue label should hide when no matching queued units remain")

	menu.queue_free()


func _test_worker_build_buttons_show_costs():
	var menu = WorkerMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var power_button = menu.find_child("PlacePowerReactorButton", true, false)
	var cost_label = power_button.find_child(CommandButtonStatus.COST_LABEL_NAME, true, false)
	assert(cost_label != null, "construction buttons should show a compact cost label")
	assert(
		cost_label.text == "A 3  B 1",
		"power reactor button should show resource A/B construction cost"
	)
	var name_label = power_button.find_child(CommandButtonStatus.NAME_LABEL_NAME, true, false)
	assert(name_label != null, "construction buttons should show a compact surface name")
	assert(name_label.visible, "construction button surface names should be visible")
	assert(name_label.text == "Power", "power reactor button should show its structure name")
	assert(
		power_button.get_meta(CommandButtonStatus.META_NAME_TEXT) == "Power",
		"construction surface name should be mirrored in button metadata"
	)
	assert(
		power_button.get_meta(CommandButtonStatus.META_COST_TEXT) == "A 3  B 1",
		"construction cost should be mirrored in button metadata"
	)

	CommandButtonStatus.apply_construction(power_button, PowerReactorUnit, [], FakePlayer.new(2, 1))
	assert(
		not power_button.get_meta(CommandButtonStatus.META_AFFORDABLE),
		"construction buttons should mark unaffordable structures"
	)

	CommandButtonStatus.apply_construction(power_button, PowerReactorUnit, [], FakePlayer.new(3, 1))
	assert(
		power_button.get_meta(CommandButtonStatus.META_AFFORDABLE),
		"construction buttons should mark affordable structures"
	)
	menu.queue_free()


func _test_disabled_hotkey_does_not_fire():
	var menu = VehicleFactoryMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var fake_unit = FakeProductionUnit.new()
	menu.unit = fake_unit
	var tank_button = menu.find_child("ProduceTankButton", true, false)
	tank_button.disabled = true

	assert(
		not CommandButtonHotkeys.try_activate(menu, _key_event(KEY_Q)),
		"disabled buttons should ignore hotkeys"
	)
	assert(fake_unit.production_queue.produced_paths.is_empty(), "disabled hotkey should not queue units")
	menu.queue_free()


func _test_generic_menu_uses_visual_grid_hotkeys():
	var menu = GenericMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame
	menu.refresh()

	assert(
			menu.find_child("HoldPositionButton", true, false).get_meta(CommandButtonHotkeys.META_DISPLAY) == "Q",
			"first visible generic slot should use Q"
		)
	assert(
		menu.find_child("AttackMoveButton", true, false).get_meta(CommandButtonHotkeys.META_DISPLAY) == "W",
		"attack-move should inherit the second visual grid slot hotkey"
	)
	assert(
		menu.find_child("PatrolButton", true, false).get_meta(CommandButtonHotkeys.META_DISPLAY) == "E",
		"patrol should inherit the third visual grid slot hotkey"
	)
	assert(
		menu.find_child("SellStructureButton", true, false).get_meta(CommandButtonHotkeys.META_DISPLAY) == "R",
		"sell should inherit the fourth visual grid slot hotkey"
	)
	assert(
		menu.find_child("DeployModeButton", true, false).get_meta(CommandButtonHotkeys.META_DISPLAY) == "T",
		"deploy should inherit the fifth visual grid slot hotkey"
	)
	assert(
		menu.find_child("RepairStructureButton", true, false).get_meta(
			CommandButtonHotkeys.META_DISPLAY
		) == "Y",
		"repair should inherit the sixth visual grid slot hotkey"
	)
	assert(
		menu.find_child("RepairStructureButton", true, false).disabled,
		"repair should be disabled when no damaged structure is selected"
	)
	assert(
		menu.find_child("RepairStructureButton", true, false).tooltip_text.contains(
			tr("REPAIR_STRUCTURE_DISABLED")
		),
		"repair tooltip should explain why it is disabled"
	)
	assert(
		menu.find_child("RepairStructureButton", true, false).tooltip_text.contains("Y"),
		"repair tooltip should show the assigned hotkey"
	)
	_assert_surface_name(menu.find_child("HoldPositionButton", true, false), "Hold")
	_assert_surface_name(menu.find_child("AttackMoveButton", true, false), "Attack")
	_assert_surface_name(menu.find_child("PatrolButton", true, false), "Patrol")
	_assert_surface_name(menu.find_child("SellStructureButton", true, false), "Sell")
	_assert_surface_name(menu.find_child("DeployModeButton", true, false), "Deploy")
	_assert_surface_name(menu.find_child("RepairStructureButton", true, false), "Repair")
	_assert_surface_name(menu.find_child("CancelActionButton", true, false), "Cancel")
	_assert_surface_name(menu.find_child("GuardAreaButton", true, false), "Guard")
	_assert_surface_name(menu.find_child("ScatterButton", true, false), "Scatter")
	assert(
		menu.find_child("CancelActionButton", true, false).get_meta(CommandButtonHotkeys.META_DISPLAY) == "S",
		"cancel should keep the classic stop-command S hotkey"
	)
	assert(
		menu.find_child("CancelActionButton", true, false).disabled,
		"cancel should be disabled when selected units have no active orders"
	)
	assert(
		menu.find_child("CancelActionButton", true, false).tooltip_text.contains(
			tr("CANCEL_CURRENT_ACTION_DISABLED")
		),
		"cancel tooltip should explain why it is disabled"
	)
	assert(
		menu.find_child("CancelActionButton", true, false).tooltip_text.contains("S"),
		"cancel tooltip should show the assigned hotkey"
	)
	assert(
		menu.find_child("GuardAreaButton", true, false).get_meta(CommandButtonHotkeys.META_DISPLAY) == "G",
		"guard area should keep the classic G command hotkey"
	)
	assert(
		menu.find_child("GuardAreaButton", true, false).disabled,
		"guard area should be disabled when no combat units are selected"
	)
	assert(
		menu.find_child("GuardAreaButton", true, false).tooltip_text.contains(tr("GUARD_AREA_DISABLED")),
		"guard area tooltip should explain why it is disabled"
	)
	assert(
		menu.find_child("GuardAreaButton", true, false).tooltip_text.contains("G"),
		"guard area tooltip should show the assigned hotkey"
	)
	assert(
		menu.find_child("ScatterButton", true, false).get_meta(CommandButtonHotkeys.META_DISPLAY) == "X",
		"scatter should keep the classic X command hotkey"
	)
	assert(
		menu.find_child("ScatterButton", true, false).disabled,
		"scatter should be disabled when no mobile units are selected"
	)
	assert(
		menu.find_child("ScatterButton", true, false).tooltip_text.contains(tr("SCATTER_DISABLED")),
		"scatter tooltip should explain why it is disabled"
	)
	assert(
		menu.find_child("ScatterButton", true, false).tooltip_text.contains("X"),
		"scatter tooltip should show the assigned hotkey"
	)
	menu.queue_free()


func _assert_surface_name(button, expected_text):
	assert(button != null, "surface name button should exist")
	var label = button.find_child(CommandButtonStatus.NAME_LABEL_NAME, true, false)
	assert(label != null, "{0} should show a compact surface name label".format([button.name]))
	assert(label.visible, "{0} surface name should be visible".format([button.name]))
	assert(label.text == expected_text, "{0} surface name should be {1}".format([button.name, expected_text]))
	assert(
		button.get_meta(CommandButtonStatus.META_NAME_TEXT) == expected_text,
		"{0} should mirror surface name metadata".format([button.name])
	)


func _test_generic_attack_move_hotkey_requests_targeting():
	var menu = GenericMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var tank = TankUnit.instantiate()
	tank.add_to_group("controlled_units")
	tank.attack_range = 5.0
	tank.attack_damage = 1.0
	tank.attack_domains = [Constants.Match.Navigation.Domain.TERRAIN]
	menu.units = [tank]
	menu.refresh()

	var attack_button = menu.find_child("AttackMoveButton", true, false)
	assert(not attack_button.disabled, "attack-move should be enabled for mobile combat units")
	assert(attack_button.tooltip_text.contains("W"), "attack-move tooltip should show the W hotkey")

	var attack_move_requests = [0]
	var on_attack_move_requested = func(): attack_move_requests[0] += 1
	MatchSignals.attack_move_requested.connect(on_attack_move_requested)
	assert(
		CommandButtonHotkeys.try_activate(menu, _key_event(KEY_W)),
		"W should activate the generic attack-move command"
	)
	assert(attack_move_requests[0] == 1, "attack-move hotkey should request battlefield targeting")
	MatchSignals.attack_move_requested.disconnect(on_attack_move_requested)
	tank.free()
	menu.queue_free()


func _test_generic_patrol_hotkey_requests_targeting():
	var menu = GenericMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var tank = TankUnit.instantiate()
	tank.add_to_group("controlled_units")
	tank.attack_range = 5.0
	tank.attack_damage = 1.0
	tank.attack_domains = [Constants.Match.Navigation.Domain.TERRAIN]
	menu.units = [tank]
	menu.refresh()

	var patrol_button = menu.find_child("PatrolButton", true, false)
	assert(not patrol_button.disabled, "patrol should be enabled for mobile combat units")
	assert(patrol_button.tooltip_text.contains("E"), "patrol tooltip should show the E hotkey")
	var patrol_icon = patrol_button.find_child("TextureRect").texture
	assert(patrol_icon != null, "patrol button should have a command icon")
	assert(
		patrol_icon.resource_path == "res://assets/ui/icons/Patrol.png",
		"patrol should use the packaged root command icon"
	)

	var patrol_requests = [0]
	var on_patrol_requested = func(): patrol_requests[0] += 1
	MatchSignals.patrol_requested.connect(on_patrol_requested)
	assert(
		CommandButtonHotkeys.try_activate(menu, _key_event(KEY_E)),
		"E should activate the generic patrol command"
	)
	assert(patrol_requests[0] == 1, "patrol hotkey should request battlefield targeting")
	MatchSignals.patrol_requested.disconnect(on_patrol_requested)
	tank.free()
	menu.queue_free()


func _test_generic_scatter_button_shows_hotkey():
	var menu = GenericMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var tank = TankUnit.instantiate()
	tank.add_to_group("controlled_units")
	tank.attack_range = 5.0
	tank.attack_damage = 1.0
	tank.attack_domains = [Constants.Match.Navigation.Domain.TERRAIN]
	menu.units = [tank]
	menu.refresh()

	var guard_button = menu.find_child("GuardAreaButton", true, false)
	assert(InputMap.has_action("guard_area"), "guard area input action should exist")
	assert(not guard_button.disabled, "guard area should be enabled for mobile combat units")
	assert(guard_button.tooltip_text.contains("G"), "guard area tooltip should show the G hotkey")

	var scatter_button = menu.find_child("ScatterButton", true, false)
	assert(InputMap.has_action("scatter"), "scatter input action should exist")
	assert(not scatter_button.disabled, "scatter should be enabled for mobile units")
	assert(scatter_button.tooltip_text.contains("X"), "scatter tooltip should show the X hotkey")
	tank.free()
	menu.queue_free()


func _test_command_center_rally_point_hotkey_requests_targeting():
	var menu = CommandCenterMenuScene.instantiate()
	add_child(menu)
	await get_tree().process_frame

	var fake_structure = FakeProductionStructure.new()
	add_child(fake_structure)
	menu.unit = fake_structure
	menu.refresh()

	var rally_button = menu.find_child("SetRallyPointButton", true, false)
	assert(not rally_button.disabled, "rally point should be enabled for production structures")
	assert(
		rally_button.get_meta(CommandButtonHotkeys.META_DISPLAY) == "R",
		"rally point should inherit the fourth compact grid hotkey"
	)
	assert(rally_button.tooltip_text.contains("R"), "rally point tooltip should show the R hotkey")
	var repair_button = menu.find_child("RepairStructureButton", true, false)
	assert(
		repair_button.get_meta(CommandButtonHotkeys.META_DISPLAY) == "T",
		"production structure repair should append after rally point on the T hotkey"
	)
	assert(repair_button.tooltip_text.contains("T"), "repair tooltip should show the T hotkey")

	var rally_point_requests = [0]
	var on_rally_point_requested = func(): rally_point_requests[0] += 1
	MatchSignals.rally_point_requested.connect(on_rally_point_requested)
	assert(
		CommandButtonHotkeys.try_activate(menu, _key_event(KEY_R)),
		"R should activate command center rally-point targeting"
	)
	assert(rally_point_requests[0] == 1, "rally point hotkey should request battlefield targeting")
	MatchSignals.rally_point_requested.disconnect(on_rally_point_requested)
	fake_structure.queue_free()
	menu.queue_free()


func _test_expanded_grid_hotkeys_cover_all_visible_slots():
	var menu = GridContainer.new()
	add_child(menu)
	await get_tree().process_frame

	var pressed_slots = []
	var visible_slots = 36
	for slot_index in range(visible_slots):
		var button = Button.new()
		button.name = "CommandSlot{0}".format([slot_index + 1])
		button.pressed.connect(func(): pressed_slots.append(slot_index))
		menu.add_child(button)

	CommandButtonHotkeys.assign_grid_hotkeys(menu)
	var slot_29 = menu.get_child(28)
	var slot_30 = menu.get_child(29)
	assert(slot_29.get_meta(CommandButtonHotkeys.META_DISPLAY) == "-", "slot 29 should use -")
	assert(slot_30.get_meta(CommandButtonHotkeys.META_DISPLAY) == "=", "slot 30 should use =")
	assert(
		slot_29.find_child(CommandButtonHotkeys.HOTKEY_LABEL_NAME, true, false).text == "-",
		"slot 29 should show the - hotkey label"
	)
	assert(
		slot_30.find_child(CommandButtonHotkeys.HOTKEY_LABEL_NAME, true, false).text == "=",
		"slot 30 should show the = hotkey label"
	)
	for slot_index in range(30, visible_slots):
		assert(
			menu.get_child(slot_index).get_meta(CommandButtonHotkeys.META_DISPLAY, "") == "",
			"extra mouse-visible command slots should not steal keyboard shortcuts"
		)

	assert(
		CommandButtonHotkeys.try_activate(menu, _key_event(KEY_MINUS)),
		"- should activate the 29th visible command slot"
	)
	assert(
		CommandButtonHotkeys.try_activate(menu, _key_event(KEY_EQUAL)),
		"= should activate the 30th visible command slot"
	)
	assert(pressed_slots == [28, 29], "expanded hotkeys should activate the last visible slots")
	menu.queue_free()


func _key_event(keycode):
	var event = InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	event.physical_keycode = keycode
	return event
