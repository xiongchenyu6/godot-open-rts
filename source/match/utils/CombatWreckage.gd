extends Node3D

const DEFAULT_LIFETIME = 18.0
const SCORCH_MATERIAL_COLOR = Color(0.025, 0.021, 0.018, 0.78)
const DEBRIS_BASE_COLOR = Color(0.12, 0.13, 0.13, 1.0)

var radius = 1.0
var team_color = Color(0.7, 0.7, 0.7, 1.0)
var lifetime = DEFAULT_LIFETIME

var _age = 0.0
var _fade_materials = []


func _ready():
	add_to_group("combat_wreckage")
	_build_scorch_mark()
	_build_debris()


func _process(delta):
	_age += delta
	var fade = clampf(1.0 - (_age / lifetime), 0.0, 1.0)
	for material in _fade_materials:
		var color = material.albedo_color
		color.a = min(color.a, fade)
		material.albedo_color = color
	if _age >= lifetime:
		queue_free()


func _build_scorch_mark():
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = SCORCH_MATERIAL_COLOR
	_fade_materials.append(material)

	var mesh = CylinderMesh.new()
	mesh.top_radius = maxf(radius * 0.72, 0.55)
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.025
	mesh.radial_segments = 20

	var scorch = MeshInstance3D.new()
	scorch.name = "ScorchMark"
	scorch.mesh = mesh
	scorch.material_override = material
	scorch.position = Vector3(0.0, 0.012, 0.0)
	add_child(scorch)


func _build_debris():
	var rng = RandomNumberGenerator.new()
	rng.seed = _seed_from_position()
	var debris_count = 4 + int(radius > 1.0)
	for index in range(debris_count):
		var material = _create_debris_material(index)
		_fade_materials.append(material)

		var mesh = BoxMesh.new()
		var side = rng.randf_range(0.18, 0.34) * maxf(radius, 0.8)
		mesh.size = Vector3(side, side * rng.randf_range(0.35, 0.7), side * rng.randf_range(0.7, 1.35))

		var debris = MeshInstance3D.new()
		debris.name = "Debris{0}".format([index])
		debris.mesh = mesh
		debris.material_override = material
		var angle = rng.randf_range(0.0, TAU)
		var distance = rng.randf_range(radius * 0.12, radius * 0.55)
		debris.position = Vector3(cos(angle) * distance, mesh.size.y * 0.5 + 0.035, sin(angle) * distance)
		debris.rotation = Vector3(
			rng.randf_range(-0.22, 0.22), rng.randf_range(0.0, TAU), rng.randf_range(-0.22, 0.22)
		)
		add_child(debris)


func _create_debris_material(index):
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = DEBRIS_BASE_COLOR.lerp(team_color, 0.18 + float(index % 2) * 0.08)
	material.roughness = 0.85
	material.metallic = 0.25
	return material


func _seed_from_position():
	var x = int(round(global_position.x * 100.0))
	var z = int(round(global_position.z * 100.0))
	return abs((x * 73856093) ^ (z * 19349663) ^ 0x5A17)
