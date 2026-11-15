extends Control
## What the body can perceive, drawn over the world.
##
## While sightless (a slime before Mana Perception) the screen is dark except
## for a small circle around the body, which is what it can feel by touch, and
## arcs around the centre show where sounds come from. When sight arrives the
## circle opens out to the whole screen.
##
## It also shows the interact prompt for whatever is in reach.

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.16;
uniform float softness = 0.1;
uniform float aspect = 1.777;
void fragment() {
	vec2 offset = UV - center;
	offset.x *= aspect;
	COLOR = vec4(0.0, 0.0, 0.0, smoothstep(radius, radius + softness, length(offset)));
}
"""
const BLIND_RADIUS := 0.15
const OPEN_RADIUS := 1.6
const RING_RADIUS := 190.0
const CREATURE_HEARING := 12.0

var _vignette: ColorRect
var _material: ShaderMaterial
var _radius := OPEN_RADIUS
var _prompt: Label
var _sense_prompt: Label
var _font: Font
var _arcs: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font

	var shader := Shader.new()
	shader.code = VIGNETTE_SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	_vignette = ColorRect.new()
	_vignette.material = _material
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.show_behind_parent = true
	add_child(_vignette)

	_prompt = _centered_label(0.7, 17, UiStyle.WORLD_COLOR)
	_sense_prompt = _centered_label(0.64, 17, UiStyle.ADVISOR_COLOR)
	Game.life_began.connect(_on_life_began)


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	var camera := get_viewport().get_camera_3d()
	if player == null or camera == null or Game.life == null:
		return
	var sighted := Game.is_sighted()
	var target := OPEN_RADIUS if sighted else BLIND_RADIUS
	_radius = move_toward(_radius, target, delta * (0.7 if sighted else 4.0))
	_vignette.visible = _radius < OPEN_RADIUS - 0.01
	var view := get_viewport_rect().size
	var at := camera.unproject_position(player.get_aim_origin())
	_material.set_shader_parameter("center", Vector2(at.x / view.x, at.y / view.y))
	_material.set_shader_parameter("radius", _radius)
	_material.set_shader_parameter("aspect", view.x / view.y)

	_arcs.clear()
	if not sighted and Game.is_alive():
		_collect_sounds(player, camera)
	queue_redraw()

	var thing := player.interact_target()
	_prompt.visible = thing != null and Game.can_control()
	if thing != null:
		_prompt.text = "[E]  %s" % thing.interact_label()
	var learning := not sighted and Game.life.flags.has("mana_perception_taught") and Game.can_control()
	_sense_prompt.visible = learning
	if learning:
		_sense_prompt.text = "Hold [R]  Feel the magicules  (%d%%)" % roundi(Game.practice_progress("mana_perception") * 100.0)


func _draw() -> void:
	var center := get_viewport_rect().size * 0.5
	for arc in _arcs:
		var angle: float = arc["angle"]
		var color: Color = arc["color"]
		draw_arc(center, RING_RADIUS, angle - 0.22, angle + 0.22, 16, color, 5.0, true)
		var text_at := center + Vector2.from_angle(angle) * (RING_RADIUS + 34.0)
		var width := 220.0
		draw_string_outline(_font, text_at - Vector2(width * 0.5, -5.0), str(arc["label"]),
				HORIZONTAL_ALIGNMENT_CENTER, width, 14, 4, Color(0.0, 0.0, 0.0, color.a))
		draw_string(_font, text_at - Vector2(width * 0.5, -5.0), str(arc["label"]),
				HORIZONTAL_ALIGNMENT_CENTER, width, 14, color)


func _on_life_began(_new_life: LifeState) -> void:
	_radius = OPEN_RADIUS if Game.is_sighted() else BLIND_RADIUS


func _collect_sounds(player: Player, camera: Camera3D) -> void:
	var listener := player.get_aim_origin()
	for node in get_tree().get_nodes_in_group(SoundSource.GROUP):
		if not node.is_audible():
			continue
		var from: Vector3 = node.sound_position(listener)
		var reach: float = node.sound_range()
		var distance := listener.distance_to(from)
		if distance <= reach:
			_add_arc(camera, listener, from, node.sound_label(), UiStyle.BROADCAST_COLOR, 1.0 - 0.6 * distance / reach)
	for node in get_tree().get_nodes_in_group(Combat.GROUP):
		var creature := node as Creature
		if creature == null:
			continue
		var distance := listener.distance_to(creature.global_position)
		if distance <= CREATURE_HEARING:
			_add_arc(camera, listener, creature.global_position, "something moving", UiStyle.WARNING_COLOR,
					1.0 - 0.6 * distance / CREATURE_HEARING)


func _add_arc(camera: Camera3D, listener: Vector3, from: Vector3, label: String, color: Color, strength: float) -> void:
	var local := camera.global_transform.basis.inverse() * (from - listener)
	var flat := Vector2(local.x, local.z)
	if flat.length() < 0.5:
		return
	_arcs.append({"angle": flat.angle(), "label": label, "color": Color(color, clampf(strength, 0.25, 1.0))})


func _centered_label(anchor_y: float, font_size: int, color: Color) -> Label:
	var label := UiStyle.label(font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = anchor_y
	label.anchor_bottom = anchor_y
	label.offset_left = -300.0
	label.offset_right = 300.0
	label.visible = false
	add_child(label)
	return label
