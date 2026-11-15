shader_type spatial;
// A see-through surface drawn in two flat tones: one facing the camera, one
// where it turns away, with a hard edge between them. Used for the seal's
// barrier, the lake surface and attack telegraphs until their own passes.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 face_color : source_color = vec4(0.4, 0.6, 1.0, 0.2);
uniform vec4 edge_color : source_color = vec4(0.8, 0.9, 1.0, 0.6);
uniform float edge_start = 0.6;
uniform float edge_soft = 0.03;
uniform float energy = 1.0;


void fragment() {
	float turned = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	float edge = smoothstep(edge_start, edge_start + edge_soft, turned);
	ALBEDO = mix(face_color.rgb, edge_color.rgb, edge) * energy;
	ALPHA = mix(face_color.a, edge_color.a, edge);
}
