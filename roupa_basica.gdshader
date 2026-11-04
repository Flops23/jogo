shader_type spatial;

uniform sampler2D atlas : source_color, filter_nearest;

void fragment() {
	vec3 original = texture(atlas, UV).rgb;
	float blue_bias = original.b - max(original.r, original.g);
	float fabric = smoothstep(0.035, 0.09, blue_bias);
	float lightness = clamp(original.b * 1.4, 0.0, 1.0);
	vec3 linen = mix(vec3(0.09, 0.055, 0.032), vec3(0.44, 0.30, 0.18), lightness);
	ALBEDO = mix(original, linen, fabric);
	ROUGHNESS = 0.9;
}
