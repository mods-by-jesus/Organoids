shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec3 deep_color : source_color = vec3(0.035, 0.075, 0.095);
uniform vec3 caustic_color : source_color = vec3(0.18, 0.42, 0.48);
uniform float flow_speed = 0.08;
uniform float flow_scale = 340.0;
uniform float caustic_strength = 0.16;
uniform float vignette_strength = 0.45;

varying vec2 world_pos;

mat2 rotate2d(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

float soft_wave(vec2 p, float time) {
	float a = sin(p.x * 1.7 + sin(p.y * 0.9 + time * 0.7) + time);
	float b = sin((p.x + p.y) * 1.15 - time * 0.63);
	float c = cos(length(p + vec2(sin(time * 0.2), cos(time * 0.17))) * 2.2 - time * 0.5);
	return (a + b + c) * 0.3333;
}

float smooth_fluid(vec2 p, float time) {
	float value = 0.0;
	float amplitude = 0.55;
	float frequency = 1.0;
	for (int i = 0; i < 5; i++) {
		vec2 q = rotate2d(float(i) * 0.73) * p * frequency;
		value += soft_wave(q, time * (0.45 + float(i) * 0.11)) * amplitude;
		frequency *= 1.72;
		amplitude *= 0.52;
	}
	return value * 0.5 + 0.5;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float time = TIME * flow_speed * 8.0;
	vec2 p = world_pos / flow_scale;
	vec2 drift = vec2(sin(time * 0.23), cos(time * 0.19)) * 0.35;
	vec2 warped = p + drift;
	warped += vec2(
		soft_wave(p * 1.4, time * 0.4),
		soft_wave(rotate2d(1.57) * p * 1.2, time * 0.36)
	) * 0.22;

	float slow_clouds = smooth_fluid(warped, time);
	float fine_caustics = smooth_fluid(warped * 3.1 + vec2(time * 0.18, -time * 0.12), time * 1.4);
	float strands = pow(smoothstep(0.58, 0.92, fine_caustics), 2.4);
	float depth = smoothstep(0.1, 0.9, slow_clouds);
	vec2 screen_uv = SCREEN_UV * 2.0 - 1.0;
	float vignette = smoothstep(1.15, 0.15, length(screen_uv));
	vec3 color = mix(deep_color * 0.7, deep_color, depth);
	color += caustic_color * strands * caustic_strength * vignette;
	color *= mix(1.0 - vignette_strength, 1.0, vignette);
	COLOR = vec4(color, 1.0);
}
