extends Node3D

# A small native physics city, generated in bounded chunks around the player.
const CELL := 44.0
const RADIUS := 2
var chunks: Dictionary = {}
var anchors: Array[Vector3] = []
var player: CharacterBody3D
const FACADE = preload("res://scripts/facade.gdshader")
var paint_material: StandardMaterial3D
var roof_material: StandardMaterial3D
var grass_material: StandardMaterial3D
var leaf_material: StandardMaterial3D
var trunk_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var awning_material: StandardMaterial3D
var metal_material: StandardMaterial3D

func _ready() -> void:
	paint_material = material(Color("ded9bb"))
	roof_material = material(Color("585f62"))
	grass_material = material(Color("54794a"))
	leaf_material = material(Color("386839"))
	trunk_material = material(Color("6b5035"))
	glass_material = material(Color("223b4b"))
	awning_material = material(Color("a84b40"))
	metal_material = material(Color("38474c"))
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
	ground_mesh.material_override = material(Color("424b54"))
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

func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat

func update_chunks(at: Vector3) -> void:
	var cx := floori(at.x / CELL)
	var cz := floori(at.z / CELL)
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

func make_chunk(key: Vector2i) -> void:
	var chunk := Node3D.new()
	chunk.name = "Block_%d_%d" % [key.x, key.y]
	add_child(chunk)
	chunks[key] = chunk
	var roofs: Array[Vector3] = []
	var rooftop_details: Array[Transform3D] = []
	var doors: Array[Transform3D] = []
	var awnings: Array[Transform3D] = []
	var street_furniture: Array[Transform3D] = []
	var road_marks: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(key.x * 73856093 ^ key.y * 19349663) + 913
	var sidewalk := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(33, 0.25, 33)
	sidewalk.mesh = slab
	sidewalk.position = Vector3((key.x + 0.5) * CELL, 0.01, (key.y + 0.5) * CELL)
	var is_park := absi(key.x * 7 + key.y * 11) % 17 == 5
	sidewalk.material_override = grass_material if is_park else material(Color("777d7e"))
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
			var height := rng.randf_range(12, 34)
			var size := Vector3(rng.randf_range(12, 15), height, rng.randf_range(12, 15))
			var building := StaticBody3D.new()
			building.position = center + Vector3.UP * height * 0.5
			var visual := MeshInstance3D.new()
			var shape := BoxShape3D.new()
			var cube := BoxMesh.new()
			cube.size = size
			shape.size = size
			visual.mesh = cube
			var facade := ShaderMaterial.new()
			facade.shader = FACADE
			facade.set_shader_parameter("building_color", Color.from_hsv(rng.randf_range(0.04, 0.14), 0.13, rng.randf_range(0.42, 0.67)))
			visual.material_override = facade
			building.add_child(visual)
			var collision := CollisionShape3D.new()
			collision.shape = shape
			building.add_child(collision)
			chunk.add_child(building)
			rooftop_details.append(Transform3D(Basis.from_scale(Vector3(2.8, 1.3, 2.3)), center + Vector3(0, height + 0.65, 0)))
			rooftop_details.append(Transform3D(Basis.from_scale(Vector3(size.x + 0.3, 0.35, size.z + 0.3)), center + Vector3.UP * height))
			doors.append(Transform3D(Basis.from_scale(Vector3(0.1, 3.0, 2.3)), center + Vector3(dx * (size.x * 0.5 + 0.06), 1.5, 0)))
			awnings.append(Transform3D(Basis.from_scale(Vector3(1.1, 0.25, 3.2)), center + Vector3(dx * (size.x * 0.5 + 0.5), 3.2, 0)))
			for side_x in [-1, 1]:
				for side_z in [-1, 1]:
					roofs.append(center + Vector3(side_x * (size.x * 0.5 + 0.3), height + 0.25, side_z * (size.z * 0.5 + 0.3)))
	add_instances(chunk, rooftop_details, roof_material)
	add_instances(chunk, doors, glass_material)
	add_instances(chunk, awnings, awning_material)
	chunk.set_meta("anchors", roofs)

func add_park(parent: Node3D, key: Vector2i, rng: RandomNumberGenerator) -> void:
	var trunks: Array[Transform3D] = []
	var canopies: Array[Transform3D] = []
	for x in [-1, 0, 1]:
		for z in [-1, 1]:
			var p := Vector3((key.x + 0.5) * CELL + x * 10.0, 0, (key.y + 0.5) * CELL + z * 8.0)
			var height := rng.randf_range(3.0, 4.5)
			trunks.append(Transform3D(Basis.from_scale(Vector3(0.55, height, 0.55)), p + Vector3.UP * height * 0.5))
			canopies.append(Transform3D(Basis.from_scale(Vector3(2.6, 2.4, 2.6)), p + Vector3.UP * (height + 1.1)))
	add_instances(parent, trunks, trunk_material)
	var foliage := SphereMesh.new()
	add_instances(parent, canopies, leaf_material, foliage)

func add_instances(parent: Node3D, transforms: Array[Transform3D], mat: Material, supplied_mesh: PrimitiveMesh = null) -> void:
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
