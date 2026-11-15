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
## Record of the species being mimicked ({} in the body's own shape).
var _form: Dictionary = {}
var _form_visual: Node3D
## The body's own shape, from the asset manifest.
var _own_model: Node3D

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
	_own_model = Assets.instantiate("slime")
	_visual.add_child(_own_model)
	add_to_group(GROUP)
	add_to_group(Combat.GROUP)
	Game.life_began.connect(_on_life_began)


# --- Combatant contract ------------------------------------------------------

func get_faction() -> String:
	return "player"


func get_vitals() -> Vitals:
	return Game.life.vitals


## In a Mimicry form the copy is only as strong as the body behind it:
## power is the square root of the player's EP over the species' EP.
func get_power() -> float:
	if not _form.is_empty():
		return sqrt(maxf(1.0, float(Game.life.ep)) / maxf(1.0, float(_form.get("ep", 1))))
	return Game.get_power()


func get_lifesteal() -> float:
	return Game.get_lifesteal()


func get_aim_origin() -> Vector3:
	return global_position + Vector3(0.0, _own_radius(), 0.0)


func get_body_radius() -> float:
	return _own_radius()


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


func in_form() -> bool:
	return not _form.is_empty()


## Takes the shape of an analysed species, or returns to the body's own
## shape with "". Mimicry is a function of Predator.
func set_form(creature_id: String) -> bool:
	var life := Game.life
	if creature_id != "" and (not life.has_skill("predator") or not life.forms.has(creature_id)):
		return false
	if creature_id == life.form_id:
		return true
	if is_instance_valid(_form_visual):
		_form_visual.queue_free()
	_form_visual = null
	attacker.cancel()
	_clinging = false
	_set_squeezed(false, true)
	life.form_id = creature_id
	_form = Database.get_creature(creature_id) if creature_id != "" else {}
	_own_model.visible = _form.is_empty()
	if not _form.is_empty():
		_form_visual = Assets.instantiate(creature_id, {"mimic": true})
		_visual.add_child(_form_visual)
		if float(_form.get("body", {}).get("hover_height", 0.0)) > 0.0:
			_form_visual.position.y = _own_radius()
		Voice.say("form_taken", {"form": str(_form.get("name", creature_id))})
		Game.count("forms_taken")
	_apply_radius()
	return true


## Steps through the own shape and every recorded form.
func cycle_form() -> void:
	var life := Game.life
	if not life.has_skill("predator") or life.forms.is_empty():
		return
	var next := life.forms.find(life.form_id) + 1
	if next >= life.forms.size():
		set_form("")
		Voice.say("form_released")
	else:
		set_form(life.forms[next])


## Magicules per second the current form costs to hold.
func form_upkeep() -> float:
	if _form.is_empty():
		return 0.0
	var ratio := float(_form.get("ep", 0)) / maxf(1.0, float(Game.life.ep))
	return clampf(Database.tune("predator", "form_upkeep_base", 1.5) * ratio,
			Database.tune("predator", "form_upkeep_min", 0.2), Database.tune("predator", "form_upkeep_max", 12.0))


## The nearest thing in reach that can be spoken to or used, or null.
func interact_target() -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("interactable"):
		var thing := node as Node3D
		if thing == null or not thing.can_interact():
			continue
		var distance := global_position.distance_to(thing.global_position)
		if distance <= float(thing.interact_range()) and distance < best_distance:
			best = thing
			best_distance = distance
	return best


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
		if Input.is_action_just_pressed("form_next"):
			cycle_form()
		if Input.is_action_just_pressed("interact"):
			var thing := interact_target()
			if thing != null:
				thing.interact(self)
		# Feeling for magicules: hold still and hold the sense button.
		if Input.is_action_pressed("scan") and not Game.is_sighted() and input.length() < 0.1:
			Game.practice("sensing_seconds", delta)
	if not _form.is_empty() and Game.is_alive():
		life.magicules -= form_upkeep() * delta
		if life.magicules <= 0.0:
			life.magicules = 0.0
			set_form("")
			Voice.say("form_starved")
	var wish := _camera_rig.yaw_basis() * Vector3(input.x, 0.0, input.y)
	var swimming := in_water()

	# Clinging and squeezing belong to the slime's own body.
	var own_shape := _form.is_empty() and not swimming
	_set_squeezed(controllable and Input.is_action_pressed("squeeze") and own_shape)
	_update_cling(controllable and Input.is_action_pressed("cling") and own_shape, life)
	if controllable and not predator.is_devouring() and not _squeezed and not _clinging:
		_read_attacks(vitals)

	var speed := _move_speed * vitals.speed_factor()
	if not _form.is_empty():
		speed = float(_form.get("stats", {}).get("speed", _move_speed)) * vitals.speed_factor()
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
	if is_instance_valid(_form_visual) and _form_visual.has_method("animate"):
		_form_visual.call("animate", delta, clampf(Vector2(velocity.x, velocity.z).length() / maxf(speed, 0.1), 0.0, 1.0))
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
	if is_instance_valid(_form_visual):
		_form_visual.queue_free()
	_form_visual = null
	_form = {}
	_own_model.visible = true
	_apply_radius()


# --- Ways of moving ----------------------------------------------------------

func _walk(delta: float, wish: Vector3, speed: float, wants_jump: bool) -> void:
	var grounded := is_on_floor()
	if _mantle > 0.0:
		_mantle -= delta
		velocity = -_wall_normal * 3.0 + Vector3.UP * 2.5
		return
	if not grounded:
		velocity.y -= _gravity * delta
		if _flies():
			_glide(wants_jump)
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


func _flies() -> bool:
	return float(_form.get("body", {}).get("hover_height", 0.0)) > 0.0


## Winged forms: holding jump in the air spreads the wings and slows the
## fall; pressing it again flaps upward for stamina.
func _glide(wants_jump: bool) -> void:
	var life := Game.life
	var flap_cost := Database.tune("predator", "flap_stamina", 15.0)
	if wants_jump and life.stamina >= flap_cost:
		life.stamina -= flap_cost
		velocity.y = Database.tune("predator", "flap_velocity", 5.5)
		Game.count("flaps")
	elif Input.is_action_pressed("jump") and Game.can_control():
		velocity.y = maxf(velocity.y, -Database.tune("predator", "glide_fall_speed", 1.0))


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
	_apply_radius()


## Radius of the body's current shape: flattened, its own, or a form's.
func _own_radius() -> float:
	if _squeezed:
		return SQUEEZED_RADIUS
	if _form.is_empty():
		return RADIUS
	return minf(float(_form.get("body", {}).get("radius", RADIUS)), Database.tune("predator", "form_max_radius", 0.8))


func _apply_radius() -> void:
	var radius := _own_radius()
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
	if not _form.is_empty():
		# A form fights with the species' own moves: first on the light
		# button, second on the skill button.
		var moves: Array = _form.get("attacks", [])
		if Input.is_action_just_pressed("attack_light") and moves.size() > 0:
			attacker.begin(moves[0], aim_direction())
		elif Input.is_action_just_pressed("attack_skill") and moves.size() > 1:
			attacker.begin(moves[1], aim_direction())
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
