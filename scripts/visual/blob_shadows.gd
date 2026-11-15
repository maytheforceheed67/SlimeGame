class_name BlobShadows
extends MultiMeshInstance3D
## Blob shadows (docs/VISUAL_STYLE.md, section 3.4): a soft disc on the
## ground under every actor and pickup, shrinking in strength and growing in
## size with height, so a hop or a hovering bat reads at a glance. All of
## them are one draw.
##
## This only reads where things are. Nothing in the game reads it back.

const MAX_DISCS := 96
## Groups whose members get a disc.
const GROUPS: Array[String] = [Combat.GROUP, Creature.CORPSE_GROUP, Harvestable.GROUP]
const SHADER: Shader = preload("res://scripts/visual/shaders/blob_shadow.gdshader")
const LIFT := 0.03

## Strength of each disc drawn this frame, in drawing order.
var strengths := PackedFloat32Array()

var _material: ShaderMaterial


func _ready() -> void:
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = quad
	multimesh.instance_count = MAX_DISCS
	multimesh.visible_instance_count = 0
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The discs are placed in world space all over the level.
	top_level = true
	global_transform = Transform3D.IDENTITY
	custom_aabb = AABB(Vector3(-1000.0, -200.0, -1000.0), Vector3(2000.0, 400.0, 2000.0))
	Visual.changed.connect(_apply_look)
	_apply_look("")


func _apply_look(_path: String) -> void:
	_material.set_shader_parameter("tint", Visual.color("blob_shadow.tint", Color(0.18, 0.165, 0.4)))
	_material.set_shader_parameter("softness", Visual.number("blob_shadow.softness", 0.45))


func _physics_process(_delta: float) -> void:
	var count := 0
	strengths.clear()
	if Visual.flag("blob_shadow.enabled", true):
		var space := get_world_3d().direct_space_state
		var opacity := Visual.number("blob_shadow.opacity", 0.55)
		var radius_factor := Visual.number("blob_shadow.radius_factor", 1.25)
		var grow := Visual.number("blob_shadow.grow_with_height", 0.12)
		var fade_height := maxf(Visual.number("blob_shadow.fade_height", 7.0), 0.1)
		for group in GROUPS:
			for node in get_tree().get_nodes_in_group(group):
				var body := node as Node3D
				if body == null or count >= MAX_DISCS or not body.is_visible_in_tree():
					continue
				var radius := 0.3
				if body.has_method("get_body_radius"):
					radius = float(body.call("get_body_radius"))
				var from := body.global_position + Vector3.UP * 0.3
				var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * (fade_height + 0.5), Combat.WORLD_LAYER)
				var hit := space.intersect_ray(query)
				if hit.is_empty():
					continue
				var height := maxf(0.0, body.global_position.y - (hit["position"] as Vector3).y)
				var strength := opacity * clampf(1.0 - height / fade_height, 0.0, 1.0)
				var width := radius * 2.0 * radius_factor * (1.0 + height * grow)
				var basis := Basis.from_scale(Vector3(width, 1.0, width))
				multimesh.set_instance_transform(count, Transform3D(basis, (hit["position"] as Vector3) + Vector3.UP * LIFT))
				multimesh.set_instance_color(count, Color(1.0, 1.0, 1.0, strength))
				strengths.append(strength)
				count += 1
	multimesh.visible_instance_count = count
