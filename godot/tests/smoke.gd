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
	touch.pressed = false
	scene.controls._input(touch)
	check(not scene.controls.held("swing"), "releasing touch releases web")
	drag.pressed = false
	scene.controls._input(drag)
	check(scene.controls.movement == Vector2.ZERO, "releasing joystick stops input")
	check(scene.people.size() == 6 and scene.stage == 0, "story starts at the first objective")
	check(scene.hero.animator != null and scene.hero.skeleton != null, "hero model and skeleton imported")
	check(scene.hero.hand_bone >= 0 and scene.hero.animator.has_animation("run"), "hand and run animation imported")
	scene.hero.attach_web(Vector3(0, 0, -1))
	check(scene.hero.rope_active and scene.hero.rope_length > 0, "web finds an unobstructed roof")
	scene.hero.rope_active = false
	scene.interact()
	check(scene.controls.message.begins_with("Civilian:"), "nearby civilian can be interacted with")

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
				scene.world.update_chunks(mission.at)
				await physics_frame
				scene.hero.position = mission.at + Vector3(0, 0.1, -1)
				enemy.position = mission.at + Vector3(0, 0.1, 0)
				scene.hero.attack_cooldown = 0
				var previous: float = enemy.health
				scene.hero.attack()
				check(enemy.health == previous - 25, "hero attack damages enemy in stage %d" % expected)
				if expected == 1:
					scene.hero.shoot_web(Vector3.FORWARD)
					check(enemy.health == previous - 35 and enemy.stun == 2.0, "web shot damages and stuns enemy")
				if expected == 1:
					enemy.stun = 0
					enemy.attack_cooldown = 0
					enemy._physics_process(0.05)
					enemy._physics_process(0.7)
					check(scene.hero.health == 90, "enemy attack damages hero")
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
	check(not Saves.valid({"version": 1, "mode": "Story", "stage": 500, "health": 100, "position": [0,0,0]}, "Story"), "out of range stage rejected")
	check(not Saves.valid({"version": 1, "mode": "Story", "stage": 0, "health": 100, "position": [0,0,0], "crime_sequence": []}, "Story"), "malformed optional state rejected")
	scene.hero.update_camera(1.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.resize(384, 216)
	image.save_jpg("/tmp/native-scene.jpg", 0.4)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Saves.slot_path("Story")))
	if not failed:
		print("Native scene smoke checks passed")
	quit(1 if failed else 0)
