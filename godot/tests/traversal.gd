extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_test")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("TEST FAILED: " + message)
		failures += 1

func settle(scene) -> void:
	scene.controls.movement = Vector2.ZERO
	scene.hero.position = Vector3(0, 0.2, 0)
	scene.hero.velocity = Vector3.ZERO
	scene.hero.yaw = 0.0
	for i in range(15):
		await physics_frame

func drive(scene, input: Vector2, frames: int) -> void:
	scene.controls.movement = input
	for i in range(frames):
		await physics_frame

func run_test() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	scene.save_enabled = false
	scene.start_mode("Free Roam")
	scene.set_process(false)
	for npc in scene.people:
		npc.set_physics_process(false)
	for car in scene.traffic:
		car.set_physics_process(false)
		car.position = Vector3(500, 0, 500)
	var hero = scene.hero
	await settle(scene)
	scene.controls.set_movement(scene.controls.stick_center() + Vector2(2, 0))
	check(scene.controls.movement == Vector2.ZERO, "joystick deadzone suppresses tiny touches")
	await drive(scene, Vector2(0, -1), 60)
	var forward_speed := Vector2(hero.velocity.x, hero.velocity.z).length()
	check(hero.velocity.z < -6.8 and absf(hero.velocity.x) < 0.1, "forward moves in the camera-facing direction")
	check(absf(wrapf(hero.visual.rotation.y, -PI, PI)) < 0.2, "hero turns to face forward motion")
	await settle(scene)
	await drive(scene, Vector2(1, -1).normalized(), 60)
	var diagonal_speed := Vector2(hero.velocity.x, hero.velocity.z).length()
	check(hero.velocity.x > 4.0 and hero.velocity.z < -4.0, "diagonal input moves in both directions")
	check(diagonal_speed <= forward_speed + 0.15, "diagonal motion is not faster than forward motion")
	await settle(scene)
	await drive(scene, Vector2(0, 1), 60)
	check(hero.velocity.z > 6.8, "backward input reverses direction")
	check(absf(absf(wrapf(hero.visual.rotation.y, -PI, PI)) - PI) < 0.2, "hero turns to face backward travel")
	await settle(scene)
	hero.yaw = PI / 2.0
	await drive(scene, Vector2(0, -1), 60)
	check(hero.velocity.x < -6.8 and absf(hero.velocity.z) < 0.15, "forward follows a turned camera")
	await settle(scene)
	scene.controls.pressed_once["jump"] = true
	await physics_frame
	await physics_frame
	check(hero.velocity.y > 5.0 and hero.position.y > 0.2, "jump gives an upward physical impulse")
	await settle(scene)
	scene.sun.shadow_enabled = false
	hero.update_contact_shadow()
	check(hero.contact_shadow.visible, "fallback contact shadow is shown with sun shadows off")
	scene.sun.shadow_enabled = true
	hero.update_contact_shadow()
	check(not hero.contact_shadow.visible, "fallback shadow is hidden when sun shadows are on")
	# Camera must be in front of a wall behind the player even while smoothing.
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5, 6, 0.25)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0, 2, 3)
	scene.add_child(wall)
	hero.camera.global_position = Vector3(0, 2.5, 6)
	await physics_frame
	await physics_frame
	hero.update_camera(1.0 / 60.0)
	check(hero.camera.global_position.z < 3.0, "camera remains on the hero side of an obstruction")
	wall.queue_free()
	if failures > 0:
		quit(1)
		return
	print("Forward, diagonal, reverse, camera-relative movement, jump, shadow and camera checks passed")
	quit(0)
