shader_type canvas_item;

uniform float radius = 4.0;
uniform float step_size = 1.0;
uniform float sd = 12.0;
uniform float additive_strength = 20.0;
uniform float center_strength = 1.0;

void fragment() {
	float pi = 3.141592653;
	float e = 2.71828;
	float left = 1.0 / (2.0 * pi * pow(sd, 2));
	vec4 sum = vec4(0.0);
	for (float x = -radius; x <= radius; x += step_size) {
		for (float y = -radius; y <= radius; y += step_size) {
			vec4 value = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE * vec2(x, y));
			float p = -(pow(x, 2) + pow(y, 2)) / (2.0 * pow(sd, 2));
			sum += value * left * pow(e, p);
		}
	}
	COLOR = sum * additive_strength + texture(SCREEN_TEXTURE, SCREEN_UV) * center_strength;
}