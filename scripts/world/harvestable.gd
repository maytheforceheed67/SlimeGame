class_name Harvestable
extends Node3D
## Something inanimate in the world that can be devoured: a hipokute herb, a
## vein of magic ore. Its item comes from data/items.json, and so does its
## placeholder shape.

const GROUP := "devourable"

@export var item_id := "hipokute_herb"
@export var amount := 1

var _visual: Node3D
var _taken := false


## Creates a harvestable for an item. Add it to the scene, then place it.
static func create(id: String, count: int = 1) -> Harvestable:
	var node := Harvestable.new()
	node.item_id = id
	node.amount = count
	return node


func _ready() -> void:
	add_to_group(GROUP)
	_visual = Node3D.new()
	add_child(_visual)
	var model: Dictionary = Database.get_item(item_id).get("model", {})
	var color := Color(str(model.get("color", "ffffff")))
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.8
	material.roughness = 0.6
	if str(model.get("kind", "herb")) == "ore":
		_build_ore(material)
	else:
		_build_herb(material)

	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.5
	light.omni_range = 2.5
	light.position.y = 0.5
	add_child(light)


func display_name() -> String:
	return Database.item_name(item_id)


func is_available() -> bool:
	return not _taken


## Shrinks the node as it is drawn in. `progress` runs 0 to 1.
func set_devour_progress(progress: float) -> void:
	_visual.scale = Vector3.ONE * (1.0 - 0.7 * clampf(progress, 0.0, 1.0))


## Removes the node from the world once it has been swallowed.
func consume() -> void:
	_taken = true
	remove_from_group(GROUP)
	queue_free()


func _build_herb(material: Material) -> void:
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
		_visual.add_child(blade)


func _build_ore(material: Material) -> void:
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
		_visual.add_child(chunk)
