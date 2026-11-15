class_name SoundSource
extends Node3D
## A fixed sound in the world: dripping water, wind through a crack. While
## the player's body is sightless, the HUD shows where each audible sound
## comes from, since sound and touch are all it has.

const GROUP := "sound_source"

@export var label := "a sound"
@export var audible_range := 25.0


func _ready() -> void:
	add_to_group(GROUP)


func sound_label() -> String:
	return label


func sound_range() -> float:
	return audible_range


func is_audible() -> bool:
	return true


func sound_position(_listener: Vector3) -> Vector3:
	return global_position
