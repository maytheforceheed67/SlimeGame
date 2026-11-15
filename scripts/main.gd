extends Node3D
## Entry scene for Milestone 0: the Sealed Cave, the player and the HUD.
## Starts the first life and has the level re-seeded each time a life begins.

@onready var level: Level = $SealedCave
@onready var _player: Player = $Player


func _ready() -> void:
	Game.life_began.connect(_on_life_began)
	_player.fell_out_of_world.connect(_place_player)
	if not Database.problems.is_empty():
		Voice.say("data_fault", {"count": Database.problems.size()})
	Game.begin_life()


func _on_life_began(new_life: LifeState) -> void:
	_place_player()
	level.populate(new_life)


func _place_player() -> void:
	_player.respawn(level.spawn_position())
