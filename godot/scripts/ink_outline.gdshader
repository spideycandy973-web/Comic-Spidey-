shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform float ink_width = 0.018;
uniform vec4 ink_color : source_color = vec4(0.035, 0.025, 0.075, 1.0);

void vertex() {
	VERTEX += NORMAL * ink_width;
}

void fragment() {
	ALBEDO = ink_color.rgb;
}
