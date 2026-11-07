extends SceneTree

var failed := false

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
	check(scene.people.size() == 8, "story spawns citizens and enemies")
	check(scene.hero.animator != null, "hero animation player imported")
	check(scene.hero.skeleton != null, "hero skeleton imported")
	check(scene.hero.hand_bone >= 0, "hero hand bone imported")
	check(scene.hero.animator.has_animation("run"), "run animation imported")
	var enemy = scene.people[6]
	scene.hero.global_position = Vector3(0, 0.1, 0)
	enemy.global_position = Vector3(0, 0.1, -1.5)
	scene.hero.attack()
	check(enemy.health == 35, "player attack damages enemy")
	enemy.stun = 0
	enemy.attack_cooldown = 0
	enemy._physics_process(0.05)
	enemy._physics_process(0.7)
	check(scene.hero.health == 90, "enemy attacks damage the player")
	scene.hero.attach_web(Vector3(0, 0, -1))
	check(scene.hero.rope_active, "web finds an unobstructed roof")
	check(scene.hero.rope_length > 0, "rope length is set")
	scene.interact()
	check(scene.controls.message != "Move closer to someone to talk.", "nearby person can be interacted with")
	if not failed:
		print("Native scene smoke checks passed")
	quit(1 if failed else 0)
