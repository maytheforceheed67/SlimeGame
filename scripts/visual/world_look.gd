class_name WorldLook
extends RefCounted
## Applies the visual config to a level's Environment and viewport: tone
## mapping, bloom, colour grade, fog, the cool fill light and anti-aliasing.
## This is the Godot counterpart of the style document's post-processing
## stack (docs/VISUAL_STYLE.md, section 3.5); the vignette is a HUD overlay
## (scripts/ui/vignette.gd) because Environment has none.
##
## It also sets up the one key light (section 3.4) and keeps the fog that
## toon surfaces apply for themselves in step with the Environment's.

## Global shader values read by the toon shader (see project.godot).
const FOG_COLOR_GLOBAL := &"toon_fog_color"
const FOG_GLOBAL := &"toon_fog"

## Environment.ToneMapper values by config name. AgX exists from Godot 4.4.
const TONE_MAPPERS := {"linear": 0, "reinhard": 1, "filmic": 2, "aces": 3, "agx": 4}


static func apply(environment: Environment, viewport: Viewport) -> void:
	environment.background_mode = Environment.BG_COLOR
	environment.fog_enabled = true
	apply_fog(environment)

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


## Sets the fog, for the Environment and for toon surfaces alike.
##
## Normally the fog is the palette's cave colour, thickening with distance:
## it fades to a colour, never to black, and the background matches it. With
## `dark_beyond` at zero or more the world is instead swallowed by black from
## that distance on (the sightless opening).
static func apply_fog(environment: Environment, dark_beyond: float = -1.0) -> void:
	if dark_beyond < 0.0:
		var fog := Visual.color("palette.cave.fog")
		var density := Visual.number("fog.density", 0.018)
		environment.background_color = fog
		environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		environment.fog_light_color = fog
		environment.fog_density = density
		RenderingServer.global_shader_parameter_set(FOG_COLOR_GLOBAL, fog)
		RenderingServer.global_shader_parameter_set(FOG_GLOBAL, Vector4(density, 0.0, 1.0, 0.0))
	else:
		environment.background_color = Color.BLACK
		environment.fog_mode = Environment.FOG_MODE_DEPTH
		environment.fog_light_color = Color.BLACK
		environment.fog_density = 1.0
		environment.fog_depth_curve = 1.0
		environment.fog_depth_begin = dark_beyond
		environment.fog_depth_end = dark_beyond + 3.0
		RenderingServer.global_shader_parameter_set(FOG_COLOR_GLOBAL, Color.BLACK)
		RenderingServer.global_shader_parameter_set(FOG_GLOBAL, Vector4(0.0, dark_beyond, dark_beyond + 3.0, 1.0))


## Aims and sets up the key light: the one light that casts shadows and
## decides which side of the world is lit. Its colour never reaches a toon
## surface; the palette decides what lit looks like.
static func apply_key_light(light: DirectionalLight3D) -> void:
	light.rotation_degrees = Vector3(Visual.number("lights.key_pitch", -58.0), Visual.number("lights.key_yaw", 35.0), 0.0)
	light.light_color = Visual.color("lights.key_color", Color.WHITE)
	light.light_energy = Visual.number("lights.key_energy", 1.0)
	light.shadow_enabled = Visual.flag("lights.shadow_enabled", true)
	match int(Visual.number("lights.shadow_splits", 2.0)):
		4:
			light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		2:
			light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		_:
			light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	light.directional_shadow_blend_splits = true
	light.directional_shadow_max_distance = Visual.number("lights.shadow_distance", 36.0)
	RenderingServer.directional_soft_shadow_filter_set_quality(
			clampi(int(Visual.number("lights.shadow_filter", 3.0)), 0, 5) as RenderingServer.ShadowQuality)
	light.shadow_bias = Visual.number("lights.shadow_bias", 0.05)
	light.shadow_normal_bias = Visual.number("lights.shadow_normal_bias", 1.5)
	RenderingServer.directional_shadow_atlas_set_size(int(Visual.number("lights.shadow_map_size", 2048.0)), true)


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


## Whether the project runs on the Compatibility renderer, which has no
## screen-space anti-aliasing.
static func on_compatibility_renderer() -> bool:
	return str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")) == "gl_compatibility"


static func _apply_antialiasing(viewport: Viewport, mode: String) -> void:
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	if not on_compatibility_renderer():
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	match mode:
		"fxaa":
			if on_compatibility_renderer():
				# The closest thing this renderer offers.
				viewport.msaa_3d = Viewport.MSAA_2X
			else:
				viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		"msaa2x":
			viewport.msaa_3d = Viewport.MSAA_2X
		"msaa4x":
			viewport.msaa_3d = Viewport.MSAA_4X
		"off":
			pass
		_:
			push_warning("[WorldLook] unknown antialiasing '%s'" % mode)
