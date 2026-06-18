extends Node

const ProductionQueueScene = preload("res://source/match/hud/ProductionQueue.tscn")
const ProductionQueueElementScene = preload("res://source/match/hud/ProductionQueueElement.tscn")
const TankUnit = preload("res://source/match/units/Tank.tscn")
const WorkerUnit = preload("res://source/match/units/Worker.tscn")
const EngineerDroneUnit = preload("res://source/match/units/EngineerDrone.tscn")
const LightRifleInfantryUnit = preload("res://source/match/units/LightRifleInfantry.tscn")
const RocketInfantryUnit = preload("res://source/match/units/RocketInfantry.tscn")
const SaboteurInfiltratorUnit = preload("res://source/match/units/SaboteurInfiltrator.tscn")
const LongbowMissileCrawlerUnit = preload("res://source/match/units/LongbowMissileCrawler.tscn")
const RailgunTankUnit = preload("res://source/match/units/RailgunTank.tscn")
const CryoSprayerUnit = preload("res://source/match/units/CryoSprayer.tscn")
const ShieldTrooperUnit = preload("res://source/match/units/ShieldTrooper.tscn")
const TacticalOfficerUnit = preload("res://source/match/units/TacticalOfficer.tscn")
const RailSniperTeamUnit = preload("res://source/match/units/RailSniperTeam.tscn")
const PulseRifleCommandoUnit = preload("res://source/match/units/PulseRifleCommando.tscn")
const ModularMissileCarrierUnit = preload("res://source/match/units/ModularMissileCarrier.tscn")
const TeslaCrawlerMk2Unit = preload("res://source/match/units/TeslaCrawlerMk2.tscn")
const FieldMedicUnit = preload("res://source/match/units/FieldMedic.tscn")
const JammerVehicleUnit = preload("res://source/match/units/JammerVehicle.tscn")
const LanceBeamTankUnit = preload("res://source/match/units/LanceBeamTank.tscn")
const HeavySiegeWalkerUnit = preload("res://source/match/units/HeavySiegeWalker.tscn")
const InterceptorVTOLUnit = preload("res://source/match/units/InterceptorVTOL.tscn")
const RocketGunshipUnit = preload("res://source/match/units/RocketGunship.tscn")
const HeavyBombardmentAirshipUnit = preload("res://source/match/units/HeavyBombardmentAirship.tscn")
const QUEUE_ELEMENT_SIZE = Vector2(72, 72)
const QUEUE_ORDER_LABEL_NAME = "QueueOrderLabel"
const STATUS_BACKDROP_NAME = "StatusBackdrop"
const PROGRESS_FILL_NAME = "ProgressFill"
const CANONICAL_ICON_ALIASES = {}
const ACTIVE_BORDER_COLOR = Color(0.50, 0.86, 1.0, 1.0)
const WAITING_BORDER_COLOR = Color(0.18, 0.30, 0.34, 1.0)
const READY_BLOCKED_BORDER_COLOR = Color(1.0, 0.72, 0.18, 1.0)


class FakeQueue:
	extends RefCounted

	var canceled_element = null

	func cancel(element):
		canceled_element = element


class FakeObservedQueue:
	extends RefCounted

	signal element_enqueued(element)
	signal element_removed(element)

	var elements = []

	func _init(a_elements):
		elements = a_elements

	func get_elements():
		return elements

	func enqueue(element):
		elements.append(element)
		element_enqueued.emit(element)

	func remove(element):
		elements.erase(element)
		element_removed.emit(element)


class FakeQueueElement:
	extends Resource

	var unit_prototype = null
	var time_total = 10.0
	var time_left = 6.0

	func progress():
		return (time_total - time_left) / time_total


class FakeSelectedProductionUnit:
	extends Node

	var production_queue = null

	func _init(a_production_queue):
		production_queue = a_production_queue


func _ready():
	await _test_queue_element_icon_tooltip_and_cancel()
	await _test_queue_element_ready_blocked_feedback()
	await _test_queue_element_uses_packaged_command_icons()
	await _test_queue_element_finds_alias_packaged_icons()
	await _test_queue_element_prefers_packaged_late_tech_icons()
	await _test_queue_hud_hides_empty_selected_production_queue()
	await _test_queue_hud_preserves_production_order()
	await _test_queue_hud_aggregates_multi_selected_production_queues()
	get_tree().quit()


func _test_queue_element_icon_tooltip_and_cancel():
	var fake_queue = FakeQueue.new()
	var fake_queue_element = _make_queue_element(LongbowMissileCrawlerUnit)

	var queue_element_node = ProductionQueueElementScene.instantiate()
	queue_element_node.queue = fake_queue
	queue_element_node.queue_element = fake_queue_element
	add_child(queue_element_node)
	await get_tree().process_frame

	var icon_texture_rect = queue_element_node.find_child("IconTextureRect")
	assert(
		icon_texture_rect.texture != null,
		"production queue should find the canonical unit icon"
	)
	assert(icon_texture_rect.visible, "production queue icon control should be visible")
	assert(
		icon_texture_rect.size.x >= 32.0 and icon_texture_rect.size.y >= 32.0,
		"production queue icon control should keep a readable on-screen size"
	)
	assert(
		queue_element_node.icon == icon_texture_rect.texture,
		"production queue should also expose its icon through Button.icon"
	)
	assert(
		queue_element_node.expand_icon,
		"production queue should expand Button.icon as a Web fallback"
	)
	assert(
		queue_element_node.custom_minimum_size == QUEUE_ELEMENT_SIZE,
		"production queue elements should be large enough to read"
	)
	assert(queue_element_node.text == "", "production queue should prefer icons over fallback text")
	_assert_texture_is_visible_on_dark_ui(icon_texture_rect.texture, "longbow queue icon")
	assert(
		icon_texture_rect.texture.resource_path == _canonical_icon_path_for_unit(
			LongbowMissileCrawlerUnit
		),
		"production queue should prefer the packaged root icon over generated icon fallbacks"
	)
	assert(
		queue_element_node.find_child("Label").text == "40%",
		"production queue should show element progress"
	)
	_assert_status_strip_keeps_icon_readable(queue_element_node, 0.4)
	assert(
		queue_element_node.tooltip_text.contains(tr("LONGBOW_MISSILE_CRAWLER")),
		"production queue tooltip should show the translated unit name"
	)
	assert(
		queue_element_node.tooltip_text.contains(tr("PRODUCTION_QUEUE_CANCEL")),
		"production queue tooltip should explain cancellation"
	)
	var costs = Constants.Match.Units.PRODUCTION_COSTS[LongbowMissileCrawlerUnit.resource_path]
	assert(
		queue_element_node.tooltip_text.contains(str(costs["resource_a"]))
		and queue_element_node.tooltip_text.contains(str(costs["resource_b"])),
		"production queue tooltip should show refunded resources"
	)

	queue_element_node.emit_signal("pressed")
	assert(
		fake_queue.canceled_element == fake_queue_element,
		"clicking a production queue element should cancel that queued item"
	)
	remove_child(queue_element_node)
	queue_element_node.queue_free()


func _test_queue_element_uses_packaged_command_icons():
	for unit_prototype in [
		WorkerUnit,
		EngineerDroneUnit,
		LightRifleInfantryUnit,
		RocketInfantryUnit,
		FieldMedicUnit,
		TankUnit,
		ModularMissileCarrierUnit,
		SaboteurInfiltratorUnit,
		RailgunTankUnit,
		ShieldTrooperUnit,
		InterceptorVTOLUnit,
		RocketGunshipUnit,
		CryoSprayerUnit,
	]:
		var queue_element_node = ProductionQueueElementScene.instantiate()
		queue_element_node.queue = FakeQueue.new()
		queue_element_node.queue_element = _make_queue_element(unit_prototype)
		add_child(queue_element_node)
		await get_tree().process_frame

		var icon_texture = queue_element_node.find_child("IconTextureRect").texture
		var icon_rect = queue_element_node.find_child("IconTextureRect")
		assert(
			icon_texture != null,
			"{0} should resolve its command-menu queue icon".format([unit_prototype.resource_path])
		)
		assert(
			icon_rect.size.x >= 32.0 and icon_rect.size.y >= 32.0,
			"{0} queue icon should keep a readable on-screen size".format(
				[unit_prototype.resource_path]
			)
		)
		assert(
			queue_element_node.icon == icon_texture and queue_element_node.expand_icon,
			"{0} queue icon should also render through Button.icon".format(
				[unit_prototype.resource_path]
			)
		)
		_assert_queue_icon_uses_packaged_root_icon(icon_texture, unit_prototype)
		_assert_texture_is_visible_on_dark_ui(icon_texture, unit_prototype.resource_path)
		assert(queue_element_node.text == "", "mapped queue icons should avoid text fallback")

		remove_child(queue_element_node)
		queue_element_node.queue_free()


func _test_queue_element_ready_blocked_feedback():
	var fake_queue_element = _make_queue_element(TankUnit)
	fake_queue_element.time_left = 0.0

	var queue_element_node = ProductionQueueElementScene.instantiate()
	queue_element_node.queue = FakeQueue.new()
	queue_element_node.queue_element = fake_queue_element
	add_child(queue_element_node)
	await get_tree().process_frame

	assert(
		queue_element_node.find_child("Label").text == tr("PRODUCTION_QUEUE_READY"),
		"finished queued production should show a ready state while waiting for placement"
	)
	assert(
		queue_element_node.tooltip_text.contains(tr("PRODUCTION_QUEUE_BLOCKED")),
		"ready queued production should explain that the factory exit is blocked"
	)
	var normal_style = queue_element_node.get_theme_stylebox("normal")
	assert(
		normal_style is StyleBoxFlat and normal_style.border_color == READY_BLOCKED_BORDER_COLOR,
		"ready blocked production should use the warning border color"
	)
	_assert_status_strip_keeps_icon_readable(queue_element_node, 1.0)

	remove_child(queue_element_node)
	queue_element_node.queue_free()


func _test_queue_element_finds_alias_packaged_icons():
	for unit_prototype in [ShieldTrooperUnit, TacticalOfficerUnit, RailSniperTeamUnit, TeslaCrawlerMk2Unit]:
		var queue_element_node = ProductionQueueElementScene.instantiate()
		queue_element_node.queue = FakeQueue.new()
		queue_element_node.queue_element = _make_queue_element(unit_prototype)
		add_child(queue_element_node)
		await get_tree().process_frame

		var icon_texture = queue_element_node.find_child("IconTextureRect").texture
		assert(icon_texture != null, "{0} should resolve a packaged queue icon".format([unit_prototype.resource_path]))
		_assert_queue_icon_uses_packaged_root_icon(icon_texture, unit_prototype)
		assert(queue_element_node.text == "", "packaged queue icons should avoid text fallback")

		remove_child(queue_element_node)
		queue_element_node.queue_free()


func _test_queue_element_prefers_packaged_late_tech_icons():
	for unit_prototype in [
		JammerVehicleUnit,
		LanceBeamTankUnit,
		HeavySiegeWalkerUnit,
		HeavyBombardmentAirshipUnit,
	]:
		var queue_element_node = ProductionQueueElementScene.instantiate()
		queue_element_node.queue = FakeQueue.new()
		queue_element_node.queue_element = _make_queue_element(unit_prototype)
		add_child(queue_element_node)
		await get_tree().process_frame

		var icon_texture = queue_element_node.find_child("IconTextureRect").texture
		assert(icon_texture != null, "{0} should resolve a late-tech queue icon".format([unit_prototype.resource_path]))
		_assert_queue_icon_uses_packaged_root_icon(icon_texture, unit_prototype)
		assert(queue_element_node.text == "", "late-tech queue icons should avoid text fallback")

		remove_child(queue_element_node)
		queue_element_node.queue_free()


func _test_queue_hud_hides_empty_selected_production_queue():
	var fake_queue = FakeObservedQueue.new([])
	var fake_unit = FakeSelectedProductionUnit.new(fake_queue)
	fake_unit.add_to_group("selected_units")
	fake_unit.add_to_group("controlled_units")
	add_child(fake_unit)

	var queue_hud = ProductionQueueScene.instantiate()
	add_child(queue_hud)
	await get_tree().process_frame

	assert(
		not queue_hud.visible,
		"empty selected production queues should not leave a blank HUD panel"
	)
	assert(_queue_nodes(queue_hud).is_empty(), "empty selected queues should render no queue nodes")

	var queued_element = _make_queue_element(TankUnit)
	fake_queue.enqueue(queued_element)
	await get_tree().process_frame
	var queue_nodes = _queue_nodes(queue_hud)
	assert(queue_hud.visible, "queue HUD should appear when production is queued")
	assert(queue_nodes.size() == 1, "queue HUD should render the newly queued element")
	assert(queue_nodes[0].queue_element == queued_element, "queued element should render after enqueue")

	fake_queue.remove(queued_element)
	await get_tree().process_frame
	assert(not queue_hud.visible, "queue HUD should hide after the final queued item is removed")
	assert(_queue_nodes(queue_hud).is_empty(), "queue HUD should clear nodes after the queue empties")

	remove_child(queue_hud)
	queue_hud.queue_free()
	remove_child(fake_unit)
	fake_unit.queue_free()


func _test_queue_hud_preserves_production_order():
	var first_element = _make_queue_element(TankUnit)
	var second_element = _make_queue_element(LongbowMissileCrawlerUnit)
	var fake_queue = FakeObservedQueue.new([first_element, second_element])
	var fake_unit = FakeSelectedProductionUnit.new(fake_queue)
	fake_unit.add_to_group("selected_units")
	fake_unit.add_to_group("controlled_units")
	add_child(fake_unit)

	var queue_hud = ProductionQueueScene.instantiate()
	add_child(queue_hud)
	await get_tree().process_frame

	var queue_nodes = _queue_nodes(queue_hud)
	assert(queue_nodes.size() == 2, "production queue HUD should render selected unit queue")
	assert(
		queue_nodes[0].queue_element == first_element,
		"first queued element should stay on the left as the active production item"
	)
	assert(
		queue_nodes[1].queue_element == second_element,
		"second queued element should stay to the right of the active production item"
	)
	assert(
		_queue_order_text(queue_nodes[0]) == "1" and _queue_order_text(queue_nodes[1]) == "2",
		"production queue HUD should number elements from left to right"
	)

	var third_element = _make_queue_element(WorkerUnit)
	fake_queue.enqueue(third_element)
	await get_tree().process_frame
	queue_nodes = _queue_nodes(queue_hud)
	assert(
		queue_nodes[2].queue_element == third_element,
		"newly queued elements should be appended to the right"
	)
	assert(_queue_order_text(queue_nodes[2]) == "3", "newly queued element should get queue order 3")

	fake_queue.remove(first_element)
	await get_tree().process_frame
	queue_nodes = _queue_nodes(queue_hud)
	assert(
		queue_nodes[0].queue_element == second_element,
		"removing the active production item should promote the next item to the left"
	)
	assert(
		_queue_order_text(queue_nodes[0]) == "1" and _queue_order_text(queue_nodes[1]) == "2",
		"production queue HUD should renumber after an element is removed"
	)

	remove_child(queue_hud)
	queue_hud.queue_free()
	remove_child(fake_unit)
	fake_unit.queue_free()


func _test_queue_hud_aggregates_multi_selected_production_queues():
	var first_element = _make_queue_element(TankUnit)
	var second_element = _make_queue_element(LongbowMissileCrawlerUnit)
	var third_element = _make_queue_element(WorkerUnit)
	var first_queue = FakeObservedQueue.new([first_element])
	var second_queue = FakeObservedQueue.new([second_element, third_element])
	var first_unit = FakeSelectedProductionUnit.new(first_queue)
	first_unit.name = "AFactory"
	first_unit.add_to_group("selected_units")
	first_unit.add_to_group("controlled_units")
	add_child(first_unit)
	var second_unit = FakeSelectedProductionUnit.new(second_queue)
	second_unit.name = "BFactory"
	second_unit.add_to_group("selected_units")
	second_unit.add_to_group("controlled_units")
	add_child(second_unit)

	var queue_hud = ProductionQueueScene.instantiate()
	add_child(queue_hud)
	await get_tree().process_frame

	var queue_nodes = _queue_nodes(queue_hud)
	assert(queue_hud.visible, "multi-selected production queues should show the queue HUD")
	assert(queue_nodes.size() == 3, "queue HUD should aggregate all selected production queues")
	assert(queue_nodes[0].queue == first_queue, "first queue element should keep its source queue")
	assert(queue_nodes[0].queue_element == first_element, "first queue element should render first")
	assert(queue_nodes[1].queue == second_queue, "second queue element should keep its source queue")
	assert(queue_nodes[1].queue_element == second_element, "second queue should render after first queue")
	assert(queue_nodes[2].queue_element == third_element, "second queue should preserve its internal order")
	assert(
		_queue_order_text(queue_nodes[0]) == "1"
		and _queue_order_text(queue_nodes[1]) == "2"
		and _queue_order_text(queue_nodes[2]) == "3",
		"aggregate queue HUD should number elements across all selected queues"
	)
	assert(
		_status_text(queue_nodes[0]) == "40%"
		and _status_text(queue_nodes[1]) == "40%"
		and _status_text(queue_nodes[2]) == tr("PRODUCTION_QUEUE_WAITING"),
		"each selected factory should show its own active production item"
	)
	assert(
		_normal_border_color(queue_nodes[0]) == ACTIVE_BORDER_COLOR
		and _normal_border_color(queue_nodes[1]) == ACTIVE_BORDER_COLOR
		and _normal_border_color(queue_nodes[2]) == WAITING_BORDER_COLOR,
		"multi-selected queues should style active slots per source queue"
	)

	var fourth_element = _make_queue_element(RailgunTankUnit)
	first_queue.enqueue(fourth_element)
	await get_tree().process_frame
	queue_nodes = _queue_nodes(queue_hud)
	assert(queue_nodes.size() == 4, "aggregate queue HUD should refresh when any queue changes")
	assert(
		queue_nodes[1].queue == first_queue and queue_nodes[1].queue_element == fourth_element,
		"new elements should stay with their source queue order"
	)
	assert(
		_queue_order_text(queue_nodes[3]) == "4",
		"aggregate queue HUD should renumber after enqueueing"
	)
	assert(
		_status_text(queue_nodes[1]) == tr("PRODUCTION_QUEUE_WAITING"),
		"newly queued second item in the first factory should wait behind that factory active item"
	)

	second_queue.remove(second_element)
	await get_tree().process_frame
	queue_nodes = _queue_nodes(queue_hud)
	assert(queue_nodes.size() == 3, "aggregate queue HUD should refresh after removing from any queue")
	assert(
		queue_nodes[2].queue == second_queue and queue_nodes[2].queue_element == third_element,
		"remaining elements from later queues should stay visible"
	)
	assert(
		_queue_order_text(queue_nodes[0]) == "1"
		and _queue_order_text(queue_nodes[1]) == "2"
		and _queue_order_text(queue_nodes[2]) == "3",
		"aggregate queue HUD should renumber after removal"
	)

	remove_child(queue_hud)
	queue_hud.queue_free()
	remove_child(first_unit)
	first_unit.queue_free()
	remove_child(second_unit)
	second_unit.queue_free()


func _make_queue_element(unit_prototype):
	var fake_queue_element = FakeQueueElement.new()
	fake_queue_element.unit_prototype = unit_prototype
	return fake_queue_element


func _queue_nodes(queue_hud):
	return queue_hud.find_child("QueueElements").get_children().filter(
		func(child): return "queue_element" in child
	)


func _queue_order_text(queue_element_node):
	return queue_element_node.find_child(QUEUE_ORDER_LABEL_NAME, true, false).text


func _status_text(queue_element_node):
	return queue_element_node.find_child("Label", true, false).text


func _normal_border_color(queue_element_node):
	var normal_style = queue_element_node.get_theme_stylebox("normal")
	if normal_style is StyleBoxFlat:
		return normal_style.border_color
	return Color.TRANSPARENT


func _assert_status_strip_keeps_icon_readable(queue_element_node, expected_progress):
	var icon_rect = queue_element_node.find_child("IconTextureRect", true, false)
	var status_label = queue_element_node.find_child("Label", true, false)
	var status_backdrop = queue_element_node.find_child(STATUS_BACKDROP_NAME, true, false)
	var progress_fill = queue_element_node.find_child(PROGRESS_FILL_NAME, true, false)
	assert(icon_rect != null, "queue element should have an icon rect")
	assert(status_label != null, "queue element should have a status label")
	assert(status_backdrop != null, "queue element should have a status backdrop")
	assert(progress_fill != null, "queue element should have a progress fill")
	assert(
		not icon_rect.get_global_rect().intersects(status_label.get_global_rect()),
		"queue status text should stay in a bottom strip instead of covering the unit icon"
	)
	assert(
		is_equal_approx(progress_fill.anchor_right, expected_progress),
		"queue progress fill should match the production state"
	)


func _is_canonical_icon_path(icon_path):
	return icon_path.begins_with("res://assets/ui/icons/") and not icon_path.contains("/generated/")


func _assert_queue_icon_uses_packaged_root_icon(icon_texture, unit_prototype):
	var canonical_icon_path = _canonical_icon_path_for_unit(unit_prototype)
	assert(
		canonical_icon_path != "",
		"{0} should have a packaged root icon mapping".format([unit_prototype.resource_path])
	)
	assert(
		icon_texture.resource_path == canonical_icon_path,
		"{0} should use packaged root icon {1}, got {2}".format(
			[unit_prototype.resource_path, canonical_icon_path, icon_texture.resource_path]
		)
	)


func _canonical_icon_path_for_unit(unit_prototype):
	var scene_path = unit_prototype.resource_path
	var file_name = scene_path.substr(scene_path.rfind("/") + 1)
	var unit_name = file_name.split(".")[0]
	var icon_path = "res://assets/ui/icons/{0}.png".format([unit_name])
	if ResourceLoader.exists(icon_path) or FileAccess.file_exists(icon_path):
		return icon_path
	var alias_name = CANONICAL_ICON_ALIASES.get(unit_name, "")
	if alias_name == "":
		return ""
	var alias_icon_path = "res://assets/ui/icons/{0}.png".format([alias_name])
	return (
		alias_icon_path
		if ResourceLoader.exists(alias_icon_path) or FileAccess.file_exists(alias_icon_path)
		else ""
	)


func _assert_texture_is_visible_on_dark_ui(texture, label):
	assert(texture != null, "{0} should have a texture".format([label]))
	var image = texture.get_image()
	assert(image != null, "{0} should expose image data".format([label]))
	var bright_pixels = 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.05 and max(pixel.r, max(pixel.g, pixel.b)) >= 0.35:
				bright_pixels += 1
	assert(
		bright_pixels >= 180,
		"{0} should have enough bright pixels to read on the dark command UI".format([label])
	)
