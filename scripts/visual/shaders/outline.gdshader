shader_type spatial;
// The ink line (docs/VISUAL_STYLE.md, section 3.3): a second draw of the
// mesh showing back faces only, pushed outward in screen space so the line
// keeps its width in pixels. It is set as the toon material's next pass by
// the Toon autoload.
//
// Vertices move along a smoothed normal stored in CUSTOM0 (see MeshKit), so
// the hull does not split at hard edges. A mesh without that channel falls
// back to its ordinary normal. Vertex-colour alpha scales the width; 0
// erases the line.
//
// The line does not write depth. That keeps it out of the shadow map, where
// it would cost one more draw per mesh for nothing; the Toon autoload gives
// it a render priority so it is drawn after any see-through surface behind it.
render_mode unshaded, cull_front, shadows_disabled, depth_draw_never;

uniform vec4 line_color : source_color = vec4(0.05, 0.08, 0.3, 1.0);
uniform float width_px = 2.0;
// The screen height at which width_px is measured.
uniform float reference_height = 1080.0;
// Beyond this distance the line stops growing relative to the object.
uniform float max_growth_distance = 25.0;
// Below this height on screen (pixels) the line fades out.
uniform float fade_below_px = 12.0;
uniform float object_height = 1.0;


void vertex() {
	vec3 smoothed = CUSTOM0.xyz;
	vec3 outward = dot(smoothed, smoothed) > 0.25 ? normalize(smoothed) : NORMAL;
	// Rotation only: the hull grows by the same width along every axis of a
	// stretched part, rather than following the stretch.
	mat3 model_view = mat3(MODELVIEW_MATRIX);
	mat3 rotation = mat3(normalize(model_view[0]), normalize(model_view[1]), normalize(model_view[2]));
	vec3 outward_view = normalize(rotation * outward);

	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	float depth = max(clip.w, 0.001);
	float pixels = width_px * VIEWPORT_SIZE.y / reference_height;
	pixels *= min(1.0, max_growth_distance / depth);
	float tall_px = object_height * abs(PROJECTION_MATRIX[1][1]) * 0.5 * VIEWPORT_SIZE.y / depth;
	pixels *= smoothstep(fade_below_px * 0.5, fade_below_px, tall_px);
	pixels *= COLOR.a;

	vec2 direction = outward_view.xy / max(length(outward_view.xy), 0.35);
	direction *= sign(vec2(PROJECTION_MATRIX[0][0], PROJECTION_MATRIX[1][1]));
	clip.xy += direction * (2.0 * pixels / VIEWPORT_SIZE) * clip.w;
	POSITION = clip;
}


void fragment() {
	ALBEDO = line_color.rgb;
}
