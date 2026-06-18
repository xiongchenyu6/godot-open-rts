const Structure = preload("res://source/match/units/Structure.gd")


static func can_construct(player, structure_scene_path):
	return missing_construction_requirements(player, structure_scene_path).is_empty()


static func can_produce(player, unit_scene_path):
	return missing_production_requirements(player, unit_scene_path).is_empty()


static func missing_construction_requirements(player, structure_scene_path):
	return _missing_requirements(
		player, Constants.Match.Units.CONSTRUCTION_REQUIREMENTS.get(structure_scene_path, [])
	)


static func missing_production_requirements(player, unit_scene_path):
	return _missing_requirements(
		player, Constants.Match.Units.PRODUCTION_REQUIREMENTS.get(unit_scene_path, [])
	)


static func requirement_names(requirement_paths):
	var names = []
	for requirement_path in requirement_paths:
		names.append(
			TranslationServer.translate(Constants.Match.Units.STRUCTURE_NAME_KEYS[requirement_path])
		)
	return ", ".join(names)


static func player_has_constructed_structure(player, structure_scene_path):
	for child in player.get_children():
		if not child is Structure:
			continue
		if not child.is_constructed():
			continue
		if child.get_script().resource_path.replace(".gd", ".tscn") == structure_scene_path:
			return true
	return false


static func _missing_requirements(player, requirement_paths):
	var missing_requirements = []
	for requirement_path in requirement_paths:
		if not player_has_constructed_structure(player, requirement_path):
			missing_requirements.append(requirement_path)
	return missing_requirements
