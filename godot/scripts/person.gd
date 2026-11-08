extends CharacterBody3D

const TENTACLE_SHADER = preload("res://scripts/tentacles.gdshader")

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
var conversations := 0
var marker: MeshInstance3D
var marker_material: StandardMaterial3D
var tentacle_materials: Array[ShaderMaterial] = []
var tentacle_time := 0.0

func setup(model: PackedScene, enemy: bool, boss: bool = false) -> void:
	is_enemy = enemy
	is_boss = boss
	health = 200.0 if boss else 60.0
	visual = model.instantiate()
	add_child(visual)
	# Supplied models have different units.
	if boss:
		visual.scale = Vector3.ONE * 1.15
		setup_tentacles()
	else:
		visual.scale = Vector3.ONE
		if enemy:
			# Distinguish the attackers' clothing from civilian clothing.
			var uniform := StandardMaterial3D.new()
			uniform.albedo_color = Color("343648")
			uniform.roughness = 0.9
			for mesh in visual.find_children("*", "MeshInstance3D", true, false):
				if str(mesh.name).to_lower().begins_with("cloth"):
					mesh.material_override = uniform
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
			anim.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
			anim.play("walk")
	origin = position

func setup_tentacles() -> void:
	for part in visual.find_children("*", "MeshInstance3D", true, false):
		if str(part.name) not in ["Object_3", "Object_4"]:
			continue
		var original = part.get_active_material(0)
		if not original is BaseMaterial3D or not original.albedo_texture:
			continue
		var animated := ShaderMaterial.new()
		animated.shader = TENTACLE_SHADER
		animated.set_shader_parameter("albedo_texture", original.albedo_texture)
		animated.set_shader_parameter("albedo_tint", original.albedo_color)
		part.material_override = animated
		# Allow for the deformation moving slightly beyond the imported bounds.
		part.extra_cull_margin = 0.4
		tentacle_materials.append(animated)

func set_civilian_clothes(variant: int) -> void:
	if is_enemy:
		return
	var colors := [Color("b94d4a"), Color("547d97"), Color("7d8959"), Color("b79a65"), Color("786589"), Color("4e7771")]
	var jacket := StandardMaterial3D.new()
	jacket.albedo_color = colors[posmod(variant, colors.size())]
	jacket.roughness = 0.9
	var trousers := StandardMaterial3D.new()
	trousers.albedo_color = Color("303d50")
	trousers.roughness = 0.95
	var i := 0
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		if str(mesh.name).to_lower().begins_with("cloth"):
			mesh.material_override = jacket if i == 0 else trousers
			i += 1

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
			if windup <= 0 and distance < (3.0 if is_boss else 2.0) and has_line_of_sight():
				hero.take_damage((24.0 if health <= 100 else 18.0) if is_boss else 10.0)
		elif stun <= 0 and distance < 24 and distance > (2.2 if is_boss else 1.5):
			var direction: Vector3 = flat.normalized()
			velocity.x = direction.x * 3.0
			velocity.z = direction.z * 3.0
			visual.rotation.y = atan2(direction.x, direction.z) + PI
		elif stun <= 0 and distance <= (2.5 if is_boss else 2.0) and attack_cooldown <= 0 and has_line_of_sight():
			windup = 0.48 if is_boss and health <= 100 else 0.65
			attack_cooldown = 1.4 if is_boss and health <= 100 else 2.0
		else:
			velocity.x = move_toward(velocity.x, 0, delta * 12)
			velocity.z = move_toward(velocity.z, 0, delta * 12)
	elif escorting:
		var direction: Vector3 = flat.normalized()
		if distance > 2.8 and distance < 30 and absf(hero.global_position.y - global_position.y) < 3:
			velocity.x = direction.x * 4.5
			velocity.z = direction.z * 4.5
			visual.rotation.y = atan2(direction.x, direction.z) + PI
		else:
			velocity.x = 0
			velocity.z = 0
	elif stationary:
		velocity.x = 0
		velocity.z = 0
	else:
		walk_time += delta
		var direction := Vector3(sin(walk_time * 0.3), 0, cos(walk_time * 0.3))
		var speed := 0.8
		if global_position.distance_to(origin) > 5:
			direction = (origin - global_position).normalized()
		for threat in hero.game.mission_enemies:
			if is_instance_valid(threat) and not threat.is_queued_for_deletion() and threat.health > 0:
				var away: Vector3 = global_position - threat.global_position
				away.y = 0
				if away.length() < 7.0 and away.length() > 0.1:
					direction = away.normalized()
					speed = 3.0
					break
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		visual.rotation.y = atan2(direction.x, direction.z) + PI
	if is_boss:
		tentacle_time += delta
		for material in tentacle_materials:
			material.set_shader_parameter("motion_time", tentacle_time)
			material.set_shader_parameter("attack_intensity", 1.7 if windup > 0 else 1.0)
	if is_enemy:
		# Telegraph the attack with a visible lunge. The supplied Doc Ock mesh is not rigged.
		var lunge := sin((0.65 - maxf(windup, 0.0)) / 0.65 * PI) * 0.45 if windup > 0 else 0.0
		visual.position = flat.normalized() * lunge
	if anim:
		anim.speed_scale = 1.0 if Vector2(velocity.x, velocity.z).length() > 0.1 else 0.0
	if marker_material:
		marker_material.albedo_color = Color(1.0, 0.08, 0.04, 0.9) if windup > 0 else Color(1.0, 0.55, 0.06, 0.8)
	move_and_slide()

func has_line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, hero.global_position + Vector3.UP, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func hit(damage: float, direction: Vector3) -> void:
	if health <= 0:
		return
	health -= damage
	windup = 0
	stun = 0.28
	velocity.x = direction.x * 4
	velocity.z = direction.z * 4
	if health <= 0:
		queue_free()
