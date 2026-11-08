extends CanvasLayer

var movement := Vector2.ZERO
var look_delta := Vector2.ZERO
var active := false
var touch_points: Dictionary = {}
var pressed_once: Dictionary = {}
var buttons_down: Dictionary = {}
var surface: Control
var status := ""
var message := ""
var objective := ""
var target_direction := Vector2.ZERO
var health := 100.0
var mirrored := false
var movement_pointer := -1

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var stored = config.get_value("controls", "mirrored", false)
		if stored is bool:
			mirrored = stored
	surface = Control.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.draw.connect(draw_controls)
	add_child(surface)

func stick_center() -> Vector2:
	var s := get_viewport().get_visible_rect().size
	return Vector2(s.x - 100 if mirrored else 100, s.y - 100)

func button_positions() -> Dictionary:
	var s := get_viewport().get_visible_rect().size
	var positions := {"menu": Vector2(s.x - 48, 50), "swing": Vector2(s.x - 82, s.y - 190), "shot": Vector2(s.x - 255, s.y - 85), "attack": Vector2(s.x - 165, s.y - 85), "jump": Vector2(s.x - 72, s.y - 85), "talk": Vector2(s.x - 165, s.y - 190)}
	if mirrored:
		for name in positions:
			var pos: Vector2 = positions[name]
			pos.x = s.x - pos.x
			positions[name] = pos
	return positions

func reset_input() -> void:
	touch_points.clear()
	buttons_down.clear()
	pressed_once.clear()
	movement = Vector2.ZERO
	look_delta = Vector2.ZERO
	movement_pointer = -1

func set_mirrored(value: bool) -> bool:
	mirrored = value
	reset_input()
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("controls", "mirrored", mirrored)
	return config.save("user://settings.cfg") == OK

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var name := ""
		match event.keycode:
			KEY_SPACE: name = "jump"
			KEY_F: name = "attack"
			KEY_Q: name = "shot"
			KEY_E: name = "talk"
			KEY_ESCAPE, KEY_BACK: name = "menu"
		if name != "":
			pressed_once[name] = true
	if event is InputEventScreenTouch:
		if event.pressed:
			var kind := "look"
			if event.position.distance_to(stick_center()) < 100:
				kind = "ignored"
				if movement_pointer == -1:
					movement_pointer = event.index
					kind = "move"
					set_movement(event.position)
			else:
				for name in button_positions():
					if event.position.distance_to(button_positions()[name]) < 42:
						kind = name
						buttons_down[name] = true
						pressed_once[name] = true
						break
			touch_points[event.index] = kind
		else:
			var kind: String = touch_points.get(event.index, "")
			touch_points.erase(event.index)
			if kind == "move" and movement_pointer == event.index:
				movement_pointer = -1
				movement = Vector2.ZERO
			elif kind not in ["look", "ignored", ""] and kind not in touch_points.values():
				buttons_down.erase(kind)
	if event is InputEventScreenDrag:
		var kind: String = touch_points.get(event.index, "")
		if kind == "move":
			set_movement(event.position)
		elif kind == "look":
			look_delta += event.relative

func set_movement(pos: Vector2) -> void:
	movement = ((pos - stick_center()) / 70.0).limit_length(1.0)

func consume(name: String) -> bool:
	var value: bool = pressed_once.get(name, false)
	pressed_once.erase(name)
	return value

func held(name: String) -> bool:
	return buttons_down.has(name)

func _process(_delta: float) -> void:
	if surface:
		surface.queue_redraw()

func draw_controls() -> void:
	if not active:
		return
	var s := get_viewport().get_visible_rect().size
	var center := stick_center()
	surface.draw_circle(center, 70, Color(0.03, 0.08, 0.12, 0.55))
	surface.draw_circle(center + movement * 48, 27, Color(0.75, 0.85, 0.9, 0.8))
	var labels := {"menu": "II", "swing": "WEB", "shot": "SHOT", "attack": "HIT", "jump": "JUMP", "talk": "TALK"}
	for name in button_positions():
		var p: Vector2 = button_positions()[name]
		var color := Color(0.60, 0.12, 0.16, 0.85) if name == "attack" else Color(0.09, 0.19, 0.27, 0.85)
		surface.draw_circle(p, 38, color)
		surface.draw_string(ThemeDB.fallback_font, p + Vector2(-25, 6), labels[name], HORIZONTAL_ALIGNMENT_CENTER, 50, 15, Color.WHITE)
	if target_direction.length_squared() > 0.01:
		var compass_center := Vector2(s.x * 0.5, 55)
		var direction := target_direction.normalized()
		var side := Vector2(-direction.y, direction.x)
		surface.draw_circle(compass_center, 25, Color(0.03, 0.08, 0.12, 0.65))
		var triangle := PackedVector2Array([compass_center + direction * 18, compass_center - direction * 11 + side * 9, compass_center - direction * 11 - side * 9])
		surface.draw_colored_polygon(triangle, Color(0.45, 0.9, 1.0))
	surface.draw_string(ThemeDB.fallback_font, Vector2(20, 32), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	surface.draw_rect(Rect2(20, 39, 180, 8), Color(0.1, 0.1, 0.12, 0.8))
	var health_color := Color(0.22, 0.85, 0.40) if health > 35 else Color(0.95, 0.24, 0.16)
	surface.draw_rect(Rect2(20, 39, 180 * clampf(health / 100.0, 0.0, 1.0), 8), health_color)
	surface.draw_string(ThemeDB.fallback_font, Vector2(20, 62), objective, HORIZONTAL_ALIGNMENT_LEFT, s.x - 40, 18, Color(0.75, 0.95, 1))
	surface.draw_string(ThemeDB.fallback_font, Vector2(20, 90), message, HORIZONTAL_ALIGNMENT_LEFT, s.x - 40, 18, Color.WHITE)
