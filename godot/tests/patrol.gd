extends SceneTree

const Missions = preload("res://scripts/missions.gd")
var avoid_frames := 0
var avoid_direction := Vector2.ZERO

func _initialize() -> void:
	call_deferred("run_test")

func steer(scene, destination: Vector3) -> Vector2:
	if avoid_frames > 0:
		avoid_frames -= 1
		return avoid_direction
	var difference := Vector2(destination.x - scene.hero.position.x, destination.z - scene.hero.position.z)
	if difference.length() < 1:
		return Vector2.ZERO
	var direction := difference.normalized()
	var from: Vector3 = scene.hero.global_position + Vector3.UP * 0.9
	var ray := PhysicsRayQueryParameters3D.create(from, from + Vector3(direction.x, 0, direction.y) * 1.8, 1)
	var obstacle: Dictionary = scene.hero.get_world_3d().direct_space_state.intersect_ray(ray)
	if not obstacle.is_empty():
		var side := Vector2(-direction.y, direction.x)
		if obstacle.collider is Node3D:
			var object_pos: Vector3 = obstacle.collider.global_position
			var away := Vector2(scene.hero.position.x - object_pos.x, scene.hero.position.z - object_pos.z)
			if away.dot(side) < 0:
				side = -side
		avoid_direction = side
		avoid_frames = 6
		return side
	return direction

func run_test() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	scene.save_enabled = false
	scene.start_mode("Free Roam")
	Engine.time_scale = 5.0
	var resolved := {}
	var previous_type := ""
	var previous_completed := 0
	var last_sequence := 0
	var retries := 0
	for frame in range(18000):
		await physics_frame
		if scene.crime_sequence != last_sequence:
			last_sequence = scene.crime_sequence
			print("Patrol emergency ", scene.crime_type, " at ", scene.crime_target)
		if scene.crime_completed > previous_completed:
			resolved[previous_type] = true
			previous_completed = scene.crime_completed
		if resolved.size() == Missions.CRIMES.size():
			print("Input-driven Free Roam emergencies passed; retries: ", retries)
			quit(0)
			return
		if not scene.hero.playing:
			if scene.hero.health <= 0 and retries < 4:
				retries += 1
				scene.retry_checkpoint()
				continue
			break
		if scene.crime_phase != "waiting":
			previous_type = scene.crime_type
		scene.controls.buttons_down.erase("attack")
		scene.controls.movement = Vector2.ZERO
		if scene.crime_phase == "waiting":
			continue
		var destination: Vector3 = scene.current_target()
		if scene.crime_phase == "fight":
			var nearest
			var distance := INF
			for enemy in scene.mission_enemies:
				if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.health > 0:
					var d: float = scene.hero.position.distance_to(enemy.position)
					if d < distance:
						nearest = enemy
						distance = d
			if nearest:
				destination = nearest.position
				scene.controls.buttons_down["attack"] = true
				if distance < 2.1:
					continue
		elif scene.crime_phase == "interact" and Missions.near(scene.hero.position, destination, 3.0):
			scene.controls.pressed_once["talk"] = true
			continue
		scene.controls.movement = steer(scene, destination)
	push_error("TEST FAILED: patrol did not complete all emergencies; completed %d; resolved %s; phase %s; type %s; hero %s; target %s" % [scene.crime_completed, resolved, scene.crime_phase, scene.crime_type, scene.hero.position, scene.current_target()])
	quit(1)
