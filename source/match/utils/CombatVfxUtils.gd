const CombatImpactAnimation = preload("res://source/match/utils/CombatImpactAnimation.tscn")
const CombatWreckage = preload("res://source/match/utils/CombatWreckage.gd")
const FadedCircle3D = preload("res://source/generic-scenes-and-nodes/3d/FadedCircle3D.tscn")

const PROMOTION_EFFECT_LIFETIME = 1.1
const PROMOTION_RANK_COLORS = [
	Color(1.0, 0.78, 0.16, 0.78),
	Color(0.18, 0.9, 1.0, 0.82),
]
const PROMOTION_RANK_LABELS = ["V", "E"]


static func spawn_impact_at_unit(unit, scale_multiplier = 1.0):
	if unit == null or not is_instance_valid(unit) or not unit.is_inside_tree():
		return
	if "visible" in unit and not unit.visible:
		return
	var radius = 1.0
	if "radius" in unit and unit.radius != null:
		radius = max(0.8, unit.radius)
	spawn_impact(unit.get_parent(), unit.global_position + Vector3(0, 0.35, 0), radius * scale_multiplier)


static func spawn_wreckage_at_unit(unit):
	if unit == null or not is_instance_valid(unit) or not unit.is_inside_tree():
		return
	if "visible" in unit and not unit.visible:
		return
	var parent = unit.get_parent()
	if parent == null or not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	var wreckage = CombatWreckage.new()
	if "radius" in unit and unit.radius != null:
		wreckage.radius = maxf(0.7, unit.radius)
	if "color" in unit:
		wreckage.team_color = unit.color
	wreckage.position = parent.to_local(unit.global_position)
	parent.add_child(wreckage)


static func spawn_promotion_at_unit(unit, rank):
	if unit == null or not is_instance_valid(unit) or not unit.is_inside_tree():
		return
	if "visible" in unit and not unit.visible:
		return
	var parent = unit.get_parent()
	if parent == null or not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	var radius = 1.0
	if "radius" in unit and unit.radius != null:
		radius = maxf(0.75, unit.radius)
	var rank_index = clampi(rank - 1, 0, PROMOTION_RANK_COLORS.size() - 1)
	var effect = Node3D.new()
	effect.name = "VeterancyPromotionEffect"
	effect.add_to_group("veterancy_promotion_effects")
	parent.add_child(effect)
	effect.global_position = unit.global_position + Vector3(0.0, 0.08, 0.0)

	var ring = FadedCircle3D.instantiate()
	ring.name = "PromotionRing"
	ring.radius = radius * 1.45
	ring.width = 42.0
	ring.inner_edge_width = 18.0
	ring.outer_edge_width = 10.0
	ring.color = PROMOTION_RANK_COLORS[rank_index]
	ring.render_priority = 5
	effect.add_child(ring)

	var label = Label3D.new()
	label.name = "PromotionRankLabel"
	label.text = PROMOTION_RANK_LABELS[rank_index]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 48
	label.modulate = Color(
		PROMOTION_RANK_COLORS[rank_index].r,
		PROMOTION_RANK_COLORS[rank_index].g,
		PROMOTION_RANK_COLORS[rank_index].b,
		1.0
	)
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.92)
	label.outline_size = 8
	label.position = Vector3(0.0, radius + 0.65, 0.0)
	effect.add_child(label)

	spawn_impact(parent, unit.global_position + Vector3(0.0, 0.45, 0.0), radius * 0.9)
	var timer = Timer.new()
	timer.one_shot = true
	effect.add_child(timer)
	timer.timeout.connect(effect.queue_free)
	timer.start(PROMOTION_EFFECT_LIFETIME)


static func spawn_impact(parent, global_position, scale_multiplier = 1.0):
	if parent == null or not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	var animation = CombatImpactAnimation.instantiate()
	parent.add_child(animation)
	animation.global_position = global_position
	animation.scale = Vector3.ONE * scale_multiplier
