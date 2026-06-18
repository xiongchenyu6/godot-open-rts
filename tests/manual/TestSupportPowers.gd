extends "res://tests/manual/Match.gd"

const UnitScript = preload("res://source/match/units/Unit.gd")
const SupportPowersScript = preload("res://source/match/hud/SupportPowers.gd")
const SupportPowerIcons = preload("res://source/match/hud/SupportPowerIcons.gd")
const PowerReactorUnit = preload("res://source/match/units/PowerReactor.tscn")
const RadarUplinkUnit = preload("res://source/match/units/RadarUplink.tscn")
const RoboticsBayUnit = preload("res://source/match/units/RoboticsBay.tscn")
const TechLabUnit = preload("res://source/match/units/TechLab.tscn")
const WeatherControlSpireUnit = preload("res://source/match/units/WeatherControlSpire.tscn")
const TechAirportUnit = preload("res://source/match/units/TechAirport.tscn")
const TankUnit = preload("res://source/match/units/Tank.tscn")
const MovingAction = preload("res://source/match/units/actions/Moving.gd")

const VISIBLE_ICON_NAME = "CommandVisibleIcon"
const SUPPORT_POWER_BUTTON_NAMES = [
	"RadarSweepButton",
	"OrbitalStrikeButton",
	"EmpPulseButton",
	"ChronoRelayButton",
	"ShieldOverdriveButton",
	"NaniteRepairSwarmButton",
	"WeatherStormButton",
	"StrategicMissileButton",
	"ParadropButton",
]

@onready var _player = $Players/Human
@onready var _enemy = $Players/SimpleClairvoyantAI
@onready var _support_powers = $HUD/SupportPowersAnchor/SupportPowers


func _ready():
	super()
	await get_tree().process_frame
	_disable_ai_controllers()
	var ready_power_ids = []
	var ready_recorder = func(power_id, player):
		if player == _player:
			ready_power_ids.append(power_id)
	var charging_events = []
	var charging_recorder = func(power_id, player, charge_seconds):
		if player == _player:
			charging_events.append({"power_id": power_id, "charge_seconds": charge_seconds})
	MatchSignals.support_power_ready.connect(ready_recorder)
	MatchSignals.support_power_charging.connect(charging_recorder)

	assert(
		_support_powers.find_child("RadarSweepButton") != null,
		"support powers panel should expose radar sweep"
	)
	assert(
		_support_powers.find_child("OrbitalStrikeButton") != null,
		"support powers panel should expose orbital strike"
	)
	assert(
		_support_powers.find_child("EmpPulseButton") != null,
		"support powers panel should expose EMP pulse"
	)
	assert(
		_support_powers.find_child("ChronoRelayButton") != null,
		"support powers panel should expose chrono relay"
	)
	assert(
		_support_powers.find_child("ShieldOverdriveButton") != null,
		"support powers panel should expose shield overdrive"
	)
	assert(
		_support_powers.find_child("NaniteRepairSwarmButton") != null,
		"support powers panel should expose nanite repair swarm"
	)
	assert(
		_support_powers.find_child("WeatherStormButton") != null,
		"support powers panel should expose weather storm"
	)
	assert(
		_support_powers.find_child("StrategicMissileButton") != null,
		"support powers panel should expose strategic missile"
	)
	assert(
		_support_powers.find_child("ParadropButton") != null,
		"support powers panel should expose paradrop"
	)
	_assert_support_power_icons_loaded()
	_assert_support_power_hotkeys_assigned()
	_assert_support_power_panel_previews_locked_powers()
	_assert_support_power_anchor_fits_preview_strip()
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.RADAR_SWEEP),
		"radar sweep should require radar tech"
	)
	_support_powers._unhandled_key_input(_key_event(KEY_F1))
	await get_tree().process_frame
	assert(
		_support_powers._armed_power_id == "",
		"locked support power hotkeys should not arm unavailable powers"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.ORBITAL_STRIKE),
		"orbital strike should require tech lab"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.EMP_PULSE),
		"EMP pulse should require robotics bay"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.CHRONO_RELAY),
		"chrono relay should require tech lab"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.SHIELD_OVERDRIVE),
		"shield overdrive should require tech lab"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.NANITE_REPAIR_SWARM),
		"nanite repair swarm should require robotics bay"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.WEATHER_STORM),
		"weather storm should require weather control spire"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.STRATEGIC_MISSILE),
		"strategic missile should require weather control spire"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.PARADROP),
		"paradrop should require a captured tech airport"
	)
	assert(
		not Utils.Match.Unit.Tech.can_construct(_player, WeatherControlSpireUnit.resource_path),
		"weather control spire should require tech lab"
	)

	_setup_and_spawn_unit(
		PowerReactorUnit.instantiate(), Transform3D(Basis(), Vector3(13.0, 0.0, 10.0)), _player, false
	)
	_setup_and_spawn_unit(
		PowerReactorUnit.instantiate(), Transform3D(Basis(), Vector3(25.0, 0.0, 10.0)), _player, false
	)
	_setup_and_spawn_unit(
		RadarUplinkUnit.instantiate(), Transform3D(Basis(), Vector3(16.0, 0.0, 10.0)), _player, false
	)
	_setup_and_spawn_unit(
		TechLabUnit.instantiate(), Transform3D(Basis(), Vector3(19.0, 0.0, 10.0)), _player, false
	)
	_setup_and_spawn_unit(
		RoboticsBayUnit.instantiate(), Transform3D(Basis(), Vector3(22.0, 0.0, 10.0)), _player, false
	)
	await get_tree().process_frame
	_support_powers.refresh()
	_assert_support_power_button_states(
		[
			"RadarSweepButton",
			"OrbitalStrikeButton",
			"EmpPulseButton",
			"ChronoRelayButton",
			"ShieldOverdriveButton",
			"NaniteRepairSwarmButton",
		],
		[
			"WeatherStormButton",
			"StrategicMissileButton",
			"ParadropButton",
		]
	)
	assert(
		Utils.Match.Unit.Tech.can_construct(_player, WeatherControlSpireUnit.resource_path),
		"constructed tech lab should unlock weather control spire construction"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.WEATHER_STORM),
		"weather storm should still require the spire itself"
	)
	_setup_and_spawn_unit(
		WeatherControlSpireUnit.instantiate(),
		Transform3D(Basis(), Vector3(28.0, 0.0, 10.0)),
		_player,
		false
	)
	_setup_and_spawn_unit(
		TechAirportUnit.instantiate(),
		Transform3D(Basis(), Vector3(31.0, 0.0, 10.0)),
		_player,
		false
	)
	await get_tree().process_frame
	_support_powers.refresh()
	_assert_support_power_button_states(
		[
			"RadarSweepButton",
			"OrbitalStrikeButton",
			"EmpPulseButton",
			"ChronoRelayButton",
			"ShieldOverdriveButton",
			"NaniteRepairSwarmButton",
			"WeatherStormButton",
			"StrategicMissileButton",
			"ParadropButton",
		],
		[]
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.WEATHER_STORM),
		"weather storm should start charging after the weather control spire is constructed"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.STRATEGIC_MISSILE),
		"strategic missile should start charging after the weather control spire is constructed"
	)
	assert(
		_support_powers.get_cooldown_remaining(Constants.Match.SupportPowers.WEATHER_STORM) > 0.0,
		"weather storm should expose its initial charge as cooldown"
	)
	assert(
		_support_powers.get_cooldown_remaining(Constants.Match.SupportPowers.STRATEGIC_MISSILE) > 0.0,
		"strategic missile should expose its initial charge as cooldown"
	)
	assert(
		_charging_event_exists(charging_events, Constants.Match.SupportPowers.WEATHER_STORM),
		"weather storm should announce when its superweapon charge starts"
	)
	assert(
		_charging_event_exists(charging_events, Constants.Match.SupportPowers.STRATEGIC_MISSILE),
		"strategic missile should announce when its superweapon charge starts"
	)
	_support_powers._cooldown_ready_at[Constants.Match.SupportPowers.WEATHER_STORM] = 0.0
	_support_powers._cooldown_ready_at[Constants.Match.SupportPowers.STRATEGIC_MISSILE] = 0.0
	_support_powers.refresh()
	await get_tree().process_frame
	assert(
		ready_power_ids.has(Constants.Match.SupportPowers.WEATHER_STORM),
		"weather storm should emit ready after its initial charge completes"
	)
	assert(
		ready_power_ids.has(Constants.Match.SupportPowers.STRATEGIC_MISSILE),
		"strategic missile should emit ready after its initial charge completes"
	)
	_support_powers.reset_cooldowns()

	assert(
		_support_powers.can_activate(Constants.Match.SupportPowers.RADAR_SWEEP),
		"constructed powered radar should unlock radar sweep"
	)
	assert(
		_support_powers.can_activate(Constants.Match.SupportPowers.ORBITAL_STRIKE),
		"constructed powered tech lab should unlock orbital strike"
	)
	assert(
		_support_powers.can_activate(Constants.Match.SupportPowers.EMP_PULSE),
		"constructed powered robotics bay should unlock EMP pulse"
	)
	assert(
		_support_powers.can_activate(Constants.Match.SupportPowers.CHRONO_RELAY),
		"constructed powered tech lab should unlock chrono relay"
	)
	assert(
		_support_powers.can_activate(Constants.Match.SupportPowers.SHIELD_OVERDRIVE),
		"constructed powered tech lab should unlock shield overdrive"
	)
	assert(
		_support_powers.can_activate(Constants.Match.SupportPowers.NANITE_REPAIR_SWARM),
		"constructed powered robotics bay should unlock nanite repair swarm"
	)
	assert(
		_support_powers.can_activate(Constants.Match.SupportPowers.WEATHER_STORM),
		"constructed powered weather control spire should unlock weather storm"
	)
	assert(
		_support_powers.can_activate(Constants.Match.SupportPowers.STRATEGIC_MISSILE),
		"constructed powered weather control spire should unlock strategic missile"
	)
	assert(
		_support_powers.can_activate(Constants.Match.SupportPowers.PARADROP),
		"captured tech airport should unlock paradrop"
	)
	_test_support_power_hotkey_arming()

	var hidden_target = $Players/SimpleClairvoyantAI/Tank
	hidden_target.global_position = Vector3(46.0, 0.0, 10.0)
	hidden_target.action = null
	var target_became_hidden = await _wait_for_visibility(hidden_target, false)
	if not target_became_hidden:
		push_error("enemy outside friendly sight should start hidden")
		get_tree().quit(1)
		return
	assert(not hidden_target.visible, "enemy outside friendly sight should start hidden")

	assert(
		_support_powers.activate_power_at(
			Constants.Match.SupportPowers.RADAR_SWEEP, hidden_target.global_position
		),
		"radar sweep should activate at a battlefield position"
	)
	var target_became_visible = await _wait_for_visibility(hidden_target, true)
	if not target_became_visible:
		push_error("radar sweep should temporarily reveal enemy units")
		get_tree().quit(1)
		return
	assert(hidden_target.visible, "radar sweep should temporarily reveal enemy units")
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.RADAR_SWEEP),
		"radar sweep should enter cooldown after activation"
	)
	_support_powers._cooldown_ready_at[Constants.Match.SupportPowers.RADAR_SWEEP] = 0.0
	_support_powers.refresh()
	await get_tree().process_frame
	assert(
		ready_power_ids.has(Constants.Match.SupportPowers.RADAR_SWEEP),
		"support powers should emit a ready signal after cooldown finishes"
	)

	_support_powers.reset_cooldowns()
	var nearby_target_hp = hidden_target.hp
	var far_target = TankUnit.instantiate()
	_setup_and_spawn_unit(
		far_target, Transform3D(Basis(), Vector3(39.0, 0.0, 10.0)), _enemy, false
	)
	await get_tree().process_frame
	var far_target_hp = far_target.hp
	assert(
		_support_powers.arm_power(Constants.Match.SupportPowers.ORBITAL_STRIKE),
		"orbital strike should arm for a minimap target"
	)
	MatchSignals.minimap_terrain_targeted.emit(hidden_target.global_position)
	await get_tree().process_frame
	assert(
		_support_power_warning_marker_count() > 0,
		"orbital strike should telegraph the targeted impact area before damage"
	)
	assert(
		hidden_target.hp == nearby_target_hp,
		"orbital strike should not damage targets before its warning delay expires"
	)
	await _wait_for_support_power_impact(Constants.Match.SupportPowers.ORBITAL_STRIKE)
	assert(
		_unit_took_damage(hidden_target, nearby_target_hp),
		"orbital strike should accept minimap targets"
	)
	assert(
		_unit_kept_hp(far_target, far_target_hp),
		"orbital strike should not damage targets outside radius"
	)
	assert(
		_support_power_warning_marker_count() == 0,
		"orbital strike warning marker should clear after impact"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.ORBITAL_STRIKE),
		"orbital strike should enter cooldown after activation"
	)

	_support_powers.reset_cooldowns()
	var repair_target = TankUnit.instantiate()
	_setup_and_spawn_unit(
		repair_target, Transform3D(Basis(), Vector3(30.0, 0.0, 26.0)), _player, false
	)
	var repair_near_target = TankUnit.instantiate()
	_setup_and_spawn_unit(
		repair_near_target, Transform3D(Basis(), Vector3(34.0, 0.0, 26.0)), _player, false
	)
	var repair_far_target = TankUnit.instantiate()
	_setup_and_spawn_unit(
		repair_far_target, Transform3D(Basis(), Vector3(40.0, 0.0, 26.0)), _player, false
	)
	await get_tree().process_frame
	repair_target.hp_max = 20
	repair_target.hp = 5
	repair_near_target.hp_max = 20
	repair_near_target.hp = 8
	repair_far_target.hp_max = 20
	repair_far_target.hp = 5
	var repair_far_hp = repair_far_target.hp
	assert(
		_support_powers.activate_power_at(
			Constants.Match.SupportPowers.NANITE_REPAIR_SWARM, repair_target.global_position
		),
		"nanite repair swarm should activate at a battlefield position"
	)
	await get_tree().process_frame
	assert(repair_target.hp == 15, "nanite repair swarm should repair the target")
	assert(repair_near_target.hp == 18, "nanite repair swarm should repair nearby allies")
	assert(
		repair_far_target.hp == repair_far_hp,
		"nanite repair swarm should not repair allies outside radius"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.NANITE_REPAIR_SWARM),
		"nanite repair swarm should enter cooldown after activation"
	)

	_support_powers.reset_cooldowns()
	assert(
		_support_powers.activate_power_at(
			Constants.Match.SupportPowers.CHRONO_RELAY, repair_target.global_position
		),
		"chrono relay should activate at a battlefield position"
	)
	await get_tree().process_frame
	assert(repair_target.is_chrono_relayed(), "chrono relay should accelerate the target")
	assert(repair_near_target.is_chrono_relayed(), "chrono relay should accelerate nearby allies")
	assert(
		not repair_far_target.is_chrono_relayed(),
		"chrono relay should not accelerate allies outside radius"
	)
	assert(
		repair_target.get_chrono_speed_multiplier() > 1.0,
		"chrono relay should raise the movement speed multiplier"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.CHRONO_RELAY),
		"chrono relay should enter cooldown after activation"
	)

	_support_powers.reset_cooldowns()
	repair_target.hp = 20
	var shielded_hp = repair_target.hp
	assert(
		_support_powers.activate_power_at(
			Constants.Match.SupportPowers.SHIELD_OVERDRIVE, repair_target.global_position
		),
		"shield overdrive should activate at a battlefield position"
	)
	await get_tree().process_frame
	assert(repair_target.is_support_shielded(), "shield overdrive should shield nearby allies")
	assert(
		not repair_far_target.is_support_shielded(),
		"shield overdrive should not shield allies outside radius"
	)
	repair_target.hp -= 8.0
	assert(
		repair_target.hp > shielded_hp - 8.0 and repair_target.hp < shielded_hp,
		"shielded allies should take reduced damage"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.SHIELD_OVERDRIVE),
		"shield overdrive should enter cooldown after activation"
	)

	_support_powers.reset_cooldowns()
	var storm_target = TankUnit.instantiate()
	_setup_and_spawn_unit(
		storm_target, Transform3D(Basis(), Vector3(32.0, 0.0, 18.0)), _enemy, false
	)
	var storm_near_target = TankUnit.instantiate()
	_setup_and_spawn_unit(
		storm_near_target, Transform3D(Basis(), Vector3(37.0, 0.0, 18.0)), _enemy, false
	)
	var storm_far_target = TankUnit.instantiate()
	_setup_and_spawn_unit(
		storm_far_target, Transform3D(Basis(), Vector3(45.0, 0.0, 18.0)), _enemy, false
	)
	await get_tree().process_frame
	storm_target.hp_max = 20
	storm_target.hp = 20
	storm_near_target.hp_max = 20
	storm_near_target.hp = 20
	storm_far_target.hp_max = 20
	storm_far_target.hp = 20
	var storm_target_hp = storm_target.hp
	var storm_near_target_hp = storm_near_target.hp
	var storm_far_target_hp = storm_far_target.hp
	assert(
		_support_powers.activate_power_at(
			Constants.Match.SupportPowers.WEATHER_STORM, storm_target.global_position
		),
		"weather storm should activate at a battlefield position"
	)
	await get_tree().process_frame
	assert(
		_support_power_warning_marker_count() > 0,
		"weather storm should telegraph the superweapon target before damage"
	)
	assert(
		storm_target.hp == storm_target_hp,
		"weather storm should not damage targets before its warning delay expires"
	)
	await _wait_for_support_power_impact(Constants.Match.SupportPowers.WEATHER_STORM)
	assert(_unit_took_damage(storm_target, storm_target_hp), "weather storm should damage the target")
	assert(
		_unit_took_damage(storm_near_target, storm_near_target_hp),
		"weather storm should damage nearby enemies in its large radius"
	)
	assert(
		_unit_kept_hp(storm_far_target, storm_far_target_hp),
		"weather storm should not damage targets outside radius"
	)
	assert(
		_support_power_warning_marker_count() == 0,
		"weather storm warning marker should clear after impact"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.WEATHER_STORM),
		"weather storm should enter cooldown after activation"
	)

	_support_powers.reset_cooldowns()
	var missile_target = TankUnit.instantiate()
	_setup_and_spawn_unit(
		missile_target, Transform3D(Basis(), Vector3(31.0, 0.0, 30.0)), _enemy, false
	)
	var missile_near_target = TankUnit.instantiate()
	_setup_and_spawn_unit(
		missile_near_target, Transform3D(Basis(), Vector3(34.0, 0.0, 30.0)), _enemy, false
	)
	var missile_far_target = TankUnit.instantiate()
	_setup_and_spawn_unit(
		missile_far_target, Transform3D(Basis(), Vector3(47.0, 0.0, 47.0)), _enemy, false
	)
	await get_tree().process_frame
	missile_target.hp_max = 30
	missile_target.hp = 30
	missile_near_target.hp_max = 30
	missile_near_target.hp = 30
	missile_far_target.hp_max = 30
	missile_far_target.hp = 30
	var missile_target_hp = missile_target.hp
	var missile_near_target_hp = missile_near_target.hp
	var missile_far_target_hp = missile_far_target.hp
	assert(
		_support_powers.activate_power_at(
			Constants.Match.SupportPowers.STRATEGIC_MISSILE, missile_target.global_position
		),
		"strategic missile should activate at a battlefield position"
	)
	await get_tree().process_frame
	assert(
		_support_power_warning_marker_count() > 0,
		"strategic missile should telegraph the target before damage"
	)
	assert(
		_support_power_projectile_count() > 0,
		"strategic missile should show an incoming missile before impact"
	)
	assert(
		missile_target.hp == missile_target_hp,
		"strategic missile should not damage targets before its warning delay expires"
	)
	await _wait_for_support_power_impact(Constants.Match.SupportPowers.STRATEGIC_MISSILE)
	assert(
		_unit_took_damage(missile_target, missile_target_hp),
		"strategic missile should damage the target"
	)
	assert(
		_unit_took_damage(missile_near_target, missile_near_target_hp),
		"strategic missile should damage nearby enemies in its blast radius"
	)
	assert(
		_unit_kept_hp(missile_far_target, missile_far_target_hp),
		"strategic missile should not damage targets outside radius"
	)
	assert(
		_support_power_warning_marker_count() == 0,
		"strategic missile warning marker should clear after impact"
	)
	assert(
		_support_power_projectile_count() == 0,
		"strategic missile projectile should clear after impact"
	)
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.STRATEGIC_MISSILE),
		"strategic missile should enter cooldown after activation"
	)

	_support_powers.reset_cooldowns()
	var friendly_units_before_paradrop = _player.get_children().filter(func(child): return child is UnitScript).size()
	var player_units_before_paradrop = _player.get_children().filter(func(child): return child is UnitScript)
	assert(
		_support_powers.activate_power_at(
			Constants.Match.SupportPowers.PARADROP, Vector3(24.0, 0.0, 18.0)
		),
		"paradrop should activate at a battlefield position"
	)
	await get_tree().process_frame
	assert(
		_support_power_warning_marker_count() > 0,
		"paradrop should telegraph its landing zone before units arrive"
	)
	var friendly_units_after_paradrop = _player.get_children().filter(func(child): return child is UnitScript).size()
	assert(
		friendly_units_after_paradrop == friendly_units_before_paradrop,
		"paradrop should not spawn units before its drop delay expires"
	)
	await _wait_for_support_power_impact(Constants.Match.SupportPowers.PARADROP)
	var player_units_after_paradrop = _player.get_children().filter(func(child): return child is UnitScript)
	var paradropped_units = player_units_after_paradrop.filter(
		func(unit): return not player_units_before_paradrop.has(unit)
	)
	friendly_units_after_paradrop = player_units_after_paradrop.size()
	assert(
		friendly_units_after_paradrop == friendly_units_before_paradrop + 3,
		"paradrop should spawn three friendly infantry units"
	)
	assert(
		_support_power_warning_marker_count() == 0,
		"paradrop landing marker should clear after the squad arrives"
	)
	assert(
		_units_are_spaced(paradropped_units),
		"paradrop should place the landing squad without unit overlap"
	)
	assert(_unit_count_by_scene(_player, "res://source/match/units/LightRifleInfantry.tscn") >= 2, "paradrop should include rifle infantry")
	assert(_unit_count_by_scene(_player, "res://source/match/units/RocketInfantry.tscn") >= 1, "paradrop should include rocket infantry")
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.PARADROP),
		"paradrop should enter cooldown after activation"
	)

	_support_powers.reset_cooldowns()
	var emp_target = TankUnit.instantiate()
	_setup_and_spawn_unit(
		emp_target, Transform3D(Basis(), Vector3(32.0, 0.0, 10.0)), _enemy, false
	)
	await get_tree().process_frame
	assert(
		_support_powers.activate_power_at(
			Constants.Match.SupportPowers.EMP_PULSE, emp_target.global_position
		),
		"EMP pulse should activate at a battlefield position"
	)
	await get_tree().process_frame
	assert(emp_target.is_emp_disabled(), "EMP pulse should disable mobile enemy units")
	assert(emp_target.action == null, "EMP pulse should interrupt current enemy actions")
	emp_target.action = MovingAction.new(emp_target.global_position + Vector3(3.0, 0.0, 0.0))
	await get_tree().process_frame
	assert(emp_target.action == null, "EMP-disabled units should reject new actions")
	assert(
		not _support_powers.can_activate(Constants.Match.SupportPowers.EMP_PULSE),
		"EMP pulse should enter cooldown after activation"
	)
	await get_tree().create_timer(
		Constants.Match.SupportPowers.DEFINITIONS[
			Constants.Match.SupportPowers.EMP_PULSE
		]["duration"] + 0.2
	).timeout
	assert(not emp_target.is_emp_disabled(), "EMP-disabled units should recover after duration")
	emp_target.action = MovingAction.new(emp_target.global_position + Vector3(3.0, 0.0, 0.0))
	await get_tree().process_frame
	assert(emp_target.action != null, "recovered units should accept actions again")
	MatchSignals.support_power_charging.disconnect(charging_recorder)
	MatchSignals.support_power_ready.disconnect(ready_recorder)
	get_tree().quit()


func _unit_took_damage(unit, previous_hp):
	return not _is_alive(unit) or unit.hp < previous_hp


func _unit_kept_hp(unit, expected_hp):
	return _is_alive(unit) and unit.hp == expected_hp


func _is_alive(unit):
	return unit != null and is_instance_valid(unit) and unit.is_inside_tree() and unit.hp > 0


func _wait_for_visibility(unit, expected_visibility, max_frames = 30):
	for _i in range(max_frames):
		await get_tree().process_frame
		await get_tree().physics_frame
		if unit.visible == expected_visibility:
			return true
	return false


func _wait_for_support_power_impact(power_id):
	await get_tree().create_timer(_impact_delay(power_id) + 0.2).timeout
	await get_tree().process_frame


func _impact_delay(power_id):
	return Constants.Match.SupportPowers.DEFINITIONS[power_id].get("impact_delay", 0.0)


func _support_power_warning_marker_count():
	return get_tree().get_nodes_in_group("support_power_warning_markers").size()


func _support_power_projectile_count():
	return get_tree().get_nodes_in_group("support_power_projectiles").size()


func _charging_event_exists(charging_events, power_id):
	for event in charging_events:
		if event["power_id"] == power_id and event["charge_seconds"] > 0.0:
			return true
	return false


func _assert_support_power_panel_previews_locked_powers():
	_support_powers.refresh()
	assert(
		_support_powers.visible,
		"support power panel should stay visible so locked powers preview the tech tree"
	)
	_assert_support_power_button_states([], SUPPORT_POWER_BUTTON_NAMES)


func _assert_support_power_anchor_fits_preview_strip():
	var anchor = _support_powers.get_parent()
	assert(anchor != null, "support powers should be placed inside an anchor")
	assert(
		anchor.size.x >= _support_powers.get_combined_minimum_size().x - 0.5,
		"support powers anchor should fit all F1-F9 preview buttons without clipping"
	)


func _assert_support_power_button_states(unlocked_button_names, locked_button_names):
	assert(
		_support_powers.visible,
		"support power panel should stay visible when a human player exists"
	)
	for button_name in unlocked_button_names:
		var button = _support_powers.find_child(button_name)
		var cooldown_label = _support_power_cooldown_label_for_button(button_name)
		assert(button != null, button_name + " should exist")
		assert(button.visible, button_name + " should be visible after its tech unlocks")
		assert(
			button.modulate == SupportPowersScript.READY_BUTTON_MODULATE,
			button_name + " should use full-strength icon colors after unlocking"
		)
		assert(
			cooldown_label.text != _support_powers.tr("COMMAND_TECH_LOCK_SHORT"),
			button_name + " should clear its tech-lock label after unlocking"
		)
	for button_name in locked_button_names:
		var button = _support_powers.find_child(button_name)
		var cooldown_label = _support_power_cooldown_label_for_button(button_name)
		assert(button != null, button_name + " should exist")
		assert(button.visible, button_name + " should stay visible as a locked tech preview")
		assert(button.disabled, button_name + " locked preview should not be clickable")
		assert(
			button.modulate == SupportPowersScript.LOCKED_BUTTON_MODULATE,
			button_name + " locked preview should be visually dimmed"
		)
		assert(
			cooldown_label.text == _support_powers.tr("COMMAND_TECH_LOCK_SHORT"),
			button_name + " locked preview should show a compact tech label"
		)
		assert(
			button.tooltip_text.contains(_support_powers.tr("MISSING_TECH")),
			button_name + " locked preview tooltip should explain missing tech"
		)


func _support_power_cooldown_label_for_button(button_name):
	var label_name = button_name.trim_suffix("Button") + "CooldownLabel"
	var label = _support_powers.find_child(label_name)
	assert(label != null, label_name + " should exist")
	return label


func _assert_support_power_icons_loaded():
	assert(
		not SupportPowerIcons._should_use_procedural_overlay_for_platform(true),
		"Web builds should avoid stacked procedural support-power overlays when texture icons are available"
	)
	assert(
		not SupportPowerIcons._should_use_procedural_overlay_for_platform(false),
		"native builds should keep packaged support-power icon textures by default"
	)
	for button_name in [
		"RadarSweepButton",
		"OrbitalStrikeButton",
		"EmpPulseButton",
		"ChronoRelayButton",
		"ShieldOverdriveButton",
		"NaniteRepairSwarmButton",
		"WeatherStormButton",
		"StrategicMissileButton",
		"ParadropButton"
	]:
		var button = _support_powers.find_child(button_name)
		var icon = button.find_child("IconTextureRect")
		assert(icon.texture != null, button_name + " should have a command icon texture")
		assert(button.icon == null, button_name + " should avoid duplicate Button.icon drawing")
		assert(not button.expand_icon, button_name + " should not expand a hidden built-in icon")
		assert(not icon.visible, button_name + " source TextureRect icon should stay hidden")
		var visible_icon = button.find_child(VISIBLE_ICON_NAME, false, false)
		assert(visible_icon != null, button_name + " should have one visible icon layer")
		assert(visible_icon.visible, button_name + " visible icon layer should be visible")
		assert(
			visible_icon.texture == icon.texture,
			button_name + " visible icon layer should draw the support-power texture"
		)
		_assert_texture_is_visible_on_dark_ui(icon.texture, button_name)
		var overlay = button.find_child(SupportPowerIcons.ICON_OVERLAY_NAME, false, false)
		assert(overlay != null, button_name + " should keep a hidden legacy overlay node for compatibility")
		assert(not overlay.visible, button_name + " legacy procedural overlay should stay hidden")
	_assert_support_power_icon_path("EmpPulseButton", "EmpPulse.png")
	_assert_support_power_icon_path("ChronoRelayButton", "ChronoRelay.png")
	_assert_support_power_icon_path("ShieldOverdriveButton", "ShieldOverdrive.png")
	_assert_support_power_icon_path("NaniteRepairSwarmButton", "NaniteRepairSwarm.png")
	_assert_support_power_icon_path("WeatherStormButton", "WeatherStorm.png")
	_assert_support_power_icon_path("StrategicMissileButton", "StrategicMissile.png")
	_assert_support_power_icon_path("ParadropButton", "Paradrop.png")
	_assert_support_power_procedural_web_fallback()


func _assert_support_power_procedural_web_fallback():
	SupportPowerIcons.force_procedural_support_power_icons_for_tests = true
	for button_name in [
		"RadarSweepButton",
		"OrbitalStrikeButton",
		"EmpPulseButton",
		"ChronoRelayButton",
		"ShieldOverdriveButton",
		"NaniteRepairSwarmButton",
		"WeatherStormButton",
		"StrategicMissileButton",
		"ParadropButton"
	]:
		var button = _support_powers.find_child(button_name)
		SupportPowerIcons.ensure(button)
		var overlay = button.find_child(SupportPowerIcons.ICON_OVERLAY_NAME, false, false)
		assert(overlay != null, button_name + " legacy Web icon overlay should exist")
		assert(not overlay.visible, button_name + " forced legacy Web icon overlay should stay hidden")
	SupportPowerIcons.force_procedural_support_power_icons_for_tests = false
	for button_name in [
		"RadarSweepButton",
		"OrbitalStrikeButton",
		"EmpPulseButton",
		"ChronoRelayButton",
		"ShieldOverdriveButton",
		"NaniteRepairSwarmButton",
		"WeatherStormButton",
		"StrategicMissileButton",
		"ParadropButton"
	]:
		SupportPowerIcons.ensure(_support_powers.find_child(button_name))


func _assert_support_power_icon_path(button_name, file_name):
	var button = _support_powers.find_child(button_name)
	var icon = button.find_child("IconTextureRect").texture
	var expected_path = "res://assets/ui/icons/{0}".format([file_name])
	assert(
		icon.resource_path == expected_path,
		"{0} should use packaged root icon {1}, got {2}".format(
			[button_name, expected_path, icon.resource_path]
		)
	)


func _assert_texture_is_visible_on_dark_ui(texture, label):
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
		"{0} icon should have enough bright pixels to read on the dark support UI".format([label])
	)


func _test_support_power_hotkey_arming():
	var started_power_ids = []
	var finished_power_ids = []
	var record_started = func(power_id): started_power_ids.append(power_id)
	var record_finished = func(power_id): finished_power_ids.append(power_id)
	MatchSignals.support_power_targeting_started.connect(record_started)
	MatchSignals.support_power_targeting_finished.connect(record_finished)

	var orbital_id = Constants.Match.SupportPowers.ORBITAL_STRIKE
	var orbital_button = _support_powers.find_child("OrbitalStrikeButton")
	_support_powers._unhandled_key_input(_key_event(KEY_F2))
	assert(_support_powers._armed_power_id == orbital_id, "F2 should arm orbital strike targeting")
	assert(orbital_button.button_pressed, "orbital strike button should show hotkey-armed state")
	assert(
		started_power_ids.has(orbital_id),
		"support power hotkeys should emit the targeting-started signal"
	)

	_support_powers._unhandled_key_input(_key_event(KEY_F2))
	assert(
		_support_powers._armed_power_id == "",
		"pressing the armed support hotkey again should cancel targeting"
	)
	assert(not orbital_button.button_pressed, "orbital strike button should clear its pressed state")
	assert(
		finished_power_ids.has(orbital_id),
		"canceling a hotkey-armed support power should emit targeting-finished"
	)

	MatchSignals.support_power_targeting_started.disconnect(record_started)
	MatchSignals.support_power_targeting_finished.disconnect(record_finished)


func _assert_support_power_hotkeys_assigned():
	var expected_hotkeys = {
		"RadarSweepButton": ["F1", KEY_F1],
		"OrbitalStrikeButton": ["F2", KEY_F2],
		"EmpPulseButton": ["F3", KEY_F3],
		"ChronoRelayButton": ["F4", KEY_F4],
		"ShieldOverdriveButton": ["F5", KEY_F5],
		"NaniteRepairSwarmButton": ["F6", KEY_F6],
		"WeatherStormButton": ["F7", KEY_F7],
		"StrategicMissileButton": ["F8", KEY_F8],
		"ParadropButton": ["F9", KEY_F9],
	}
	for button_name in expected_hotkeys:
		var button = _support_powers.find_child(button_name)
		var display = expected_hotkeys[button_name][0]
		var keycode = expected_hotkeys[button_name][1]
		var label = button.find_child(SupportPowersScript.HOTKEY_LABEL_NAME, true, false)
		assert(label != null, button_name + " should show a support-power hotkey label")
		assert(label.text == display, button_name + " should show hotkey " + display)
		assert(
			button.get_meta(SupportPowersScript.META_HOTKEY_DISPLAY) == display,
			button_name + " should store the hotkey display"
		)
		assert(
			button.get_meta(SupportPowersScript.META_HOTKEY_KEYCODE) == keycode,
			button_name + " should store the hotkey keycode"
		)
		assert(
			button.tooltip_text.contains(display),
			button_name + " tooltip should mention the support-power hotkey"
		)


func _disable_ai_controllers():
	for child in _enemy.get_children():
		if not child is UnitScript:
			child.queue_free()


func _unit_count_by_scene(player, scene_path):
	return player.get_children().filter(
		func(child):
			return (
				child is UnitScript
				and child.get_script().resource_path.replace(".gd", ".tscn") == scene_path
			)
	).size()


func _units_are_spaced(units):
	for index in range(units.size()):
		for other_index in range(index + 1, units.size()):
			var first = units[index]
			var second = units[other_index]
			var minimum_distance = first.radius + second.radius - 0.05
			if first.global_position_yless.distance_to(second.global_position_yless) < minimum_distance:
				return false
	return true


func _key_event(keycode):
	var event = InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	event.physical_keycode = keycode
	return event
