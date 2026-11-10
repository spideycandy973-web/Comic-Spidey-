extends CanvasLayer

const ComicFont = preload("res://fonts/Bangers-Regular.ttf")
const CONTROL_SCALES := [0.9, 1.0, 1.15]
const CONTROL_SIZE_LABELS := ["Compact", "Large", "Extra large"]

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
var map_position := Vector3.ZERO
var map_yaw := 0.0
var map_target := Vector3.ZERO
var map_has_target := false
var district := "Downtown"
var enemy_name := ""
var enemy_health := 0.0
var enemy_max_health := 1.0
var health := 100.0
var mirrored := false
var control_size_index := 1
var movement_pointer := -1

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var stored = config.get_value("controls", "mirrored", false)
		if stored is bool:
			mirrored = stored
		var size = config.get_value("controls", "size_index", 1)
		if size is int and size >= 0 and size < CONTROL_SCALES.size():
			control_size_index = size
	surface = Control.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.draw.connect(draw_controls)
	add_child(surface)

func control_scale() -> float:
	return CONTROL_SCALES[control_size_index]

func stick_center() -> Vector2:
	var s := get_viewport().get_visible_rect().size
	var inset := 110.0 * control_scale()
	return Vector2(s.x - inset if mirrored else inset, s.y - inset)

func button_positions() -> Dictionary:
	var s := get_viewport().get_visible_rect().size
	var k := control_scale()
	var positions := {"menu": Vector2(s.x - 48 * k, 50 * k), "swing": Vector2(s.x - 68 * k, s.y - 205 * k), "shot": Vector2(s.x - 285 * k, s.y - 75 * k), "attack": Vector2(s.x - 177 * k, s.y - 75 * k), "jump": Vector2(s.x - 68 * k, s.y - 75 * k), "talk": Vector2(s.x - 177 * k, s.y - 205 * k)}
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

func set_control_size(value: int) -> bool:
	control_size_index = clampi(value, 0, CONTROL_SCALES.size() - 1)
	reset_input()
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("controls", "size_index", control_size_index)
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
			if event.position.distance_to(stick_center()) < 110.0 * control_scale():
				kind = "ignored"
				if movement_pointer == -1:
					movement_pointer = event.index
					kind = "move"
					set_movement(event.position)
			else:
				for name in button_positions():
					if event.position.distance_to(button_positions()[name]) < (46.0 if name == "menu" else 52.0) * control_scale():
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
	movement = ((pos - stick_center()) / (70.0 * control_scale())).limit_length(1.0)

func consume(name: String) -> bool:
	var value: bool = pressed_once.get(name, false)
	pressed_once.erase(name)
	return value

func held(name: String) -> bool:
	return buttons_down.has(name)

func _process(_delta: float) -> void:
	if surface:
		surface.queue_redraw()

func map_offset(from: Vector3, to: Vector3) -> Vector2:
	return (Vector2(to.x - from.x, to.z - from.z) * 0.9).limit_length(72.0)

func draw_minimap(screen_size: Vector2) -> void:
	var center := Vector2(screen_size.x - 115, 170)
	var inner := Rect2(center - Vector2(76, 76), Vector2(152, 152))
	surface.draw_rect(inner.grow(5), Color("171429"))
	surface.draw_rect(inner, Color("e6d8ad"))
	# World-aligned roads and parks; north is always at the top.
	var cell := 44.0
	var base_x := floori(map_position.x / cell)
	var base_z := floori(map_position.z / cell)
	for x in range(base_x - 3, base_x + 4):
		for z in range(base_z - 3, base_z + 4):
			if absi(x * 7 + z * 11) % 17 == 5:
				var p := center + Vector2((x * cell + 5.5 - map_position.x) * 0.9, (z * cell + 5.5 - map_position.z) * 0.9)
				var park := Rect2(p, Vector2(29.7, 29.7)).intersection(inner)
				if park.has_area():
					surface.draw_rect(park, Color("75a86b"))
	for i in range(-3, 4):
		var x := center.x + ((base_x + i) * cell - map_position.x) * 0.9
		var z := center.y + ((base_z + i) * cell - map_position.z) * 0.9
		if x >= inner.position.x and x <= inner.end.x:
			surface.draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), Color("70808b"), 8)
		if z >= inner.position.y and z <= inner.end.y:
			surface.draw_line(Vector2(inner.position.x, z), Vector2(inner.end.x, z), Color("70808b"), 8)
	if map_has_target:
		var objective_point := center + map_offset(map_position, map_target)
		surface.draw_circle(objective_point, 7, Color("171429"))
		surface.draw_circle(objective_point, 4, Color("ed524d"))
	var heading := Vector2(-sin(map_yaw), -cos(map_yaw))
	var sideways := Vector2(-heading.y, heading.x)
	var triangle := PackedVector2Array([center + heading * 10, center - heading * 7 + sideways * 6, center - heading * 7 - sideways * 6])
	surface.draw_colored_polygon(triangle, Color("171429"))
	var small := PackedVector2Array([center + heading * 6, center - heading * 5 + sideways * 3, center - heading * 5 - sideways * 3])
	surface.draw_colored_polygon(small, Color("36b4de"))
	surface.draw_string(ComicFont, inner.position + Vector2(6, 17), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("171429"))
	surface.draw_string_outline(ComicFont, Vector2(inner.position.x + 6, inner.end.y - 6), district, HORIZONTAL_ALIGNMENT_LEFT, 140, 15, 3, Color("fff3d0"))
	surface.draw_string(ComicFont, Vector2(inner.position.x + 6, inner.end.y - 6), district, HORIZONTAL_ALIGNMENT_LEFT, 140, 15, Color("171429"))

func draw_controls() -> void:
	if not active:
		return
	var s := get_viewport().get_visible_rect().size
	var center := stick_center()
	draw_minimap(s)
	var k := control_scale()
	surface.draw_circle(center, 85 * k, Color(0.06, 0.05, 0.10, 0.8))
	surface.draw_circle(center, 80 * k, Color(0.12, 0.34, 0.48, 0.8))
	surface.draw_circle(center + movement * 52 * k, 33 * k, Color("171429"))
	surface.draw_circle(center + movement * 52 * k, 28 * k, Color("ffe15d"))
	var labels := {"menu": "II", "swing": "WEB", "shot": "SHOT", "attack": "HIT", "jump": "JUMP", "talk": "TALK"}
	for name in button_positions():
		var p: Vector2 = button_positions()[name]
		var color := Color("e14c49") if name == "attack" else Color("266d89")
		surface.draw_circle(p, (51 if name != "menu" else 44) * k, Color("171429"))
		surface.draw_circle(p, (46 if name != "menu" else 39) * k, color)
		surface.draw_string(ComicFont, p + Vector2(-45, 9) * k, labels[name], HORIZONTAL_ALIGNMENT_CENTER, 90 * k, roundi(27 * k), Color("fff8e8"))
	if target_direction.length_squared() > 0.01:
		var compass_center := Vector2(s.x * 0.5, 55)
		var direction := target_direction.normalized()
		var side := Vector2(-direction.y, direction.x)
		surface.draw_circle(compass_center, 25, Color(0.03, 0.08, 0.12, 0.65))
		var triangle := PackedVector2Array([compass_center + direction * 18, compass_center - direction * 11 + side * 9, compass_center - direction * 11 - side * 9])
		surface.draw_colored_polygon(triangle, Color(0.45, 0.9, 1.0))
	surface.draw_rect(Rect2(12, 8, 370, 65), Color("171429"))
	surface.draw_rect(Rect2(16, 12, 362, 57), Color("fff3cc"))
	surface.draw_string(ComicFont, Vector2(25, 37), status, HORIZONTAL_ALIGNMENT_LEFT, 345, 22, Color("171429"))
	surface.draw_rect(Rect2(25, 44, 180, 12), Color("171429"))
	var health_color := Color(0.22, 0.85, 0.40) if health > 35 else Color(0.95, 0.24, 0.16)
	surface.draw_rect(Rect2(27, 46, 176 * clampf(health / 100.0, 0.0, 1.0), 8), health_color)
	surface.draw_rect(Rect2(12, 78, 470, 34), Color("171429"))
	surface.draw_rect(Rect2(16, 82, 462, 26), Color("ffe15d"))
	surface.draw_string(ComicFont, Vector2(25, 102), objective, HORIZONTAL_ALIGNMENT_LEFT, 446, 21, Color("171429"))
	if not enemy_name.is_empty():
		surface.draw_rect(Rect2(12, 154, 250, 43), Color("171429"))
		surface.draw_rect(Rect2(16, 158, 242, 35), Color("fff3cc"))
		surface.draw_string(ComicFont, Vector2(23, 176), enemy_name, HORIZONTAL_ALIGNMENT_LEFT, 225, 18, Color("171429"))
		surface.draw_rect(Rect2(23, 180, 225, 8), Color("171429"))
		surface.draw_rect(Rect2(25, 182, 221 * clampf(enemy_health / maxf(enemy_max_health, 1.0), 0.0, 1.0), 4), Color("e65049"))
	if not message.is_empty():
		surface.draw_string_outline(ComicFont, Vector2(20, 143), message, HORIZONTAL_ALIGNMENT_LEFT, s.x - 40, 21, 4, Color("171429"))
		surface.draw_string(ComicFont, Vector2(20, 143), message, HORIZONTAL_ALIGNMENT_LEFT, s.x - 40, 21, Color.WHITE)
