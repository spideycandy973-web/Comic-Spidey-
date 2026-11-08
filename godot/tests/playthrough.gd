extends SceneTree

const Missions = preload("res://scripts/missions.gd")

func _initialize() -> void:
	call_deferred("run_test")

func steer(from: Vector3, to: Vector3, road_navigation: bool) -> Vector2:
	var delta := Vector2(to.x - from.x, to.z - from.z)
	# Turn onto the street center before heading along the next block.
	if road_navigation and absf(delta.x) > 7 and absf(delta.y) > 2:
		delta.x = 0
	elif road_navigation and absf(delta.y) > 7 and absf(delta.x) > 2:
		delta.y = 0
	return delta.normalized() if delta.length() > 1 else Vector2.ZERO

func run_test() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	scene.save_enabled = false
	scene.start_mode("Story")
	Engine.time_scale = 5.0
	var previous_stage := -1
	var retries := 0
	var stage_frames := 0
	var avoid_frames := 0
	var avoid_direction := Vector2.ZERO
	var detour_grace := 0
	for frame in range(16000):
		await physics_frame
		if scene.stage != previous_stage:
			previous_stage = scene.stage
			stage_frames = 0
			print("Playthrough stage ", previous_stage, " at ", scene.hero.position, " health ", scene.hero.health)
		stage_frames += 1
		if stage_frames == 1800:
			print("Playthrough stalled: stage ", scene.stage, " hero ", scene.hero.position, " target ", scene.current_target(), " movement ", scene.controls.movement)
			break
		if scene.stage == Missions.STORY.size() - 1:
			print("Input-driven story playthrough passed; retries: ", retries)
			quit(0)
			return
		if not scene.hero.playing:
			if scene.hero.health <= 0 and retries < 4:
				retries += 1
				scene.retry_checkpoint()
				continue
			break
		scene.controls.buttons_down.erase("attack")
		var mission: Dictionary = Missions.story_stage(scene.stage)
		var destination: Vector3 = mission.at
		var walking := true
		if mission.type in ["fight", "boss"]:
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
					walking = false
		elif mission.type == "interact":
			if is_instance_valid(scene.mission_prop):
				destination = scene.mission_prop.position
			if Missions.near(scene.hero.position, destination, 3):
				scene.controls.pressed_once["talk"] = true
				walking = false
		elif mission.type == "escort":
			destination = mission.destination
			if is_instance_valid(scene.escort) and scene.hero.position.distance_to(scene.escort.position) > 8:
				walking = false
		var desired := steer(scene.hero.position, destination, mission.type in ["travel", "escort"] and detour_grace <= 0) if walking else Vector2.ZERO
		if avoid_frames > 0:
			avoid_frames -= 1
			desired = avoid_direction
		elif desired.length_squared() > 0.1 and mission.type in ["travel", "escort"]:
			var from: Vector3 = scene.hero.global_position + Vector3.UP * 0.9
			var forward := Vector3(desired.x, 0, desired.y)
			var ray := PhysicsRayQueryParameters3D.create(from, from + forward * 1.8, 1)
			var obstacle := scene.hero.get_world_3d().direct_space_state.intersect_ray(ray)
			if not obstacle.is_empty():
				var side := Vector2(-desired.y, desired.x)
				var away := Vector2.ZERO
				if obstacle.collider is Node3D:
					var object_pos: Vector3 = obstacle.collider.global_position
					away = Vector2(scene.hero.position.x - object_pos.x, scene.hero.position.z - object_pos.z)
				if away.dot(side) < 0:
					side = -side
				avoid_direction = side
				avoid_frames = 6
				detour_grace = 80
				desired = side
		if detour_grace > 0:
			detour_grace -= 1
		scene.controls.movement = desired
	print("Playthrough stopped at stage ", scene.stage, " hero ", scene.hero.position, " health ", scene.hero.health, " target ", scene.current_target(), " retries ", retries)
	push_error("TEST FAILED: playthrough stalled at stage %d; hero %s; target %s; movement %s; velocity %s" % [scene.stage, scene.hero.position, scene.current_target(), scene.controls.movement, scene.hero.velocity])
	quit(1)
