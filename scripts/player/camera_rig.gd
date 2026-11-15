class_name CameraRig
extends Node3D
## Orbit camera. This node turns left and right (yaw); the SpringArm3D child
## tilts up and down (pitch) and pulls the camera in when rock is in the way.

@export var mouse_sensitivity := 0.003
@export var stick_sensitivity := 2.6
@export var min_pitch_degrees := -75.0
@export var max_pitch_degrees := 30.0
@export var min_distance := 2.5
@export var max_distance := 12.0
@export var zoom_step := 0.75

var _yaw := 0.0
var _pitch := deg_to_rad(-20.0)

@onready var _arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	var body := get_parent() as CollisionObject3D
	if body != null:
		_arm.add_excluded_object(body.get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply()


func _process(delta: float) -> void:
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look != Vector2.ZERO:
		_yaw -= look.x * stick_sensitivity * delta
		_pitch -= look.y * stick_sensitivity * delta
		_apply()


func _unhandled_input(event: InputEvent) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion:
		if captured:
			var motion := event as InputEventMouseMotion
			_yaw -= motion.relative.x * mouse_sensitivity
			_pitch -= motion.relative.y * mouse_sensitivity
			_apply()
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if not click.pressed:
			return
		if click.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(-zoom_step)
		elif click.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(zoom_step)
		elif not captured:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("toggle_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if captured else Input.MOUSE_MODE_CAPTURED


## Horizontal facing of the camera, used to make movement camera-relative.
func yaw_basis() -> Basis:
	return Basis(Vector3.UP, _yaw)


func _zoom(amount: float) -> void:
	_arm.spring_length = clampf(_arm.spring_length + amount, min_distance, max_distance)


func _apply() -> void:
	_pitch = clampf(_pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
	rotation.y = _yaw
	_arm.rotation.x = _pitch
