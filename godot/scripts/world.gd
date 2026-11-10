extends Node3D

# A small native physics city, generated in bounded chunks around the player.
const CELL := 44.0
const RADIUS := 2
var chunks: Dictionary = {}
var anchors: Array[Vector3] = []
var last_chunk_center := Vector2i(2147483647, 2147483647)
var stream_revision := 0
var player: CharacterBody3D
const FACADE = preload("res://scripts/facade.gdshader")
const STREET_SURFACE = preload("res://scripts/street_surface.gdshader")
const SIGN_TEXTURES = [preload("res://assets/signs/comics.png"), preload("res://assets/signs/pizza.png"), preload("res://assets/signs/bugle.png"), preload("res://assets/signs/cafe.png")]
var sign_materials: Array[StandardMaterial3D] = []
var paint_material: StandardMaterial3D
var roof_material: StandardMaterial3D
var grass_material: StandardMaterial3D
var leaf_material: StandardMaterial3D
var trunk_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var awning_material: StandardMaterial3D
var metal_material: StandardMaterial3D
var facade_material: ShaderMaterial
var sidewalk_material: ShaderMaterial
var tank_material: StandardMaterial3D
var path_material: StandardMaterial3D
var neon_cyan_material: StandardMaterial3D
var neon_pink_material: StandardMaterial3D
var neon_city := false

func _ready() -> void:
	facade_material = ShaderMaterial.new()
	facade_material.shader = FACADE
	for texture in SIGN_TEXTURES:
		var sign := StandardMaterial3D.new()
		sign.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sign.albedo_texture = texture
		sign_materials.append(sign)
	paint_material = material(Color("f9eab8"))
	roof_material = material(Color("28354b"))
	grass_material = material(Color("68a968"))
	leaf_material = material(Color("3b905d"))
	trunk_material = material(Color("76533f"))
	glass_material = material(Color("246078"))
	awning_material = material(Color("e04a50"))
	metal_material = material(Color("38474c"))
	sidewalk_material = surface_material(Color("b8b7a9"), 0.06)
	tank_material = material(Color("b2764f"))
	path_material = material(Color("ddcda1"))
	neon_cyan_material = neon_material(Color("57e8ff"))
	neon_pink_material = neon_material(Color("ff3cb9"))
	var ground := StaticBody3D.new()
	var ground_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2000, 1, 2000)
	ground_shape.shape = box
	ground_shape.position.y = -0.5
	ground.add_child(ground_shape)
	add_child(ground)
	var ground_mesh := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2000, 0.2, 2000)
	ground_mesh.mesh = mesh
	ground_mesh.position.y = -0.11
	ground_mesh.material_override = surface_material(Color("40536b"), 0.08)
	add_child(ground_mesh)
	# The floor is finite; invisible boundaries prevent falling beyond it.
	for side in [-1, 1]:
		for axis in [0, 1]:
			var wall := StaticBody3D.new()
			var wall_shape := CollisionShape3D.new()
			var wall_box := BoxShape3D.new()
			wall_box.size = Vector3(4, 500, 1900) if axis == 0 else Vector3(1900, 500, 4)
			wall_shape.shape = wall_box
			wall.position = Vector3(side * 925, 200, 0) if axis == 0 else Vector3(0, 200, side * 925)
			wall.add_child(wall_shape)
			add_child(wall)

func neon_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	return mat

func set_neon_city(enabled: bool) -> void:
	neon_city = enabled
	facade_material.set_shader_parameter("night_mix", 1.0 if enabled else 0.0)
	for chunk in chunks.values():
		set_chunk_neon(chunk, enabled)

func set_chunk_neon(chunk: Node3D, enabled: bool) -> void:
	for child in chunk.get_children():
		if child.name == "NeonCyan" or child.name == "NeonPink":
			child.visible = enabled

func surface_material(color: Color, detail: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = STREET_SURFACE
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("detail_strength", detail)
	return mat

func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return mat

func update_chunks(at: Vector3) -> void:
	var cx := floori(at.x / CELL)
	var cz := floori(at.z / CELL)
	var center := Vector2i(cx, cz)
	if center == last_chunk_center:
		return
	last_chunk_center = center
	stream_revision += 1
	for x in range(cx - RADIUS, cx + RADIUS + 1):
		for z in range(cz - RADIUS, cz + RADIUS + 1):
			var key := Vector2i(x, z)
			if abs(x) > 21 or abs(z) > 21:
				continue
			if not chunks.has(key):
				make_chunk(key)
	for key in chunks.keys():
		if abs(key.x - cx) > RADIUS or abs(key.y - cz) > RADIUS:
			chunks[key].queue_free()
			chunks.erase(key)
	anchors.clear()
	for chunk in chunks.values():
		for p in chunk.get_meta("anchors"):
			anchors.append(p)

func district_for(key: Vector2i) -> String:
	if key.x >= 4:
		return "Industrial"
	if key.x <= -4:
		return "Residential"
	if absi(key.x) <= 2 and absi(key.y) <= 2:
		return "Downtown"
	return "Midtown"

func make_chunk(key: Vector2i) -> void:
	var chunk := Node3D.new()
	chunk.name = "Block_%d_%d" % [key.x, key.y]
	add_child(chunk)
	chunks[key] = chunk
	var district := district_for(key)
	chunk.set_meta("district", district)
	var roofs: Array[Vector3] = []
	var building_transforms: Array[Transform3D] = []
	var building_colors: Array[Color] = []
	var rooftop_details: Array[Transform3D] = []
	var tanks: Array[Transform3D] = []
	var tank_roofs: Array[Transform3D] = []
	var tank_legs: Array[Transform3D] = []
	var doors: Array[Transform3D] = []
	var awnings: Array[Transform3D] = []
	var street_furniture: Array[Transform3D] = []
	var neon_cyan: Array[Transform3D] = []
	var neon_pink: Array[Transform3D] = []
	var road_marks: Array[Transform3D] = []
	var sign_comics: Array[Transform3D] = []
	var sign_pizza: Array[Transform3D] = []
	var sign_bugle: Array[Transform3D] = []
	var sign_cafe: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(key.x * 73856093 ^ key.y * 19349663) + 913
	var sidewalk := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(33, 0.25, 33)
	sidewalk.mesh = slab
	sidewalk.position = Vector3((key.x + 0.5) * CELL, 0.01, (key.y + 0.5) * CELL)
	var is_park := absi(key.x * 7 + key.y * 11) % 17 == 5
	sidewalk.material_override = grass_material if is_park else sidewalk_material
	chunk.add_child(sidewalk)
	# Dashed lane markings and pedestrian crossings, batched per city block.
	var ox := key.x * CELL
	var oz := key.y * CELL
	for i in range(4):
		road_marks.append(Transform3D(Basis.from_scale(Vector3(0.12, 0.02, 3.0)), Vector3(ox, 0.025, oz + 11 + i * 8)))
		road_marks.append(Transform3D(Basis.from_scale(Vector3(3.0, 0.02, 0.12)), Vector3(ox + 11 + i * 8, 0.025, oz)))
	for i in range(-2, 3):
		road_marks.append(Transform3D(Basis.from_scale(Vector3(0.55, 0.02, 2.0)), Vector3(ox + i * 1.7, 0.03, oz + 6)))
		road_marks.append(Transform3D(Basis.from_scale(Vector3(2.0, 0.02, 0.55)), Vector3(ox + 6, 0.03, oz + i * 1.7)))
	add_instances(chunk, road_marks, paint_material)
	# Street lights stay outside the drivable road and are batched per block.
	for dz in [9.0, 35.0]:
		street_furniture.append(Transform3D(Basis.from_scale(Vector3(0.18, 4.0, 0.18)), Vector3(ox + 5.2, 2, oz + dz)))
		street_furniture.append(Transform3D(Basis.from_scale(Vector3(0.6, 0.18, 0.4)), Vector3(ox + 5.0, 4, oz + dz)))
	add_instances(chunk, street_furniture, metal_material)
	if is_park:
		add_park(chunk, key, rng)
		chunk.set_meta("anchors", roofs)
		return
	for dx in [-1, 1]:
		for dz in [-1, 1]:
			var center := Vector3((key.x + 0.5) * CELL + dx * 8.2, 0, (key.y + 0.5) * CELL + dz * 8.2)
			var height := rng.randf_range(24, 53) if district == "Downtown" else (rng.randf_range(9, 20) if district == "Residential" else (rng.randf_range(10, 24) if district == "Industrial" else rng.randf_range(13, 30)))
			var size := Vector3(rng.randf_range(12, 15), height, rng.randf_range(12, 15))
			var building := StaticBody3D.new()
			building.position = center + Vector3.UP * height * 0.5
			var shape := BoxShape3D.new()
			shape.size = size
			building_transforms.append(Transform3D(Basis.from_scale(size), building.position))
			# Graphic edge strips are batched geometry, not dynamic lights: this keeps
			# the optional night palette inexpensive on mobile hardware.
			if district in ["Downtown", "Midtown"] and rng.randi_range(0, 2) != 0:
				var strip_x: float = center.x + dx * (size.x * 0.5 + 0.09)
				var strips: Array[Transform3D] = neon_cyan if rng.randi_range(0, 1) == 0 else neon_pink
				strips.append(Transform3D(Basis.from_scale(Vector3(0.12, height * 0.62, 0.18)), Vector3(strip_x, height * 0.60, center.z + dz * (size.z * 0.5 - 0.35))))
				strips.append(Transform3D(Basis.from_scale(Vector3(0.12, 0.18, size.z * 0.85)), Vector3(strip_x, height * 0.90, center.z)))
			var palette := [Color("d17b76"), Color("e4a27e"), Color("7c8da6"), Color("af84a1"), Color("d39a92"), Color("9c9bb0")]
			if district == "Residential":
				palette = [Color("e5ae88"), Color("c98985"), Color("e7c78a"), Color("91b3a2")]
			elif district == "Industrial":
				palette = [Color("b97b65"), Color("c08d66"), Color("9a9c91"), Color("a78978")]
			building_colors.append(palette[rng.randi_range(0, palette.size() - 1)])
			var collision := CollisionShape3D.new()
			collision.shape = shape
			building.add_child(collision)
			chunk.add_child(building)
			rooftop_details.append(Transform3D(Basis.from_scale(Vector3(2.8, 1.3, 2.3)), center + Vector3(0, height + 0.65, 0)))
			rooftop_details.append(Transform3D(Basis.from_scale(Vector3(size.x + 0.3, 0.35, size.z + 0.3)), center + Vector3.UP * height))
			# Familiar rooftop water tanks add silhouette variety without extra collision.
			if rng.randi_range(0, 2) == 0:
				var tank_pos := center + Vector3(3.2 * dx, height, 0)
				tanks.append(Transform3D(Basis.from_scale(Vector3(2.2, 1.15, 2.2)), tank_pos + Vector3.UP * 3.0))
				tank_roofs.append(Transform3D(Basis.from_scale(Vector3(2.5, 0.9, 2.5)), tank_pos + Vector3.UP * 4.6))
				for tx in [-0.75, 0.75]:
					for tz in [-0.75, 0.75]:
						tank_legs.append(Transform3D(Basis.from_scale(Vector3(0.14, 1.8, 0.14)), tank_pos + Vector3(tx, 0.9, tz)))
			doors.append(Transform3D(Basis.from_scale(Vector3(0.1, 3.0, 2.3)), center + Vector3(dx * (size.x * 0.5 + 0.06), 1.5, 0)))
			awnings.append(Transform3D(Basis.from_scale(Vector3(1.1, 0.25, 3.2)), center + Vector3(dx * (size.x * 0.5 + 0.5), 3.2, 0)))
			var sign_basis := Basis(Vector3.UP, dx * PI * 0.5) * Basis.from_scale(Vector3(3.5, 1.3, 1))
			var sign_transform := Transform3D(sign_basis, center + Vector3(dx * (size.x * 0.5 + 0.08), 4.6, 0))
			match rng.randi_range(0, 3):
				0: sign_comics.append(sign_transform)
				1: sign_pizza.append(sign_transform)
				2: sign_bugle.append(sign_transform)
				3: sign_cafe.append(sign_transform)
			for side_x in [-1, 1]:
				for side_z in [-1, 1]:
					roofs.append(center + Vector3(side_x * (size.x * 0.5 + 0.3), height + 0.25, side_z * (size.z * 0.5 + 0.3)))
	add_buildings(chunk, building_transforms, building_colors)
	if not neon_cyan.is_empty():
		var cyan := add_instances(chunk, neon_cyan, neon_cyan_material)
		cyan.name = "NeonCyan"
		cyan.visible = neon_city
	if not neon_pink.is_empty():
		var pink := add_instances(chunk, neon_pink, neon_pink_material)
		pink.name = "NeonPink"
		pink.visible = neon_city
	add_instances(chunk, rooftop_details, roof_material)
	if not tanks.is_empty():
		var tank_mesh := CylinderMesh.new()
		var tank_roof := CylinderMesh.new()
		tank_roof.top_radius = 0
		tank_roof.bottom_radius = 0.5
		tank_roof.height = 1
		add_instances(chunk, tanks, tank_material, tank_mesh)
		add_instances(chunk, tank_roofs, roof_material, tank_roof)
		add_instances(chunk, tank_legs, metal_material)
	chunk.set_meta("water_tanks", tanks.size())
	add_instances(chunk, doors, glass_material)
	add_instances(chunk, awnings, awning_material)
	add_signs(chunk, sign_comics, sign_materials[0])
	add_signs(chunk, sign_pizza, sign_materials[1])
	add_signs(chunk, sign_bugle, sign_materials[2])
	add_signs(chunk, sign_cafe, sign_materials[3])
	chunk.set_meta("anchors", roofs)

func add_signs(parent: Node3D, transforms: Array[Transform3D], mat: Material) -> void:
	if transforms.is_empty():
		return
	var quad := QuadMesh.new()
	add_instances(parent, transforms, mat, quad)

func add_park(parent: Node3D, key: Vector2i, rng: RandomNumberGenerator) -> void:
	var trunks: Array[Transform3D] = []
	var canopies: Array[Transform3D] = []
	var paths: Array[Transform3D] = []
	var benches: Array[Transform3D] = []
	var middle := Vector3((key.x + 0.5) * CELL, 0, (key.y + 0.5) * CELL)
	paths.append(Transform3D(Basis.from_scale(Vector3(3, 0.04, 31)), middle + Vector3.UP * 0.15))
	paths.append(Transform3D(Basis.from_scale(Vector3(31, 0.04, 3)), middle + Vector3.UP * 0.15))
	for side in [-1, 1]:
		var b := middle + Vector3(side * 4.3, 0, 4.2)
		benches.append(Transform3D(Basis.from_scale(Vector3(2.5, 0.18, 0.65)), b + Vector3.UP * 0.65))
		benches.append(Transform3D(Basis.from_scale(Vector3(2.5, 0.7, 0.14)), b + Vector3(0, 1.05, 0.3)))
		for leg in [-0.85, 0.85]:
			benches.append(Transform3D(Basis.from_scale(Vector3(0.15, 0.5, 0.15)), b + Vector3(leg, 0.37, 0)))
	add_instances(parent, paths, path_material)
	add_instances(parent, benches, tank_material)
	for x in [-1, 0, 1]:
		for z in [-1, 1]:
			var p := Vector3((key.x + 0.5) * CELL + x * 10.0, 0, (key.y + 0.5) * CELL + z * 8.0)
			var height := rng.randf_range(3.0, 4.5)
			trunks.append(Transform3D(Basis.from_scale(Vector3(0.55, height, 0.55)), p + Vector3.UP * height * 0.5))
			canopies.append(Transform3D(Basis.from_scale(Vector3(2.6, 2.4, 2.6)), p + Vector3.UP * (height + 1.1)))
	add_instances(parent, trunks, trunk_material)
	var foliage := SphereMesh.new()
	add_instances(parent, canopies, leaf_material, foliage)

func add_instances(parent: Node3D, transforms: Array[Transform3D], mat: Material, supplied_mesh: PrimitiveMesh = null) -> MultiMeshInstance3D:
	var mesh: PrimitiveMesh = supplied_mesh if supplied_mesh else BoxMesh.new()
	mesh.material = mat
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multi
	parent.add_child(instance)
	return instance

# Draw the four building facades in each block as a single instanced mesh,
# while retaining independent physics bodies and roof anchors.
func add_buildings(parent: Node3D, transforms: Array[Transform3D], colors: Array[Color]) -> void:
	var cube := BoxMesh.new()
	cube.material = facade_material
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = cube
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, colors[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = "BuildingFacades"
	instance.multimesh = multi
	parent.add_child(instance)
