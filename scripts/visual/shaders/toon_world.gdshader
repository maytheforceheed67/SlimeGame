shader_type spatial;
// The toon material for the world: rock, floors, anything that is lit by
// the key light and receives shadows (docs/VISUAL_STYLE.md, section 3.2).
// It is made only by the Toon autoload, which fills every uniform from
// data/visual_config.json. Characters use toon_character.gdshader instead.
//
// A surface is either lit or shaded, with a softer edge than a character's.
// The shaded side is the base colour multiplied by a blue-violet tint, never
// darkened toward grey. A cast shadow is folded into the same band, so it
// takes the same colour as a form shadow.
//
// Everything a surface shows except its glow (tone, rim, highlight, flash and
// fog) is written while the key light is processed. The Compatibility
// renderer draws a shadow-casting light as a second pass added on top of the
// first after colour encoding, so a result split across the two passes would
// not add up to the palette colour. For the same reason the engine's own fog
// is switched off here and the same fog is applied by hand from two global
// values that WorldLook keeps in step with the Environment. Glow is the one
// thing left in the first pass, because bloom only sees that pass.
render_mode ambient_light_disabled, fog_disabled;

global uniform vec4 toon_fog_color : source_color;
// x: exponential density. y, z: depth fog begin and end. w: depth fog strength.
global uniform vec4 toon_fog;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D albedo_map : source_color, hint_default_white;
uniform vec3 shade_tint : source_color = vec3(0.55, 0.5, 0.75);
uniform float band_threshold = 0.45;
uniform float band_softness = 0.01;
// An optional middle tone between shade and lit: 0 is off, 1 is on.
uniform float band2_amount = 0.0;
uniform float band2_threshold = 0.75;
// The "light cap": faces that look up take cap_color instead of the base.
uniform vec3 cap_color : source_color = vec3(1.0);
uniform float cap_amount = 0.0;
uniform float cap_threshold = 0.7;

uniform float shadow_low = 0.45;
uniform float shadow_high = 0.55;
// How strongly a nearby lamp tints this surface, and where its pool ends.
uniform float lamp_tint = 0.015;
uniform float lamp_threshold = 0.3;

uniform float rim_start = 0.65;
uniform float rim_soft = 0.02;
uniform float rim_strength = 0.0;
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

varying vec3 world_normal;
varying float curved;
varying float fog_amount;


void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}


void fragment() {
	vec3 surface = base_color.rgb * texture(albedo_map, UV).rgb * COLOR.rgb;
	float cap = cap_amount * smoothstep(cap_threshold - 0.02, cap_threshold + 0.02, normalize(world_normal).y);
	ALBEDO = mix(surface, cap_color, cap);
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;

	// A rim belongs on rounded forms. A flat face would switch on all at
	// once as the camera tilts, so faces whose normal does not vary get none.
	curved = step(0.0002, length(fwidth(NORMAL)));

	float distance_away = length(VERTEX);
	float exponential = 1.0 - exp(-distance_away * toon_fog.x);
	float by_depth = toon_fog.w * smoothstep(toon_fog.y, max(toon_fog.z, toon_fog.y + 0.001), distance_away);
	fog_amount = clamp(max(exponential, by_depth), 0.0, 1.0);

	EMISSION = emission * emission_energy * (1.0 - flash) * (1.0 - fog_amount);
}


void light() {
	float clear = 1.0 - fog_amount;
	if (LIGHT_IS_DIRECTIONAL) {
		// The key light. Its colour is ignored on purpose: the palette
		// decides what a lit surface looks like.
		vec3 toward_light = normalize(LIGHT);
		float coordinate = dot(NORMAL, toward_light) * 0.5 + 0.5;
		coordinate *= smoothstep(shadow_low, shadow_high, ATTENUATION);

		float lit = smoothstep(band_threshold - band_softness, band_threshold + band_softness, coordinate);
		float upper = smoothstep(band2_threshold - band_softness, band2_threshold + band_softness, coordinate);
		lit = mix(lit, 0.5 * (lit + upper), band2_amount);
		vec3 tone = mix(shade_tint, vec3(1.0), lit);

		float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float rim = smoothstep(rim_start, rim_start + rim_soft, 1.0 - facing) * rim_strength * curved;
		rim *= smoothstep(0.0, 0.2, dot(NORMAL, normalize(rim_light_dir)));
		vec3 half_way = normalize(toward_light + VIEW);
		float gloss = pow(max(dot(NORMAL, half_way), 0.0), spec_gloss);
		float spec = step(0.5, gloss) * spec_strength * lit;

		// Mixes written as a part multiplied by the base colour and a part
		// added as it is: base -> rim -> highlight -> flash -> fog.
		float keep = (1.0 - rim) * (1.0 - spec) * (1.0 - flash);
		vec3 added = (rim_color * rim * (1.0 - spec) + spec_color * spec) * (1.0 - flash) + flash_color * flash;
		DIFFUSE_LIGHT += tone * keep * clear;
		SPECULAR_LIGHT += added * clear + toon_fog_color.rgb * fog_amount;
	} else {
		// A lamp: a soft-edged pool of its hue on the world's surfaces.
		float reach = (dot(NORMAL, LIGHT) * 0.5 + 0.5) * ATTENUATION;
		float pool = smoothstep(lamp_threshold - 0.1, lamp_threshold + 0.1, reach);
		vec3 hue = LIGHT_COLOR / max(max(LIGHT_COLOR.r, max(LIGHT_COLOR.g, LIGHT_COLOR.b)), 0.0001);
		DIFFUSE_LIGHT += hue * pool * lamp_tint * (1.0 - flash) * clear;
	}
}
