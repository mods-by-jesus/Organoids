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
uniform float shape_tendrils = 0.0;
uniform float shape_lobes = 0.0;
uniform float shape_boxy = 0.0;
uniform float shape_worm = 0.0;
uniform float shape_spiral = 0.0;
uniform float time_multiplier = 1.0;

float membrane_wave(float angle, float time) {
	float primary = sin(angle * 3.0 + time * pulse_speed);
	float secondary = sin(angle * 5.0 - time * pulse_speed * 0.73);
	float tertiary = cos(angle * 7.0 + time * pulse_speed * 0.31);
	return primary * 0.55 + secondary * 0.3 + tertiary * 0.15;
}

void fragment() {
	float t = TIME * time_multiplier;
	vec2 uv = (UV * 2.0 - 1.0) * visual_padding;
	vec2 swim_dir = normalize(motion_direction + vec2(0.001, 0.0));
	float along_motion = dot(uv, swim_dir);
	float side_motion = dot(uv, vec2(-swim_dir.y, swim_dir.x));
	uv = swim_dir * (along_motion / (1.0 + motion_deform * 0.32)) + vec2(-swim_dir.y, swim_dir.x) * (side_motion * (1.0 + motion_deform * 0.16));
	uv.x /= 1.0 + split_pressure * 0.65;
	uv.y *= 1.0 + split_pressure * 0.22;

	float worm_length = 1.0 + shape_worm * 0.35 + shape_elongation * 0.75 + shape_spiral * 0.35;
	float worm_phase = t * (1.10 + pulse_speed * 0.24) + membrane_asymmetry * 7.0;
	uv.x /= worm_length;
	float worm_bend = sin(uv.x * worm_length * 7.2 + worm_phase) * shape_worm * 0.22;
	worm_bend += sin(uv.x * worm_length * 12.0 - worm_phase * 0.72) * shape_worm * 0.055;
	float spiral_bend = sin(uv.x * worm_length * 5.6 + t * pulse_speed * 0.72) * shape_spiral * 0.18;
	uv.y += worm_bend + spiral_bend;
	uv.y *= 1.0 + shape_worm * 0.10;

	float angle = atan(uv.y, uv.x);
	float round_r = length(uv);
	float box_r = max(abs(uv.x), abs(uv.y)) * mix(1.18, 1.02, shape_lobes);
	float r = mix(round_r, box_r, shape_boxy * 0.88);
	float pulse = sin(t * pulse_speed + energy_ratio * 2.0) * 0.025;
	float soft_asymmetry = sin(angle + t * 0.17) * membrane_asymmetry;
	float edge_wave = membrane_wave(angle + membrane_asymmetry * 2.0, t) * deformation * (0.6 + membrane_roughness);
	
	// Вычисляем плавное непрерывное изменение формы на основе смешения генов
	float elong_power = mix(1.0, 1.6, shape_spikiness);
	float elong_val = shape_elongation * 0.48 * pow(abs(cos(angle)), elong_power);
	
	float star_val = shape_spikiness * (1.0 - shape_elongation * 0.4) * 0.28 * abs(sin(angle * 5.0));

	float amoeba_val = shape_amoeboid * 0.24 * sin(angle * 3.0 + sin(t * 1.35)) * cos(angle * 2.0 - t * 0.95);

	float spiral_val = shape_amoeboid * shape_elongation * 0.12 * sin(angle * 3.0 + t * pulse_speed * 1.4);
	float lobe_phase = membrane_asymmetry * 5.1 + nucleus_size * 3.7;
	float lobe_val = shape_lobes * 0.22 * (0.45 + 0.55 * abs(sin(angle * 2.0 + lobe_phase)));
	float tendril_wave = max(sin(angle * 6.0 + lobe_phase + t * 0.18), 0.0);
	float tendril_val = shape_tendrils * (0.16 + 0.20 * membrane_roughness) * pow(tendril_wave, 8.0);
	tendril_val += shape_tendrils * 0.10 * pow(max(sin(angle * 9.0 - lobe_phase), 0.0), 12.0);
	float box_val = shape_boxy * 0.08 * (1.0 - shape_amoeboid * 0.35);
	float worm_val = shape_worm * 0.08 * sin(uv.x * worm_length * 4.6 + t * 1.25);
	float spiral_shape_val = shape_spiral * 0.18 * sin(angle * 2.0 + round_r * 5.5 + t * pulse_speed * 0.65);

	float shape_factor = 1.0 - shape_elongation * 0.28 - shape_worm * 0.22 + elong_val + star_val + amoeba_val + spiral_val + lobe_val + tendril_val + box_val + worm_val + spiral_shape_val;
	
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

	float nucleus_wave = sin(t * pulse_speed * 1.5 + membrane_asymmetry * 8.0) * 0.025;
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
