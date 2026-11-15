class_name Attacker
extends Node
## Runs attacks for its parent body, one at a time: wind-up, strike, recovery.
## Attacks are plain dictionaries from data (creature attacks, race movesets,
## skill actives), so the player and creatures fight by the same rules.
##
## kind "melee"       hits everything in an arc once, as the wind-up ends
## kind "lunge"       the body dashes forward and hits what it touches
## kind "projectile"  launches a Projectile
## kind "cone"        a breath: several ticks over its duration

signal started(attack: Dictionary)
signal struck(attack: Dictionary, target: Node3D, dealt: float)
signal finished(attack: Dictionary)

enum Phase { IDLE, WINDUP, ACTIVE, RECOVER }

var phase := Phase.IDLE
var current: Dictionary = {}
## Horizontal direction of the attack in progress.
var direction := Vector3.FORWARD
## While lunging, the velocity the body should move with; otherwise zero.
var lunge_velocity := Vector3.ZERO

var _body: Node3D
var _timer := 0.0
var _ticks_left := 0
var _tick_timer := 0.0
var _cooldowns: Dictionary = {}
var _already_hit: Array[Node3D] = []
var _effect: Node3D


func _ready() -> void:
	_body = get_parent() as Node3D


func is_busy() -> bool:
	return phase != Phase.IDLE


func cooldown_left(attack: Dictionary) -> float:
	return float(_cooldowns.get(str(attack.get("id", "")), 0.0))


func is_ready(attack: Dictionary) -> bool:
	return not is_busy() and cooldown_left(attack) <= 0.0


## Starts an attack toward `aim` (any vector; it is flattened for melee and
## lunges). Returns false when busy or still on cooldown.
func begin(attack: Dictionary, aim: Vector3) -> bool:
	if not is_ready(attack):
		return false
	current = attack
	direction = aim.normalized() if aim.length_squared() > 0.0001 else Vector3.FORWARD
	if str(attack.get("kind", "")) != "projectile":
		var flat := Vector3(direction.x, 0.0, direction.z)
		direction = flat.normalized() if flat.length_squared() > 0.0001 else Vector3.FORWARD
	_cooldowns[str(attack.get("id", ""))] = float(attack.get("cooldown", 0.5))
	_already_hit.clear()
	phase = Phase.WINDUP
	_timer = float(attack.get("windup", 0.0))
	started.emit(attack)
	return true


## Stops the attack in progress (stagger, death, form change).
func cancel() -> void:
	if phase == Phase.IDLE:
		return
	_end_effect()
	lunge_velocity = Vector3.ZERO
	phase = Phase.IDLE
	finished.emit(current)


func _physics_process(delta: float) -> void:
	for id: String in _cooldowns.keys():
		_cooldowns[id] = float(_cooldowns[id]) - delta
		if float(_cooldowns[id]) <= 0.0:
			_cooldowns.erase(id)
	if phase == Phase.IDLE:
		return

	_timer -= delta
	match phase:
		Phase.WINDUP:
			if _timer <= 0.0:
				_enter_active()
		Phase.ACTIVE:
			_run_active(delta)
			if _timer <= 0.0:
				_end_effect()
				lunge_velocity = Vector3.ZERO
				phase = Phase.RECOVER
				_timer = float(current.get("recover", 0.2))
		Phase.RECOVER:
			if _timer <= 0.0:
				phase = Phase.IDLE
				finished.emit(current)


func _enter_active() -> void:
	phase = Phase.ACTIVE
	var kind := str(current.get("kind", "melee"))
	match kind:
		"melee":
			_timer = 0.12
			_show_cone(float(current.get("range", 2.0)), float(current.get("arc", 90.0)), true)
			_hit_arc()
		"lunge":
			_timer = float(current.get("duration", 0.25))
			lunge_velocity = direction * float(current.get("speed", 10.0))
		"projectile":
			_timer = 0.05
			_launch_projectile()
		"cone":
			_timer = float(current.get("duration", 1.0))
			_ticks_left = int(current.get("ticks", 1))
			_tick_timer = 0.0
			_show_cone(float(current.get("range", 5.0)), float(current.get("arc", 50.0)), false)


func _run_active(delta: float) -> void:
	var kind := str(current.get("kind", "melee"))
	if kind == "lunge":
		var reach := float(current.get("range", 1.2)) + float(_body.get_body_radius())
		for target in Combat.targets_in_arc(_body, _body.get_aim_origin(), direction, reach, 200.0):
			if not _already_hit.has(target):
				_already_hit.append(target)
				_land(target)
	elif kind == "cone" and _ticks_left > 0:
		_tick_timer -= delta
		if _tick_timer <= 0.0:
			_tick_timer = float(current.get("duration", 1.0)) / maxf(1.0, float(current.get("ticks", 1)))
			_ticks_left -= 1
			_hit_arc()


func _hit_arc() -> void:
	var reach := float(current.get("range", 2.0)) + float(_body.get_body_radius())
	for target in Combat.targets_in_arc(_body, _body.get_aim_origin(), direction, reach, float(current.get("arc", 90.0))):
		_land(target)


func _land(target: Node3D) -> void:
	var dealt := Combat.strike(_body, target, current, direction)
	struck.emit(current, target, dealt)


func _launch_projectile() -> void:
	var projectile := Projectile.new()
	projectile.setup(_body, current, direction)
	_body.get_parent().add_child(projectile)
	projectile.global_position = _body.get_aim_origin() + direction * (float(_body.get_body_radius()) + 0.3)


## A translucent cone showing the area an attack covers. `flat` draws the
## thin sweep of a melee swing instead of a breath.
func _show_cone(reach: float, arc_degrees: float, flat: bool) -> void:
	_end_effect()
	reach += float(_body.get_body_radius())
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = reach * tan(deg_to_rad(minf(arc_degrees, 150.0) * 0.5))
	mesh.height = reach
	mesh.radial_segments = 16
	var color := Combat.attack_color(current)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = Toon.veil({"face": color, "face_alpha": "props.telegraph_alpha",
			"edge": color, "edge_alpha": "props.telegraph_edge_alpha", "edge_start": 0.5})
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var up := -direction
	var side := up.cross(Vector3.UP)
	side = side.normalized() if side.length_squared() > 0.0001 else Vector3.RIGHT
	var basis := Basis(side, up, side.cross(up))
	if flat:
		basis = basis * Basis.from_scale(Vector3(1.0, 1.0, 0.08))
	instance.top_level = true
	_body.add_child(instance)
	instance.global_transform = Transform3D(basis, _body.get_aim_origin() + direction * reach * 0.5)
	_effect = instance


func _end_effect() -> void:
	if is_instance_valid(_effect):
		_effect.queue_free()
	_effect = null
