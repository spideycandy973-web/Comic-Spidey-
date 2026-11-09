extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	scene.save_enabled = false
	scene.cutscenes_enabled = false
	scene.start_mode("Story")
	scene.set_process(false)
	scene.hero.set_physics_process(false)
	for person in scene.people:
		person.set_physics_process(false)
	for car in scene.traffic:
		car.set_physics_process(false)
	scene.stage = 3
	scene.hero.position = Vector3(0, 0.2, -128)
	scene.world.update_chunks(scene.hero.position)
	scene.setup_story_stage()
	var boss = scene.mission_enemies[0]
	boss.set_physics_process(false)
	boss.position = Vector3(0, 0.2, -132)
	scene.hero.visual.visible = false
	scene.beacon.visible = false
	scene.controls.active = false
	scene.hero.camera.global_position = Vector3(0, 2.6, -125)
	scene.hero.camera.look_at(Vector3(0, 1.3, -132), Vector3.UP)
	for material in boss.tentacle_materials:
		material.set_shader_parameter("motion_time", 0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var first := root.get_texture().get_image()
	for material in boss.tentacle_materials:
		material.set_shader_parameter("motion_time", 1.6)
	await process_frame
	await RenderingServer.frame_post_draw
	var second := root.get_texture().get_image()
	var changed := 0
	for x in range(0, second.get_width(), 3):
		for y in range(0, second.get_height(), 3):
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.12:
				changed += 1
	second.resize(384, 216)
	second.save_jpg("/tmp/native-boss.jpg", 0.3)
	print("Boss rendered pixel changes: ", changed)
	if boss.tentacle_materials.size() != 2 or changed < 12:
		push_error("TEST FAILED: boss tentacle deformation not visibly rendered")
		quit(1)
		return
	print("Native boss rendering check passed")
	quit(0)
