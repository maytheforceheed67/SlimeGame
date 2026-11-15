class_name WaterVolume
extends Area3D
## A body of water. While the player's body is below the surface it swims
## instead of walking, and Predator can drink the water into the Stomach.

const GROUP := "water"

## World height of the surface.
@export var surface_y := 0.0


func _ready() -> void:
	add_to_group(GROUP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func display_name() -> String:
	return "Water"


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.enter_water(self)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		body.exit_water(self)
