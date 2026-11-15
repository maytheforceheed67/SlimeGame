class_name Player
extends CharacterBody3D
## The player's body. Milestone 0 has one body, the slime: it slides, hops and
## squashes. It fights through the same Attacker and Vitals as every creature.

## The body dropped below `fall_limit`; the level decides where to put it back.
signal fell_out_of_world

@export var ground_acceleration := 40.0
@export var air_acceleration := 12.0
@export var turn_rate := 12.0
@export var fall_limit := -40.0

var attacker: Attacker

var _move_speed := 5.5
var _jump_velocity := 7.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _was_on_floor := true
var _landing_squash := 0.0
var _impulse := Vector3.ZERO
var _flinch := 0.0
var _invulnerable := 0.0

@onready var _visual: Node3D = $Visual
@onready var _camera_rig: CameraRig = $CameraRig


func _ready() -> void:
	attacker = Attacker.new()
	add_child(attacker)
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
	return global_position + Vector3(0.0, 0.4, 0.0)


func get_body_radius() -> float:
	return 0.4


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
	var controllable := Game.can_control()
	var vitals: Vitals = Game.life.vitals if Game.life != null else null
	if vitals != null and Game.is_alive():
		vitals.tick(delta)

	var wish := Vector3.ZERO
	var wants_jump := false
	if controllable and _flinch <= 0.0:
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		wish = _camera_rig.yaw_basis() * Vector3(input.x, 0.0, input.y)
		wants_jump = Input.is_action_just_pressed("jump")
		_read_attacks(vitals)

	var grounded := is_on_floor()
	if not grounded:
		velocity.y -= _gravity * delta
	elif wants_jump and not attacker.is_busy():
		velocity.y = _jump_velocity

	var speed := _move_speed * (vitals.speed_factor() if vitals != null else 1.0)
	var horizontal := Vector3(velocity.x, 0.0, velocity.z) - _impulse
	if attacker.lunge_velocity != Vector3.ZERO:
		horizontal = attacker.lunge_velocity
	else:
		var rate := ground_acceleration if grounded else air_acceleration
		horizontal = horizontal.move_toward(wish * speed, rate * delta)
	_impulse = _impulse.move_toward(Vector3.ZERO, 30.0 * delta)
	velocity.x = horizontal.x + _impulse.x
	velocity.z = horizontal.z + _impulse.z
	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		_landing_squash = 1.0
	_was_on_floor = is_on_floor()

	_face(attacker.direction if attacker.is_busy() else wish, delta)
	_animate(delta)

	if global_position.y < fall_limit:
		fell_out_of_world.emit()


## Puts the body at `at`, standing still.
func respawn(at: Vector3) -> void:
	global_position = at
	velocity = Vector3.ZERO
	_impulse = Vector3.ZERO
	_landing_squash = 0.0
	attacker.cancel()


func _on_life_began(new_life: LifeState) -> void:
	var vitals := Database.race_vitals(new_life.race_id)
	_move_speed = float(vitals.get("move_speed", 5.5))
	_jump_velocity = float(vitals.get("jump_velocity", 7.0))
	_flinch = 0.0
	_invulnerable = 0.0


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
		use_skill(Game.life.selected_skill)


## Uses an owned active skill, paying its cost. Returns whether it started.
func use_skill(skill_id: String) -> bool:
	var life := Game.life
	if skill_id == "" or not life.has_skill(skill_id):
		return false
	var active: Variant = Database.get_skill(skill_id).get("active")
	if not (active is Dictionary) or not attacker.is_ready(active):
		return false
	var cost: Dictionary = active.get("cost", {})
	var water := int(cost.get("water", 0))
	var magicules := float(cost.get("magicules", 0.0))
	if life.item_count("water") < water or life.magicules < magicules:
		return false
	if not attacker.begin(active, aim_direction()):
		return false
	if water > 0:
		life.stomach["water"] = life.item_count("water") - water
	life.magicules -= magicules
	Game.count("skill_uses")
	Game.count("used_" + skill_id)
	return true


## First value of a passive key among owned skills, or null.
func _passive(key: String) -> Variant:
	for skill_id in Game.life.skills:
		var passive: Variant = Database.get_skill(skill_id).get("passive")
		if passive is Dictionary and passive.has(key):
			return passive[key]
	return null


func _face(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.01:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw, 1.0 - exp(-turn_rate * delta))


## Squash and stretch: taller while rising, flatter while falling and on landing.
func _animate(delta: float) -> void:
	_landing_squash = move_toward(_landing_squash, 0.0, delta * 5.0)
	var stretch := clampf(velocity.y * 0.035, -0.2, 0.3) - _landing_squash * 0.3
	if attacker.lunge_velocity != Vector3.ZERO:
		stretch -= 0.15
	var target := Vector3(1.0 - stretch * 0.5, 1.0 + stretch, 1.0 - stretch * 0.5)
	_visual.scale = _visual.scale.lerp(target, 1.0 - exp(-20.0 * delta))
