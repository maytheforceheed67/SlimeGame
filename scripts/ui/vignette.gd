extends ColorRect
## A tinted vignette over the 3D world and under the rest of the HUD. The tint
## is a dark colour from the palette, not black: shadows are a colour.
## Offset and darkness come from the visual config (post.vignette_*).

const SHADER := """
shader_type canvas_item;
uniform float offset = 0.35;
uniform float darkness = 0.45;
uniform vec4 tint : source_color = vec4(0.1, 0.086, 0.25, 1.0);
void fragment() {
	float distance_from_centre = length(UV - vec2(0.5)) * 1.41421;
	COLOR = vec4(tint.rgb, smoothstep(offset, 1.0, distance_from_centre) * darkness);
}
"""

var _material: ShaderMaterial


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	material = _material
	Visual.changed.connect(_apply)
	_apply("")


func _apply(_path: String) -> void:
	var darkness := Visual.number("post.vignette_darkness", 0.45)
	_material.set_shader_parameter("offset", Visual.number("post.vignette_offset", 0.35))
	_material.set_shader_parameter("darkness", darkness)
	_material.set_shader_parameter("tint", Visual.color("post.vignette_color", Color(0.1, 0.086, 0.25)))
	visible = darkness > 0.001
