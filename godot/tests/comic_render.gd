extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	# Wait for initial desktop/window resize events before inspecting the menu.
	for i in range(8):
		await process_frame
		await RenderingServer.frame_post_draw
	var menu := root.get_texture().get_image()
	print("Menu viewport: ", menu.get_size(), " panel: ", scene.menu.get_child(0).size)
	var corner := menu.get_pixel(menu.get_width() - 10, menu.get_height() - 10)
	if corner.r > 0.35 and absf(corner.r - corner.g) < 0.03 and absf(corner.g - corner.b) < 0.03:
		push_error("TEST FAILED: comic menu does not fill the viewport")
		quit(1)
		return
	menu.resize(480, 270)
	menu.save_jpg("/tmp/comic-menu.jpg", 0.4)
	scene.save_enabled = false
	scene.start_mode("Free Roam")
	scene.set_process(false)
	scene.hero.set_physics_process(false)
	for person in scene.people:
		person.set_physics_process(false)
	for car in scene.traffic:
		car.set_physics_process(false)
	scene.hero.position = Vector3(0, 0.2, 0)
	scene.hero.camera.global_position = Vector3(0, 3.1, 6)
	scene.hero.camera.look_at(Vector3(0, 1.2, -20), Vector3.UP)
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.resize(480, 270)
	image.save_jpg("/tmp/comic-game.jpg", 0.4)
	# Verify that an interaction objective is actually rendered, not merely
	# present in the scene tree. Compare the same view with its prop hidden.
	scene.mode = "Story"
	scene.stage = 5
	scene.hero.position = Vector3(88, 0.2, -128)
	scene.hero.visual.visible = false
	scene.controls.active = false
	scene.controls.surface.queue_redraw()
	scene.world.update_chunks(scene.hero.position)
	scene.setup_story_stage()
	scene.beacon.visible = false
	scene.mission_prop.set_process(false)
	scene.hero.camera.global_position = Vector3(90, 2.8, -126)
	scene.hero.camera.look_at(Vector3(90, 1.5, -134), Vector3.UP)
	scene.mission_prop.visible = false
	await physics_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var empty := root.get_texture().get_image()
	scene.mission_prop.visible = true
	await process_frame
	await RenderingServer.frame_post_draw
	var with_prop := root.get_texture().get_image()
	var changed := 0
	for x in range(0, with_prop.get_width(), 4):
		for y in range(0, with_prop.get_height(), 4):
			var a := empty.get_pixel(x, y)
			var b := with_prop.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.12:
				changed += 1
	with_prop.resize(384, 216)
	with_prop.save_jpg("/tmp/comic-objective.jpg", 0.35)
	print("Objective rendered pixel changes: ", changed)
	if changed < 30:
		push_error("TEST FAILED: objective prop is not visibly rendered")
		quit(1)
		return
	print("Comic menu, gameplay and objective frames rendered")
	quit(0)
