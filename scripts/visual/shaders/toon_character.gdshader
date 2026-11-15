shader_type spatial;
// The toon material for characters, creatures, pickups and hero props
// (docs/VISUAL_STYLE.md, section 3.2). It is made only by the Toon autoload,
// which fills every uniform from data/visual_config.json.
//
// A character carries its own light (rule S8): it is shaded from a fixed
// direction relative to the camera and takes nothing from the scene's
// lights, so it looks the same in every corner of the cave. It still casts
// shadows; it does not receive them. Because nothing here depends on a
// scene light the material is unshaded, which also keeps it to one draw.
//
// A surface is either lit or shaded, with a crisp edge between the two. The
// shaded side is the base colour multiplied by a blue-violet tint, never
// darkened toward grey.
render_mode unshaded;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D albedo_map : source_color, hint_default_white;
uniform vec3 shade_tint : source_color = vec3(0.55, 0.5, 0.75);
uniform float band_threshold = 0.45;
uniform float band_softness = 0.01;
// An optional middle tone between shade and lit: 0 is off, 1 is on.
uniform float band2_amount = 0.0;
uniform float band2_threshold = 0.75;
// Where the character is lit from, in view space: x right, y up, z toward
// the viewer.
uniform vec3 light_dir = vec3(-0.45, 0.75, 0.5);

uniform float rim_start = 0.65;
uniform float rim_soft = 0.02;
uniform float rim_strength = 0.5;
uniform vec3 rim_color : source_color = vec3(0.56, 0.91, 1.0);
// Where the rim light comes from (view space). Only the edge that faces it
// is lit, so the rim reads as a back light and not as a second outline.
uniform vec3 rim_light_dir = vec3(0.45, 0.75, -0.5);
uniform float spec_gloss = 64.0;
uniform float spec_strength = 0.0;
uniform vec3 spec_color : source_color = vec3(1.0);

uniform vec3 emission : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
// Hit feedback: 0 to 1 mix toward flash_color.
uniform float flash = 0.0;
uniform vec3 flash_color : source_color = vec3(1.0);


void fragment() {
	vec3 surface = base_color.rgb * texture(albedo_map, UV).rgb * COLOR.rgb;
	vec3 normal = normalize(NORMAL);
	vec3 toward_light = normalize(light_dir);

	float coordinate = dot(normal, toward_light) * 0.5 + 0.5;
	float lit = smoothstep(band_threshold - band_softness, band_threshold + band_softness, coordinate);
	float upper = smoothstep(band2_threshold - band_softness, band2_threshold + band_softness, coordinate);
	lit = mix(lit, 0.5 * (lit + upper), band2_amount);
	vec3 colour = surface * mix(shade_tint, vec3(1.0), lit);

	// A rim belongs on rounded forms. A flat face would switch on all at
	// once as the camera tilts, so faces whose normal does not vary get none.
	float curved = step(0.0002, length(fwidth(NORMAL)));
	float facing = clamp(dot(normal, VIEW), 0.0, 1.0);
	float rim = smoothstep(rim_start, rim_start + rim_soft, 1.0 - facing) * rim_strength * curved;
	rim *= smoothstep(0.0, 0.2, dot(normal, normalize(rim_light_dir)));
	colour = mix(colour, rim_color, rim);

	float gloss = pow(max(dot(normal, normalize(toward_light + VIEW)), 0.0), spec_gloss);
	colour = mix(colour, spec_color, step(0.5, gloss) * spec_strength * lit);

	// Glow is added past 1.0 on purpose: that excess is what blooms.
	colour += emission * emission_energy;
	ALBEDO = mix(colour, flash_color, flash);
}
