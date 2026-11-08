extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var menu := root.get_texture().get_image()
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
