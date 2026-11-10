extends CharacterBody3D

const ComicStyle = preload("res://scripts/comic_style.gd")

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
var coyote_timer := 0.0
var jump_buffer := 0.0
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
var vehicle_impact_cooldown := 0.0
var climbing := false
var transfer_timer := 0.0
var mantle_cooldown := 0.0

func setup() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	collision_layer = 2
	collision_mask = 5
	visual = preload("res://assets/hero.glb").instantiate()
	add_child(visual)
	ComicStyle.apply_to_character(visual)
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
	vehicle_impact_cooldown = maxf(0.0, vehicle_impact_cooldown - delta)
	transfer_timer = maxf(0.0, transfer_timer - delta)
	mantle_cooldown = maxf(0.0, mantle_cooldown - delta)
	web_retry = maxf(0, web_retry - delta)
	landing_timer = maxf(0, landing_timer - delta)
	coyote_timer = 0.12 if is_on_floor() else maxf(0.0, coyote_timer - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if controls.consume("jump"):
		jump_buffer = 0.14
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
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, desired.x * top_speed, accel * delta)
		velocity.z = move_toward(velocity.z, desired.z * top_speed, accel * delta)
	else:
		# Air steering adds acceleration rather than instantly braking a fast
		# swing release back to walking speed. Gentle drag prevents endless drift.
		var horizontal := Vector2(velocity.x, velocity.z)
		var speed_before := horizontal.length()
		horizontal += Vector2(desired.x, desired.z) * accel * delta
		horizontal = horizontal.limit_length(maxf(top_speed, speed_before))
		horizontal = horizontal.move_toward(Vector2.ZERO, 0.25 * delta)
		velocity.x = horizontal.x
		velocity.z = horizontal.y
	velocity.y -= 18 * delta
	climbing = not rope_active and not is_on_floor() and is_on_wall() and absf(get_wall_normal().y) < 0.4 and desired.dot(-get_wall_normal()) > 0.3
	if climbing:
		velocity.y = 4.0
		if mantle_cooldown <= 0.0 and jump_buffer <= 0.0:
			try_mantle(get_wall_normal())
	if jump_buffer > 0:
		var jumped := false
		if rope_active:
			release_web()
			swing_blocked_until_release = true
			velocity.y = maxf(velocity.y, 5.0)
			jumped = true
		elif is_on_floor():
			velocity.y = 8.5
			jumped = true
		elif is_on_wall() and absf(get_wall_normal().y) < 0.4:
			var wall_normal := get_wall_normal()
			velocity.x = wall_normal.x * 6.0
			velocity.z = wall_normal.z * 6.0
			velocity.y = 8.0
			jumped = true
		elif coyote_timer > 0:
			velocity.y = 8.5
			jumped = true
		if jumped:
			jump_buffer = 0.0
			coyote_timer = 0.0
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
	if rope_active and transfer_timer <= 0.0:
		var travel := Vector3(velocity.x, 0, velocity.z)
		var to_anchor := Vector3(anchor.x - global_position.x, 0, anchor.z - global_position.z)
		if travel.length() > 4.0 and to_anchor.dot(travel) < 0.0:
			transfer_timer = 1.5
			attach_web(travel.normalized(), true)
	if rope_active:
		var offset := global_position + Vector3.UP - anchor
		if offset.length() >= rope_length - 0.15:
			var radial := offset.normalized()
			var outward := velocity.dot(radial)
			if outward > 0:
				velocity -= radial * outward
	# Predict contact at the capsule's front before sliding. Godot can resolve
	# a kinematic body as an overlap recovery without returning a slide hit.
	var horizontal_motion := Vector3(velocity.x, 0, velocity.z)
	if horizontal_motion.length() >= 3.0 and vehicle_impact_cooldown <= 0.0:
		var origin := global_position + Vector3.UP * 0.9
		var reach := horizontal_motion.normalized() * (0.43 + horizontal_motion.length() * delta)
		var vehicle_hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + reach, 4))
		if not vehicle_hit.is_empty() and vehicle_hit.collider in game.traffic:
			vehicle_impact(vehicle_hit.collider.velocity - velocity, -vehicle_hit.normal)
	var impact_velocity := velocity
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var hit := get_slide_collision(i)
		var collider := hit.get_collider()
		if collider in game.traffic:
			vehicle_impact(collider.velocity - impact_velocity, -hit.get_normal())
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

# Step onto a rooftop once the climber reaches its lip. Both the roof ray and
# capsule clearance are checked so the move cannot put the hero inside a wall
# or under a low ceiling. Only a static-world surface can be a landing.
func try_mantle(wall_normal: Vector3) -> bool:
	var toward := -Vector3(wall_normal.x, 0.0, wall_normal.z).normalized()
	if toward.length_squared() < 0.5:
		return false
	var space := get_world_3d().direct_space_state
	var front := global_position + toward * 0.95
	var ray := PhysicsRayQueryParameters3D.create(front + Vector3.UP * 2.2, front + Vector3.DOWN * 0.1, 1)
	var hit := space.intersect_ray(ray)
	if hit.is_empty() or hit.normal.y < 0.8:
		return false
	var rise: float = hit.position.y - global_position.y
	if rise < -0.05 or rise > 1.2:
		return false
	var destination := Vector3(front.x, hit.position.y + 0.06, front.z)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, destination + Vector3.UP * 0.93)
	query.collision_mask = 5
	query.exclude = [get_rid()]
	if not space.intersect_shape(query, 1).is_empty():
		return false
	global_position = destination
	velocity = toward * 2.0
	climbing = false
	mantle_cooldown = 0.5
	return true

func update_animation(_desired: Vector3) -> void:
	if not animator:
		return
	var name := "idle"
	if rope_active:
		name = "swing"
	elif climbing:
		name = "run"
	elif not is_on_floor():
		name = "jump" if velocity.y > 0.5 else "fall"
	elif Vector2(velocity.x, velocity.z).length() > 0.5:
		name = "run"
	elif landing_timer > 0:
		name = "land"
	if animator.has_animation(name) and animator.current_animation != name:
		animator.play(name, 0.15)
	# Match the running clip to actual speed so small joystick inputs do not
	# look like a full sprint, while preserving airborne clip timing.
	animator.speed_scale = clampf(Vector2(velocity.x, velocity.z).length() / 7.5, 0.45, 1.2) if name == "run" else 1.0

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

func attach_web(forward: Vector3, transfer: bool = false) -> void:
	var start := global_position + Vector3.UP * 1.4
	var best := INF
	var selected := Vector3.ZERO
	for candidate in world.anchors:
		if transfer and candidate.distance_to(anchor) < 1.0:
			continue
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
	elif not transfer:
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
		game.comic_popup("THWIP!", closest.global_position, Color("c8f4ff"))
		closest.hit(10, forward)
		closest.stun = 2.0
		game.show_message("THWIP! Enemy webbed.")
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
		if not is_instance_valid(npc) or npc.is_queued_for_deletion() or not npc.is_enemy or npc.health <= 0:
			continue
		var dist := global_position.distance_to(npc.global_position)
		if dist < best:
			var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, npc.global_position + Vector3.UP, 1)
			if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
				best = dist
				nearest = npc
	if nearest:
		var direction: Vector3 = (nearest.global_position - global_position).normalized()
		visual.rotation.y = atan2(direction.x, direction.z) + PI
		velocity.x += direction.x * 2.0
		velocity.z += direction.z * 2.0
		game.comic_popup("POW!", nearest.global_position, Color("ffe15d"))
		nearest.hit(25, direction)
		game.show_message("POW! Enemy health: %d" % maxi(0, ceili(nearest.health)))
		return
	game.show_message("Attack: move closer to an enemy")

func take_damage(amount: float) -> void:
	if not playing:
		return
	game.sound.play_effect("hurt")
	game.comic_popup("OUCH!", global_position, Color("ff8176"))
	health = maxf(0, health - amount)
	game.show_message("Hit! Health: %d" % ceili(health))
	if health <= 0:
		playing = false
		game.game_over()

# Both moving bodies can detect the collision first; the cooldown makes the
# response independent of physics tick order and prevents repeated damage.
func vehicle_impact(relative_velocity: Vector3, collision_normal: Vector3) -> void:
	if vehicle_impact_cooldown > 0.0 or not playing:
		return
	var normal := collision_normal.normalized()
	var impact_speed := absf(relative_velocity.dot(normal))
	if impact_speed < 3.0:
		return
	vehicle_impact_cooldown = 1.2
	var push := -normal
	push.y = 0.0
	if push.length_squared() < 0.01:
		push = Vector3(relative_velocity.x, 0, relative_velocity.z).normalized()
	velocity += push.normalized() * minf(impact_speed * 0.8, 9.0)
	velocity.y = maxf(velocity.y, 3.0)
	take_damage(clampf(impact_speed * 1.5, 5.0, 20.0))
