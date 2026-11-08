extends SceneTree

var failed := false
const Missions = preload("res://scripts/missions.gd")
const Saves = preload("res://scripts/saves.gd")

func _initialize() -> void:
	call_deferred("run_test")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("TEST FAILED: " + message)
		failed = true

func run_test() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	scene.save_enabled = false
	scene.start_mode("Story")
	scene.set_process(false)
	scene.hero.set_physics_process(false)
	for npc in scene.people:
		npc.set_physics_process(false)
	await physics_frame
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = scene.controls.button_positions()["swing"]
	scene.controls._input(touch)
	check(scene.controls.held("swing"), "touch holds the swing button")
	var drag := InputEventScreenTouch.new()
	drag.index = 1
	drag.pressed = true
	drag.position = Vector2(140, 620)
	scene.controls._input(drag)
	check(scene.controls.movement.length() > 0, "joystick works while web is held")
	var second_touch := InputEventScreenTouch.new()
	second_touch.index = 2
	second_touch.pressed = true
	second_touch.position = scene.controls.button_positions()["swing"]
	scene.controls._input(second_touch)
	touch.pressed = false
	scene.controls._input(touch)
	check(scene.controls.held("swing"), "one finger releasing does not cancel another held web touch")
	second_touch.pressed = false
	scene.controls._input(second_touch)
	check(not scene.controls.held("swing"), "releasing last touch releases web")
	drag.pressed = false
	scene.controls._input(drag)
	check(scene.controls.movement == Vector2.ZERO, "releasing joystick stops input")
	var default_stick: Vector2 = scene.controls.stick_center()
	check(scene.controls.set_mirrored(true), "mirrored control setting saves")
	check(scene.controls.stick_center().x > default_stick.x and scene.controls.button_positions()["attack"].x < default_stick.x + 200, "mirrored controls swap sides")
	scene.sound.toggle()
	var settings := ConfigFile.new()
	check(settings.load("user://settings.cfg") == OK and settings.get_value("controls", "mirrored", false), "audio setting preserves control layout")
	scene.sound.toggle()
	scene.controls.set_mirrored(false)
	check(scene.people.size() == 6 and scene.stage == 0, "story starts at the first objective")
	check(scene.traffic.size() == 6, "native traffic spawns")
	check(scene.people[2].anim != null and scene.people[2].anim.has_animation("run") and scene.people[3].anim != null and scene.people[3].anim.has_animation("run"), "additional rigged citizens have run clips")
	var block = scene.world.chunks[Vector2i(0, 0)]
	var facades = block.get_node_or_null("BuildingFacades")
	check(facades != null and facades.multimesh.instance_count == 4, "city batches building visuals without removing collisions")
	var car = scene.traffic[0]
	car.set_physics_process(false)
	car.axis = 0
	car.travel_sign = 1.0
	car.position = Vector3(0, 0.1, -20)
	car.velocity = Vector3(0, 0, 5)
	scene.hero.position = Vector3(0, 0.1, -16)
	car._physics_process(0.5)
	check(Vector2(car.velocity.x, car.velocity.z).length() < 0.1, "traffic stops for a person ahead")
	scene.hero.position = Vector3(0, 0.1, 0)
	car.recenter(0)
	check(scene.hero.animator != null and scene.hero.skeleton != null, "hero model and skeleton imported")
	var hero_meshes: Array = scene.hero.visual.find_children("*", "MeshInstance3D", true, false)
	check(not hero_meshes.is_empty(), "hero model has visible mesh")
	if not hero_meshes.is_empty():
		var hero_material = hero_meshes[0].get_active_material(0)
		check(hero_material is BaseMaterial3D and hero_material.next_pass is ShaderMaterial and hero_material.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON, "hero has toon lighting and an ink outline")
	check(scene.hero.hand_bone >= 0 and scene.hero.animator.has_animation("run"), "hand and run animation imported")
	check(scene.hero.animator.get_animation("run").loop_mode == Animation.LOOP_LINEAR, "run animation loops")
	check(scene.sound.samples.size() == 5, "offline sound cues were generated")
	scene.hero.attach_web(Vector3(0, 0, -1))
	check(scene.hero.rope_active and scene.hero.rope_length > 0, "web finds an unobstructed roof")
	var swing_start: Vector3 = scene.hero.position
	scene.controls.buttons_down["swing"] = true
	scene.controls.movement = Vector2(0, -1)
	for frame in range(60):
		scene.hero._physics_process(1.0 / 60.0)
	check(scene.hero.rope_active and scene.hero.position.distance_to(swing_start) > 1.0, "held web permits physical movement")
	scene.controls.buttons_down.erase("swing")
	scene.controls.movement = Vector2.ZERO
	scene.hero._physics_process(1.0 / 60.0)
	check(not scene.hero.rope_active and not scene.hero.web.visible, "releasing web ends rope")
	scene.hero.position = Vector3(0, 0.1, 0)
	scene.hero.velocity = Vector3.ZERO
	scene.hero.attach_web(Vector3.FORWARD)
	scene.controls.buttons_down["swing"] = true
	scene.controls.pressed_once["jump"] = true
	scene.hero._physics_process(1.0 / 60.0)
	check(not scene.hero.rope_active and scene.hero.velocity.y > 0 and scene.hero.swing_blocked_until_release, "jump releases web with an upward boost")
	scene.controls.buttons_down.erase("swing")
	scene.hero._physics_process(1.0 / 60.0)
	check(not scene.hero.swing_blocked_until_release, "web can be used again after releasing the button")
	scene.hero.position = Vector3(0, 0.1, 0)
	scene.hero.velocity = Vector3.ZERO
	scene.interact()
	check(scene.controls.message.begins_with("Civilian:"), "nearby civilian can be interacted with")
	# An occluded closer enemy must not steal an attack from a visible target.
	var hidden = scene.spawn_person(Vector3(0, 0, -1.4), true, false, 0)
	var visible = scene.spawn_person(Vector3(2, 0, 0), true, false, 1)
	hidden.set_physics_process(false)
	visible.set_physics_process(false)
	var wall := StaticBody3D.new()
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(0.6, 2, 0.2)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.position = Vector3(0, 1, -0.7)
	scene.add_child(wall)
	await physics_frame
	scene.hero.attack_cooldown = 0
	scene.hero.attack()
	check(visible.health < 60 and hidden.health == 60, "melee selects a visible target when the closest is blocked")
	hidden.queue_free()
	visible.queue_free()
	wall.queue_free()
	await physics_frame

	# Exercise the actual mission transitions, not only the definition table.
	for expected in range(13):
		check(scene.stage == expected, "story stage %d reached in order" % expected)
		var mission: Dictionary = Missions.story_stage(expected)
		match mission.type:
			"travel":
				scene.hero.position = mission.at + Vector3.UP * 0.1
				scene.update_story()
			"fight", "boss":
				check(scene.enemies_alive() > 0, "enemies spawned for stage %d" % expected)
				var enemy = scene.mission_enemies[0]
				if mission.type == "boss":
					check(enemy.tentacle_materials.size() == 2, "boss tentacle meshes have animation shaders")
					var before: float = enemy.tentacle_time
					enemy._physics_process(0.1)
					check(enemy.tentacle_time > before, "boss tentacle animation advances")
				scene.world.update_chunks(mission.at)
				await physics_frame
				scene.hero.position = mission.at + Vector3(0, 0.1, -1)
				enemy.position = mission.at + Vector3(0, 0.1, 0)
				scene.hero.attack_cooldown = 0
				var previous: float = enemy.health
				scene.hero.attack()
				check(enemy.health == previous - 25, "hero attack damages enemy in stage %d" % expected)
				if expected == 1:
					scene.hero.shoot_web(Vector3.BACK)
					check(enemy.health == previous - 35 and enemy.stun == 2.0, "web shot damages and stuns enemy")
				if expected == 1:
					enemy.stun = 0
					enemy.attack_cooldown = 0
					enemy._physics_process(0.05)
					enemy._physics_process(0.7)
					check(scene.hero.health == 90, "enemy attack damages hero")
					var old_health: float = scene.hero.health
					scene.hero.position.y += 10
					enemy.windup = 0.1
					enemy._physics_process(0.2)
					check(scene.hero.health == old_health, "street enemies cannot strike a hero far above them")
					scene.hero.position.y -= 10
				if mission.type == "boss":
					enemy.position = scene.hero.position + Vector3(0, 0, 4)
					enemy.stun = 0
					enemy.windup = 0
					enemy.attack_cooldown = 0
					enemy._physics_process(0.01)
					check(enemy.windup > 0, "boss starts a longer-range tentacle attack")
				for target in scene.mission_enemies:
					target.hit(999, Vector3.FORWARD)
				scene.update_story()
			"interact":
				scene.hero.position = mission.at + Vector3.UP * 0.1
				scene.interact()
			"escort":
				check(is_instance_valid(scene.escort), "escort civilian spawned")
				scene.hero.position = mission.destination + Vector3.UP * 0.1
				scene.escort.position = mission.destination + Vector3(1, 0.1, 0)
				scene.update_story()
	check(scene.stage == 13, "story reaches completed state")
	scene.pause_game()
	check(not scene.hero.playing and not scene.controls.active, "pause stops gameplay and touch")
	scene.show_credits()
	check(is_instance_valid(scene.menu), "credits open")
	scene.close_credits()
	scene.resume_game()
	check(scene.hero.playing and scene.controls.active, "resume restarts gameplay")
	scene.start_mode("Free Roam")
	check(scene.mode == "Free Roam" and scene.people.size() == 6, "free roam starts with citizens")
	check(not scene.hero.rope_active, "starting a mode clears the previous rope")
	for type in Missions.CRIMES:
		scene.start_crime()
		check(scene.crime_type == type and scene.enemies_alive() > 0, "crime spawns " + type)
		for enemy in scene.mission_enemies:
			enemy.hit(999, Vector3.FORWARD)
		scene.update_crime(0.01)
		if type != "assault":
			check(scene.crime_phase == "interact", "crime requires interaction")
			scene.hero.position = scene.crime_target + Vector3.UP * 0.1
			scene.interact()
		check(scene.crime_phase == "waiting", "crime resolves")
	check(scene.crime_completed == 3, "free roam tracks resolved crimes")
	scene.crime_sequence = 2
	scene.start_crime()
	scene.pause_game()
	check(not scene.mission_enemies[0].is_physics_processing(), "pause stops enemy AI")
	check(not scene.traffic[0].is_physics_processing(), "pause stops traffic")
	scene.resume_game()
	scene.update_crime(100)
	check(scene.crime_phase == "waiting" and scene.crime_failed == 1, "timed emergencies can fail")
	scene.hero.position = Vector3(440, 0.1, 440)
	scene.recenter_civilians()
	for npc in scene.people:
		if npc.local_civilian:
			check(npc.position.distance_to(scene.hero.position) < 20, "civilians follow the player between neighborhoods")

	# Use a real user:// slot to test round-trip and malformed saves.
	scene.save_enabled = true
	scene.start_mode("Story")
	scene.hero.position = Vector3(0, 0.1, -44)
	scene.update_story()
	scene.mission_enemies[0].health = 35
	scene.hero.health = 73
	scene.save_game()
	var saved: Dictionary = Saves.read("Story")
	check(not saved.is_empty() and saved.stage == 1 and saved.enemies.size() == 2, "story save stores mission and enemies")
	scene.continue_mode("Story")
	check(scene.stage == 1 and scene.hero.health == 73 and scene.enemies_alive() == 2, "story restores combat state")
	check(scene.mission_enemies[0].health == 35, "story restores enemy health")
	scene.pause_game()
	scene.request_new_mode("Story")
	check(scene.stage == 1 and not scene.hero.playing, "new story asks before replacing existing progress")
	scene.close_credits()
	scene.resume_game()
	scene.start_mode("Free Roam")
	scene.crime_sequence = 1
	scene.start_crime()
	scene.mission_enemies[0].health = 35
	scene.hero.health = 82
	scene.save_game()
	scene.continue_mode("Free Roam")
	check(scene.crime_type == "rescue" and scene.crime_phase == "fight", "free roam restores active rescue")
	check(scene.mission_enemies.size() == 3 and scene.mission_enemies[0].health == 35 and scene.hero.health == 82, "free roam restores combat and player health")
	check(is_instance_valid(scene.crime_civilian), "free roam restores rescue civilian")
	for target in scene.mission_enemies:
		target.hit(999, Vector3.FORWARD)
	scene.update_crime(0.01)
	scene.save_game()
	scene.continue_mode("Free Roam")
	check(scene.crime_phase == "interact" and is_instance_valid(scene.crime_civilian), "free roam restores rescue interaction")
	check(not Saves.valid({"version": 1, "mode": "Story", "stage": 500, "health": 100, "position": [0,0,0]}, "Story"), "out of range stage rejected")
	check(not Saves.valid({"version": 1, "mode": "Story", "stage": 0, "health": 100, "position": [0,0,0], "crime_sequence": []}, "Story"), "malformed optional state rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Saves.slot_path("Story")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Saves.slot_path("Free Roam")))
	if not failed:
		print("Native scene smoke checks passed")
	quit(1 if failed else 0)
