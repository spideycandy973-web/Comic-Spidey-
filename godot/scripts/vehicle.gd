extends CharacterBody3D

var game
var axis := 0
var travel_sign := 1.0
var lane := 2.5
var speed := 8.0
var visual: Node3D

func setup(index: int) -> void:
	axis = index % 2
	travel_sign = -1.0 if (index / 2) % 2 == 0 else 1.0
	lane = 2.5 * travel_sign
	speed = 7.0 + (index % 3)
	collision_layer = 4
	collision_mask = 3
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.7, 1.1, 3.7)
	collision.shape = box
	collision.position.y = 0.8
	if axis == 1:
		collision.rotation.y = PI * 0.5
	add_child(collision)
	visual = Node3D.new()
	add_child(visual)
	if axis == 0:
		visual.rotation.y = 0 if travel_sign < 0 else PI
	else:
		visual.rotation.y = PI * 0.5 if travel_sign < 0 else -PI * 0.5
	var body_color: Color = [Color("b85440"), Color("52718a"), Color("d3b36c"), Color("63796a")][index % 4]
	make_box(Vector3(1.7, 0.65, 3.7), Vector3(0, 0.7, 0), body_color)
	make_box(Vector3(1.45, 0.65, 1.8), Vector3(0, 1.3, 0.1), Color("385f75"))
	make_box(Vector3(1.5, 0.15, 1.9), Vector3(0, 1.65, 0.1), body_color)
	make_box(Vector3(1.65, 0.17, 0.15), Vector3(0, 0.45, -1.9), Color("253246"))
	make_box(Vector3(1.65, 0.17, 0.15), Vector3(0, 0.45, 1.9), Color("253246"))
	var tire := CylinderMesh.new()
	tire.top_radius = 0.37
	tire.bottom_radius = 0.37
	tire.height = 0.26
	tire.radial_segments = 12
	var tire_mat := StandardMaterial3D.new()
	tire_mat.albedo_color = Color("1d2733")
	tire_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	tire.material = tire_mat
	var hub := CylinderMesh.new()
	hub.top_radius = 0.16
	hub.bottom_radius = 0.16
	hub.height = 0.28
	hub.radial_segments = 12
	var hub_mat := StandardMaterial3D.new()
	hub_mat.albedo_color = Color("c9d7d6")
	hub_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	hub.material = hub_mat
	for side in [-1, 1]:
		for z in [-1.15, 1.15]:
			var wheel := MeshInstance3D.new()
			wheel.name = "Wheel_%s_%s" % ["L" if side < 0 else "R", "Front" if z < 0 else "Rear"]
			wheel.mesh = tire
			wheel.rotation.z = PI * 0.5
			wheel.position = Vector3(side * 0.9, 0.38, z)
			visual.add_child(wheel)
			var cap := MeshInstance3D.new()
			cap.mesh = hub
			cap.rotation.z = PI * 0.5
			cap.position = Vector3(side * 0.91, 0.38, z)
			visual.add_child(cap)
		make_box(Vector3(0.3, 0.2, 0.08), Vector3(side * 0.55, 0.75, -1.88), Color("fff0a2"))
		make_box(Vector3(0.3, 0.16, 0.08), Vector3(side * 0.55, 0.75, 1.88), Color("e75550"))
		make_box(Vector3(0.04, 0.05, 0.3), Vector3(side * 0.86, 0.95, 0.55), Color("e3e1cf"))
	recenter(index)

func make_box(size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mesh.material = mat
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	visual.add_child(instance)

func recenter(index: int = 0) -> void:
	var player: Vector3 = game.hero.global_position
	var offset := (55.0 + (index % 3) * 15.0) * -travel_sign
	var candidate := Vector3.ZERO
	# At city limits clamping the preferred side could place traffic on the
	# player. Try the other side and avoid teleporting onto pedestrians/cars.
	for side in [1.0, -1.0]:
		if axis == 0:
			candidate = Vector3(roundf(player.x / 44.0) * 44.0 + lane, 0.05, clampf(player.z + offset * side, -900, 900))
		else:
			candidate = Vector3(clampf(player.x + offset * side, -900, 900), 0.05, roundf(player.z / 44.0) * 44.0 + lane)
		var clear := candidate.distance_to(player) > 10.0
		for actor in game.people + game.traffic:
			if is_instance_valid(actor) and actor != self and not actor.is_queued_for_deletion() and actor.global_position.distance_to(candidate) < 6.0:
				clear = false
				break
		if clear:
			global_position = candidate
			break
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game.hero) or not game.hero.playing:
		return
	if global_position.distance_to(game.hero.global_position) > 115:
		recenter(get_instance_id() % 3)
	var heading := Vector3(0, 0, travel_sign) if axis == 0 else Vector3(travel_sign, 0, 0)
	var should_stop := false
	var pedestrians: Array = game.people.duplicate()
	pedestrians.append(game.hero)
	for person in pedestrians:
		if is_instance_valid(person) and not person.is_queued_for_deletion() and absf(person.global_position.y - global_position.y) < 2.5:
			var diff: Vector3 = person.global_position - global_position
			diff.y = 0
			var ahead := diff.dot(heading)
			var lateral := (diff - heading * ahead).length()
			if ahead > -0.5 and ahead < 5.0 and lateral < 1.7:
				should_stop = true
				break
	var target := 0.0 if should_stop else speed
	var current := Vector2(velocity.x, velocity.z).length()
	var next := move_toward(current, target, 15.0 * delta)
	velocity.x = heading.x * next
	velocity.z = heading.z * next
	velocity.y -= 18.0 * delta
	var impact_velocity := velocity
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var hit := get_slide_collision(i)
		if hit.get_collider() == game.hero:
			game.hero.vehicle_impact(impact_velocity, hit.get_normal())
