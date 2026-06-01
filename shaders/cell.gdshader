shader_type canvas_item;

uniform vec3 base_color : source_color = vec3(0.2, 0.8, 0.2);
uniform float pulse_speed = 2.0;
uniform float energy_ratio = 1.0;
uniform float deformation = 0.05;
uniform float membrane_roughness = 0.25;
uniform float membrane_asymmetry = 0.12;
uniform float nucleus_size = 0.3;
uniform float bioluminescence = 0.0;
uniform float motion_deform = 0.0;
uniform vec2 motion_direction = vec2(1.0, 0.0);
uniform float split_pressure = 0.0;
uniform float dissolve = 0.0;
uniform float visual_padding = 1.65;
uniform float shape_elongation = 0.0;
uniform float shape_spikiness = 0.0;
uniform float shape_amoeboid = 0.0;

float membrane_wave(float angle, float time) {
	float primary = sin(angle * 3.0 + time * pulse_speed);
	float secondary = sin(angle * 5.0 - time * pulse_speed * 0.73);
	float tertiary = cos(angle * 7.0 + time * pulse_speed * 0.31);
	return primary * 0.55 + secondary * 0.3 + tertiary * 0.15;
}

void fragment() {
	vec2 uv = (UV * 2.0 - 1.0) * visual_padding;
	vec2 swim_dir = normalize(motion_direction + vec2(0.001, 0.0));
	float along_motion = dot(uv, swim_dir);
	float side_motion = dot(uv, vec2(-swim_dir.y, swim_dir.x));
	uv = swim_dir * (along_motion / (1.0 + motion_deform * 0.32)) + vec2(-swim_dir.y, swim_dir.x) * (side_motion * (1.0 + motion_deform * 0.16));
	uv.x /= 1.0 + split_pressure * 0.65;
	uv.y *= 1.0 + split_pressure * 0.22;

	float angle = atan(uv.y, uv.x);
	float r = length(uv);
	float pulse = sin(TIME * pulse_speed + energy_ratio * 2.0) * 0.025;
	float soft_asymmetry = sin(angle + TIME * 0.17) * membrane_asymmetry;
	float edge_wave = membrane_wave(angle + membrane_asymmetry * 2.0, TIME) * deformation * (0.6 + membrane_roughness);
	
	// Вычисляем плавное непрерывное изменение формы на основе смешения генов
	float elong_power = mix(1.0, 1.6, shape_spikiness);
	float elong_val = shape_elongation * 0.48 * pow(abs(cos(angle)), elong_power);
	
	float star_val = shape_spikiness * (1.0 - shape_elongation * 0.4) * 0.28 * abs(sin(angle * 5.0));
	
	float amoeba_val = shape_amoeboid * 0.24 * sin(angle * 3.0 + sin(TIME * 1.35)) * cos(angle * 2.0 - TIME * 0.95);
	
	float spiral_val = shape_amoeboid * shape_elongation * 0.12 * sin(angle * 3.0 + TIME * pulse_speed * 1.4);

	float shape_factor = 1.0 - shape_elongation * 0.28 + elong_val + star_val + amoeba_val + spiral_val;
	
	float cell_radius = (0.82 + pulse + soft_asymmetry + edge_wave) * shape_factor;
	float edge_softness = mix(0.09, 0.035, clamp(membrane_roughness, 0.0, 1.0));
	float alpha = 1.0 - smoothstep(cell_radius - edge_softness, cell_radius, r);
	alpha *= 1.0 - dissolve;

	if (alpha < 0.01) {
		discard;
	}

	float normalized_r = clamp(r / cell_radius, 0.0, 1.0);
	float z = sqrt(max(0.0, 1.0 - normalized_r * normalized_r));
	vec3 normal = normalize(vec3(uv.x * 0.9, uv.y * 0.9, z + 0.45));

	float nucleus_wave = sin(TIME * pulse_speed * 1.5 + membrane_asymmetry * 8.0) * 0.025;
	float nucleus_radius = nucleus_size + nucleus_wave + energy_ratio * 0.06;
	float nucleus = 1.0 - smoothstep(nucleus_radius - 0.055, nucleus_radius + 0.055, r);
	float cytoplasm = smoothstep(cell_radius, 0.0, r);
	float membrane_rim = smoothstep(cell_radius - 0.18, cell_radius, r) * alpha;
	float cleavage = split_pressure * (1.0 - smoothstep(0.04, 0.18, abs(uv.x))) * smoothstep(0.1, 0.78, abs(uv.y));

	vec3 low_energy_color = base_color * vec3(0.45, 0.5, 0.55);
	vec3 alive_color = mix(low_energy_color, base_color, energy_ratio);
	vec3 color = mix(alive_color * 0.55, alive_color * 1.12, cytoplasm);
	color = mix(color, alive_color * 0.22, nucleus * 0.78);
	color = mix(color, alive_color * 0.08, cleavage * 0.85);
	color += alive_color * membrane_rim * (0.18 + membrane_roughness * 0.28);
	color += vec3(0.35, 0.8, 1.0) * bioluminescence * pow(cytoplasm, 3.0) * (0.35 + energy_ratio);

	float cytoplasm_alpha = 0.52;
	float final_alpha = mix(cytoplasm_alpha, 0.95, clamp(nucleus * 0.88 + membrane_rim * 0.38, 0.0, 1.0));
	alpha *= final_alpha;

	COLOR = vec4(color, alpha) * COLOR;
	NORMAL = normal;
}

void light() {
	vec3 light_dir = normalize(LIGHT_DIRECTION);
	float n_dot_l = max(dot(NORMAL, light_dir), 0.0);
	vec3 diffuse = LIGHT_COLOR.rgb * LIGHT_ENERGY * n_dot_l * 0.72;
	vec3 view_dir = vec3(0.0, 0.0, 1.0);
	vec3 half_vec = normalize(light_dir + view_dir);
	float spec = pow(max(dot(NORMAL, half_vec), 0.0), 14.0);
	vec3 specular = vec3(1.0) * spec * LIGHT_ENERGY * 0.24;
	LIGHT = vec4(diffuse + specular, LIGHT_COLOR.a) * COLOR.a;
}
