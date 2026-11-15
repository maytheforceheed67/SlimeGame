class_name StandIns
extends RefCounted
## Procedural stand-ins: models built in code. The asset manager uses one
## whenever the manifest names no file for an asset, or the file is missing.
## An asset's manifest entry picks its builder by name (placeholder.builder).
##
## These are the bodies the game has had so far, moved here unchanged so that
## every model now comes through the manifest. Later passes of the visual
## overhaul replace each builder with a better-looking one of the same name.

## Every builder name the manifest may use.
const BUILDERS: Array[String] = [
	"slime_blob", "veldora_blocks", "seal_dome", "creature_model",
	"herb_cones", "ore_chunks", "mote_orb", "missing",
]


## Builds the stand-in called `builder` for the asset `id`.
static func build(builder: String, id: String, params: Dictionary) -> Node3D:
	match builder:
		"slime_blob":
			return _slime_blob()
		"veldora_blocks":
			return _veldora_blocks()
		"seal_dome":
			return _seal_dome(float(params.get("radius", 8.0)))
		"creature_model":
			var visual := CreatureVisual.new()
			visual.build(Database.get_creature(id).get("model", {}), bool(params.get("mimic", false)))
			return visual
		"herb_cones":
			return _herb_cones(_glow_material(params.get("color", Color(0.31, 0.84, 0.54))))
		"ore_chunks":
			return _ore_chunks(_glow_material(params.get("color", Color(0.56, 0.48, 1.0))))
		"mote_orb":
			return _mote_orb()
	return _missing_marker()


# --- Slime -------------------------------------------------------------------

static func _slime_blob() -> Node3D:
	var root := Node3D.new()
	root.name = "Slime"

	var jelly := StandardMaterial3D.new()
	jelly.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	jelly.albedo_color = Color(0.36, 0.78, 0.86, 0.8)
	jelly.roughness = 0.12
	jelly.emission_enabled = true
	jelly.emission = Color(0.08, 0.3, 0.36)
	jelly.rim_enabled = true
	jelly.rim = 0.7
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.5
	body_mesh.height = 0.8
	body_mesh.material = jelly
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.4, 0.0)
	root.add_child(body)

	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.85, 0.98, 1.0)
	glow.emission_enabled = true
	glow.emission = Color(0.7, 0.95, 1.0)
	glow.emission_energy_multiplier = 1.5
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.09
	core_mesh.height = 0.18
	core_mesh.material = glow
	var core := MeshInstance3D.new()
	core.name = "Core"
	core.mesh = core_mesh
	core.position = Vector3(0.0, 0.38, -0.14)
	root.add_child(core)
	return root


# --- Veldora and his seal ----------------------------------------------------

static func _veldora_blocks() -> Node3D:
	var root := Node3D.new()
	root.name = "Veldora"
	var scales := StandardMaterial3D.new()
	scales.albedo_color = Color(0.07, 0.06, 0.1)
	scales.roughness = 0.55
	scales.metallic = 0.3
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color(0.75, 0.6, 0.2)
	trim.emission_enabled = true
	trim.emission = Color(0.9, 0.7, 0.2)
	trim.emission_energy_multiplier = 0.6
	var eyes := StandardMaterial3D.new()
	eyes.albedo_color = Color(1.0, 0.85, 0.3)
	eyes.emission_enabled = true
	eyes.emission = Color(1.0, 0.8, 0.25)
	eyes.emission_energy_multiplier = 4.0

	# Lying coiled, head raised toward whoever stands in front (-Z).
	_sphere(root, Vector3(0.0, 2.2, 1.5), Vector3(5.5, 4.2, 8.0), scales)
	_sphere(root, Vector3(0.0, 3.6, -2.6), Vector3(2.6, 2.8, 3.6), scales)
	_sphere(root, Vector3(0.0, 5.0, -4.4), Vector3(2.0, 2.0, 3.0), scales)
	_box(root, Vector3(0.0, 5.3, -6.0), Vector3(1.7, 1.3, 2.6), scales)
	_box(root, Vector3(0.0, 4.9, -7.4), Vector3(1.2, 0.8, 1.2), scales)
	for side: float in [-1.0, 1.0]:
		_sphere(root, Vector3(0.88 * side, 5.75, -6.6), Vector3(0.3, 0.5, 0.7), eyes)
		_cone(root, Vector3(0.6 * side, 6.6, -5.2), 0.28, 1.8, trim).rotation = Vector3(-0.7, 0.0, 0.25 * side)
		var wing := _box(root, Vector3(3.6 * side, 4.6, 1.6), Vector3(4.4, 0.16, 5.6), scales)
		wing.rotation = Vector3(0.1, 0.0, 0.9 * side)
		_box(root, Vector3(2.4 * side, 0.7, -1.6), Vector3(1.1, 1.4, 2.2), scales)
	for i in 5:
		_cone(root, Vector3(0.0, 4.9 - i * 0.25, -1.6 + i * 1.5), 0.3, 1.2, trim)
	for i in 4:
		var taper := 1.0 - i * 0.2
		_sphere(root, Vector3(1.4 + i * 1.3, 0.9 * taper, 5.4 + i * 0.4), Vector3(2.0, 1.7, 2.2) * taper, scales)

	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.8, 0.35)
	glow.light_energy = 1.4
	glow.omni_range = 12.0
	glow.position = Vector3(0.0, 5.6, -7.6)
	root.add_child(glow)
	return root


## The look of the Infinity Prison: a faint sphere. Its collision belongs to
## the character script, not to the model.
static func _seal_dome(radius: float) -> Node3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.8, 1.0, 0.1)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.4, 0.65, 1.0)
	material.emission_energy_multiplier = 0.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.rim_enabled = true
	material.rim = 1.0
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = "Seal"
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


# --- Pickups -----------------------------------------------------------------

static func _herb_cones(material: Material) -> Node3D:
	var root := Node3D.new()
	root.name = "Herb"
	for i in 5:
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0
		mesh.bottom_radius = 0.07
		mesh.height = 0.45 + 0.1 * (i % 3)
		mesh.radial_segments = 6
		var blade := MeshInstance3D.new()
		blade.mesh = mesh
		blade.material_override = material
		var angle := TAU * i / 5.0
		blade.position = Vector3(cos(angle) * 0.12, mesh.height * 0.5, sin(angle) * 0.12)
		blade.rotation = Vector3(sin(angle) * 0.3, 0.0, -cos(angle) * 0.3)
		root.add_child(blade)
	return root


static func _ore_chunks(material: Material) -> Node3D:
	var root := Node3D.new()
	root.name = "Ore"
	var sizes: Array[Vector3] = [Vector3(0.5, 0.4, 0.45), Vector3(0.3, 0.55, 0.3), Vector3(0.28, 0.3, 0.36)]
	var spots: Array[Vector3] = [Vector3(0.0, 0.2, 0.0), Vector3(0.28, 0.27, 0.1), Vector3(-0.25, 0.15, -0.15)]
	for i in sizes.size():
		var mesh := BoxMesh.new()
		mesh.size = sizes[i]
		var chunk := MeshInstance3D.new()
		chunk.mesh = mesh
		chunk.material_override = material
		chunk.position = spots[i]
		chunk.rotation = Vector3(0.3 * i, 0.7 * i + 0.4, 0.2)
		root.add_child(chunk)
	return root


static func _mote_orb() -> Node3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.78, 0.6, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.7, 0.45, 1.0)
	material.emission_energy_multiplier = 3.0
	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = "Mote"
	instance.mesh = mesh
	return instance


## Shown for an id that is not in the manifest at all: an obvious marker, so
## the mistake is seen and fixed rather than hidden.
static func _missing_marker() -> Node3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.0, 0.8)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.5, 0.5, 0.5)
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = "MissingAsset"
	instance.mesh = mesh
	instance.position.y = 0.25
	return instance


# --- Shared pieces -----------------------------------------------------------

static func _glow_material(color: Variant) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.8
	material.roughness = 0.6
	return material


static func _add(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance


static func _sphere(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	var instance := _add(parent, mesh, at, material)
	instance.scale = size
	return instance


static func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, at, material)


static func _cone(parent: Node3D, at: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return _add(parent, mesh, at, material)
