extends CharacterBody3D

var world
var game
var controls
var camera: Camera3D
var visual: Node3D
var animator: AnimationPlayer
var skeleton: Skeleton3D
var hand_bone := -1
var arm_bone := -1
var health := 100.0
var yaw := 0.0
var pitch := 0.25
var rope_active := false
var anchor := Vector3.ZERO
var rope_length := 0.0
var web_retry := 0.0
var swing_blocked_until_release := false
var was_grounded := false
var landing_timer := 0.0
var attack_cooldown := 0.0
var shot_cooldown := 0.0
var shot_timer := 0.0
var shot_end := Vector3.ZERO
var shot_line: MeshInstance3D
var web: MeshInstance3D
var punch_flash: MeshInstance3D
var punch_timer := 0.0
var playing := false
var debug_movement_reported := false

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
		for clip in ["idle", "run", "swing"]:
			if animator.has_animation(clip):
				animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var skeletons := visual.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		skeleton = skeletons[0]
		hand_bone = skeleton.find_bone("mixamorigRightHand")
		arm_bone = skeleton.find_bone("mixamorigRightArm")
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
	shot_line = MeshInstance3D.new()
	shot_line.mesh = cylinder
	shot_line.material_override = mat
	game.add_child(shot_line)
	shot_line.visible = false
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
	if controls.consume("menu"):
		game.pause_game()
		return
	web_retry = maxf(0, web_retry - delta)
	landing_timer = maxf(0, landing_timer - delta)
	attack_cooldown = maxf(0, attack_cooldown - delta)
	shot_cooldown = maxf(0, shot_cooldown - delta)
	shot_timer = maxf(0, shot_timer - delta)
	shot_line.visible = shot_timer > 0
	if shot_line.visible:
		draw_line(shot_line, hand_position(), shot_end)
	punch_timer = maxf(0, punch_timer - delta)
	punch_flash.visible = punch_timer > 0
	if skeleton and arm_bone >= 0:
		skeleton.clear_bones_global_pose_override()
		if punch_timer > 0:
			var pose := skeleton.get_bone_global_pose(arm_bone)
			var strike := sin((0.2 - punch_timer) / 0.2 * PI)
			pose.basis = pose.basis * Basis(Vector3.FORWARD, -strike * 1.35)
			skeleton.set_bone_global_pose_override(arm_bone, pose, 1.0, true)
	if punch_flash.visible:
		punch_flash.global_position = hand_position()
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
	if OS.is_debug_build() and desired.length() > 0.1 and not debug_movement_reported:
		debug_movement_reported = true
		print("Native movement input received")
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
	if controls.consume("jump"):
		if rope_active:
			release_web()
			swing_blocked_until_release = true
			velocity.y = maxf(velocity.y, 5.0)
			game.sound.play_effect("jump")
		elif is_on_floor():
			velocity.y = 8.5
			game.sound.play_effect("jump")
	if controls.consume("attack") or controls.held("attack") or Input.is_key_pressed(KEY_F):
		attack()
	if controls.consume("talk"):
		game.interact()
	if controls.consume("shot"):
		shoot_web(forward)
	var swinging: bool = controls.held("swing") or Input.is_key_pressed(KEY_SHIFT)
	if not swinging:
		swing_blocked_until_release = false
	if swinging and not rope_active and not swing_blocked_until_release and web_retry <= 0:
		web_retry = 0.35
		attach_web(forward)
	elif not swinging and rope_active:
		release_web()
	if rope_active:
		var offset := global_position + Vector3.UP - anchor
		if offset.length() >= rope_length - 0.15:
			var radial := offset.normalized()
			var outward := velocity.dot(radial)
			if outward > 0:
				velocity -= radial * outward
	move_and_slide()
	var grounded := is_on_floor()
	if grounded and not was_grounded and velocity.y <= 0:
		landing_timer = 0.4
	was_grounded = grounded
	if rope_active:
		var offset := global_position + Vector3.UP - anchor
		if offset.length() > rope_length:
			var collision := move_and_collide(-offset.normalized() * (offset.length() - rope_length))
			if collision and (global_position + Vector3.UP).distance_to(anchor) > rope_length + 0.5:
				release_web()
		if rope_active and not web_has_clear_path():
			release_web()
		if rope_active:
			update_web()
	update_animation(desired)
	update_camera(delta)

func update_animation(desired: Vector3) -> void:
	if not animator:
		return
	var name := "idle"
	if rope_active:
		name = "swing"
	elif not is_on_floor():
		name = "jump" if velocity.y > 0.5 else "fall"
	elif desired.length() > 0.1:
		name = "run"
	elif landing_timer > 0:
		name = "land"
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
		# A small launch assist makes the first ground-level web usable without
		# overriding the pendulum's momentum once the player is airborne.
		if is_on_floor():
			velocity.y = maxf(velocity.y, 4.5)
			var pull := Vector3(anchor.x - global_position.x, 0, anchor.z - global_position.z).normalized()
			velocity.x += pull.x * 1.5
			velocity.z += pull.z * 1.5
		if OS.is_debug_build():
			print("Native web attached")
		game.sound.play_effect("web")
		web.visible = true
	else:
		game.show_message("No reachable rooftop ahead")

func release_web() -> void:
	rope_active = false
	web.visible = false

func web_has_clear_path() -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.4, anchor, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.position.distance_to(anchor) <= 1.0

func hand_position() -> Vector3:
	if skeleton and hand_bone >= 0:
		return skeleton.global_transform * skeleton.get_bone_global_pose(hand_bone).origin
	return global_position + Vector3.UP * 1.3

func draw_line(mesh: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var line := to - from
	if line.length_squared() < 0.0001:
		mesh.visible = false
		return
	mesh.global_position = from + line * 0.5
	mesh.quaternion = Quaternion(Vector3.UP, line.normalized())
	mesh.scale = Vector3(1, line.length(), 1)

func update_web() -> void:
	draw_line(web, hand_position(), anchor)

func shoot_web(forward: Vector3) -> void:
	if shot_cooldown > 0 or not playing:
		return
	shot_cooldown = 1.0
	game.sound.play_effect("web")
	var closest
	var best := 19.0
	for npc in game.people:
		if not is_instance_valid(npc) or npc.is_queued_for_deletion() or not npc.is_enemy or npc.health <= 0:
			continue
		var direction: Vector3 = npc.global_position - global_position
		var distance := direction.length()
		if distance < best and direction.normalized().dot(forward) > 0.4:
			var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, npc.global_position + Vector3.UP, 1)
			if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				closest = npc
				best = distance
	shot_end = global_position + Vector3.UP * 1.2 + forward * 18.0
	if not closest:
		var obstacle := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.2, shot_end, 1))
		if not obstacle.is_empty():
			shot_end = obstacle.position
	if closest:
		shot_end = closest.global_position + Vector3.UP
		closest.hit(10, forward)
		closest.stun = 2.0
		game.show_message("Web hit! Enemy slowed.")
	else:
		game.show_message("No enemy in range ahead.")
	shot_timer = 0.25
	shot_line.visible = true
	draw_line(shot_line, hand_position(), shot_end)

func attack() -> void:
	if attack_cooldown > 0 or not playing:
		return
	attack_cooldown = 0.45
	if OS.is_debug_build():
		print("Native attack input received")
	game.sound.play_effect("hit")
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
			velocity.x += direction.x * 2.0
			velocity.z += direction.z * 2.0
			nearest.hit(25, direction)
			game.show_message("Hit! Enemy health: %d" % maxi(0, ceili(nearest.health)))
			return
	game.show_message("Attack: move closer to an enemy")

func take_damage(amount: float) -> void:
	if not playing:
		return
	game.sound.play_effect("hurt")
	health = maxf(0, health - amount)
	game.show_message("Hit! Health: %d" % ceili(health))
	if health <= 0:
		playing = false
		game.game_over()
