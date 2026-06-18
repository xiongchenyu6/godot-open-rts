const Structure = preload("res://source/match/units/Structure.gd")


static func apply_projectile_damage(source_unit, target_unit):
	if not _can_damage(source_unit, target_unit):
		return
	_apply_damage(source_unit, target_unit, _get_damage_amount(source_unit, target_unit))
	if source_unit.splash_radius <= 0.0:
		return
	for splash_target in source_unit.get_tree().get_nodes_in_group("units"):
		if splash_target == target_unit:
			continue
		if not _can_damage(source_unit, splash_target):
			continue
		if not (splash_target.movement_domain in source_unit.attack_domains):
			continue
		if (
			splash_target.global_position_yless.distance_to(target_unit.global_position_yless)
			> source_unit.splash_radius
		):
			continue
		_apply_damage(
			source_unit,
			splash_target,
			_get_damage_amount(source_unit, splash_target)
			* source_unit.splash_damage_multiplier
		)


static func _can_damage(source_unit, target_unit):
	return (
		source_unit != null
		and target_unit != null
		and is_instance_valid(source_unit)
		and is_instance_valid(target_unit)
		and target_unit.is_inside_tree()
		and "hp" in target_unit
		and target_unit.hp != null
		and source_unit.player.is_enemy_with(target_unit.player)
	)


static func _apply_damage(source_unit, target_unit, amount):
	target_unit.register_damage_source(source_unit)
	target_unit.hp -= amount


static func _get_damage_amount(source_unit, target_unit):
	var damage = source_unit.attack_damage
	if target_unit is Structure:
		damage *= source_unit.structure_damage_multiplier
	return damage
