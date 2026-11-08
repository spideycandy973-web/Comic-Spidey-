shader_type spatial;
render_mode diffuse_burley;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 wall = COLOR.rgb;
	float face_coord = abs(world_normal.x) > abs(world_normal.z) ? world_position.z : world_position.x;
	vec2 cell = vec2(fract(face_coord / 2.1), fract((world_position.y - 1.0) / 2.8));
	float window = step(0.18, cell.x) * step(cell.x, 0.82) * step(0.19, cell.y) * step(cell.y, 0.78);
	window *= step(2.3, world_position.y) * (1.0 - step(0.5, abs(world_normal.y)));
	float tint = fract(sin(floor(face_coord / 2.1) * 13.47 + floor(world_position.y / 2.8) * 42.18) * 43758.5);
	vec3 glass = mix(vec3(0.075, 0.12, 0.16), vec3(0.24, 0.34, 0.4), tint);
	ALBEDO = mix(wall, glass, window * 0.92);
	ROUGHNESS = mix(0.9, 0.32, window);
}
