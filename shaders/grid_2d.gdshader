shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec3 bg_color : source_color = vec3(0.08, 0.08, 0.08); // Светлее
uniform vec3 line_color : source_color = vec3(0.18, 0.18, 0.18); // Мягче
uniform float grid_size = 256.0;
uniform float line_alpha = 0.4;

varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec2 d = fwidth(world_pos / grid_size);
    vec2 grid = abs(fract(world_pos / grid_size - 0.5) - 0.5) / d;
    float line = min(grid.x, grid.y);
    float mask = 1.0 - smoothstep(0.0, 1.2, line);
    float distance_fade = clamp(1.0 - (length(d) * 0.1), 0.2, 1.0);
    float alpha = mask * line_alpha * distance_fade;
    COLOR = vec4(line_color, alpha);
}
