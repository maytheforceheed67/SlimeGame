shader_type spatial;
// Blob shadows (docs/VISUAL_STYLE.md, section 3.4): a soft disc under every
// actor, drawn for all of them in one MultiMesh. The disc is a dark
// blue-violet laid over the ground, so the shadow is a colour and never
// grey. The instance colour's alpha carries each disc's strength.
//
// It is blended over the ground rather than multiplied into it: with bloom
// on, the Compatibility renderer stores colours scaled down, and a
// multiplying blend would darken everything it touched.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec3 tint : source_color = vec3(0.18, 0.165, 0.4);
uniform float softness = 0.45;


void fragment() {
	float from_centre = length(UV - vec2(0.5)) * 2.0;
	float disc = 1.0 - smoothstep(1.0 - softness, 1.0, from_centre);
	ALBEDO = tint;
	ALPHA = disc * COLOR.a;
}
