extends Control

# Flat screen-space artwork: a comic-book burst and halftone, with no textures
# or extra scene draw calls in gameplay.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var s := size
	var center := Vector2(s.x * 0.5, s.y * 0.46)
	var radius := s.length() * 1.2
	draw_rect(Rect2(Vector2.ZERO, s), Color("163550"))
	for i in range(16):
		var a := TAU * float(i) / 16.0
		var b := TAU * (float(i) + 0.48) / 16.0
		var points := PackedVector2Array([center, center + Vector2(cos(a), sin(a)) * radius, center + Vector2(cos(b), sin(b)) * radius])
		draw_colored_polygon(points, Color(0.12, 0.32, 0.43, 0.65))
	for x in range(18, int(s.x), 34):
		for y in range(18, int(s.y), 34):
			draw_circle(Vector2(x, y), 2.3, Color(0.01, 0.05, 0.09, 0.5))
	draw_rect(Rect2(0, 0, s.x, 9), Color("171429"))
	draw_rect(Rect2(0, s.y - 9, s.x, 9), Color("171429"))
