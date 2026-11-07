extends Node3D

# A small native physics city, generated in bounded chunks around the player.
const CELL := 44.0
const RADIUS := 2
var chunks: Dictionary = {}
var anchors: Array[Vector3] = []
var player: CharacterBody3D

func _ready() -> void:
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
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(key.x * 73856093 ^ key.y * 19349663) + 913
	var sidewalk := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(33, 0.25, 33)
	sidewalk.mesh = slab
	sidewalk.position = Vector3((key.x + 0.5) * CELL, 0.01, (key.y + 0.5) * CELL)
	sidewalk.material_override = material(Color("777d7e"))
	chunk.add_child(sidewalk)
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
			visual.material_override = material(Color.from_hsv(rng.randf_range(0.04, 0.14), 0.13, rng.randf_range(0.42, 0.67)))
			building.add_child(visual)
			var collision := CollisionShape3D.new()
			collision.shape = shape
			building.add_child(collision)
			chunk.add_child(building)
			for side_x in [-1, 1]:
				for side_z in [-1, 1]:
					roofs.append(center + Vector3(side_x * (size.x * 0.5 + 0.3), height + 0.25, side_z * (size.z * 0.5 + 0.3)))
	chunk.set_meta("anchors", roofs)
