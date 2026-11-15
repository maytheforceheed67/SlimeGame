extends Node3D
## Milestone 0 entry scene: a greybox Sealed Cave, the player and the HUD.
## Starts the first life and re-seeds the level every time a life begins.

const ORB_SCENE: PackedScene = preload("res://scenes/world/magicule_orb.tscn")
const ORBS_PER_LIFE := 10

@onready var _player: Player = $Player
@onready var _spawn_point: Marker3D = $SealedCave/SpawnPoint
@onready var _orb_spots: Node3D = $SealedCave/OrbSpots
@onready var _orbs: Node3D = $Orbs


func _ready() -> void:
	Game.life_began.connect(_on_life_began)
	_player.fell_out_of_world.connect(_place_player)
	if not Database.problems.is_empty():
		Voice.say("data_fault", {"count": Database.problems.size()})
	Game.begin_life()


func _on_life_began(new_life: LifeState) -> void:
	_place_player()
	_scatter_orbs(new_life)


func _place_player() -> void:
	_player.respawn(_spawn_point.global_position)


## Each life is a fresh branch of the timeline: the same cave, with the
## magicule motes placed by that life's seed.
func _scatter_orbs(new_life: LifeState) -> void:
	for old_orb in _orbs.get_children():
		old_orb.queue_free()

	var rng := RandomNumberGenerator.new()
	rng.seed = new_life.world_seed
	var spots: Array[Node] = _orb_spots.get_children()
	for i in range(spots.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held := spots[i]
		spots[i] = spots[j]
		spots[j] = held

	var region := Database.get_region(new_life.region_id)
	var density := Database.density_level(int(region.get("magicule_density", 0)))
	var ep_each := int(density.get("ambient_ep", 0))
	for i in mini(ORBS_PER_LIFE, spots.size()):
		var orb := ORB_SCENE.instantiate() as MagiculeOrb
		orb.ep_value = ep_each
		_orbs.add_child(orb)
		orb.global_position = (spots[i] as Node3D).global_position
