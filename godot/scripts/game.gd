extends Node3D

const ComicBackdrop = preload("res://scripts/comic_backdrop.gd")
const ComicFont = preload("res://fonts/Bangers-Regular.ttf")
const WorldScript = preload("res://scripts/world.gd")
const HeroScript = preload("res://scripts/hero.gd")
const ObjectivePropScript = preload("res://scripts/objective_prop.gd")
const VehicleScript = preload("res://scripts/vehicle.gd")
const PersonScript = preload("res://scripts/person.gd")
const SoundScript = preload("res://scripts/sound.gd")
const ControlsScript = preload("res://scripts/controls.gd")
const Missions = preload("res://scripts/missions.gd")
const Saves = preload("res://scripts/saves.gd")
const CITIZENS = [preload("res://assets/citizen.glb"), preload("res://assets/citizen2.glb"), preload("res://assets/citizen3.glb"), preload("res://assets/citizen4.glb")]
const DOCTOR = preload("res://assets/doctor_octopus.glb")
var world
var hero
var controls
var sound
var people: Array = []
var traffic: Array = []
var mission_enemies: Array = []
var escort
var beacon: MeshInstance3D
var menu: CanvasLayer
var mode := ""
var stage := 0
var message_timer := 0.0
var chunk_timer := 0.0
var save_timer := 15.0
var save_enabled := true
var checkpoint := Vector3.ZERO
var crime_sequence := 0
var crime_phase := "waiting"
var crime_type := ""
var crime_target := Vector3.ZERO
var crime_timer := 12.0
var crime_completed := 0
var crime_failed := 0
var crime_civilian
var mission_prop

func _ready() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("7ac7df")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.8, 0.9)
	environment.ambient_light_energy = 0.55
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.3
	add_child(sun)
	world = Node3D.new()
	world.set_script(WorldScript)
	add_child(world)
	world.update_chunks(Vector3.ZERO)
	sound = Node.new()
	sound.set_script(SoundScript)
	add_child(sound)
	controls = CanvasLayer.new()
	controls.set_script(ControlsScript)
	add_child(controls)
	hero = CharacterBody3D.new()
	hero.set_script(HeroScript)
	hero.world = world
	hero.game = self
	hero.controls = controls
	add_child(hero)
	hero.position = Vector3(0, 0.2, 0)
	hero.setup()
	make_beacon()
	show_menu()

func make_beacon() -> void:
	beacon = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.5
	cylinder.height = 9.0
	beacon.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.8, 1.0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beacon.material_override = mat
	beacon.visible = false
	add_child(beacon)

func show_menu(can_resume: bool = false, can_retry: bool = false) -> void:
	if is_instance_valid(menu):
		menu.queue_free()
	menu = CanvasLayer.new()
	menu.layer = 3
	add_child(menu)
	var panel := Control.new()
	panel.set_script(ComicBackdrop)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -190
	box.offset_right = 190
	box.offset_top = -250
	box.offset_bottom = 250
	panel.add_child(box)
	var title := Label.new()
	title.text = "COMIC SPIDEY" + ("\nDEFEATED" if can_retry else "")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ComicFont)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("ffe15d"))
	title.add_theme_color_override("font_outline_color", Color("171429"))
	title.add_theme_constant_override("outline_size", 5)
	box.add_child(title)
	if can_resume:
		add_menu_button(box, "Resume", resume_game)
	if can_retry:
		add_menu_button(box, "Retry checkpoint", retry_checkpoint)
	add_menu_button(box, "Sound: " + ("On" if sound.enabled else "Off"), toggle_sound)
	add_menu_button(box, "Credits and licenses", show_credits)
	add_menu_button(box, "Layout: " + ("Mirrored" if controls.mirrored else "Default"), toggle_layout)
	for label in ["Story", "Free Roam"]:
		if save_enabled and not Saves.read(label).is_empty():
			add_menu_button(box, "Continue " + label, continue_mode.bind(label))
		add_menu_button(box, "New " + label, request_new_mode.bind(label))
	add_menu_button(box, "How to play", show_help)

func show_help() -> void:
	if is_instance_valid(menu):
		menu.queue_free()
	menu = CanvasLayer.new()
	menu.layer = 3
	add_child(menu)
	var panel := Control.new()
	panel.set_script(ComicBackdrop)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 130
	box.offset_right = -130
	box.offset_top = 60
	box.offset_bottom = -60
	panel.add_child(box)
	var heading := Label.new()
	heading.text = "HOW TO PLAY"
	heading.add_theme_font_override("font", ComicFont)
	heading.add_theme_font_size_override("font_size", 38)
	heading.add_theme_color_override("font_color", Color("ffe15d"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	var instructions := Label.new()
	instructions.text = """MOVE with the left stick. Drag empty space to look around.

Hold WEB to attach to a rooftop and swing; release to let go. Press JUMP while swinging for a boosted release.

Use HIT up close, or SHOT to web an enemy from a distance. TAP TALK near a person or objective to interact.

Follow the arrow and beacon. In Story, complete objectives and protect the city. In Free Roam, answer emergency calls.

Pause to change sound or mirror the controls. Your progress saves locally."""
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.add_theme_font_size_override("font_size", 22)
	instructions.add_theme_color_override("font_color", Color("fff8df"))
	instructions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(instructions)
	add_menu_button(box, "Back", close_credits)

func request_new_mode(selected: String) -> void:
	if not save_enabled or Saves.read(selected).is_empty():
		start_mode(selected)
		return
	if is_instance_valid(menu):
		menu.queue_free()
	menu = CanvasLayer.new()
	menu.layer = 3
	add_child(menu)
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.04, 0.08, 0.96)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -260
	box.offset_right = 260
	box.offset_top = -120
	box.offset_bottom = 120
	panel.add_child(box)
	var warning := Label.new()
	warning.text = "Starting a new %s game replaces that mode's save." % selected
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(warning)
	add_menu_button(box, "Cancel", close_credits)
	add_menu_button(box, "Start new " + selected, start_mode.bind(selected))

func show_credits() -> void:
	if OS.is_debug_build():
		print("Native credits opened")
	if is_instance_valid(menu):
		menu.queue_free()
	menu = CanvasLayer.new()
	menu.layer = 3
	add_child(menu)
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.04, 0.08, 0.98)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 40
	box.offset_right = -40
	box.offset_top = 20
	box.offset_bottom = -20
	panel.add_child(box)
	add_menu_button(box, "Back", close_credits)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var text := Label.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size.x = 1100
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.text = """COMIC SPIDEY — CREDITS AND LICENSES

Spider-Man character and animation: supplied by the user; animations identify Mixamo. Permission to redistribute supplied by the user. No official endorsement is implied.

Doctor Octopus model: LombaxLover2K. Licensed under Creative Commons Attribution 4.0. Source: https://sketchfab.com/3d-models/doctor-octopus-spider-man-2-ps2-32b278b99a9c400d8f34a46f0e401859
License: https://creativecommons.org/licenses/by/4.0/

Citizens: generated using Citizen Maker by Janelle Ghanem, MIT license, and MakeHuman CC0 base geometry. The Citizen Maker license is reproduced below.

Bangers font: Copyright 2010 The Bangers Project Authors; SIL Open Font License 1.1, reproduced below.

Godot Engine and its dependencies are credited and licensed below. The city geometry and synthesized audio are original to this project.

"""
	text.text += FileAccess.get_file_as_string("res://credits/CITIZEN-MAKER-LICENSE.txt")
	text.text += "\n\nBANGERS FONT LICENSE\n" + FileAccess.get_file_as_string("res://fonts/BANGERS-OFL.txt")
	text.text += "\n\nGODOT ENGINE LICENSE\n" + Engine.get_license_text()
	for license_name in Engine.get_license_info():
		text.text += "\n\n" + str(license_name) + "\n" + str(Engine.get_license_info()[license_name])
	scroll.add_child(text)

func close_credits() -> void:
	show_menu(is_instance_valid(hero) and not hero.playing and hero.health > 0 and not mode.is_empty(), is_instance_valid(hero) and hero.health <= 0)

func toggle_layout() -> void:
	if not controls.set_mirrored(not controls.mirrored):
		push_warning("Could not save the control layout setting")
	show_menu(is_instance_valid(hero) and not hero.playing and hero.health > 0 and not mode.is_empty(), is_instance_valid(hero) and hero.health <= 0)

func toggle_sound() -> void:
	sound.toggle()
	show_menu(is_instance_valid(hero) and not hero.playing and hero.health > 0 and not mode.is_empty(), is_instance_valid(hero) and hero.health <= 0)

func add_menu_button(box: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(380, 54)
	button.add_theme_font_override("font", ComicFont)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color("fff6db"))
	button.add_theme_color_override("font_hover_color", Color("171429"))
	button.add_theme_color_override("font_pressed_color", Color("171429"))
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("d64a49") if state == "normal" else Color("ffe15d")
		style.border_color = Color("171429")
		style.set_border_width_all(3)
		style.set_corner_radius_all(3)
		style.content_margin_left = 12
		style.content_margin_right = 12
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(callback)
	box.add_child(button)

func clear_people() -> void:
	if is_instance_valid(mission_prop):
		mission_prop.queue_free()
	mission_prop = null
	for car in traffic:
		if is_instance_valid(car):
			car.queue_free()
	traffic.clear()
	for npc in people:
		if is_instance_valid(npc):
			npc.queue_free()
	people.clear()
	mission_enemies.clear()
	escort = null
	crime_civilian = null

func start_mode(selected: String) -> void:
	if selected not in ["Story", "Free Roam"]:
		return
	mode = selected
	print("Native mode started: ", mode)
	stage = 0
	crime_sequence = 0
	crime_completed = 0
	crime_failed = 0
	crime_phase = "waiting"
	crime_timer = 12.0
	hero.health = 100
	hero.position = Vector3(0, 0.2, 0)
	hero.velocity = Vector3.ZERO
	checkpoint = hero.position
	begin_play()
	if mode == "Story":
		setup_story_stage()
	else:
		show_message("Explore the city. Watch for emergency calls.")
	save_game()

func begin_play() -> void:
	if is_instance_valid(menu):
		menu.queue_free()
	clear_people()
	hero.release_web()
	hero.web_retry = 0
	hero.swing_blocked_until_release = false
	hero.was_grounded = false
	hero.landing_timer = 0
	hero.punch_flash.visible = false
	hero.shot_line.visible = false
	hero.punch_timer = 0
	hero.shot_timer = 0
	hero.shot_cooldown = 0
	hero.attack_cooldown = 0
	if hero.skeleton:
		hero.skeleton.clear_bones_global_pose_override()
	controls.reset_input()
	world.update_chunks(hero.position)
	for i in range(6):
		spawn_local_civilian(i)
	for i in range(6):
		var car := CharacterBody3D.new()
		car.set_script(VehicleScript)
		car.game = self
		add_child(car)
		car.setup(i)
		traffic.append(car)
	hero.playing = true
	if hero.animator:
		hero.animator.speed_scale = 1.0
	controls.active = true

func spawn_local_civilian(index: int) -> void:
	var x := roundf(hero.position.x / 44.0) * 44.0 + float(index % 3 - 1) * 2.2
	var z := roundf(hero.position.z / 44.0) * 44.0 + float(index / 3 - 1) * 3.0
	var npc = spawn_person(Vector3(x, 0.2, z), false, false, index)
	npc.line = ["Thanks for watching over us.", "I saw trouble near the crossing.", "Be careful up there!", "The city is lucky to have you.", "I hope everyone gets home safely.", "Doctor Octopus is causing chaos."][index % 6]
	npc.local_civilian = true

func spawn_person(pos: Vector3, enemy: bool, boss: bool, variant: int):
	var npc = CharacterBody3D.new()
	npc.set_script(PersonScript)
	npc.position = pos + Vector3.UP * 0.2
	npc.hero = hero
	add_child(npc)
	npc.setup(DOCTOR if boss else CITIZENS[variant % CITIZENS.size()], enemy, boss, variant)
	people.append(npc)
	return npc

func spawn_wave(at: Vector3, count: int, boss: bool = false) -> void:
	mission_enemies.clear()
	for i in range(count):
		var npc = spawn_person(at + Vector3((i - (count - 1) * 0.5) * 2.0, 0, 2), true, boss, i)
		mission_enemies.append(npc)

func clear_mission_actors() -> void:
	if is_instance_valid(mission_prop):
		mission_prop.queue_free()
	mission_prop = null
	for enemy in mission_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	mission_enemies.clear()
	if is_instance_valid(escort):
		escort.queue_free()
	escort = null
	if is_instance_valid(crime_civilian):
		crime_civilian.queue_free()
	crime_civilian = null

func spawn_mission_prop(at: Vector3, kind: String) -> void:
	if is_instance_valid(mission_prop):
		mission_prop.queue_free()
	mission_prop = Node3D.new()
	mission_prop.set_script(ObjectivePropScript)
	mission_prop.game = self
	mission_prop.position = at + Vector3(2, 0, -2)
	add_child(mission_prop)
	mission_prop.setup(kind)

func setup_story_stage() -> void:
	clear_mission_actors()
	var mission: Dictionary = Missions.story_stage(stage)
	var at: Vector3 = mission.at
	match mission.type:
		"fight": spawn_wave(at, mission.count)
		"boss": spawn_wave(at, 1, true)
		"escort":
			escort = spawn_person(at, false, false, 1)
			escort.escorting = true
	if stage in [4, 5]:
		spawn_mission_prop(at, "relay")
	elif stage in [10, 11, 12]:
		spawn_mission_prop(at, "generator")
	show_message(str(mission.get("dialogue", mission.title)))
	update_beacon()

func advance_story() -> void:
	if stage >= Missions.STORY.size() - 1:
		return
	stage += 1
	sound.play_effect("success")
	checkpoint = hero.position
	setup_story_stage()
	save_game()

func enemies_alive() -> int:
	var count := 0
	for npc in mission_enemies:
		if is_instance_valid(npc) and not npc.is_queued_for_deletion() and npc.health > 0:
			count += 1
	return count

func update_story() -> void:
	var mission: Dictionary = Missions.story_stage(stage)
	match mission.type:
		"travel":
			if Missions.near(hero.position, mission.at, 6.0):
				advance_story()
		"fight", "boss":
			if enemies_alive() == 0:
				advance_story()
		"escort":
			if is_instance_valid(escort) and Missions.near(hero.position, mission.destination, 9.0) and Missions.near(escort.position, mission.destination, 9.0):
				advance_story()

func start_crime() -> void:
	clear_mission_actors()
	crime_type = Missions.CRIMES[crime_sequence % Missions.CRIMES.size()]
	crime_target = Missions.crime_location(hero.position, crime_sequence)
	crime_sequence += 1
	crime_phase = "fight"
	crime_timer = 90.0 if crime_type == "sabotage" else 0.0
	spawn_wave(crime_target, 3 if crime_type == "rescue" else 2)
	if crime_type == "rescue":
		crime_civilian = spawn_person(crime_target + Vector3(0, 0, -2), false, false, 1)
		crime_civilian.stationary = true
	elif crime_type == "sabotage":
		spawn_mission_prop(crime_target, "device")
	show_message("Emergency: " + crime_type.capitalize() + " at the beacon!")
	update_beacon()

func finish_crime(success: bool) -> void:
	if success:
		sound.play_effect("success")
		crime_completed += 1
		hero.health = minf(100, hero.health + 12)
		show_message("Emergency resolved. Health restored.")
	else:
		crime_failed += 1
		show_message("The emergency timed out.")
	clear_mission_actors()
	crime_phase = "waiting"
	crime_timer = 25.0
	update_beacon()
	save_game()

func update_crime(delta: float) -> void:
	if crime_phase == "waiting":
		crime_timer -= delta
		if crime_timer <= 0:
			start_crime()
		return
	if crime_type == "sabotage":
		crime_timer -= delta
		if crime_timer <= 0:
			finish_crime(false)
			return
	if crime_phase == "fight" and enemies_alive() == 0:
		if crime_type == "assault":
			finish_crime(true)
		else:
			crime_phase = "interact"
			show_message("Press TALK near the civilian." if crime_type == "rescue" else "Press TALK near the device to disarm it.")

func current_target() -> Variant:
	if mode == "Story":
		var mission: Dictionary = Missions.story_stage(stage)
		if mission.type == "complete":
			return null
		if mission.type == "escort":
			return mission.destination
		if mission.type == "interact" and is_instance_valid(mission_prop):
			return mission_prop.position
		return mission.at
	if crime_phase != "waiting":
		if crime_phase == "interact" and crime_type == "sabotage" and is_instance_valid(mission_prop):
			return mission_prop.position
		if crime_phase == "interact" and crime_type == "rescue" and is_instance_valid(crime_civilian):
			return crime_civilian.position
		return crime_target
	return null

func update_beacon() -> void:
	var target = current_target()
	beacon.visible = target != null
	if target != null:
		# Hide the column nearby so it cannot obscure the hero or a fight.
		beacon.visible = Vector2(hero.position.x - target.x, hero.position.z - target.z).length() > 8.0
		beacon.position = target + Vector3.UP * 4.5

func _process(delta: float) -> void:
	if not hero or not hero.playing:
		return
	chunk_timer -= delta
	if chunk_timer <= 0:
		world.update_chunks(hero.global_position)
		controls.district = world.district_for(Vector2i(floori(hero.position.x / world.CELL), floori(hero.position.z / world.CELL)))
		recenter_civilians()
		chunk_timer = 1
	message_timer -= delta
	if message_timer <= 0:
		controls.message = ""
	if mode == "Story":
		update_story()
	else:
		update_crime(delta)
	var target = current_target()
	controls.map_position = hero.global_position
	controls.map_yaw = hero.yaw
	controls.map_has_target = target != null
	if target != null:
		controls.map_target = target
	var distance := ""
	controls.target_direction = Vector2.ZERO
	if target != null:
		var direction: Vector3 = target - hero.position
		var forward := Vector3(-sin(hero.yaw), 0, -cos(hero.yaw))
		var right := Vector3(cos(hero.yaw), 0, -sin(hero.yaw))
		controls.target_direction = Vector2(direction.dot(right), -direction.dot(forward))
		distance = "  |  %dm" % roundi(Vector2(hero.position.x - target.x, hero.position.z - target.z).length())
	controls.health = hero.health
	controls.enemy_name = ""
	var nearest_enemy_distance := 12.0
	for enemy in mission_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.health > 0:
			var enemy_distance: float = hero.global_position.distance_to(enemy.global_position)
			if enemy_distance < nearest_enemy_distance:
				nearest_enemy_distance = enemy_distance
				controls.enemy_name = "DOCTOR OCTOPUS" if enemy.is_boss else "ATTACKER"
				controls.enemy_health = enemy.health
				controls.enemy_max_health = 200.0 if enemy.is_boss else 60.0
	controls.status = "%s  |  HEALTH %d  |  %s" % [mode.to_upper(), ceili(hero.health), "WEB ATTACHED" if hero.rope_active else "WEB READY"]
	if mode == "Story":
		controls.objective = Missions.story_stage(stage).title + distance
	else:
		var crime_action := "defeat attackers" if crime_phase == "fight" else ("TALK to civilian" if crime_type == "rescue" else "TALK to disarm device")
		controls.objective = ("Patrol the city" if crime_phase == "waiting" else "%s: %s" % [crime_type.capitalize(), crime_action]) + distance
		if crime_type == "sabotage" and crime_phase != "waiting":
			controls.objective += "  |  %ds" % ceili(crime_timer)
	update_beacon()
	save_timer -= delta
	if save_timer <= 0:
		save_timer = 15
		save_game()

func recenter_civilians() -> void:
	people = people.filter(func(npc): return is_instance_valid(npc) and not npc.is_queued_for_deletion())
	var index := 0
	for npc in people:
		if is_instance_valid(npc) and not npc.is_queued_for_deletion() and npc.local_civilian:
			if npc.global_position.distance_to(hero.global_position) > 75:
				var pos := Vector3(roundf(hero.position.x / 44.0) * 44.0 + (index % 3 - 1) * 2.0, 0.2, roundf(hero.position.z / 44.0) * 44.0 + (index / 3 - 1) * 3.0)
				npc.position = pos
				npc.origin = pos
			index += 1

func interact() -> void:
	if mode == "Story":
		var mission: Dictionary = Missions.story_stage(stage)
		if mission.type == "interact" and is_instance_valid(mission_prop) and Missions.near(hero.position, mission_prop.position, 3.5):
			advance_story()
			return
	elif crime_phase == "interact":
		var subject = mission_prop if crime_type == "sabotage" else crime_civilian
		if is_instance_valid(subject) and Missions.near(hero.position, subject.position, 3.5):
			finish_crime(true)
			return
	var nearest
	var distance := 3.5
	for npc in people:
		if is_instance_valid(npc) and not npc.is_queued_for_deletion() and npc.health > 0:
			var d: float = hero.global_position.distance_to(npc.global_position)
			if d < distance:
				var ray := PhysicsRayQueryParameters3D.create(hero.global_position + Vector3.UP, npc.global_position + Vector3.UP, 1)
				if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
					distance = d
					nearest = npc
	if nearest:
		if nearest.is_boss:
			show_message("Doctor Octopus: You cannot stop me!")
		elif nearest.is_enemy:
			show_message("Attacker: Get out of our way!")
		elif nearest.escorting:
			show_message("Civilian: I'll follow you to safety!")
		else:
			var replies := [nearest.line, "I heard sirens nearby. Stay alert.", "Thanks for helping people in this city."]
			show_message("Civilian: " + str(replies[nearest.conversations % replies.size()]))
			nearest.conversations += 1
	else:
		show_message("Move closer to someone or an objective to use TALK.")

func comic_popup(text: String, at: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = "ImpactText"
	label.text = text
	label.font = ComicFont
	label.font_size = 80
	label.pixel_size = 0.008
	label.outline_size = 14
	label.modulate = color
	label.outline_modulate = Color("171429")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = at + Vector3.UP * 2.2
	add_child(label, true)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 0.8, 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)

func show_message(text: String) -> void:
	controls.message = text
	message_timer = 6

func pause_game() -> void:
	save_game()
	hero.playing = false
	if hero.animator:
		hero.animator.speed_scale = 0.0
	controls.active = false
	controls.reset_input()
	for npc in people:
		if is_instance_valid(npc):
			npc.set_physics_process(false)
			if npc.anim:
				npc.anim.speed_scale = 0.0
	for car in traffic:
		if is_instance_valid(car):
			car.set_physics_process(false)
	show_menu(true)

func resume_game() -> void:
	if OS.is_debug_build():
		print("Native game resumed")
	if is_instance_valid(menu):
		menu.queue_free()
	for npc in people:
		if is_instance_valid(npc):
			npc.set_physics_process(true)
	for car in traffic:
		if is_instance_valid(car):
			car.set_physics_process(true)
	hero.playing = true
	if hero.animator:
		hero.animator.speed_scale = 1.0
	controls.active = true

func game_over() -> void:
	if hero.animator:
		hero.animator.speed_scale = 0.0
	controls.active = false
	for npc in people:
		if is_instance_valid(npc):
			npc.set_physics_process(false)
			if npc.anim:
				npc.anim.speed_scale = 0.0
	for car in traffic:
		if is_instance_valid(car):
			car.set_physics_process(false)
	show_menu(false, true)

func retry_checkpoint() -> void:
	hero.health = 100
	hero.position = checkpoint
	hero.velocity = Vector3.ZERO
	begin_play()
	if mode == "Story":
		setup_story_stage()
	else:
		crime_phase = "waiting"
		crime_timer = 12
		show_message("Back on patrol.")
	save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(hero) and hero.playing:
		pause_game()

func vector_data(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func data_vector(v: Array) -> Vector3:
	return Vector3(float(v[0]), float(v[1]), float(v[2]))

func save_game() -> void:
	if not save_enabled or not is_instance_valid(hero) or not hero.playing or hero.health <= 0 or mode.is_empty():
		return
	var enemies: Array = []
	for npc in mission_enemies:
		if is_instance_valid(npc) and not npc.is_queued_for_deletion() and npc.health > 0:
			enemies.append({"position": vector_data(npc.position), "health": npc.health})
	var state := {
		"version": Saves.VERSION, "mode": mode, "stage": stage,
		"position": vector_data(hero.position), "health": hero.health,
		"checkpoint": vector_data(checkpoint), "enemies": enemies,
		"crime_sequence": crime_sequence, "crime_phase": crime_phase,
		"crime_type": crime_type, "crime_target": vector_data(crime_target),
		"crime_timer": crime_timer, "crime_completed": crime_completed, "crime_failed": crime_failed,
	}
	if is_instance_valid(escort):
		state["escort"] = vector_data(escort.position)
	if not Saves.write(mode, state):
		show_message("Could not save progress on this device.")

func continue_mode(selected: String) -> void:
	var state: Dictionary = Saves.read(selected)
	if state.is_empty():
		return
	mode = selected
	stage = int(state.stage)
	hero.position = data_vector(state.position)
	hero.velocity = Vector3.ZERO
	hero.health = float(state.health)
	checkpoint = data_vector(state.checkpoint) if Saves.valid_position(state.get("checkpoint")) else hero.position
	crime_sequence = clampi(int(state.get("crime_sequence", 0)), 0, 1000000)
	crime_completed = clampi(int(state.get("crime_completed", 0)), 0, 1000000)
	crime_failed = clampi(int(state.get("crime_failed", 0)), 0, 1000000)
	crime_phase = str(state.get("crime_phase", "waiting"))
	crime_type = str(state.get("crime_type", ""))
	crime_timer = clampf(float(state.get("crime_timer", 12.0)), 0.0, 90.0)
	crime_target = data_vector(state.crime_target) if Saves.valid_position(state.get("crime_target")) else Vector3.ZERO
	if crime_phase not in ["waiting", "fight", "interact"] or (crime_phase != "waiting" and crime_type not in Missions.CRIMES):
		crime_phase = "waiting"
		crime_timer = 12.0
	begin_play()
	if mode == "Story":
		setup_story_stage()
		if is_instance_valid(escort) and Saves.valid_position(state.get("escort")):
			escort.position = data_vector(state.escort)
		if Missions.story_stage(stage).type in ["fight", "boss"]:
			restore_enemies(state.get("enemies"), Missions.story_stage(stage).type == "boss")
	elif crime_phase != "waiting":
		if crime_phase == "fight":
			restore_enemies(state.get("enemies"), false)
		if crime_type == "rescue":
			crime_civilian = spawn_person(crime_target + Vector3(0, 0, -2), false, false, 1)
			crime_civilian.stationary = true
		elif crime_type == "sabotage":
			spawn_mission_prop(crime_target, "device")
	update_beacon()
	show_message("Progress restored.")

func restore_enemies(data, boss: bool) -> void:
	if not data is Array or data.size() > 3:
		return
	for item in data:
		if not item is Dictionary or not Saves.valid_position(item.get("position")):
			return
		var hp = item.get("health")
		if not (hp is int or hp is float) or not is_finite(float(hp)) or float(hp) <= 0 or float(hp) > (200 if boss else 60):
			return
	for old in mission_enemies:
		if is_instance_valid(old):
			old.queue_free()
	mission_enemies.clear()
	for i in range(data.size()):
		var npc = spawn_person(data_vector(data[i].position) - Vector3.UP * 0.2, true, boss, i)
		npc.health = float(data[i].health)
		mission_enemies.append(npc)
