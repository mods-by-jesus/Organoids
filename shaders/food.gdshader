shader_type canvas_item;

uniform vec3 base_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float pulse_speed = 3.0;
uniform float shape_lobes = 4.0;
uniform float shape_roughness = 0.1;
uniform float time_multiplier = 1.0;
uniform float time_offset = 0.0;

void fragment() {
    vec3 tint_color = COLOR.rgb;
    vec2 uv = UV * 2.0 - 1.0;
    float r = length(uv);
    float angle = atan(uv.y, uv.x);
    
    // Мягкая, быстрая пульсация для еды (сгусток энергии) с настраиваемой формой
    float wave = sin(angle * shape_lobes + (TIME * time_multiplier + time_offset) * pulse_speed) * shape_roughness;
    float radius = 0.8 + wave;
    
    float alpha = 1.0 - smoothstep(radius - 0.1, radius, r);
    if (alpha < 0.01) {
        discard;
    }
    
    // Вычисляем 3D нормаль для освещения, как у клеток
    float normalized_r = clamp(r / radius, 0.0, 1.0);
    float z = sqrt(max(0.0, 1.0 - normalized_r * normalized_r));
    vec3 normal = normalize(vec3(uv.x, uv.y, z + 0.3));
    
    // Еда светится изнутри (градиент от темного края к яркому центру)
    vec3 food_color = base_color * tint_color;
    vec3 color = mix(food_color * 0.6, food_color * 1.5, 1.0 - smoothstep(0.0, radius, r));
    
    COLOR = vec4(color, alpha);
    NORMAL = normal;
}

void light() {
    vec3 light_dir = normalize(LIGHT_DIRECTION);
    
    // Диффузный свет
    float n_dot_l = max(dot(NORMAL, light_dir), 0.0);
    vec3 diffuse = LIGHT_COLOR.rgb * LIGHT_ENERGY * n_dot_l * 0.8;
    
    // Блик (чуть более яркий, чем у клеток, чтобы еда "светилась" на фоне)
    vec3 view_dir = vec3(0.0, 0.0, 1.0);
    vec3 half_vec = normalize(light_dir + view_dir);
    float spec = pow(max(dot(NORMAL, half_vec), 0.0), 16.0);
    vec3 specular = vec3(1.0) * spec * LIGHT_ENERGY * 0.4;
    
    LIGHT = vec4(diffuse + specular, LIGHT_COLOR.a) * COLOR.a;
}
