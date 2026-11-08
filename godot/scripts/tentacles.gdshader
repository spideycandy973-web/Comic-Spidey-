shader_type spatial;
render_mode cull_disabled, diffuse_burley;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform float motion_time = 0.0;
uniform float attack_intensity = 1.0;

void vertex() {
	// Original supplied GLB coordinates: Z is up, Y extends backwards.
	// The two tentacle meshes are static, so this is a gentle GPU deformation,
	// not a skeletal rig. The base stays anchored to the body.
	float weight = clamp((VERTEX.y - 0.2) / 1.5, 0.0, 1.0);
	float phase = motion_time * 2.0 + VERTEX.x * 1.4 + VERTEX.z * 1.3;
	VERTEX.x += weight * 0.12 * attack_intensity * sin(phase);
	VERTEX.y += weight * 0.05 * attack_intensity * cos(phase * 0.8);
	VERTEX.z += weight * 0.11 * attack_intensity * sin(phase + 1.1);
}

void fragment() {
	vec4 surface = texture(albedo_texture, UV) * albedo_tint;
	ALBEDO = surface.rgb;
	ROUGHNESS = 0.75;
}
