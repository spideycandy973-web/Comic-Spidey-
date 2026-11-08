extends Node3D

const ComicStyle = preload("res://scripts/comic_style.gd")
const ComicFont = preload("res://fonts/Bangers-Regular.ttf")

var game
var signal_light: MeshInstance3D
var marker: Node3D
var elapsed := 0.0
var kind := ""

func setup(prop_kind: String) -> void:
	kind = prop_kind
	var dark := material(Color("26364a"))
	var body_color := Color("e5b844") if kind == "relay" else (Color("568bb3") if kind == "generator" else Color("b4444c"))
	var body := material(body_color)
	var accent := material(Color("ffe56b") if kind != "device" else Color("ff716a"))
	make_box(Vector3(2.2, 0.3, 1.6), Vector3(0, 0.15, 0), dark)
	make_box(Vector3(1.7, 1.8, 1.2), Vector3(0, 1.2, 0), body)
	make_box(Vector3(1.35, 0.8, 0.09), Vector3(0, 1.35, -0.65), dark)
	for i in range(3):
		make_box(Vector3(0.22, 0.12, 0.12), Vector3(-0.38 + i * 0.38, 1.35, -0.72), accent)
	make_box(Vector3(1.0, 0.18, 0.9), Vector3(0, 2.18, 0), dark)
	marker = Node3D.new()
	marker.position = Vector3(0, 2.65, 0)
	add_child(marker)
	var crystal := PrismMesh.new()
	crystal.size = Vector3(0.55, 0.8, 0.55)
	crystal.material = accent
	signal_light = MeshInstance3D.new()
	signal_light.mesh = crystal
	marker.add_child(signal_light)
	ComicStyle.apply_to_character(self)
	var label := Label3D.new()
	label.text = "RELAY" if kind == "relay" else ("GENERATOR" if kind == "generator" else "DEVICE")
	label.font = ComicFont
	label.font_size = 64
	label.pixel_size = 0.007
	label.outline_size = 12
	label.modulate = Color("ffe56b")
	label.outline_modulate = Color("171429")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 3.5
	add_child(label)

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.85
	return result

func make_box(size: Vector3, at: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	add_child(part)

func _process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.hero) or not game.hero.playing:
		return
	elapsed += delta
	marker.rotation.y += delta * 1.8
	signal_light.scale = Vector3.ONE * (1.0 + 0.12 * sin(elapsed * 4.0))
