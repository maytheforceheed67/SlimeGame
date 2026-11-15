class_name Player
extends CharacterBody3D
## The player's body. Milestone 0 has one body, the slime: it slides, hops,
## clings to rock, flattens to squeeze through gaps and drifts or swims in
## water. It fights through the same Attacker and Vitals as every creature.
##
## Each physics frame picks one way of moving, in this order: swimming (below
## a water surface), clinging (holding cling against a wall, with stamina
## left), otherwise walking and hopping.

## The body dropped below `fall_limit`; the level decides where to put it back.
signal fell_out_of_world

const GROUP := "player"
const RADIUS := 0.4
const SQUEEZED_RADIUS := 0.2
const RIG_HEIGHT := 0.7
const SQUEEZED_RIG_HEIGHT := 0.28

@export var ground_acceleration := 40.0
@export var air_acceleration := 12.0
@export var turn_rate := 12.0
@export var fall_limit := -40.0

var attacker: Attacker
var predator: Predator
var advisor: Advisor

var _move_speed := 5.5
var _jump_velocity := 7.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _was_on_floor := true
var _landing_squash := 0.0
var _impulse := Vector3.ZERO
var _flinch := 0.0
var _invulnerable := 0.0

var _water: WaterVolume
var _squeezed := false
var _clinging := false
var _wall_normal := Vector3.ZERO
var _mantle := 0.0
var _jet := 0.0
var _jet_velocity := Vector3.ZERO

@onready var _visual: Node3D = $Visual
@onready var _camera_rig: CameraRig = $CameraRig
@onready var _collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	attacker = Attacker.new()
	add_child(attacker)
	predator = Predator.new()
	add_child(predator)
	advisor = Advisor.new()
	add_child(advisor)
	add_to_group(GROUP)
	add_to_group(Combat.GROUP)
	Game.life_began.connect(_on_life_began)


# --- Combatant contract ------------------------------------------------------

func get_faction() -> String:
	return "player"


func get_vitals() -> Vitals:
	return Game.life.vitals


func get_power() -> float:
	return Game.get_power()


func get_lifesteal() -> float:
	return Game.get_lifesteal()


func get_aim_origin() -> Vector3:
	return global_position + Vector3(0.0, SQUEEZED_RADIUS if _squeezed else RADIUS, 0.0)


func get_body_radius() -> float:
	return RADIUS


func take_hit(hit: Dictionary) -> float:
	if not Game.is_alive() or _invulnerable > 0.0:
		return 0.0
	var vitals := Game.life.vitals
	var damage_type := str(hit.get("damage_type", "impact"))
	var dealt := vitals.apply_damage(float(hit.get("amount", 0.0)), damage_type)
	Game.hit_landed.emit(get_aim_origin(), dealt, damage_type, true)
	Game.count("damage_taken", dealt)
	Game.count("damage_taken_" + damage_type, dealt)
	if not vitals.alive:
		return dealt
	Combat.apply_hit_status(vitals, hit)
	_impulse += hit.get("knockback", Vector3.ZERO)
	_invulnerable = Database.tune("combat", "invulnerable_after_hit", 0.4)
	if dealt > 0.0 and not Game.life.resistances.has("pain_nullification"):
		_flinch = Database.tune("combat", "flinch_time", 0.3)
	return dealt


# --- State others ask about ----------------------------------------------------

## True while the body's centre is below a water surface.
func in_water() -> bool:
	return _water != null and get_aim_origin().y < _water.surface_y


## The water the body is in, or null.
func water() -> WaterVolume:
	return _water if in_water() else null


func is_clinging() -> bool:
	return _clinging


func is_squeezed() -> bool:
	return _squeezed


func enter_water(volume: WaterVolume) -> void:
	_water = volume


func exit_water(volume: WaterVolume) -> void:
	if _water == volume:
		_water = null


# --- Aiming ------------------------------------------------------------------

## The hostile creature the player is most plausibly aiming at, or null.
func soft_target() -> Node3D:
	var forward := -_camera_rig.yaw_basis().z
	var targets := Combat.targets_in_arc(self, get_aim_origin(), forward,
			Database.tune("combat", "aim_assist_range", 14.0), Database.tune("combat", "aim_assist_angle", 50.0))
	if targets.is_empty():
		# Something right on top of the body is the target whichever way the camera looks.
		targets = Combat.targets_in_arc(self, get_aim_origin(), forward,
				Database.tune("combat", "aim_assist_close_range", 3.5), 360.0)
	return targets[0] if not targets.is_empty() else null


## Direction an attack should go: at the soft target, else where the camera faces.
func aim_direction() -> Vector3:
	var target := soft_target()
	if target != null:
		return (target.get_aim_origin() - get_aim_origin()).normalized()
	return -_camera_rig.yaw_basis().z


# --- Frame update ------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_flinch = maxf(0.0, _flinch - delta)
	_invulnerable = maxf(0.0, _invulnerable - delta)
	var life := Game.life
	if life == null:
		return
	var vitals := life.vitals
	if Game.is_alive():
		vitals.tick(delta)

	var controllable := Game.can_control() and _flinch <= 0.0
	var input := Vector2.ZERO
	var wants_jump := false
	if controllable:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		wants_jump = Input.is_action_just_pressed("jump")
		if Input.is_action_just_pressed("use_potion"):
			Game.use_potion()
	var wish := _camera_rig.yaw_basis() * Vector3(input.x, 0.0, input.y)
	var swimming := in_water()

	_set_squeezed(controllable and Input.is_action_pressed("squeeze") and not swimming)
	_update_cling(controllable and Input.is_action_pressed("cling") and not swimming, life)
	if controllable and not predator.is_devouring() and not _squeezed and not _clinging:
		_read_attacks(vitals)

	var speed := _move_speed * vitals.speed_factor()
	if predator.is_devouring():
		speed *= 0.4
	if _squeezed:
		speed *= Database.tune("traversal", "squeeze_speed_factor", 0.45)

	if swimming:
		_swim(delta, wish, speed, wants_jump, controllable)
	elif _clinging:
		_climb(delta, input, wants_jump, life)
	else:
		_walk(delta, wish, speed, wants_jump)

	_impulse = _impulse.move_toward(Vector3.ZERO, 30.0 * delta)
	velocity.x += _impulse.x
	velocity.z += _impulse.z
	move_and_slide()
	velocity.x -= _impulse.x
	velocity.z -= _impulse.z

	if _clinging:
		if is_on_wall():
			_wall_normal = get_wall_normal()
		elif input.y < -0.1:
			# Climbed past the top of the wall: push over onto the ledge.
			_clinging = false
			_mantle = 0.3
		else:
			_clinging = false
	if is_on_floor() and not _clinging:
		life.stamina = minf(Database.tune("vitals", "stamina_max", 100.0),
				life.stamina + Database.tune("vitals", "stamina_regen_per_second", 30.0) * delta)

	if is_on_floor() and not _was_on_floor:
		_landing_squash = 1.0
	_was_on_floor = is_on_floor()

	_face(attacker.direction if attacker.is_busy() else wish, delta)
	_animate(delta)
	_camera_rig.position.y = move_toward(_camera_rig.position.y,
			SQUEEZED_RIG_HEIGHT if _squeezed else RIG_HEIGHT, 3.0 * delta)

	if global_position.y < fall_limit:
		fell_out_of_world.emit()


## Puts the body at `at`, standing still.
func respawn(at: Vector3) -> void:
	global_position = at
	velocity = Vector3.ZERO
	_impulse = Vector3.ZERO
	_landing_squash = 0.0
	_clinging = false
	_mantle = 0.0
	_jet = 0.0
	_set_squeezed(false, true)
	attacker.cancel()


func _on_life_began(new_life: LifeState) -> void:
	var vitals := Database.race_vitals(new_life.race_id)
	_move_speed = float(vitals.get("move_speed", 5.5))
	_jump_velocity = float(vitals.get("jump_velocity", 7.0))
	_flinch = 0.0
	_invulnerable = 0.0


# --- Ways of moving ----------------------------------------------------------

func _walk(delta: float, wish: Vector3, speed: float, wants_jump: bool) -> void:
	var grounded := is_on_floor()
	if _mantle > 0.0:
		_mantle -= delta
		velocity = -_wall_normal * 3.0 + Vector3.UP * 2.5
		return
	if not grounded:
		velocity.y -= _gravity * delta
	elif wants_jump and not attacker.is_busy() and not _squeezed:
		velocity.y = _jump_velocity

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if attacker.lunge_velocity != Vector3.ZERO:
		horizontal = attacker.lunge_velocity
	else:
		var rate := ground_acceleration if grounded else air_acceleration
		horizontal = horizontal.move_toward(wish * speed, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Starts or stops clinging. A slime sticks to any wall it is pressed against
## for as long as its stamina lasts.
func _update_cling(wanted: bool, life: LifeState) -> void:
	if not wanted or life.stamina <= 0.0 or _squeezed:
		_clinging = false
	elif not _clinging and is_on_wall():
		_clinging = true
		_wall_normal = get_wall_normal()
		velocity = Vector3.ZERO


func _climb(delta: float, input: Vector2, wants_jump: bool, life: LifeState) -> void:
	var speed := Database.tune("traversal", "cling_speed", 3.2)
	var along := _wall_normal.cross(Vector3.UP).normalized()
	if along.dot(_camera_rig.yaw_basis().x) < 0.0:
		along = -along
	velocity = Vector3.UP * (-input.y) * speed + along * input.x * speed - _wall_normal * 1.5
	var effort := 1.0 if input.length() > 0.1 else 0.35
	life.stamina = maxf(0.0, life.stamina - Database.tune("traversal", "cling_stamina_per_second", 22.0) * effort * delta)
	Game.count("seconds_clinging", delta)
	if wants_jump:
		# Kick away from the wall.
		_clinging = false
		velocity = _wall_normal * 5.0 + Vector3.UP * _jump_velocity * 0.8


## Movement below a water surface. Without Water Current Motion the slime
## sinks and bounces along the bed; with it, the slime swims freely.
## Hydraulic Propulsion turns stored water into a jet dash.
func _swim(delta: float, wish: Vector3, speed: float, wants_jump: bool, controllable: bool) -> void:
	var life := Game.life
	var depth := _water.surface_y - get_aim_origin().y
	var swims := life.has_skill("water_current_motion")
	speed *= Database.tune("traversal", "water_current_motion_factor", 1.1) if swims \
			else Database.tune("traversal", "swim_speed_factor", 0.45)
	if wish.length_squared() > 0.01:
		Game.practice("swim_seconds", delta)
	Game.count("seconds_in_water", delta)

	if _jet > 0.0:
		_jet -= delta
		velocity = _jet_velocity
		return

	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(wish * speed, 16.0 * delta)
	var vertical := velocity.y
	if swims:
		var rise := 0.0
		if controllable and Input.is_action_pressed("jump"):
			rise = 3.6
		elif controllable and Input.is_action_pressed("squeeze"):
			rise = -3.6
		vertical = move_toward(vertical, rise, 14.0 * delta)
	else:
		vertical = move_toward(vertical, -1.2, 6.0 * delta)

	if wants_jump:
		if depth < 0.6:
			vertical = _jump_velocity * 0.9
		elif is_on_floor() and not swims:
			vertical = 6.5
		elif life.item_count("water") > 0:
			var heading := wish if wish.length_squared() > 0.01 else -_camera_rig.yaw_basis().z
			heading = (heading + Vector3.UP * 0.25).normalized()
			Game.remove_item("water")
			if life.has_skill("hydraulic_propulsion"):
				_jet = Database.tune("traversal", "jet_time", 0.35)
				_jet_velocity = heading * Database.tune("traversal", "jet_speed", 16.0)
				Game.count("jets")
			else:
				# An untrained spurt: a weak shove that teaches the real skill.
				horizontal += heading * 3.0
				vertical += 1.5
				Game.practice("water_spurts", 1.0)
	velocity = Vector3(horizontal.x, vertical, horizontal.z)


## Flattens the body so it fits under a low ceiling, or stands it back up
## when there is room overhead.
func _set_squeezed(wanted: bool, force: bool = false) -> void:
	if wanted == _squeezed:
		return
	if not wanted and not force and not _has_headroom():
		return
	_squeezed = wanted
	var radius := SQUEEZED_RADIUS if _squeezed else RADIUS
	(_collision.shape as SphereShape3D).radius = radius
	_collision.position.y = radius


func _has_headroom() -> bool:
	var from := global_position + Vector3(0.0, 0.15, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3(0.0, RADIUS * 2.0, 0.0), Combat.WORLD_LAYER)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


# --- Attacks -----------------------------------------------------------------

func _read_attacks(vitals: Vitals) -> void:
	if Input.is_action_just_pressed("skill_next"):
		Game.cycle_selected_skill()
	if attacker.is_busy() or vitals.attacks_blocked():
		return
	if Input.is_action_just_pressed("attack_light"):
		var light: Variant = Database.get_race(Game.life.race_id).get("moveset", {}).get("light")
		if light is Dictionary:
			var attack: Dictionary = light.duplicate()
			var tackle_status: Variant = _passive("tackle_status")
			if tackle_status is Dictionary:
				attack["status"] = tackle_status
			attacker.begin(attack, aim_direction())
	elif Input.is_action_just_pressed("attack_skill"):
		if not use_skill(Game.life.selected_skill):
			_practise_attack()


## Uses an owned active skill, paying its cost. Returns whether it started.
func use_skill(skill_id: String) -> bool:
	var life := Game.life
	if skill_id == "" or not life.has_skill(skill_id):
		return false
	var active: Variant = Database.get_skill(skill_id).get("active")
	if not (active is Dictionary) or not _pay_and_begin(active):
		return false
	Game.count("skill_uses")
	Game.count("used_" + skill_id)
	return true


## A clumsy first attempt at a skill the body does not have yet: its
## "precursor" attack. Enough attempts and the skill itself is acquired.
func _practise_attack() -> void:
	var life := Game.life
	if life.selected_skill != "":
		return
	for skill_id: String in Database.skills:
		var rule: Variant = Database.skills[skill_id].get("practice")
		if life.has_skill(skill_id) or not (rule is Dictionary) or not (rule.get("precursor") is Dictionary):
			continue
		if _pay_and_begin(rule["precursor"]):
			Game.practice(str(rule.get("stat", "")), 1.0)
			return


func _pay_and_begin(attack: Dictionary) -> bool:
	var life := Game.life
	var cost: Dictionary = attack.get("cost", {})
	var water_cost := int(cost.get("water", 0))
	var magicule_cost := float(cost.get("magicules", 0.0))
	if not attacker.is_ready(attack) or life.item_count("water") < water_cost or life.magicules < magicule_cost:
		return false
	if not attacker.begin(attack, aim_direction()):
		return false
	if water_cost > 0:
		Game.remove_item("water", water_cost)
	life.magicules -= magicule_cost
	return true


## First value of a passive key among owned skills, or null.
func _passive(key: String) -> Variant:
	for skill_id in Game.life.skills:
		var passive: Variant = Database.get_skill(skill_id).get("passive")
		if passive is Dictionary and passive.has(key):
			return passive[key]
	return null


# --- Look --------------------------------------------------------------------

func _face(direction: Vector3, delta: float) -> void:
	if _clinging:
		direction = -_wall_normal
	if direction.length_squared() < 0.01:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw, 1.0 - exp(-turn_rate * delta))


## Squash and stretch: taller while rising, flatter while falling and on
## landing, and pressed flat while squeezing.
func _animate(delta: float) -> void:
	_landing_squash = move_toward(_landing_squash, 0.0, delta * 5.0)
	var stretch := clampf(velocity.y * 0.035, -0.2, 0.3) - _landing_squash * 0.3
	if attacker.lunge_velocity != Vector3.ZERO:
		stretch -= 0.15
	var target := Vector3(1.0 - stretch * 0.5, 1.0 + stretch, 1.0 - stretch * 0.5)
	if _squeezed:
		target = Vector3(1.3, 0.42, 1.3)
	elif _clinging:
		target = Vector3(1.1, 0.9, 0.7)
	_visual.scale = _visual.scale.lerp(target, 1.0 - exp(-20.0 * delta))
