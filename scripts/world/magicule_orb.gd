class_name MagiculeOrb
extends Area3D
## A mote of condensed ambient magicules. Touching it absorbs it and raises EP.
## Milestone 0 placeholder for "EP rises through absorbed magicules"; devouring
## and analysing real prey replaces it as the main source later.

@export var ep_value := 100

var _taken := false
var _phase := 0.0

var _mesh: Node3D


func _ready() -> void:
	_mesh = Assets.instantiate("magicule_mote")
	add_child(_mesh)
	_phase = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_phase += delta * 2.0
	_mesh.position.y = sin(_phase) * 0.12


func _on_body_entered(body: Node3D) -> void:
	if _taken or not (body is Player) or not Game.is_alive():
		return
	_taken = true
	Game.add_ep(ep_value, "ambient_magicules")
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.2)
	tween.tween_callback(queue_free)
