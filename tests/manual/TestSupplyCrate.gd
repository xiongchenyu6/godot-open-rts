extends "res://tests/manual/Match.gd"

@onready var _human = $Players/Human
@onready var _worker = $Players/Human/Worker
@onready var _tank = $Players/Human/Tank
@onready var _rifle = $Players/Human/LightRifleInfantry
@onready var _enemy_tank = $Players/Enemy/Tank
@onready var _resource_crate = $SupplyCrates/ResourceCrate
@onready var _repair_crate = $SupplyCrates/RepairCrate
@onready var _veterancy_crate = $SupplyCrates/VeterancyCrate


func _ready():
	super()
	await get_tree().process_frame

	var collected_effects = []
	MatchSignals.supply_crate_collected.connect(
		func(_crate, _unit, effect_type): collected_effects.append(effect_type)
	)

	_tank.attack_domains = []
	_rifle.attack_domains = []
	_enemy_tank.attack_domains = []
	_worker.process_mode = Node.PROCESS_MODE_DISABLED
	_tank.process_mode = Node.PROCESS_MODE_DISABLED
	_rifle.process_mode = Node.PROCESS_MODE_DISABLED
	_enemy_tank.process_mode = Node.PROCESS_MODE_DISABLED
	_worker.global_position = _resource_crate.global_position + Vector3(0.15, 0.0, 0.0)
	var resource_a_before = _human.resource_a
	var resource_b_before = _human.resource_b
	var resource_a_bonus = _resource_crate.resource_a_bonus
	var resource_b_bonus = _resource_crate.resource_b_bonus
	assert(
		_resource_crate._can_collect(_worker),
		"worker should be able to collect resource crate: distance={0} speed={1} unit_count={2}".format(
			[
				_resource_crate.global_position_yless.distance_to(_worker.global_position_yless),
				_worker.movement_speed,
				get_tree().get_nodes_in_group("units").size(),
			]
		)
	)
	assert(_resource_crate.collect(_worker), "resource crate should be collected by worker")
	await _wait_for_crate_to_leave(_resource_crate)
	assert(
		_human.resource_a == resource_a_before + resource_a_bonus,
		"resource crate should grant blue crystal"
	)
	assert(
		_human.resource_b == resource_b_before + resource_b_bonus,
		"resource crate should grant red crystal"
	)

	_tank.global_position = _repair_crate.global_position + Vector3(0.15, 0.0, 0.0)
	_rifle.global_position = _repair_crate.global_position + Vector3(1.4, 0.0, 0.0)
	_enemy_tank.global_position = _repair_crate.global_position + Vector3(1.2, 0.0, 1.2)
	_tank.hp = 2.0
	_rifle.hp = 1.0
	_enemy_tank.hp = 2.0
	assert(_repair_crate.collect(_tank), "repair crate should be collected by tank")
	await _wait_for_crate_to_leave(_repair_crate)
	assert(_tank.hp > 2.0, "repair crate should repair the collecting unit")
	assert(_rifle.hp > 1.0, "repair crate should repair nearby friendly units")
	assert(_enemy_tank.hp == 2.0, "repair crate should not repair enemy units")

	_rifle.global_position = _veterancy_crate.global_position + Vector3(0.15, 0.0, 0.0)
	var rank_before = _rifle.veterancy_rank
	assert(_veterancy_crate.collect(_rifle), "veterancy crate should be collected by infantry")
	await _wait_for_crate_to_leave(_veterancy_crate)
	assert(_rifle.veterancy_rank == rank_before + 1, "veterancy crate should promote collector")
	assert(
		collected_effects == ["resources", "repair", "veterancy"],
		"supply crate signal should report each collected effect"
	)

	get_tree().quit()


func _wait_for_crate_to_leave(crate, max_frames = 12):
	for _i in range(max_frames):
		await get_tree().process_frame
		if not is_instance_valid(crate) or not crate.is_inside_tree():
			return
	assert(false, "supply crate should be collected")
