extends CharacterBody3D

var world
var game
var controls
var camera: Camera3D
var visual: Node3D
var animator: AnimationPlayer
var skeleton: Skeleton3D
var hand_bone := -1
var health := 100.0
var yaw := 0.0
var pitch := 0.25
var rope_active := false
var anchor := Vector3.ZERO
var rope_length := 0.0
var attack_cooldown := 0.0
var web: MeshInstance3D
var punch_flash: MeshInstance3D
var punch_timer := 0.0
var playing := false

func setup() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	collision_layer = 2
	collision_mask = 1
	visual = preload("res://assets/hero.glb").instantiate()
	add_child(visual)
	var animators := visual.find_children("*", "AnimationPlayer", true, false)
	if not animators.is_empty():
		animator = animators[0]
	var skeletons := visual.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		skeleton = skeletons[0]
		hand_bone = skeleton.find_bone("mixamorigRightHand")
	camera = Camera3D.new()
	camera.fov = 65
	game.add_child(camera)
	camera.current = true
	web = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.025
	cylinder.bottom_radius = 0.025
	cylinder.height = 1
	web.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	web.material_override = mat
	game.add_child(web)
	web.visible = false
	punch_flash = MeshInstance3D.new()
	var spark := SphereMesh.new()
	spark.radius = 0.16
	spark.height = 0.32
	punch_flash.mesh = spark
	punch_flash.material_override = mat
	game.add_child(punch_flash)
	punch_flash.visible = false

func _physics_process(delta: float) -> void:
	if not playing:
		return
	attack_cooldown = maxf(0, attack_cooldown - delta)
	punch_timer = maxf(0, punch_timer - delta)
	punch_flash.visible = punch_timer > 0
	if punch_flash.visible:
		var hand := global_position + Vector3.UP * 1.3
		if skeleton and hand_bone >= 0:
			hand = skeleton.global_transform * skeleton.get_bone_global_pose(hand_bone).origin
		punch_flash.global_position = hand
	yaw -= controls.look_delta.x * 0.004
	pitch = clampf(pitch - controls.look_delta.y * 0.004, -0.25, 1.05)
	controls.look_delta = Vector2.ZERO
	var input: Vector2 = controls.movement
	input.x += float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	input.y += float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	input = input.limit_length(1.0)
	var forward := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var desired := (right * input.x - forward * input.y).limit_length(1.0)
	if desired.length() > 0.05:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(desired.x, desired.z) + PI, delta * 10)
	var accel := 13.0 if is_on_floor() else (8.0 if rope_active else 4.0)
	var top_speed := 7.5 if is_on_floor() else 11.0
	if rope_active:
		# Do not brake horizontal momentum toward walking speed while swinging.
		velocity.x += desired.x * 5.0 * delta
		velocity.z += desired.z * 5.0 * delta
		var horizontal_speed := Vector2(velocity.x, velocity.z).limit_length(25.0)
		velocity.x = horizontal_speed.x
		velocity.z = horizontal_speed.y
	else:
		velocity.x = move_toward(velocity.x, desired.x * top_speed, accel * delta)
		velocity.z = move_toward(velocity.z, desired.z * top_speed, accel * delta)
	velocity.y -= 18 * delta
	if controls.consume("jump") and is_on_floor():
		velocity.y = 8.5
	if controls.consume("attack"):
		attack()
	if controls.consume("talk"):
		game.interact()
	var swinging: bool = controls.held("swing") or Input.is_key_pressed(KEY_SHIFT)
	if swinging and not rope_active:
		attach_web(forward)
	elif not swinging and rope_active:
		rope_active = false
		web.visible = false
	if rope_active:
		var offset := global_position + Vector3.UP - anchor
		if offset.length() >= rope_length - 0.15:
			var radial := offset.normalized()
			var outward := velocity.dot(radial)
			if outward > 0:
				velocity -= radial * outward
	move_and_slide()
	if rope_active:
		var offset := global_position + Vector3.UP - anchor
		if offset.length() > rope_length:
			move_and_collide(-offset.normalized() * (offset.length() - rope_length))
		update_web()
	update_animation(desired)
	update_camera(delta)

func update_animation(desired: Vector3) -> void:
	if not animator:
		return
	var name := "swing" if rope_active else ("run" if desired.length() > 0.1 and is_on_floor() else "idle")
	if animator.has_animation(name) and animator.current_animation != name:
		animator.play(name, 0.15)

func update_camera(delta: float) -> void:
	var target := global_position + Vector3.UP * 1.5
	var horizontal := Vector3(sin(yaw), 0, cos(yaw))
	var wanted := target + horizontal * (6.5 * cos(pitch)) + Vector3.UP * (1.2 + sin(pitch) * 6.5)
	var query := PhysicsRayQueryParameters3D.create(target, wanted, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		wanted = hit.position + hit.normal * 0.25
	camera.global_position = camera.global_position.lerp(wanted, minf(1, delta * 10))
	camera.look_at(target, Vector3.UP)

func attach_web(forward: Vector3) -> void:
	var start := global_position + Vector3.UP * 1.4
	var best := INF
	var selected := Vector3.ZERO
	for candidate in world.anchors:
		var offset: Vector3 = candidate - start
		var distance := offset.length()
		if distance < 8 or distance > 65 or offset.y < 3:
			continue
		var horizontal := Vector3(offset.x, 0, offset.z).normalized()
		var alignment := horizontal.dot(forward)
		if alignment < 0.1:
			continue
		var score := distance - alignment * 20
		if score >= best:
			continue
		var query := PhysicsRayQueryParameters3D.create(start, candidate, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.position.distance_to(candidate) > 1.0:
			continue
		best = score
		selected = candidate
	if best < INF:
		anchor = selected
		rope_length = (global_position + Vector3.UP).distance_to(anchor)
		rope_active = true
		web.visible = true
	else:
		game.show_message("No reachable rooftop ahead")

func update_web() -> void:
	var start := global_position + Vector3.UP * 1.3
	if skeleton and hand_bone >= 0:
		start = skeleton.global_transform * skeleton.get_bone_global_pose(hand_bone).origin
	var line := anchor - start
	web.global_position = start + line * 0.5
	web.quaternion = Quaternion(Vector3.UP, line.normalized())
	web.scale = Vector3(1, line.length(), 1)

func attack() -> void:
	if attack_cooldown > 0 or not playing:
		return
	attack_cooldown = 0.45
	punch_timer = 0.2
	var nearest
	var best := 2.8
	for npc in game.people:
		if not is_instance_valid(npc) or not npc.is_enemy or npc.health <= 0:
			continue
		var dist := global_position.distance_to(npc.global_position)
		if dist < best:
			best = dist
			nearest = npc
	if nearest:
		var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, nearest.global_position + Vector3.UP, 1)
		if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			var direction: Vector3 = (nearest.global_position - global_position).normalized()
			visual.rotation.y = atan2(direction.x, direction.z) + PI
			nearest.hit(25, direction)
			game.show_message("Hit! Enemy health: %d" % maxi(0, ceili(nearest.health)))
			return
	game.show_message("Attack: move closer to an enemy")

func take_damage(amount: float) -> void:
	if not playing:
		return
	health = maxf(0, health - amount)
	game.show_message("Hit! Health: %d" % ceili(health))
	if health <= 0:
		playing = false
		game.game_over()
