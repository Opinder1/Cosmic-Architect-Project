shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

void vertex() {
	// Face the camera and keep distant systems visible as small points.
	vec4 center = VIEW_MATRIX * MODEL_MATRIX[3];
	float radius = max(length(MODEL_MATRIX[0].xyz), length(center.xyz) * 0.004);
	MODELVIEW_MATRIX = mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0), center);
	VERTEX.xy *= radius;
}

void fragment() {
	vec2 point = (UV - 0.5) * 2.0;
	float radius_squared = dot(point, point);
	float core = exp(-radius_squared * 12.0);
	float glow = exp(-radius_squared * 5.0) * 0.3;
	ALBEDO = mix(COLOR.rgb, vec3(1.0), core) * 3.0;
	ALPHA = (core + glow) * (1.0 - smoothstep(0.6, 1.0, radius_squared)) * COLOR.a;
}
