extends Node

const ResourcesBarScene = preload("res://source/match/hud/ResourcesBar.tscn")


class FakePlayer:
	signal changed

	var resource_a = 11
	var resource_b = 7
	var power_supply = 10
	var power_drain = 8

	func get_power_supply():
		return power_supply

	func get_power_drain():
		return power_drain

	func is_low_power():
		return power_supply < power_drain


func _ready():
	var original_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	var player = FakePlayer.new()
	var resources_bar = ResourcesBarScene.instantiate()
	add_child(resources_bar)
	await get_tree().process_frame

	resources_bar.setup(player)
	await get_tree().process_frame

	var power_label = resources_bar.find_child("PowerLabel", true, false)
	var power_caption_label = resources_bar.find_child("PowerCaptionLabel", true, false)
	var low_power_label = resources_bar.find_child("LowPowerLabel", true, false)
	var power_container = resources_bar.find_child("PowerContainer", true, false)

	assert(power_caption_label.text == tr("POWER_SHORT"), "power caption should use translated short label")
	assert(power_label.text == "10/8", "power bar should show supply/drain")
	assert(not low_power_label.visible, "low-power badge should stay hidden while power is sufficient")

	player.power_drain = 14
	player.changed.emit()
	await get_tree().process_frame

	assert(power_label.text == "10/14", "power bar should update when drain changes")
	assert(low_power_label.visible, "low-power badge should appear when drain exceeds supply")
	assert(
		low_power_label.text == tr("LOW_POWER_STATUS"),
		"low-power badge should use the translated status label"
	)
	assert(
		power_container.tooltip_text.contains(tr("LOW_POWER_EFFECTS")),
		"low-power tooltip should explain the gameplay penalty"
	)

	player.power_supply = 18
	player.changed.emit()
	await get_tree().process_frame

	assert(power_label.text == "18/14", "power bar should update when supply changes")
	assert(not low_power_label.visible, "low-power badge should hide after power is restored")
	TranslationServer.set_locale("zh_CN")
	player.changed.emit()
	await get_tree().process_frame

	assert(power_caption_label.text == "电力", "Chinese power caption should not stay as PWR")
	assert(
		power_container.tooltip_text.contains("电力"),
		"Chinese power tooltip should use the localized power label"
	)
	TranslationServer.set_locale(original_locale)
	get_tree().quit()
