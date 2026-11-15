class_name Player
extends CharacterBody3D
## The player's body. Milestone 0 has one body, the slime: it slides, hops and
## squashes. Race-specific movement is layered on in later milestones.

## The body dropped below `fall_limit`; the level decides where to put it back.
signal fell_out_of_world

@export var move_speed := 5.5
@export var ground_acceleration := 40.0
@export var air_acceleration := 12.0
@export var jump_velocity := 7.0
@export var turn_rate := 12.0
@export var fall_limit := -25.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _was_on_floor := true
var _landing_squash := 0.0

@onready var _visual: Node3D = $Visual
@onready var _camera_rig: CameraRig = $CameraRig


func _physics_process(delta: float) -> void:
	var wish := Vector3.ZERO
	var wants_jump := false
	if Game.is_alive():
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		wish = _camera_rig.yaw_basis() * Vector3(input.x, 0.0, input.y)
		wants_jump = Input.is_action_just_pressed("jump")

	var grounded := is_on_floor()
	if not grounded:
		velocity.y -= _gravity * delta
	elif wants_jump:
		velocity.y = jump_velocity

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var rate := ground_acceleration if grounded else air_acceleration
	horizontal = horizontal.move_toward(wish * move_speed, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		_landing_squash = 1.0
	_was_on_floor = is_on_floor()

	_face(wish, delta)
	_animate(delta)

	if global_position.y < fall_limit:
		fell_out_of_world.emit()


## Puts the body at `at`, standing still.
func respawn(at: Vector3) -> void:
	global_position = at
	velocity = Vector3.ZERO
	_landing_squash = 0.0


func _face(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.01:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw, 1.0 - exp(-turn_rate * delta))


## Squash and stretch: taller while rising, flatter while falling and on landing.
func _animate(delta: float) -> void:
	_landing_squash = move_toward(_landing_squash, 0.0, delta * 5.0)
	var stretch := clampf(velocity.y * 0.035, -0.2, 0.3) - _landing_squash * 0.3
	var target := Vector3(1.0 - stretch * 0.5, 1.0 + stretch, 1.0 - stretch * 0.5)
	_visual.scale = _visual.scale.lerp(target, 1.0 - exp(-20.0 * delta))
