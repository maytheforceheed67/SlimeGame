class_name StandIns
extends RefCounted
## Procedural stand-ins: models built in code. The asset manager uses one
## whenever the manifest names no file for an asset, or the file is missing.
## An asset's manifest entry picks its builder by name (placeholder.builder).
##
## These are still the simple bodies the game began with, now drawn with the
## shared toon material and an ink line (visual overhaul, Pass 1). Later
## passes replace each builder with a better-looking one of the same name.
##
## Every part is one of MeshKit's unit shapes, and every material comes from
## the Toon autoload with its colours named by their path in the visual
## config. A model that does not move its parts is baked into one mesh per
## material (see Sculpt below), so it costs a draw or two, not thirty.

## Every builder name the manifest may use.
const BUILDERS: Array[String] = [
	"slime_blob", "veldora_blocks", "seal_dome", "creature_model",
	"herb_cones", "ore_chunks", "mote_orb", "missing",
]


## Builds the stand-in called `builder` for the asset `id`. `params` carries
## what the caller asked for plus the manifest's "outline_px".
static func build(builder: String, id: String, params: Dictionary) -> Node3D:
	var line := float(params.get("outline_px", 0.0))
	match builder:
		"slime_blob":
			return _slime_blob(line)
		"veldora_blocks":
			return _veldora_blocks(line)
		"seal_dome":
			return _seal_dome(float(params.get("radius", 8.0)))
		"creature_model":
			var visual := CreatureVisual.new()
			visual.build(Database.get_creature(id).get("model", {}), bool(params.get("mimic", false)), line)
			return visual
		"herb_cones":
			return _herb_cones(line)
		"ore_chunks":
			return _ore_chunks(line)
		"mote_orb":
			return _mote_orb()
	return _missing_marker()


# --- Slime -------------------------------------------------------------------

## An opaque, banded body for now. The translucent jelly and its visible
## core are Pass 2; the core is built already and waits inside.
static func _slime_blob(line: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Slime"
	var jelly := Toon.make({"color": "palette.slime.body", "shade": "palette.slime.shade",
			"rim_color": "palette.slime.rim", "outline_px": line, "outline_color": "palette.slime.outline",
			"spec": "slime.highlight", "spec_color": "palette.slime.highlight", "height": 0.8})
	var body := _sphere(root, Vector3(0.0, 0.4, 0.0), Vector3(1.0, 0.8, 1.0), jelly)
	body.name = "Body"
	var glow := Toon.make({"color": "palette.slime.core", "emission": "palette.slime.core", "emission_energy": "props.eye_glow"})
	var core := _sphere(root, Vector3(0.0, 0.38, -0.14), Vector3.ONE * 0.18, glow)
	core.name = "Core"
	core.visible = false
	return root


# --- Veldora and his seal ----------------------------------------------------

static func _veldora_blocks(line: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Veldora"
	var scales := Toon.shared({"color": "palette.veldora.scales", "shade": "palette.veldora.shade",
			"outline_px": line, "outline_color": "palette.veldora.outline", "rim_color": "palette.veldora.storm", "height": 8.0})
	var wings := Toon.shared({"color": "palette.veldora.wing", "outline_px": line,
			"outline_color": "palette.veldora.outline", "height": 8.0})
	var trim := Toon.shared({"color": "palette.veldora.horn", "shade": "palette.veldora.horn_shade",
			"outline_px": "outline.detail_px", "height": 8.0})
	var eyes := Toon.shared({"color": "palette.veldora.eyes", "emission": "palette.veldora.eyes",
			"emission_energy": "props.eye_glow", "outline_px": "outline.detail_px",
			"outline_color": "palette.veldora.outline", "height": 8.0})

	# Lying coiled, head raised toward whoever stands in front (-Z).
	var sculpt := Sculpt.new()
	sculpt.sphere(scales, Vector3(0.0, 2.2, 1.5), Vector3(5.5, 4.2, 8.0))
	sculpt.sphere(scales, Vector3(0.0, 3.6, -2.6), Vector3(2.6, 2.8, 3.6))
	sculpt.sphere(scales, Vector3(0.0, 5.0, -4.4), Vector3(2.0, 2.0, 3.0))
	sculpt.box(scales, Vector3(0.0, 5.3, -6.0), Vector3(1.7, 1.3, 2.6))
	sculpt.box(scales, Vector3(0.0, 4.9, -7.4), Vector3(1.2, 0.8, 1.2))
	for side: float in [-1.0, 1.0]:
		sculpt.sphere(eyes, Vector3(0.88 * side, 5.75, -6.6), Vector3(0.3, 0.5, 0.7))
		sculpt.cone(trim, Vector3(0.6 * side, 6.6, -5.2), 0.28, 1.8, Vector3(-0.7, 0.0, 0.25 * side))
		sculpt.box(wings, Vector3(3.6 * side, 4.6, 1.6), Vector3(4.4, 0.16, 5.6), Vector3(0.1, 0.0, 0.9 * side))
		sculpt.box(scales, Vector3(2.4 * side, 0.7, -1.6), Vector3(1.1, 1.4, 2.2))
	for i in 5:
		sculpt.cone(trim, Vector3(0.0, 4.9 - i * 0.25, -1.6 + i * 1.5), 0.3, 1.2)
	for i in 4:
		var taper := 1.0 - i * 0.2
		sculpt.sphere(scales, Vector3(1.4 + i * 1.3, 0.9 * taper, 5.4 + i * 0.4), Vector3(2.0, 1.7, 2.2) * taper)
	sculpt.build(root, "veldora")

	var glow := OmniLight3D.new()
	glow.light_color = Visual.color("palette.veldora.horn")
	glow.light_energy = 1.4
	glow.omni_range = 12.0
	glow.position = Vector3(0.0, 5.6, -7.6)
	root.add_child(glow)
	return root


## The look of the Infinity Prison: a faint barrier with a bright edge. Its
## collision belongs to the character script, not to the model.
static func _seal_dome(radius: float) -> Node3D:
	var instance := MeshInstance3D.new()
	instance.name = "Seal"
	instance.mesh = MeshKit.sphere(48)
	instance.scale = Vector3.ONE * radius * 2.0
	instance.material_override = Toon.veil({"face": "palette.seal.barrier", "face_alpha": "seal.face_alpha",
			"edge": "palette.seal.barrier", "edge_alpha": "seal.edge_alpha",
			"edge_start": "seal.edge_start", "energy": "seal.energy"})
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


# --- Pickups -----------------------------------------------------------------

static func _herb_cones(line: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Herb"
	root.set_meta("glow_color", Visual.color("palette.herb.tip"))
	var leaf := Toon.shared({"color": "palette.herb.leaf", "shade": "palette.herb.shade",
			"emission": "palette.herb.tip", "emission_energy": "props.pickup_glow", "outline_px": line, "height": 0.6})
	var sculpt := Sculpt.new()
	for i in 5:
		var height := 0.45 + 0.1 * (i % 3)
		var angle := TAU * i / 5.0
		sculpt.cone(leaf, Vector3(cos(angle) * 0.12, height * 0.5, sin(angle) * 0.12), 0.07, height,
				Vector3(sin(angle) * 0.3, 0.0, -cos(angle) * 0.3), 6)
	sculpt.build(root, "herb")
	return root


static func _ore_chunks(line: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Ore"
	root.set_meta("glow_color", Visual.color("palette.ore.mid"))
	var facet := Toon.shared({"color": "palette.ore.mid", "shade": "palette.ore.dark",
			"emission": "palette.ore.mid", "emission_energy": "props.pickup_glow", "outline_px": line, "height": 0.6})
	var sizes: Array[Vector3] = [Vector3(0.5, 0.4, 0.45), Vector3(0.3, 0.55, 0.3), Vector3(0.28, 0.3, 0.36)]
	var spots: Array[Vector3] = [Vector3(0.0, 0.2, 0.0), Vector3(0.28, 0.27, 0.1), Vector3(-0.25, 0.15, -0.15)]
	var sculpt := Sculpt.new()
	for i in sizes.size():
		sculpt.box(facet, spots[i], sizes[i], Vector3(0.3 * i, 0.7 * i + 0.4, 0.2))
	sculpt.build(root, "ore")
	return root


static func _mote_orb() -> Node3D:
	var instance := MeshInstance3D.new()
	instance.name = "Mote"
	instance.mesh = MeshKit.sphere(16)
	instance.scale = Vector3.ONE * 0.36
	instance.material_override = Toon.shared({"color": "palette.ore.mote_b", "emission": "palette.ore.mote_b",
			"emission_energy": "props.mote_glow"})
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## Shown for an id that is not in the manifest at all: an obvious marker, so
## the mistake is seen and fixed rather than hidden.
static func _missing_marker() -> Node3D:
	var instance := MeshInstance3D.new()
	instance.name = "MissingAsset"
	instance.mesh = MeshKit.cube()
	instance.scale = Vector3.ONE * 0.5
	instance.position.y = 0.25
	instance.material_override = Toon.shared({"color": Color(1.0, 0.0, 0.8), "emission": Color(1.0, 0.0, 0.8),
			"emission_energy": 0.6, "outline_px": "outline.width_px"})
	return instance


# --- Shared pieces -----------------------------------------------------------

static func _add(parent: Node3D, mesh: Mesh, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.scale = size
	parent.add_child(instance)
	return instance


static func _sphere(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	return _add(parent, MeshKit.sphere(32), at, size, material)


## Collects placed shapes and bakes them into one mesh per material: for
## models whose parts never move against each other.
class Sculpt:
	var _materials: Array[Material] = []
	var _parts: Array[Array] = []

	func sphere(material: Material, at: Vector3, size: Vector3, turn: Vector3 = Vector3.ZERO) -> void:
		_place(material, MeshKit.sphere(32), at, size, turn)

	func box(material: Material, at: Vector3, size: Vector3, turn: Vector3 = Vector3.ZERO) -> void:
		_place(material, MeshKit.cube(), at, size, turn)

	func cone(material: Material, at: Vector3, radius: float, height: float, turn: Vector3 = Vector3.ZERO, sides: int = 8) -> void:
		_place(material, MeshKit.cone(sides), at, Vector3(radius * 2.0, height, radius * 2.0), turn)

	## Adds one MeshInstance3D per material to `root`. `key` names the model
	## so that every copy of it shares the same baked meshes.
	func build(root: Node3D, key: String) -> void:
		for i in _materials.size():
			var instance := MeshInstance3D.new()
			instance.mesh = MeshKit.merged("%s:%d" % [key, i], _parts[i])
			instance.material_override = _materials[i]
			root.add_child(instance)

	func _place(material: Material, mesh: Mesh, at: Vector3, size: Vector3, turn: Vector3) -> void:
		var index := _materials.find(material)
		if index < 0:
			index = _materials.size()
			_materials.append(material)
			_parts.append([])
		# The same placement a node gives: turned, then scaled along its own axes.
		_parts[index].append([mesh, Transform3D(Basis.from_euler(turn) * Basis.from_scale(size), at)])
