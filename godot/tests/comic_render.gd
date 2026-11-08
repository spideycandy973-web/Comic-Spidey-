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
	print("Comic menu and gameplay frames rendered")
	quit(0)
