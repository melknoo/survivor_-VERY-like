shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	// Mix original color with white, preserving alpha
	COLOR = mix(original, vec4(1.0, 1.0, 1.0, original.a), flash_amount * original.a);
}
