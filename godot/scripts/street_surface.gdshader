shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.25, 0.32, 0.40, 1.0);
uniform float detail_strength : hint_range(0.0, 0.15) = 0.035;
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Fine, low-contrast aggregate is stable in world space across city chunks.
	vec2 p = floor(world_pos.xz * 2.0);
	float grain = fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453) - 0.5;
	ALBEDO = base_color.rgb * (1.0 + grain * detail_strength);
	ROUGHNESS = 1.0;
}
