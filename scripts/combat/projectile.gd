class_name Projectile
extends Area3D
## A shot in flight: a water blade, a strand of thread. It strikes the first
## hostile body it touches and breaks on rock. Hostile shots can be swallowed
## by Predator while they are in the air.

const GROUP := "projectile"

var attack: Dictionary = {}
var direction := Vector3.FORWARD
var user: Node3D
var faction := ""
var power := 1.0

var _travelled := 0.0
var _spent := false


func setup(from: Node3D, attack_data: Dictionary, aim: Vector3) -> void:
	user = from
	attack = attack_data
	direction = aim.normalized()
	faction = from.get_faction()
	power = from.get_power()


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = 0
	collision_mask = Combat.WORLD_LAYER | Combat.PLAYER_LAYER | Combat.CREATURE_LAYER
	var radius := float(attack.get("radius", 0.35))

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	add_child(shape)

	var color := Combat.attack_color(attack)
	var instance := MeshInstance3D.new()
	instance.mesh = MeshKit.sphere(16)
	instance.scale = Vector3(radius * 2.0, radius * 0.7, radius * 2.0)
	instance.material_override = Toon.shared({"color": color, "emission": color, "emission_energy": "props.projectile_glow"})
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var step := float(attack.get("speed", 20.0)) * delta
	global_position += direction * step
	_travelled += step
	if _travelled >= float(attack.get("range", 20.0)):
		queue_free()


func get_faction() -> String:
	return faction


func get_power() -> float:
	return power


## What a swallowed shot becomes in the Stomach.
func swallowed_item() -> String:
	return "toxin" if attack.get("status") is Dictionary else ""


func _on_body_entered(body: Node3D) -> void:
	if _spent or body == user:
		return
	if body.is_in_group(Combat.GROUP):
		if body.get_faction() == faction:
			return
		_spent = true
		var striker: Node3D = user if is_instance_valid(user) else self
		Combat.strike(striker, body, attack, direction)
	else:
		_spent = true
	queue_free()
