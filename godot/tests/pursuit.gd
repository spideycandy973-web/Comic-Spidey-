extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

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
	for car in scene.traffic:
		car.set_physics_process(false)
		car.position = Vector3(500, 0, 500)
	scene.hero.position = Vector3(0, 0.2, -24)
	var enemy = scene.spawn_person(Vector3(0, 0, -16), true, false, 0)
	enemy.set_physics_process(false)
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4, 2.5, 0.5)
	collision.shape = shape
	wall.add_child(collision)
	wall.position = Vector3(0, 1.25, -20)
	scene.add_child(wall)
	await physics_frame
	for frame in range(480):
		enemy._physics_process(1.0 / 60.0)
		await physics_frame
		if scene.hero.health < 100:
			break
	print("Pursuit position: ", enemy.position, " hero health: ", scene.hero.health)
	if enemy.position.z > -20.5 or scene.hero.health >= 100:
		push_error("TEST FAILED: enemy did not navigate around obstacle and attack")
		quit(1)
		return
	print("Obstacle pursuit and attack passed")
	quit(0)
