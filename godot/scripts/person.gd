extends CharacterBody3D

var is_enemy := false
var is_boss := false
var health := 60.0
var attack_cooldown := 1.0
var windup := 0.0
var stun := 0.0
var hero
var visual: Node3D
var anim: AnimationPlayer
var origin: Vector3
var walk_time := 0.0
var local_civilian := false
var escorting := false
var stationary := false
var line := "Stay safe out there, Spider-Man."
var marker: MeshInstance3D
var marker_material: StandardMaterial3D

func setup(model: PackedScene, enemy: bool, boss: bool = false) -> void:
	is_enemy = enemy
	is_boss = boss
	health = 200.0 if boss else 60.0
	visual = model.instantiate()
	add_child(visual)
	# Supplied models have different units.
	if boss:
		visual.scale = Vector3.ONE * 1.15
	else:
		visual.scale = Vector3.ONE
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	if is_enemy:
		marker = MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.75 if is_boss else 0.55
		disc.bottom_radius = disc.top_radius
		disc.height = 0.04
		marker.mesh = disc
		marker.position.y = 0.05
		marker_material = StandardMaterial3D.new()
		marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		marker_material.albedo_color = Color(1.0, 0.55, 0.06, 0.8)
		marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		marker.material_override = marker_material
		add_child(marker)
	collision_layer = 2
	collision_mask = 1
	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		anim = players[0]
		if anim.has_animation("walk"):
			anim.play("walk")
	origin = position

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hero) or health <= 0:
		return
	attack_cooldown = maxf(0, attack_cooldown - delta)
	stun = maxf(0, stun - delta)
	var flat: Vector3 = hero.global_position - global_position
	flat.y = 0
	var distance: float = flat.length()
	velocity.y -= 18 * delta
	if is_enemy:
		if windup > 0:
			windup -= delta
			velocity.x = move_toward(velocity.x, 0, delta * 15)
			velocity.z = move_toward(velocity.z, 0, delta * 15)
			if windup <= 0 and distance < (3.0 if is_boss else 2.0):
				hero.take_damage(18.0 if is_boss else 10.0)
		elif stun <= 0 and distance < 24 and distance > 1.5:
			var direction: Vector3 = flat.normalized()
			velocity.x = direction.x * 3.0
			velocity.z = direction.z * 3.0
			visual.rotation.y = atan2(direction.x, direction.z)
		elif stun <= 0 and distance <= 2.0 and attack_cooldown <= 0:
			windup = 0.65
			attack_cooldown = 2.0
		else:
			velocity.x = move_toward(velocity.x, 0, delta * 12)
			velocity.z = move_toward(velocity.z, 0, delta * 12)
	elif escorting:
		var direction: Vector3 = flat.normalized()
		if distance > 2.8 and distance < 30 and absf(hero.global_position.y - global_position.y) < 3:
			velocity.x = direction.x * 4.5
			velocity.z = direction.z * 4.5
			visual.rotation.y = atan2(direction.x, direction.z)
		else:
			velocity.x = 0
			velocity.z = 0
	elif stationary:
		velocity.x = 0
		velocity.z = 0
	else:
		walk_time += delta
		var direction := Vector3(sin(walk_time * 0.3), 0, cos(walk_time * 0.3))
		if global_position.distance_to(origin) > 5:
			direction = (origin - global_position).normalized()
		velocity.x = direction.x * 0.8
		velocity.z = direction.z * 0.8
		visual.rotation.y = atan2(direction.x, direction.z)
	if marker_material:
		marker_material.albedo_color = Color(1.0, 0.08, 0.04, 0.9) if windup > 0 else Color(1.0, 0.55, 0.06, 0.8)
	move_and_slide()

func hit(damage: float, direction: Vector3) -> void:
	if health <= 0:
		return
	health -= damage
	windup = 0
	stun = 0.45
	velocity.x = direction.x * 4
	velocity.z = direction.z * 4
	if health <= 0:
		queue_free()
