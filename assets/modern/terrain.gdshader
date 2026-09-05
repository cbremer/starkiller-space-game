shader_type canvas_item;
render_mode unshaded;
varying vec2 local_position;
void vertex() { local_position = VERTEX; }
void fragment() {
	float facet = sin(local_position.x * 0.018 + local_position.y * 0.032) * 0.05;
	float lighting = 0.75 + 0.5 * (1.0 - SCREEN_UV.y) + facet;
	COLOR.rgb = COLOR.rgb * lighting + vec3(0.025, 0.045, 0.065);
}
