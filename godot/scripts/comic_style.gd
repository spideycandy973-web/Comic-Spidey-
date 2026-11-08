extends RefCounted

const INK_SHADER = preload("res://scripts/ink_outline.gdshader")

# Keep imported textures and skinning intact; change only lighting and add an
# inverted-hull ink pass. The pass is shared, while source materials are copied
# so one character's clothing cannot mutate another's.
static func apply_to_character(root: Node3D) -> void:
	var ink := ShaderMaterial.new()
	ink.shader = INK_SHADER
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		if mesh.material_override is BaseMaterial3D:
			mesh.material_override = comic_material(mesh.material_override, ink)
		elif mesh.material_override == null and mesh.mesh:
			for i in range(mesh.mesh.get_surface_count()):
				var mat = mesh.get_active_material(i)
				if mat is BaseMaterial3D:
					mesh.set_surface_override_material(i, comic_material(mat, ink))

static func comic_material(original: BaseMaterial3D, ink: Material) -> BaseMaterial3D:
	var mat := original.duplicate() as BaseMaterial3D
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.roughness = 1.0
	mat.next_pass = ink
	return mat
