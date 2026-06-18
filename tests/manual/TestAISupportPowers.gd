extends "res://tests/manual/Match.gd"

const UnitScript = preload("res://source/match/units/Unit.gd")
const TankUnit = preload("res://source/match/units/Tank.tscn")
const TechAirportUnit = preload("res://source/match/units/TechAirport.tscn")

var _last_ai_power_id = ""
var _ready_ai_power_ids = []
var _charging_ai_power_ids = []

@onready var _human = $Players/Human
@onready var _ai = $Players/SimpleClairvoyantAI
@onready var _controller = $Players/SimpleClairvoyantAI/TacticalSupportPowersController
@onready var _human_command_center = $Players/Human/CommandCenter
@onready var _human_tank_a = $Players/Human/Tank
@onready var _human_tank_b = $Players/Human/Tank2
@onready var _ai_tank = $Players/SimpleClairvoyantAI/Tank


func _ready():
	super()
	_controller.setup(_ai)
	_controller.set_auto_refresh_enabled(false)
	MatchSignals.support_power_activated.connect(_on_support_power_activated)
	MatchSignals.support_power_charging.connect(_on_support_power_charging)
	MatchSignals.support_power_ready.connect(_on_support_power_ready)
	for _i in range(8):
		await get_tree().process_frame
	_human_command_center.hp_max = 96
	_human_command_center.hp = 96
	assert(
		not _controller.can_activate(Constants.Match.SupportPowers.WEATHER_STORM),
		"AI weather storm should start charging after the weather control spire is available"
	)
	assert(
		not _controller.can_activate(Constants.Match.SupportPowers.STRATEGIC_MISSILE),
		"AI strategic missile should start charging after the weather control spire is available"
	)
	assert(
		_controller.get_cooldown_remaining(Constants.Match.SupportPowers.WEATHER_STORM) > 0.0,
		"AI weather storm should expose its initial charge as cooldown"
	)
	assert(
		_controller.get_cooldown_remaining(Constants.Match.SupportPowers.STRATEGIC_MISSILE) > 0.0,
		"AI strategic missile should expose its initial charge as cooldown"
	)
	assert(
		_charging_ai_power_ids.has(Constants.Match.SupportPowers.WEATHER_STORM),
		"AI weather storm should announce when its superweapon charge starts"
	)
	assert(
		_charging_ai_power_ids.has(Constants.Match.SupportPowers.STRATEGIC_MISSILE),
		"AI strategic missile should announce when its superweapon charge starts"
	)
	_controller.reset_cooldowns()

	assert(
		_controller.can_activate(Constants.Match.SupportPowers.EMP_PULSE),
		"AI should unlock EMP pulse after constructing Robotics Bay with power"
	)
	var used_power_id = _controller.try_activate_best_power()
	assert(
		_ready_ai_power_ids.has(Constants.Match.SupportPowers.WEATHER_STORM),
		"AI should emit a ready signal when its weather storm superweapon is available"
	)
	assert(
		_ready_ai_power_ids.has(Constants.Match.SupportPowers.STRATEGIC_MISSILE),
		"AI should emit a ready signal when its strategic missile superweapon is available"
	)
	assert(
		used_power_id == Constants.Match.SupportPowers.EMP_PULSE,
		"AI should prefer EMP pulse against clustered mobile enemy units"
	)
	await get_tree().process_frame
	assert(
		_last_ai_power_id == Constants.Match.SupportPowers.EMP_PULSE,
		"AI support power activation should emit the shared support power signal"
	)
	assert(_human_tank_a.is_emp_disabled(), "AI EMP should disable the first clustered enemy")
	assert(_human_tank_b.is_emp_disabled(), "AI EMP should disable the second clustered enemy")
	assert(not _ai_tank.is_emp_disabled(), "AI EMP should not disable friendly units")
	assert(
		not _controller.can_activate(Constants.Match.SupportPowers.EMP_PULSE),
		"AI EMP should enter cooldown after activation"
	)
	_human_tank_a.hp = 0
	_human_tank_b.hp = 0
	await get_tree().process_frame

	_controller.reset_cooldowns()
	_ai_tank.hp -= 6
	var damaged_ai_tank_hp = _ai_tank.hp
	assert(
		_controller.can_activate(Constants.Match.SupportPowers.NANITE_REPAIR_SWARM),
		"AI should unlock nanite repair swarm after constructing Robotics Bay with power"
	)
	used_power_id = _controller.try_activate_best_power()
	assert(
		used_power_id == Constants.Match.SupportPowers.NANITE_REPAIR_SWARM,
		"AI should repair damaged friendly units before firing offensive powers"
	)
	await get_tree().process_frame
	assert(
		_last_ai_power_id == Constants.Match.SupportPowers.NANITE_REPAIR_SWARM,
		"AI nanite repair swarm should emit the shared support power signal"
	)
	assert(_ai_tank.hp > damaged_ai_tank_hp, "AI nanite repair swarm should repair allies")
	assert(
		not _controller.can_activate(Constants.Match.SupportPowers.NANITE_REPAIR_SWARM),
		"AI nanite repair swarm should enter cooldown after activation"
	)

	_controller.reset_cooldowns()
	var pressure_tank = TankUnit.instantiate()
	_setup_and_spawn_unit(
		pressure_tank,
		Transform3D(Basis(), _ai_tank.global_position + Vector3(2.0, 0.0, 0.0)),
		_human,
		false
	)
	await get_tree().process_frame
	assert(
		_controller.can_activate(Constants.Match.SupportPowers.SHIELD_OVERDRIVE),
		"AI should unlock shield overdrive after constructing Tech Lab with power"
	)
	used_power_id = _controller.try_activate_best_power()
	assert(
		used_power_id == Constants.Match.SupportPowers.SHIELD_OVERDRIVE,
		"AI should shield friendly units under local enemy pressure"
	)
	await get_tree().process_frame
	assert(
		_last_ai_power_id == Constants.Match.SupportPowers.SHIELD_OVERDRIVE,
		"AI shield overdrive should emit the shared support power signal"
	)
	assert(_ai_tank.is_support_shielded(), "AI shield overdrive should shield nearby allies")
	assert(
		not _controller.can_activate(Constants.Match.SupportPowers.SHIELD_OVERDRIVE),
		"AI shield overdrive should enter cooldown after activation"
	)
	pressure_tank.hp = 0
	await get_tree().process_frame

	var wing_tank = TankUnit.instantiate()
	_setup_and_spawn_unit(
		wing_tank,
		Transform3D(Basis(), _ai_tank.global_position + Vector3(-2.0, 0.0, 0.0)),
		_ai,
		false
	)
	await get_tree().process_frame
	assert(
		_controller.can_activate(Constants.Match.SupportPowers.CHRONO_RELAY),
		"AI should unlock chrono relay after constructing Tech Lab with power"
	)
	used_power_id = _controller.try_activate_best_power()
	assert(
		used_power_id == Constants.Match.SupportPowers.CHRONO_RELAY,
		"AI should chrono boost friendly mobile clusters before firing offensive powers"
	)
	await get_tree().process_frame
	assert(
		_last_ai_power_id == Constants.Match.SupportPowers.CHRONO_RELAY,
		"AI chrono relay should emit the shared support power signal"
	)
	assert(_ai_tank.is_chrono_relayed(), "AI chrono relay should accelerate the first ally")
	assert(wing_tank.is_chrono_relayed(), "AI chrono relay should accelerate clustered allies")
	assert(
		not _controller.can_activate(Constants.Match.SupportPowers.CHRONO_RELAY),
		"AI chrono relay should enter cooldown after activation"
	)

	assert(
		_controller.can_activate(Constants.Match.SupportPowers.WEATHER_STORM),
		"AI should unlock weather storm after constructing Weather Control Spire with power"
	)
	var weather_target_hp = _human_command_center.hp
	used_power_id = _controller.try_activate_best_power()
	assert(
		used_power_id == Constants.Match.SupportPowers.WEATHER_STORM,
		"AI should prefer weather storm against a high-value enemy structure"
	)
	await get_tree().process_frame
	assert(
		_last_ai_power_id == Constants.Match.SupportPowers.WEATHER_STORM,
		"AI weather storm should emit the shared support power signal"
	)
	assert(
		_support_power_warning_marker_count() > 0,
		"AI weather storm should telegraph the targeted superweapon area before damage"
	)
	assert(
		_human_command_center.hp == weather_target_hp,
		"AI weather storm should not damage the target before its warning delay expires"
	)
	await _wait_for_support_power_impact(Constants.Match.SupportPowers.WEATHER_STORM)
	assert(
		_human_command_center.hp < weather_target_hp,
		"AI weather storm should damage the targeted enemy structure"
	)
	assert(_ai_tank.hp == _ai_tank.hp_max, "AI weather storm should not damage friendly units")
	assert(
		_support_power_warning_marker_count() == 0,
		"AI weather storm warning marker should clear after impact"
	)
	assert(
		not _controller.can_activate(Constants.Match.SupportPowers.WEATHER_STORM),
		"AI weather storm should enter cooldown after activation"
	)

	var command_center_hp = _human_command_center.hp
	used_power_id = _controller.try_activate_best_power()
	assert(
		used_power_id == Constants.Match.SupportPowers.STRATEGIC_MISSILE,
		"AI should use strategic missile against a high-value enemy structure while weather storm is cooling down"
	)
	await get_tree().process_frame
	assert(
		_last_ai_power_id == Constants.Match.SupportPowers.STRATEGIC_MISSILE,
		"AI strategic missile should emit the shared support power signal"
	)
	assert(
		_support_power_warning_marker_count() > 0,
		"AI strategic missile should telegraph the targeted superweapon area before damage"
	)
	assert(
		_support_power_projectile_count() > 0,
		"AI strategic missile should show an incoming missile before impact"
	)
	assert(
		_human_command_center.hp == command_center_hp,
		"AI strategic missile should not damage the target before its warning delay expires"
	)
	await _wait_for_support_power_impact(Constants.Match.SupportPowers.STRATEGIC_MISSILE)
	assert(
		_human_command_center.hp < command_center_hp,
		"AI strategic missile should damage the targeted enemy structure"
	)
	assert(_ai_tank.hp == _ai_tank.hp_max, "AI strategic missile should not damage friendly units")
	assert(
		_support_power_warning_marker_count() == 0,
		"AI strategic missile warning marker should clear after impact"
	)
	assert(
		_support_power_projectile_count() == 0,
		"AI strategic missile projectile should clear after impact"
	)
	assert(
		not _controller.can_activate(Constants.Match.SupportPowers.STRATEGIC_MISSILE),
		"AI strategic missile should enter cooldown after activation"
	)

	command_center_hp = _human_command_center.hp
	var revealers_before_radar = get_tree().get_nodes_in_group("temporary_revealers").size()
	used_power_id = _controller.try_activate_best_power()
	assert(
		used_power_id == Constants.Match.SupportPowers.ORBITAL_STRIKE,
		"AI should use orbital strike against a high-value enemy structure while weather storm is cooling down"
	)
	await get_tree().process_frame
	assert(
		_last_ai_power_id == Constants.Match.SupportPowers.ORBITAL_STRIKE,
		"AI orbital strike should emit the shared support power signal"
	)
	assert(
		_support_power_warning_marker_count() > 0,
		"AI orbital strike should telegraph the targeted impact area before damage"
	)
	assert(
		_human_command_center.hp == command_center_hp,
		"AI orbital strike should not damage the target before its warning delay expires"
	)
	await _wait_for_support_power_impact(Constants.Match.SupportPowers.ORBITAL_STRIKE)
	assert(
		_human_command_center.hp < command_center_hp,
		"AI orbital strike should damage the targeted enemy structure"
	)
	assert(_ai_tank.hp == _ai_tank.hp_max, "AI orbital strike should not damage friendly units")
	assert(
		_support_power_warning_marker_count() == 0,
		"AI orbital strike warning marker should clear after impact"
	)
	assert(
		not _controller.can_activate(Constants.Match.SupportPowers.ORBITAL_STRIKE),
		"AI orbital strike should enter cooldown after activation"
	)

	_setup_and_spawn_unit(
		TechAirportUnit.instantiate(),
		Transform3D(Basis(), _ai_tank.global_position + Vector3(4.0, 0.0, 0.0)),
		_ai,
		false
	)
	await get_tree().process_frame
	var ai_unit_count_before_paradrop = _ai.get_children().filter(func(child): return child is UnitScript).size()
	var ai_units_before_paradrop = _ai.get_children().filter(func(child): return child is UnitScript)
	used_power_id = _controller.try_activate_best_power()
	assert(
		used_power_id == Constants.Match.SupportPowers.PARADROP,
		"AI should use paradrop after capturing a tech airport while damaging powers are cooling down"
	)
	await get_tree().process_frame
	assert(
		_last_ai_power_id == Constants.Match.SupportPowers.PARADROP,
		"AI paradrop should emit the shared support power signal"
	)
	assert(
		_support_power_warning_marker_count() > 0,
		"AI paradrop should telegraph its landing zone before units arrive"
	)
	assert(
		_ai.get_children().filter(func(child): return child is UnitScript).size()
		== ai_unit_count_before_paradrop,
		"AI paradrop should not spawn units before its drop delay expires"
	)
	await _wait_for_support_power_impact(Constants.Match.SupportPowers.PARADROP)
	var ai_units_after_paradrop = _ai.get_children().filter(func(child): return child is UnitScript)
	var ai_paradropped_units = ai_units_after_paradrop.filter(
		func(unit): return not ai_units_before_paradrop.has(unit)
	)
	assert(
		ai_units_after_paradrop.size() == ai_unit_count_before_paradrop + 3,
		"AI paradrop should spawn three friendly infantry units after its drop delay"
	)
	assert(
		_support_power_warning_marker_count() == 0,
		"AI paradrop landing marker should clear after the squad arrives"
	)
	assert(
		_units_are_spaced(ai_paradropped_units),
		"AI paradrop should place the landing squad without unit overlap"
	)
	assert(
		not _controller.can_activate(Constants.Match.SupportPowers.PARADROP),
		"AI paradrop should enter cooldown after activation"
	)

	used_power_id = _controller.try_activate_best_power()
	assert(
		used_power_id == Constants.Match.SupportPowers.RADAR_SWEEP,
		"AI should use radar sweep when damaging powers have no worthwhile target"
	)
	await get_tree().process_frame
	assert(
		_last_ai_power_id == Constants.Match.SupportPowers.RADAR_SWEEP,
		"AI radar sweep should emit the shared support power signal"
	)
	assert(
		not _controller.can_activate(Constants.Match.SupportPowers.RADAR_SWEEP),
		"AI radar sweep should enter cooldown after activation"
	)
	assert(
		get_tree().get_nodes_in_group("temporary_revealers").size() > revealers_before_radar,
		"AI radar sweep should create a temporary battlefield revealer"
	)
	get_tree().quit()


func _on_support_power_activated(power_id, player, _target_position):
	if player == _ai:
		_last_ai_power_id = power_id


func _on_support_power_charging(power_id, player, _charge_seconds):
	if player == _ai:
		_charging_ai_power_ids.append(power_id)


func _on_support_power_ready(power_id, player):
	if player == _ai:
		_ready_ai_power_ids.append(power_id)


func _wait_for_support_power_impact(power_id):
	await get_tree().create_timer(_impact_delay(power_id) + 0.2).timeout
	await get_tree().process_frame


func _impact_delay(power_id):
	return Constants.Match.SupportPowers.DEFINITIONS[power_id].get("impact_delay", 0.0)


func _support_power_warning_marker_count():
	return get_tree().get_nodes_in_group("support_power_warning_markers").size()


func _support_power_projectile_count():
	return get_tree().get_nodes_in_group("support_power_projectiles").size()


func _units_are_spaced(units):
	for index in range(units.size()):
		for other_index in range(index + 1, units.size()):
			var first = units[index]
			var second = units[other_index]
			var minimum_distance = first.radius + second.radius - 0.05
			if first.global_position_yless.distance_to(second.global_position_yless) < minimum_distance:
				return false
	return true
