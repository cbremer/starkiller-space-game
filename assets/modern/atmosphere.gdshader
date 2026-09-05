shader_type canvas_item;
render_mode unshaded;
uniform float travel = 0.0;
uniform float sector = 0.0;
void fragment() {
	vec2 uv = UV;
	vec3 sky = mix(vec3(0.025, 0.04, 0.12), vec3(0.13, 0.32, 0.40), uv.y);
	sky += vec3(0.09, 0.035, 0.10) * sin(sector * 1.7);
	float haze = exp(-pow((uv.y - 0.67) * 5.0, 2.0));
	sky += vec3(0.13, 0.17, 0.20) * haze;
	vec2 p = (uv - vec2(0.76, 0.36)) * vec2(1.7778, 1.0) / 0.235;
	float r = length(p);
	float atmosphere = exp(-abs(r - 1.0) * 24.0);
	sky += vec3(0.20, 0.45, 0.62) * atmosphere * 0.45;
	if (r < 1.0) {
		vec3 normal = vec3(p, sqrt(1.0 - r*r));
		float light = max(dot(normal, normalize(vec3(-0.65, -0.5, 0.7))), 0.0);
		float bands = 0.5 + 0.5*sin(p.y*34.0 + sin(p.x*8.0)*0.6);
		sky = mix(vec3(0.025,0.045,0.095), vec3(0.34,0.57,0.66), light) + bands*light*0.035;
	}
	vec2 grid = uv * vec2(180.0, 100.0) + vec2(travel * 0.0015, 0.0);
	vec2 cell = floor(grid);
	float hash = fract(sin(dot(cell, vec2(127.1,311.7)))*43758.5453);
	float star = (1.0-smoothstep(0.02,0.12,length(fract(grid)-0.5))) * step(0.985,hash);
	if (r > 1.03) { sky += star * (1.0-uv.y) * 0.6; }
	// Fade into the existing biome hills, preserving their silhouettes.
	float alpha = 1.0 - smoothstep(0.48, 0.76, uv.y);
	COLOR = vec4(sky, alpha * 0.96);
}
