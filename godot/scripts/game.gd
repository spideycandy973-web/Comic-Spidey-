extends Node3D

const WorldScript = preload("res://scripts/world.gd")
const HeroScript = preload("res://scripts/hero.gd")
const PersonScript = preload("res://scripts/person.gd")
const ControlsScript = preload("res://scripts/controls.gd")
const CITIZENS = [preload("res://assets/citizen.glb"), preload("res://assets/citizen2.glb")]
const DOCTOR = preload("res://assets/doctor_octopus.glb")
var world
var hero
var controls
var people: Array = []
var menu: CanvasLayer
var mode := ""
var stage := 0
var message_timer := 0.0
var chunk_timer := 0.0

func _ready() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("89b3d0")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.8, 0.9)
	environment.ambient_light_energy = 0.8
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
	show_menu()

func show_menu() -> void:
	menu = CanvasLayer.new()
	menu.layer = 3
	add_child(menu)
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.04, 0.08, 0.88)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -180
	box.offset_right = 180
	box.offset_top = -120
	box.offset_bottom = 120
	panel.add_child(box)
	var title := Label.new()
	title.text = "COMIC SPIDEY\nNATIVE ENGINE DEVELOPMENT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	for label in ["Story", "Free Roam"]:
		var button := Button.new()
		button.text = label
		button.custom_minimum_size = Vector2(360, 65)
		button.pressed.connect(start_mode.bind(label))
		box.add_child(button)

func start_mode(selected: String) -> void:
	if is_instance_valid(menu):
		menu.queue_free()
	mode = selected
	stage = 0
	hero.health = 100
	hero.position = Vector3(0, 0.2, 0)
	hero.velocity = Vector3.ZERO
	hero.playing = true
	controls.active = true
	for npc in people:
		if is_instance_valid(npc):
			npc.queue_free()
	people.clear()
	for i in range(6):
		spawn_person(Vector3(-4 + i * 1.5, 0.2, -4), false, false, i)
	spawn_person(Vector3(3, 0.2, -7), true, false, 0)
	spawn_person(Vector3(5, 0.2, -8), true, false, 1)
	if mode == "Story":
		show_message("Story: stop the attackers, then face Doctor Octopus.")
	else:
		spawn_person(Vector3(8, 0.2, -10), true, true, 0)
		show_message("Free Roam: explore, talk, and stop the attackers.")

func spawn_person(pos: Vector3, enemy: bool, boss: bool, variant: int):
	var npc = CharacterBody3D.new()
	npc.set_script(PersonScript)
	npc.position = pos
	npc.hero = hero
	add_child(npc)
	npc.setup(DOCTOR if boss else CITIZENS[variant % CITIZENS.size()], enemy, boss)
	people.append(npc)
	return npc

func _process(delta: float) -> void:
	if not hero or not hero.playing:
		return
	chunk_timer -= delta
	if chunk_timer <= 0:
		world.update_chunks(hero.global_position)
		chunk_timer = 1
	message_timer -= delta
	if message_timer <= 0:
		controls.message = ""
	var remaining := 0
	for npc in people:
		if is_instance_valid(npc) and npc.is_enemy and npc.health > 0:
			remaining += 1
	controls.status = "%s  |  HEALTH %d  |  ENEMIES %d  |  %s" % [mode.to_upper(), ceili(hero.health), remaining, "WEB ATTACHED" if hero.rope_active else "WEB READY"]
	if mode == "Story" and stage == 0 and remaining == 0:
		stage = 1
		spawn_person(hero.global_position + Vector3(6, 0, -6), true, true, 0)
		show_message("Doctor Octopus has arrived!")
	elif mode == "Story" and stage == 1 and remaining == 0:
		stage = 2
		show_message("Doctor Octopus defeated.")

func interact() -> void:
	var nearest
	var distance := 3.5
	for npc in people:
		if is_instance_valid(npc) and npc.health > 0:
			var d: float = hero.global_position.distance_to(npc.global_position)
			if d < distance:
				distance = d
				nearest = npc
	if nearest:
		if nearest.is_boss:
			show_message("Doctor Octopus: You cannot stop me!")
		elif nearest.is_enemy:
			show_message("Attacker: Get out of our way!")
		else:
			show_message("Civilian: " + nearest.line)
	else:
		show_message("Move closer to someone to talk.")

func show_message(text: String) -> void:
	controls.message = text
	message_timer = 4

func game_over() -> void:
	controls.active = false
	show_menu()
