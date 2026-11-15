extends Node
## The toon material factory (autoload "Toon"): the one place a material is
## made (docs/VISUAL_STYLE.md, sections 3.2 and 3.3).
##
##   Toon.make({"color": "palette.slime.body", "outline_px": 2.5})
##   Toon.shared({"kind": "environment", "color": "palette.cave.rock_lit"})
##
## Options
##   color           the lit colour: a Color, or a path into the visual config
##   shade           the shaded colour; without it the kind's shade tint is used
##   kind            "character": crisp, carries its own light, takes nothing
##                   from the scene and receives no shadow (the default; also
##                   for pickups and hero props). "environment": softer edge,
##                   lit by the key light, shadowed, tinted by nearby lamps
##   cap             colour of faces that look up (environment "light cap")
##   emission        glow colour; emission_energy above 1 is what blooms
##   outline_px      ink line width at 1080p; 0 for no line
##   outline_color   line colour; without it, derived from `color` by ink()
##   height          the object's height in metres, for fading far lines
##   rim             rim strength, overriding the kind's
##   rim_color       rim colour, overriding the config's
##   spec            0 to 1: a hard-edged highlight
##   texture         a base-colour map
##
## Any colour or number may instead be a path into the visual config
## ("palette.slime.body", "props.crystal_glow"). Those follow live edits in
## the F4 panel: every material made here is refreshed when the config changes.

const CHARACTER_SHADER: Shader = preload("res://scripts/visual/shaders/toon_character.gdshader")
const WORLD_SHADER: Shader = preload("res://scripts/visual/shaders/toon_world.gdshader")
const OUTLINE_SHADER: Shader = preload("res://scripts/visual/shaders/outline.gdshader")
const VEIL_SHADER: Shader = preload("res://scripts/visual/shaders/veil.gdshader")

const META := "toon_options"
const BLUE_HUE := 0.64

var _live: Array[WeakRef] = []
var _shared: Dictionary = {}
var _prune_at := 256


func _ready() -> void:
	Visual.changed.connect(_refresh_all)


## A new toon material of its own, for things that flash or change colour.
func make(options: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = WORLD_SHADER if str(options.get("kind", "character")) == "environment" else CHARACTER_SHADER
	material.set_meta(META, options.duplicate())
	_track(material)
	_apply(material)
	return material


## The toon material for these options, shared by everything that asks for
## the same ones. Never change a shared material; ask for another instead.
func shared(options: Dictionary) -> ShaderMaterial:
	var key := _key(options)
	if not _shared.has(key):
		_shared[key] = make(options)
	return _shared[key]


## A see-through two-tone surface (barrier, water, telegraph).
##   face, edge             colours of the part facing the camera and the
##                          part turned away from it
##   face_alpha, edge_alpha their opacity (default: the colours' own alpha)
##   edge_start             how far a face must turn away to count as edge
##   energy                 above 1 the surface blooms
func veil(options: Dictionary) -> ShaderMaterial:
	var key := "veil|" + _key(options)
	if not _shared.has(key):
		var material := ShaderMaterial.new()
		material.shader = VEIL_SHADER
		material.set_meta(META, options.duplicate())
		_track(material)
		_apply(material)
		_shared[key] = material
	return _shared[key]


## Changes some options of a material made by make() and reapplies them.
func update(material: ShaderMaterial, changes: Dictionary) -> void:
	if material == null or not material.has_meta(META):
		return
	var options: Dictionary = material.get_meta(META)
	options.merge(changes, true)
	_apply(material)


## The options a material was made with (a copy).
func options_of(material: Material) -> Dictionary:
	if material != null and material.has_meta(META):
		return (material.get_meta(META) as Dictionary).duplicate()
	return {}


## Hit feedback: mixes the surface toward `color` by `amount` (0 to 1).
func set_flash(material: ShaderMaterial, amount: float, color: Color = Color.WHITE) -> void:
	if material == null:
		return
	material.set_shader_parameter("flash", clampf(amount, 0.0, 1.0))
	material.set_shader_parameter("flash_color", color)


## The ink colour for a surface: darker and more saturated than the surface,
## nudged toward blue, and never black.
func ink(surface: Color) -> Color:
	var hue := surface.h
	var saturation := surface.s
	if saturation < 0.05:
		hue = BLUE_HUE
	else:
		var turn := wrapf(BLUE_HUE - hue, -0.5, 0.5)
		hue = wrapf(hue + turn * Visual.number("outline.hue_shift", 0.12), 0.0, 1.0)
	saturation = clampf(saturation * Visual.number("outline.saturation_boost", 1.25) + 0.12, 0.0, 1.0)
	var value := maxf(surface.v * Visual.number("outline.color_factor", 0.4), Visual.number("outline.min_value", 0.08))
	return Color.from_hsv(hue, saturation, value)


## Gives every mesh of a loaded model the toon material and an ink line,
## keeping each surface's base colour and base-colour map and nothing else.
func dress_model(root: Node, options: Dictionary = {}) -> void:
	var part := root as MeshInstance3D
	if part != null and part.mesh != null:
		part.mesh = _prepared(part.mesh)
		for surface in part.mesh.get_surface_count():
			var original := part.get_active_material(surface) as BaseMaterial3D
			var surface_options := options.duplicate()
			surface_options["color"] = original.albedo_color if original != null else Color.WHITE
			if original != null and original.albedo_texture != null:
				surface_options["texture"] = original.albedo_texture
			part.set_surface_override_material(surface, shared(surface_options))
	for child in root.get_children():
		dress_model(child, options)


# --- Internals -----------------------------------------------------------------

func _prepared(mesh: Mesh) -> Mesh:
	var key := "prepared:%d" % mesh.get_instance_id()
	if not _shared.has(key):
		_shared[key] = MeshKit.with_smooth_normals(mesh)
	return _shared[key]


func _track(material: ShaderMaterial) -> void:
	_live.append(weakref(material))
	if _live.size() > _prune_at:
		_live = _live.filter(func(entry: WeakRef) -> bool: return entry.get_ref() != null)
		_prune_at = maxi(256, _live.size() * 2)


func _refresh_all(_path: String) -> void:
	for entry in _live:
		var material := entry.get_ref() as ShaderMaterial
		if material != null:
			_apply(material)


func _apply(material: ShaderMaterial) -> void:
	var options: Dictionary = material.get_meta(META)
	if material.shader == VEIL_SHADER:
		var face := _color(options.get("face", Color(0.4, 0.6, 1.0, 0.2)))
		var edge := _color(options.get("edge", Color(0.8, 0.9, 1.0, 0.6)))
		face.a = _number(options.get("face_alpha"), face.a)
		edge.a = _number(options.get("edge_alpha"), edge.a)
		material.set_shader_parameter("face_color", face)
		material.set_shader_parameter("edge_color", edge)
		material.set_shader_parameter("edge_start", _number(options.get("edge_start"), 0.6))
		material.set_shader_parameter("energy", _number(options.get("energy"), 1.0))
		return

	var kind := str(options.get("kind", "character"))
	var character := kind != "environment"
	var prefix := "toon.character_" if character else "toon.environment_"
	var base := _color(options.get("color", Color.WHITE))
	material.set_shader_parameter("base_color", base)
	material.set_shader_parameter("albedo_map", options.get("texture"))

	var tint := Visual.color(prefix + "shade_tint", Color(0.55, 0.5, 0.75))
	if options.has("shade"):
		var shade := _color(options["shade"])
		tint = Color(_ratio(shade.r, base.r), _ratio(shade.g, base.g), _ratio(shade.b, base.b))
	material.set_shader_parameter("shade_tint", tint)
	material.set_shader_parameter("band_threshold", Visual.number(prefix + "band_threshold", 0.45))
	material.set_shader_parameter("band_softness", Visual.number(prefix + "band_softness", 0.01))
	material.set_shader_parameter("band2_amount", 1.0 if Visual.flag(prefix + "band2", false) else 0.0)
	material.set_shader_parameter("band2_threshold", Visual.number(prefix + "band2_threshold", 0.75))

	if character:
		material.set_shader_parameter("light_dir", Vector3(
				Visual.number("toon.character_light_x", -0.45),
				Visual.number("toon.character_light_y", 0.75),
				Visual.number("toon.character_light_z", 0.5)))
	else:
		material.set_shader_parameter("shadow_low", Visual.number("lights.shadow_edge_low", 0.45))
		material.set_shader_parameter("shadow_high", Visual.number("lights.shadow_edge_high", 0.55))
		material.set_shader_parameter("lamp_tint", Visual.number("toon.environment_lamp_tint", 0.015))
		material.set_shader_parameter("lamp_threshold", Visual.number("toon.environment_lamp_threshold", 0.3))
		var cap_amount := 0.0
		if options.has("cap"):
			cap_amount = 1.0
			material.set_shader_parameter("cap_color", _color(options["cap"]))
		material.set_shader_parameter("cap_amount", cap_amount)
		material.set_shader_parameter("cap_threshold", Visual.number("toon.environment_cap_threshold", 0.7))

	material.set_shader_parameter("rim_start", Visual.number("toon.character_rim_start", 0.65))
	material.set_shader_parameter("rim_soft", Visual.number("toon.character_rim_soft", 0.02))
	material.set_shader_parameter("rim_strength", _number(options.get("rim"), Visual.number(prefix + "rim_strength", 0.5)))
	material.set_shader_parameter("rim_color", _color(options.get("rim_color", "toon.rim_color")))
	material.set_shader_parameter("rim_light_dir", Vector3(
			Visual.number("toon.rim_light_x", 0.45),
			Visual.number("toon.rim_light_y", 0.75),
			Visual.number("toon.rim_light_z", -0.5)))
	material.set_shader_parameter("spec_gloss", Visual.number("toon.character_spec_gloss", 64.0))
	material.set_shader_parameter("spec_strength", _number(options.get("spec"), 0.0))
	material.set_shader_parameter("spec_color", _color(options.get("spec_color", Color.WHITE)))

	material.set_shader_parameter("emission", _color(options.get("emission", Color.BLACK)))
	material.set_shader_parameter("emission_energy", _number(options.get("emission_energy"), 0.0))

	_apply_outline(material, options, base)


func _apply_outline(material: ShaderMaterial, options: Dictionary, base: Color) -> void:
	var width := _number(options.get("outline_px"), 0.0) * Visual.number("outline.scale", 1.0)
	if width <= 0.0 or not Visual.flag("outline.enabled", true):
		material.next_pass = null
		return
	var line := material.next_pass as ShaderMaterial
	if line == null:
		line = ShaderMaterial.new()
		line.shader = OUTLINE_SHADER
		line.render_priority = 1
		material.next_pass = line
	line.set_shader_parameter("line_color", _color(options["outline_color"]) if options.has("outline_color") else ink(base))
	line.set_shader_parameter("width_px", width)
	line.set_shader_parameter("reference_height", Visual.number("outline.reference_height", 1080.0))
	line.set_shader_parameter("max_growth_distance", Visual.number("outline.max_growth_distance", 25.0))
	line.set_shader_parameter("fade_below_px", Visual.number("outline.fade_below_px", 12.0))
	line.set_shader_parameter("object_height", _number(options.get("height"), 1.0))


## A Color as it is, or the config colour at a dotted path.
func _color(given: Variant) -> Color:
	if given is Color:
		return given
	if given is String:
		return Visual.color(given)
	return Color.MAGENTA


## A number as it is, the config number at a dotted path, or `fallback`.
func _number(given: Variant, fallback: float) -> float:
	if given is float or given is int:
		return float(given)
	if given is String:
		return Visual.number(given, fallback)
	return fallback


## The multiplier that turns a lit channel into its shaded value.
func _ratio(shade: float, lit: float) -> float:
	if lit < 0.02:
		return 1.0
	return clampf(shade / lit, 0.0, 1.0)


func _key(options: Dictionary) -> String:
	var names := options.keys()
	names.sort()
	var parts := PackedStringArray()
	for option_name: Variant in names:
		parts.append("%s=%s" % [option_name, var_to_str(options[option_name])])
	return "|".join(parts)
