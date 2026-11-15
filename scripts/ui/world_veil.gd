class_name WorldVeil
extends ColorRect
## A filter over the 3D world, under the rest of the HUD: it drains the
## world's colour and darkens it. Dying drains the colour; the dark between
## lives is this at full strength.

const GROUP := "world_veil"
const SHADER := """
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float desaturation = 0.0;
uniform float darkness = 0.0;
void fragment() {
	vec3 color = texture(screen, SCREEN_UV).rgb;
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(grey), desaturation);
	COLOR = vec4(color * (1.0 - darkness), 1.0);
}
"""

## 0 leaves colour alone; 1 is fully grey.
var desaturation := 0.0:
	set(value):
		desaturation = clampf(value, 0.0, 1.0)
		_apply()
## 0 leaves brightness alone; 1 is black.
var darkness := 0.0:
	set(value):
		darkness = clampf(value, 0.0, 1.0)
		_apply()

var _material: ShaderMaterial


func _ready() -> void:
	add_to_group(GROUP)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shader := Shader.new()
	shader.code = SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	material = _material
	_apply()


func _apply() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("desaturation", desaturation)
	_material.set_shader_parameter("darkness", darkness)
	visible = desaturation > 0.001 or darkness > 0.001
