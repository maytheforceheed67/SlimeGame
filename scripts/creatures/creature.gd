class_name Creature
extends CharacterBody3D
## A monster built entirely from its record in data/creatures.json: body,
## vitals, attacks and what it yields when devoured.
##
## Behaviour is one small routine for every species. A creature idles near its
## home, notices the player inside its sight radius, then keeps choosing the
## attack whose `use_range` fits the current distance and moves to make one
## fit. Hits build stagger; a staggered creature is helpless for a few seconds,
## which is the window to devour it alive. A dead creature stays as remains.

signal died(creature: Creature)

const CORPSE_GROUP := "corpse"
const NAMEPLATE_GROUP := "nameplate"

var creature_id := ""
var data: Dictionary = {}
var vitals := Vitals.new()
var home := Vector3.ZERO
var stagger := 0.0
var staggered_for := 0.0
## Seconds this body has been dead, for remains that fade away.
var dead_for := 0.0

var _attacker: Attacker
## The body shown for this creature: a stand-in built in code, or a model
## file if the asset manifest names one. Animation hooks are optional.
var _visual: Node3D
var _target: Node3D
var _radius := 0.5
var _hover := 0.0
var _speed := 4.0
var _impulse := Vector3.ZERO
var _wander_to := Vector3.ZERO
var _wander_timer := 0.0
var _strafe := 1.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


## Creates a creature from its data id. Add it to the scene, then place it.
static func create(id: String) -> Creature:
	var creature := Creature.new()
	creature.creature_id = id
	creature.data = Database.get_creature(id)
	return creature


func _ready() -> void:
	var body: Dictionary = data.get("body", {})
	var stats: Dictionary = data.get("stats", {})
	_radius = float(body.get("radius", 0.5))
	_hover = float(body.get("hover_height", 0.0))
	_speed = float(stats.get("speed", 4.0))

	collision_layer = Combat.CREATURE_LAYER
	collision_mask = Combat.WORLD_LAYER | Combat.PLAYER_LAYER
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = _radius
	shape.shape = sphere
	shape.position.y = _radius
	add_child(shape)

	_visual = Assets.instantiate(creature_id)
	add_child(_visual)
	if _hover > 0.0:
		_visual.position.y = _radius

	_attacker = Attacker.new()
	add_child(_attacker)

	var owned: Array[String] = []
	owned.assign(data.get("resistances", []))
	vitals.setup(float(stats.get("hp", 50.0)), owned)
	vitals.died.connect(_on_died)
	vitals.resistance_gained.connect(_on_resistance_gained)

	add_to_group(Combat.GROUP)
	add_to_group(NAMEPLATE_GROUP)
	home = global_position
	_wander_to = home


# --- Combatant contract ------------------------------------------------------

func get_faction() -> String:
	return "wild"


func get_vitals() -> Vitals:
	return vitals


func get_power() -> float:
	return 1.0


func get_aim_origin() -> Vector3:
	return global_position + Vector3(0.0, _radius, 0.0)


func get_body_radius() -> float:
	return _radius


func take_hit(hit: Dictionary) -> float:
	if not vitals.alive:
		return 0.0
	var damage_type := str(hit.get("damage_type", "impact"))
	var dealt := vitals.apply_damage(float(hit.get("amount", 0.0)), damage_type)
	Game.hit_landed.emit(get_aim_origin(), dealt, damage_type, false)
	if not vitals.alive:
		return dealt
	Combat.apply_hit_status(vitals, hit)
	_impulse += hit.get("knockback", Vector3.ZERO)
	_show("flash")
	var attacker: Variant = hit.get("attacker")
	if attacker is Node3D and is_instance_valid(attacker):
		_target = attacker
	if staggered_for <= 0.0:
		stagger += float(hit.get("stagger", 0.0))
		if stagger >= float(data.get("stats", {}).get("stagger_threshold", 50.0)):
			_enter_stagger()
	return dealt


# --- Facts for the interface -------------------------------------------------

func display_name() -> String:
	return str(data.get("name", creature_id))


func get_ep() -> int:
	return int(data.get("ep", 0))


func get_rank() -> Dictionary:
	return Database.ranks_by_id.get(str(data.get("rank", "")), {})


func is_staggered() -> bool:
	return vitals.alive and staggered_for > 0.0


func is_corpse() -> bool:
	return not vitals.alive


## Height above the origin where a nameplate should float.
func nameplate_height() -> float:
	return _radius * 2.0 + 0.5


# --- Behaviour ---------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not vitals.alive:
		_tick_corpse(delta)
		return
	vitals.tick(delta)
	if not vitals.alive:
		return

	stagger = maxf(0.0, stagger - Database.tune("combat", "stagger_decay_per_second", 6.0) * delta)
	var move := Vector3.ZERO
	if staggered_for > 0.0:
		staggered_for -= delta
		if staggered_for <= 0.0:
			_show("set_staggered", [false])
	elif _attacker.is_busy():
		move = _attacker.lunge_velocity
		_face(_attacker.direction, delta)
	else:
		_update_target()
		move = _hunt(delta) if _target != null else _wander(delta)
		if move.length_squared() > 0.01:
			_face(move, delta)

	move *= vitals.speed_factor()
	_impulse = _impulse.move_toward(Vector3.ZERO, 30.0 * delta)
	velocity.x = move.x + _impulse.x
	velocity.z = move.z + _impulse.z
	if _hover > 0.0:
		velocity.y = (_desired_height() - global_position.y) * 4.0
	elif is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()
	_show("animate", [delta, clampf(move.length() / maxf(_speed, 0.1), 0.0, 1.0)])


func _update_target() -> void:
	var stats: Dictionary = data.get("stats", {})
	if _target != null:
		var gone: bool = not is_instance_valid(_target) or not _target.get_vitals().alive
		if gone or global_position.distance_to(home) > float(stats.get("leash", 20.0)):
			_target = null
		return
	for node in get_tree().get_nodes_in_group(Combat.GROUP):
		var other := node as Node3D
		if other == null or not Combat.are_hostile(self, other) or not other.get_vitals().alive:
			continue
		if global_position.distance_to(other.global_position) <= float(stats.get("sight", 12.0)) \
				and Combat.has_line_of_sight(self, get_aim_origin(), other.get_aim_origin()):
			_target = other
			return


## Chooses an attack that fits the distance, or moves until one does.
func _hunt(delta: float) -> Vector3:
	var to_target: Vector3 = _target.get_aim_origin() - get_aim_origin()
	var flat := Vector3(to_target.x, 0.0, to_target.z)
	var distance := maxf(0.0, flat.length() - float(_target.get_body_radius()) - _radius)
	var toward := flat.normalized() if flat.length_squared() > 0.0001 else Vector3.FORWARD

	var band_low := 0.0
	var band_high := 1.5
	var band_found := false
	if not vitals.attacks_blocked():
		for attack: Dictionary in data.get("attacks", []):
			if _attacker.cooldown_left(attack) > 0.0:
				continue
			var band: Array = attack.get("use_range", [0.0, 2.0])
			if distance >= float(band[0]) and distance <= float(band[1]):
				_attacker.begin(attack, toward)
				return Vector3.ZERO
			if not band_found:
				band_found = true
				band_low = float(band[0])
				band_high = float(band[1])

	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.2, 2.6)
		_strafe = 1.0 if randf() < 0.5 else -1.0
	var side := toward.cross(Vector3.UP) * _strafe
	if distance > band_high:
		return (toward + side * 0.25).normalized() * _speed
	if distance < band_low:
		return (-toward + side * 0.4).normalized() * _speed * 0.8
	return side * _speed * 0.45


func _wander(delta: float) -> Vector3:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.5, 6.0)
		_wander_to = home + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0))
	var offset := _wander_to - global_position
	offset.y = 0.0
	if offset.length() < 0.6:
		return Vector3.ZERO
	return offset.normalized() * _speed * 0.35


## Flyers hold their hover height, and drop to their prey's level to bite.
func _desired_height() -> float:
	if _target != null and is_instance_valid(_target):
		var flat_distance := Vector2(_target.global_position.x - global_position.x,
				_target.global_position.z - global_position.z).length()
		if flat_distance < 5.0:
			return _target.global_position.y + 0.2
		return _target.global_position.y + _hover
	return home.y


func _face(direction: Vector3, delta: float) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), 1.0 - exp(-9.0 * delta))


func _enter_stagger() -> void:
	stagger = 0.0
	staggered_for = Database.tune("combat", "stagger_duration", 3.5)
	_attacker.cancel()
	_show("set_staggered", [true])


func _on_died(_damage_type_id: String) -> void:
	_attacker.cancel()
	_show("set_dead")
	_target = null
	staggered_for = 0.0
	remove_from_group(Combat.GROUP)
	add_to_group(CORPSE_GROUP)
	collision_layer = Combat.CORPSE_LAYER
	collision_mask = Combat.WORLD_LAYER
	died.emit(self)
	Game.creature_died.emit(self)


## Remains fall to the floor, linger, then fade.
func _tick_corpse(delta: float) -> void:
	dead_for += delta
	velocity.x = 0.0
	velocity.z = 0.0
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()
	if dead_for >= Database.tune("combat", "corpse_lifetime", 180.0):
		queue_free()


## Tells the body to show something (flash, stagger, death, movement). A body
## that does not know the cue ignores it, so a model file need not support all.
func _show(cue: StringName, arguments: Array = []) -> void:
	if _visual.has_method(cue):
		_visual.callv(cue, arguments)


## Everyone in range hears the Voice when a creature adapts mid-fight.
func _on_resistance_gained(resistance_id: String, _cause: String) -> void:
	Voice.broadcast("creature_resistance", {
		"creature": display_name(),
		"resistance": Database.resistance_name(resistance_id),
	})
