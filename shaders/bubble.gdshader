shader_type canvas_item;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float r = length(uv);
    
    // Мягкий полупрозрачный пузырек
    float alpha = 1.0 - smoothstep(0.5, 1.0, r);
    // Добавим темную обводку для объема
    vec3 color = mix(vec3(0.0), vec3(1.0), smoothstep(0.8, 1.0, r));
    
    COLOR = vec4(color, alpha * COLOR.a);
}
