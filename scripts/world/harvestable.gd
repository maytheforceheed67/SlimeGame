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
	var model: Dictionary = Database.get_item(item_id).get("model", {})
	var color := Color(str(model.get("color", "ffffff")))
	_visual = Assets.instantiate(item_id, {"color": color})
	add_child(_visual)

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
