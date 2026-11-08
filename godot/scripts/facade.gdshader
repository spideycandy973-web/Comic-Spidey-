shader_type spatial;
render_mode diffuse_burley, specular_disabled;

varying vec3 world_position;
varying vec3 world_normal;
varying vec3 object_position;
varying vec3 object_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	object_position = VERTEX;
	object_normal = NORMAL;
}

void fragment() {
	vec3 ink = vec3(0.035, 0.035, 0.085);
	vec3 wall = COLOR.rgb;
	float face_coord = abs(world_normal.x) > abs(world_normal.z) ? world_position.z : world_position.x;
	vec2 cell = vec2(fract(face_coord / 2.1), fract((world_position.y - 1.0) / 2.8));
	float frame = step(0.12, cell.x) * step(cell.x, 0.88) * step(0.13, cell.y) * step(cell.y, 0.84);
	float window = step(0.18, cell.x) * step(cell.x, 0.82) * step(0.19, cell.y) * step(cell.y, 0.78);
	float facade = step(2.3, world_position.y) * (1.0 - step(0.5, abs(world_normal.y)));
	frame *= facade;
	window *= facade;
	float tint = fract(sin(floor(face_coord / 2.1) * 13.47 + floor(world_position.y / 2.8) * 42.18) * 43758.5);
	vec3 glass = mix(vec3(0.08, 0.22, 0.33), vec3(0.25, 0.59, 0.69), tint);
	// Diagonal highlights and a dark mullion make windows read as drawn panels.
	float shine = step(0.67, fract(cell.x + cell.y * 0.7)) * 0.12;
	glass += vec3(shine);
	vec3 color = mix(mix(wall, ink, frame), glass, window);
	float mullion = (1.0 - step(0.025, abs(cell.x - 0.5))) * window;
	color = mix(color, ink, mullion * 0.8);
	vec3 edge = 0.5 - abs(object_position);
	float edge_distance = abs(object_normal.x) > 0.5 ? min(edge.y, edge.z) : (abs(object_normal.y) > 0.5 ? min(edge.x, edge.z) : min(edge.x, edge.y));
	color = mix(ink, color, step(0.009, edge_distance));
	ALBEDO = color;
	ROUGHNESS = 1.0;
}

void light() {
	float lit = max(dot(NORMAL, LIGHT), 0.0);
	float band = lit > 0.65 ? 1.0 : (lit > 0.22 ? 0.68 : 0.38);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * band;
}
