shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

void fragment() {
	vec2 point = (UV - 0.5) * 2.0;
	float radius = length(point);
	float angle = atan(point.y, point.x);
	float arms = 0.5 + 0.5 * cos(angle * 2.0 - radius * 15.0);
	float disc = exp(-radius * 4.5) * (0.25 + 0.75 * arms);
	float core = exp(-radius * radius * 100.0);
	float fade = 1.0 - smoothstep(0.7, 1.0, radius);
	ALBEDO = mix(COLOR.rgb, vec3(1.0, 0.9, 0.7), core) * 2.0;
	ALPHA = (disc + core) * fade * COLOR.a;
}
