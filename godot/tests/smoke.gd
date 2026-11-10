extends SceneTree

var failed := false
const Missions = preload("res://scripts/missions.gd")
const Saves = preload("res://scripts/saves.gd")
const WorldScript = preload("res://scripts/world.gd")

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
	var free_roam_visible := false
	for button in scene.menu.find_children("*", "Button", true, false):
		if button.text == "New Free Roam":
			var rect: Rect2 = button.get_global_rect()
			free_roam_visible = rect.position.y >= 0 and rect.end.y <= root.get_visible_rect().size.y
	check(free_roam_visible, "free roam button fits within the menu viewport")
	scene.save_enabled = false
	scene.cutscenes_enabled = false
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
	# Graphics are persisted alongside, not instead of, audio and touch settings.
	scene.show_graphics()
	await process_frame
	for button in scene.menu.find_children("*", "Button", true, false):
		print("Graphics layout: ", button.text, " ", button.get_global_rect())
	scene.change_graphics("scale")
	check(is_equal_approx(root.scaling_3d_scale, 0.7), "3D resolution setting changes the viewport")
	scene.change_graphics("fxaa")
	check(root.screen_space_aa == Viewport.SCREEN_SPACE_AA_FXAA, "FXAA setting applies")
	scene.change_graphics("shadows")
	check(scene.sun.shadow_enabled, "shadow setting applies")
	scene.change_graphics("fps")
	check(Engine.max_fps == 30, "frame limit setting applies")
	var graphics_copy = load("res://scripts/graphics.gd").new()
	graphics_copy.load_settings()
	check(graphics_copy.scale_index == 0 and graphics_copy.fxaa and graphics_copy.shadows and graphics_copy.fps_limit == 30, "graphics settings persist")
	settings.load("user://settings.cfg")
	check(settings.get_value("controls", "mirrored", false), "graphics settings preserve touch layout")
	# Restore defaults for the remaining gameplay and rendering tests.
	scene.graphics.scale_index = 2
	scene.graphics.fxaa = false
	scene.graphics.shadows = false
	scene.graphics.fps_limit = 60
	scene.graphics.apply(root, scene.sun)
	scene.graphics.save_settings()
	scene.close_credits()
	if is_instance_valid(scene.menu):
		scene.menu.queue_free()
	scene.controls.set_mirrored(false)
	check(scene.people.size() == 6 and scene.stage == 0, "story starts at the first objective")
	scene._process(0.01)
	check(scene.controls.map_has_target and scene.controls.map_target == Missions.STORY[0].at, "minimap tracks the story objective")
	check(scene.controls.map_offset(Vector3.ZERO, Vector3(1000, 0, 0)).length() <= 72.01, "distant map objectives stay inside the minimap")
	check(scene.traffic.size() == 6, "native traffic spawns")
	check(scene.hero.collision_mask & 4 != 0 and scene.traffic[0].collision_layer == 4, "hero collides with vehicles on their own layer")
	check(is_equal_approx(absf(scene.traffic[1].get_child(0).rotation.y), PI * 0.5), "east-west traffic collision shape rotates")
	var hp_before: float = scene.hero.health
	scene.hero.vehicle_impact(Vector3(0, 0, 8), Vector3(0, 0, -1))
	check(scene.hero.health < hp_before and scene.hero.velocity.y > 0, "vehicle collision applies damage and knockback")
	var hp_after: float = scene.hero.health
	scene.hero.vehicle_impact(Vector3(0, 0, 8), Vector3(0, 0, -1))
	check(scene.hero.health == hp_after, "vehicle impact cooldown prevents repeated damage")
	scene.hero.health = hp_before
	scene.hero.velocity = Vector3.ZERO
	scene.cutscenes_enabled = true
	scene.start_story_cutscene()
	check(scene.cinematic_time > 0.0 and not scene.hero.playing and not scene.controls.active, "story cutscene suspends gameplay")
	var civilian_before: Vector3 = scene.people[0].position
	scene.people[0]._physics_process(0.5)
	check(scene.people[0].position == civilian_before, "story cutscene freezes civilian physics")
	scene.mission_enemies.append(scene.people[0])
	scene.cinematic_time = 2.5
	check(scene.story_cutscene_focus().distance_to(scene.people[0].global_position + Vector3.UP * 1.2) < 0.01, "boss cutscene focuses on the opposing character")
	scene.mission_enemies.clear()
	scene.finish_story_cutscene()
	check(scene.hero.playing and scene.controls.active and scene.cinematic_time == 0.0, "skipping cutscene resumes gameplay")
	scene.cutscenes_enabled = false
	check(scene.people[2].anim != null and scene.people[2].anim.has_animation("run") and scene.people[3].anim != null and scene.people[3].anim.has_animation("run"), "additional rigged citizens have run clips")
	check(scene.world.district_for(Vector2i(0, 0)) == "Downtown" and scene.world.district_for(Vector2i(5, 0)) == "Industrial" and scene.world.district_for(Vector2i(-5, 0)) == "Residential", "city districts have distinct profiles")
	var tank_count := 0
	for chunk in scene.world.chunks.values():
		tank_count += int(chunk.get_meta("water_tanks", 0))
	check(tank_count > 0, "city blocks include rooftop water tanks")
	var revision: int = scene.world.stream_revision
	scene.world.update_chunks(Vector3(1, 0, 1))
	check(scene.world.stream_revision == revision, "stationary city streaming avoids rebuilding anchors and blocks")
	check(scene.world.sidewalk_material is ShaderMaterial, "street surfaces use the shared detail material")
	var block = scene.world.chunks[Vector2i(0, 0)]
	var facades = block.get_node_or_null("BuildingFacades")
	check(facades != null and facades.multimesh.instance_count == 4, "city batches building visuals without removing collisions")
	var car = scene.traffic[0]
	check(car.visual.find_children("Wheel*", "MeshInstance3D", true, false).size() == 4, "traffic cars have four round wheels")
	car.set_physics_process(false)
	car.axis = 0
	car.travel_sign = 1.0
	car.position = Vector3(0, 0.1, -20)
	car.velocity = Vector3(0, 0, 5)
	scene.hero.position = Vector3(0, 0.1, -16)
	car._physics_process(0.5)
	check(Vector2(car.velocity.x, car.velocity.z).length() < 0.1, "traffic stops for a person ahead")
	scene.hero.position.y = 15
	car._physics_process(0.5)
	check(Vector2(car.velocity.x, car.velocity.z).length() > 0.1, "traffic does not stop for someone high overhead")
	scene.hero.position = Vector3(0, 0.1, 0)
	car.recenter(0)
	car.position = Vector3(0, 0.1, -5)
	car.velocity = Vector3.ZERO
	scene.hero.position = Vector3(0, 0.1, 0)
	scene.hero.velocity = Vector3.ZERO
	scene.hero.vehicle_impact_cooldown = 0
	scene.hero.yaw = 0
	scene.controls.movement = Vector2(0, -1)
	var before_collision: float = scene.hero.health
	await physics_frame
	for frame in range(90):
		await physics_frame
		scene.hero._physics_process(1.0 / 60.0)
		if scene.hero.health < before_collision:
			break
	check(scene.hero.health < before_collision, "walking into a car causes a real physics impact")
	scene.hero.health = before_collision
	scene.hero.vehicle_impact_cooldown = 0
	scene.controls.movement = Vector2.ZERO
	scene.hero.position = Vector3(0, 0.1, 0)
	scene.hero.velocity = Vector3.ZERO
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
	var environments: Array = scene.find_children("*", "WorldEnvironment", true, false)
	check(not environments.is_empty() and environments[0].environment.background_mode == Environment.BG_SKY, "city uses the procedural sky")
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
	# Two unobstructed synthetic rooftops verify transfer independently of
	# the particular streamed city layout.
	var saved_anchors: Array[Vector3] = scene.world.anchors.duplicate()
	scene.hero.position = Vector3(0, 100, 0)
	scene.hero.velocity = Vector3.ZERO
	scene.world.anchors.clear()
	scene.world.anchors.append(Vector3(0, 120, -20))
	scene.world.anchors.append(Vector3(0, 120, -40))
	scene.hero.attach_web(Vector3.FORWARD)
	var first_anchor: Vector3 = scene.hero.anchor
	scene.hero.attach_web(Vector3.FORWARD, true)
	check(scene.hero.rope_active and scene.hero.anchor != first_anchor, "web transfer selects a different reachable anchor")
	scene.hero.release_web()
	scene.world.anchors = saved_anchors
	var jump_wall := StaticBody3D.new()
	var jump_collision := CollisionShape3D.new()
	var jump_box := BoxShape3D.new()
	jump_box.size = Vector3(4, 6, 0.4)
	jump_collision.shape = jump_box
	jump_wall.add_child(jump_collision)
	jump_wall.position = Vector3(0, 3, -3)
	scene.add_child(jump_wall)
	scene.hero.position = Vector3(0, 4, -2.3)
	scene.hero.velocity = Vector3.ZERO
	scene.controls.movement = Vector2(0, -1)
	await physics_frame
	for frame in range(20):
		scene.hero._physics_process(1.0 / 60.0)
	check(scene.hero.is_on_wall() and not scene.hero.is_on_floor(), "hero can reach a wall in the air")
	check(scene.hero.climbing and scene.hero.velocity.y > 0, "holding toward a wall climbs upward")
	scene.hero.position = Vector3(0, 5.3, -2.43)
	scene.hero.velocity = Vector3.ZERO
	await physics_frame
	check(scene.hero.try_mantle(Vector3.BACK) and scene.hero.position.y > 6.0, "climbing can mantle onto a clear rooftop")
	scene.hero.position = Vector3(0, 4, -2.3)
	scene.hero.velocity = Vector3.ZERO
	for frame in range(20):
		scene.hero._physics_process(1.0 / 60.0)
	scene.controls.pressed_once["jump"] = true
	scene.hero._physics_process(1.0 / 60.0)
	check(scene.hero.velocity.y > 5 and scene.hero.velocity.z > 0, "jumping against a wall launches up and away")
	jump_wall.queue_free()
	scene.controls.movement = Vector2.ZERO
	scene.hero.position = Vector3(0, 5, 0)
	scene.hero.velocity = Vector3.ZERO
	await physics_frame
	scene.hero._physics_process(1.0 / 60.0)
	scene.hero.velocity = Vector3(20, 0, 0)
	scene.hero._physics_process(1.0 / 60.0)
	check(scene.hero.velocity.x > 19.8, "airborne swing-release momentum is preserved")
	scene.hero.coyote_timer = 0.1
	scene.controls.pressed_once["jump"] = true
	scene.hero._physics_process(1.0 / 60.0)
	check(scene.hero.velocity.y > 7, "a late jump works briefly after leaving a ledge")
	scene.hero.position = Vector3(0, 0.16, 0)
	scene.hero.velocity = Vector3(0, -3, 0)
	scene.hero.coyote_timer = 0
	scene.controls.pressed_once["jump"] = true
	var buffered_jumped := false
	for frame in range(8):
		scene.hero._physics_process(1.0 / 60.0)
		if scene.hero.velocity.y > 1:
			buffered_jumped = true
			break
	check(buffered_jumped, "jump pressed just before landing is buffered")
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
		if expected in [4, 5, 10, 11, 12]:
			check(is_instance_valid(scene.mission_prop) and not scene.mission_prop.is_queued_for_deletion(), "story objective has a visible prop at stage %d" % expected)
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
				scene._process(0.01)
				check(not scene.controls.enemy_name.is_empty() and scene.controls.enemy_health == previous, "nearby enemy health is displayed")
				scene.hero.attack()
				check(enemy.health == previous - 25, "hero attack damages enemy in stage %d" % expected)
				check(not scene.find_children("ImpactText*", "Label3D", true, false).is_empty(), "successful melee shows comic impact text")
				if expected == 1:
					scene.hero.shoot_web(Vector3.BACK)
					check(enemy.health == previous - 35 and enemy.stun == 2.0, "web shot damages and stuns enemy")
				if expected == 1:
					check(enemy.skeleton != null and enemy.strike_arm >= 0, "street enemy has a rigged striking arm")
					scene.hero.health = 100
					enemy.stun = 0
					enemy.attack_cooldown = 0
					enemy._physics_process(0.05)
					enemy._physics_process(0.25)
					check(enemy.strike_pose > 0, "street enemy animates a strike during its windup")
					enemy._physics_process(0.5)
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
				scene.hero.position = mission.at + Vector3(0, 0.1, 4)
				scene.interact()
				check(scene.stage == expected, "interaction requires being close to the visible prop")
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
	check(scene.hero.animator.speed_scale == 0, "pause freezes the hero animation")
	scene.show_help()
	check(is_instance_valid(scene.menu), "controls help opens")
	scene.close_credits()
	scene.show_credits()
	check(is_instance_valid(scene.menu), "credits open")
	check(FileAccess.file_exists("res://fonts/BANGERS-OFL.txt"), "comic font license is included")
	scene.close_credits()
	scene.resume_game()
	check(scene.hero.playing and scene.controls.active and scene.hero.animator.speed_scale == 1.0, "resume restarts gameplay and animation")
	scene.start_mode("Free Roam")
	check(scene.mode == "Free Roam" and scene.people.size() == 6, "free roam starts with citizens")
	check(not scene.hero.rope_active, "starting a mode clears the previous rope")
	for type in Missions.CRIMES:
		scene.start_crime()
		check(scene.crime_type == type and scene.enemies_alive() > 0, "crime spawns " + type)
		if type == "sabotage":
			check(is_instance_valid(scene.mission_prop) and scene.mission_prop.kind == "device", "sabotage has a visible device")
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
	scene.cutscenes_enabled = false
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
	# Simulate an older save landing inside a newly generated building.
	var building: StaticBody3D
	for child in scene.world.chunks[Vector2i(0, 0)].get_children():
		if child is StaticBody3D:
			building = child
			break
	check(building != null, "test block has a collidable building")
	if building:
		scene.hero.position = Vector3(building.position.x, 0.2, building.position.z)
		scene.save_game()
		scene.continue_mode("Story")
		await physics_frame
		await process_frame
		check(absf(fmod(scene.hero.position.x, WorldScript.CELL)) < 0.1 and absf(fmod(scene.hero.position.z, WorldScript.CELL)) < 0.1, "embedded save is recovered to a street")
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
	# Both save slots plus Resume create more options than fit in the menu.
	scene.pause_game()
	await process_frame
	await process_frame
	var menu_scroll: ScrollContainer = scene.menu.get_child(0).get_node("MenuScroll")
	check(menu_scroll.get_v_scroll_bar().max_value > menu_scroll.size.y, "full pause menu can scroll")
	var graphics_button: Button
	for button in menu_scroll.find_children("*", "Button", true, false):
		if button.text == "Graphics settings":
			graphics_button = button
	check(graphics_button != null, "full menu retains graphics settings")
	if graphics_button:
		menu_scroll.ensure_control_visible(graphics_button)
		await process_frame
		var help_rect := graphics_button.get_global_rect()
		var scroll_rect := menu_scroll.get_global_rect()
		check(help_rect.position.y >= scroll_rect.position.y - 1 and help_rect.end.y <= scroll_rect.end.y + 1, "last menu option can be scrolled into view")
	scene.resume_game()
	for target in scene.mission_enemies:
		target.hit(999, Vector3.FORWARD)
	scene.update_crime(0.01)
	scene.save_game()
	scene.continue_mode("Free Roam")
	check(scene.crime_phase == "interact" and is_instance_valid(scene.crime_civilian), "free roam restores rescue interaction")
	scene.start_mode("Free Roam")
	scene.crime_sequence = 2
	scene.start_crime()
	for target in scene.mission_enemies:
		target.hit(999, Vector3.FORWARD)
	scene.update_crime(0.01)
	scene.save_game()
	scene.continue_mode("Free Roam")
	check(scene.crime_phase == "interact" and is_instance_valid(scene.mission_prop) and scene.mission_prop.kind == "device", "free roam restores the sabotage device")
	scene.hero.position = scene.mission_prop.position + Vector3.UP * 0.1
	scene.interact()
	check(scene.crime_phase == "waiting", "restored sabotage device can be disarmed")
	check(not Saves.valid({"version": 1, "mode": "Story", "stage": 500, "health": 100, "position": [0,0,0]}, "Story"), "out of range stage rejected")
	check(not Saves.valid({"version": 1, "mode": "Story", "stage": 0, "health": 100, "position": [0,0,0], "crime_sequence": []}, "Story"), "malformed optional state rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Saves.slot_path("Story")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Saves.slot_path("Free Roam")))
	if not failed:
		print("Native scene smoke checks passed")
	quit(1 if failed else 0)
