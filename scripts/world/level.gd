class_name Level
extends Node3D
## A region's scene: fixed geography plus what one life finds in it.
##
## Geography never changes. Creatures, harvestables and magicule motes are
## placed fresh for each life from that life's seed, so every reincarnation
## is a new branch of the timeline (design document, section 3). The markers
## under Spawns, Harvest and Motes say where things may appear; a marker's
## name up to "__" is the creature or item id.

const MOTE_SCENE: PackedScene = preload("res://scenes/world/magicule_orb.tscn")

## Tests turn this off to get an empty cave.
static var populate_enabled := true

@export var region_id := ""

@onready var _spawned: Node3D = $Spawned


func spawn_position() -> Vector3:
	return point("SpawnPoint")


## World position of a named marker under Points.
func point(marker_name: String) -> Vector3:
	var marker := get_node_or_null("Points/" + marker_name) as Node3D
	return marker.global_position if marker != null else global_position


## Removes everything placed for the previous life.
func clear() -> void:
	for child in _spawned.get_children():
		child.queue_free()


## Places this life's creatures, harvestables and motes.
func populate(life: LifeState) -> void:
	clear()
	if not populate_enabled:
		return
	var region := Database.get_region(region_id)
	var rules: Dictionary = region.get("spawn", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = life.world_seed

	for marker in $Spawns.get_children():
		var creature_id := str(marker.name).get_slice("__", 0)
		var certain: bool = Database.get_creature(creature_id).get("boss", false)
		if certain or rng.randf() < float(rules.get("creature_chance", 1.0)):
			_place(Creature.create(creature_id), marker)

	for marker in $Harvest.get_children():
		if rng.randf() < float(rules.get("harvest_chance", 1.0)):
			_place(Harvestable.create(str(marker.name).get_slice("__", 0)), marker)

	var motes: Array[Node] = $Motes.get_children()
	for i in range(motes.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held := motes[i]
		motes[i] = motes[j]
		motes[j] = held
	var density := Database.density_level(int(region.get("magicule_density", 0)))
	for i in mini(int(rules.get("mote_count", 0)), motes.size()):
		var mote := MOTE_SCENE.instantiate() as MagiculeOrb
		mote.ep_value = int(density.get("ambient_ep", 0))
		_place(mote, motes[i])


func _place(node: Node3D, marker: Node) -> void:
	_spawned.add_child(node)
	node.global_position = (marker as Node3D).global_position
	if node is Creature:
		node.home = node.global_position
