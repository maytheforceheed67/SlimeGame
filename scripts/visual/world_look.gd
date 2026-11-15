class_name WorldLook
extends RefCounted
## Applies the visual config to a level's Environment and viewport: tone
## mapping, bloom, colour grade, fog, the cool fill light and anti-aliasing.
## This is the Godot counterpart of the style document's post-processing
## stack (docs/VISUAL_STYLE.md, section 3.5); the vignette is a HUD overlay
## (scripts/ui/vignette.gd) because Environment has none.

## Environment.ToneMapper values by config name. AgX exists from Godot 4.4.
const TONE_MAPPERS := {"linear": 0, "reinhard": 1, "filmic": 2, "aces": 3, "agx": 4}


static func apply(environment: Environment, viewport: Viewport) -> void:
	var fog := Visual.color("palette.cave.fog")
	# Fog fades to a colour, never to black, and the background matches it.
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = fog
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_light_color = fog
	environment.fog_density = Visual.number("fog.density", 0.018)

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Visual.color("lights.fill_color", Color(0.5, 0.55, 0.84))
	environment.ambient_light_energy = Visual.number("lights.fill_energy", 0.5)

	environment.tonemap_mode = tone_mapper(Visual.text("renderer.tonemap", "linear")) as Environment.ToneMapper
	environment.tonemap_exposure = Visual.number("renderer.exposure", 1.0)
	environment.tonemap_white = Visual.number("renderer.white", 1.0)

	# Bloom catches only what is brighter than the threshold: emissive cores.
	environment.glow_enabled = Visual.flag("post.bloom_enabled", true)
	environment.glow_hdr_threshold = Visual.number("post.bloom_threshold", 1.0)
	environment.glow_intensity = Visual.number("post.bloom_intensity", 0.8)
	environment.glow_strength = Visual.number("post.bloom_strength", 1.0)
	environment.glow_bloom = Visual.number("post.bloom_bleed", 0.0)

	environment.adjustment_enabled = true
	environment.adjustment_saturation = Visual.number("post.grade_saturation", 1.0)
	environment.adjustment_brightness = Visual.number("post.grade_brightness", 1.0)
	environment.adjustment_contrast = Visual.number("post.grade_contrast", 1.0)

	if viewport != null:
		_apply_antialiasing(viewport, Visual.text("renderer.antialiasing", "msaa2x"))


## The Environment tone mapper for a config name. Unknown names, and AgX on a
## Godot older than 4.4, fall back to linear.
static func tone_mapper(mapper_name: String) -> int:
	if not TONE_MAPPERS.has(mapper_name):
		push_warning("[WorldLook] unknown tone mapper '%s'; using linear" % mapper_name)
		return 0
	if mapper_name == "agx" and int(Engine.get_version_info().get("minor", 0)) < 4:
		push_warning("[WorldLook] the AgX tone mapper needs Godot 4.4 or newer; using linear")
		return 0
	return int(TONE_MAPPERS[mapper_name])


static func _apply_antialiasing(viewport: Viewport, mode: String) -> void:
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	match mode:
		"fxaa":
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		"msaa2x":
			viewport.msaa_3d = Viewport.MSAA_2X
		"msaa4x":
			viewport.msaa_3d = Viewport.MSAA_4X
		"off":
			pass
		_:
			push_warning("[WorldLook] unknown antialiasing '%s'" % mode)
