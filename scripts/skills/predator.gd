class_name Predator
extends Node
## The slime's devouring loop, a child of the player's body. With only the
## intrinsic Absorb, the body can take in remains and plants for their
## magicules. The Unique skill Predator adds its five functions
## (design document, section 9.1):
##
##   Predation  hold to devour; certain on the dead, the downed and the
##              inanimate, a chance on the conscious; swallows shots in flight
##   Stomach    what is swallowed is kept (LifeState.stomach)
##   Analysis   a queue that turns swallowed things into skills, recipes,
##              Mimicry forms and codex entries
##   Mimicry    analysed species become forms (see the player's form module)
##   Isolation  harmful material is broken down into magicules
##
## Knowledge of a finished analysis goes to the Soul at once, which is why a
## later life analyses the same thing almost instantly.

signal analysis_changed
signal swallowed(target_name: String)

## What the devour button would act on right now, or null.
var candidate: Node3D
## What is being drawn in, and how far along it is.
var target: Node3D
var progress := 0.0
var needed := 1.0
## Tests set this to a number from 0 to 1 to replace the random roll.
var forced_roll := -1.0

var _player: Player
var _lockout := 0.0
var _isolation_timer := 0.0


func _ready() -> void:
	_player = get_parent() as Player


func has_predator() -> bool:
	return Game.life != null and Game.life.has_skill("predator")


func can_devour() -> bool:
	return Game.life != null and (has_predator() or Game.life.has_skill("absorb"))


func is_devouring() -> bool:
	return target != null


## Chance of swallowing a conscious creature whole (0 to 1). It scales with
## the player's EP against the prey's, and rises sharply while it is staggered.
func living_chance(creature: Creature) -> float:
	var ratio := float(Game.life.ep) / maxf(1.0, float(creature.get_ep()))
	var chance := Database.tune("predator", "living_base_chance", 0.25) * ratio
	if creature.is_staggered():
		chance += Database.tune("predator", "living_staggered_bonus", 0.5)
	return clampf(chance, 0.0, Database.tune("predator", "living_max_chance", 0.95))


## Number of subjects analysed at once.
func analysis_slots() -> int:
	var slots := int(Database.tune("predator", "analysis_slots", 1.0))
	if Game.life.has_skill("great_sage"):
		slots += int(Database.tune("predator", "parallel_processing_slots", 2.0))
	return slots


## Seconds a queued subject still needs at the current analysis speed.
func time_left(entry: Dictionary) -> float:
	return maxf(0.0, _required(entry) - float(entry["progress"])) / _analysis_rate()


## Queues a swallowed subject for analysis unless it is already known in
## this life or already waiting. `kind` is "species" or "item".
func enqueue_analysis(kind: String, id: String) -> void:
	var key := "%s:%s" % [kind, id]
	if Game.life.analysed.has(key):
		return
	for entry in Game.life.analysis_queue:
		if entry["key"] == key:
			return
	var time := 0.0
	if kind == "species":
		time = float(Database.get_creature(id).get("devour", {}).get("analysis_time", 60.0))
	else:
		time = float(Database.get_item(id).get("analysis_time", 0.0))
	if time <= 0.0:
		return
	Game.life.analysis_queue.append({"key": key, "kind": kind, "id": id, "time": time, "progress": 0.0})
	analysis_changed.emit()


func _physics_process(delta: float) -> void:
	if not Game.is_alive():
		_stop()
		candidate = null
		return
	_tick_analysis(delta)
	_tick_isolation(delta)
	_lockout = maxf(0.0, _lockout - delta)

	candidate = _find_target() if can_devour() and _lockout <= 0.0 else null
	var open := Game.can_control() and Input.is_action_pressed("devour")
	if open and has_predator():
		_swallow_projectiles()
	if candidate == null or not open:
		_stop()
		return
	if target != candidate:
		_stop()
		target = candidate
		needed = _time_for(candidate)
	progress += delta
	if target is Harvestable:
		target.set_devour_progress(progress / needed)
	if progress >= needed:
		_finish()


# --- Predation ---------------------------------------------------------------

func _find_target() -> Node3D:
	var reach := Database.tune("predator", "devour_range", 2.8)
	var origin := _player.get_aim_origin()
	var best: Node3D = null
	var best_distance := INF
	var tree := get_tree()
	for node in tree.get_nodes_in_group(Creature.CORPSE_GROUP) + tree.get_nodes_in_group(Harvestable.GROUP):
		var thing := node as Node3D
		if thing == null or (thing is Harvestable and not thing.is_available()):
			continue
		var distance := _distance_to(thing, origin)
		if distance <= reach and distance < best_distance:
			best = thing
			best_distance = distance
	if best != null or not has_predator():
		return best
	# Submerged with room in the Stomach: the water itself can be drunk.
	var pool := _player.water()
	if pool != null and Game.life.item_count("water") < int(Database.tune("traversal", "water_capacity", 40.0)):
		return pool
	# Nothing inert in reach: a living creature can be attempted with Predator.
	for node in tree.get_nodes_in_group(Combat.GROUP):
		var creature := node as Creature
		if creature == null or not creature.get_vitals().alive:
			continue
		var distance := _distance_to(creature, origin)
		if distance > reach:
			continue
		if creature.is_staggered():
			distance -= 100.0
		if distance < best_distance:
			best = creature
			best_distance = distance
	return best


func _distance_to(thing: Node3D, origin: Vector3) -> float:
	var radius := 0.0
	if thing is Creature:
		radius = thing.get_body_radius()
		return maxf(0.0, origin.distance_to(thing.get_aim_origin()) - radius)
	return origin.distance_to(thing.global_position)


func _time_for(thing: Node3D) -> float:
	var time := Database.tune("predator", "devour_time_item", 0.45)
	if thing is Creature:
		time = Database.tune("predator", "devour_time_body", 1.1) if thing.is_corpse() \
				else Database.tune("predator", "devour_time_living", 1.6)
	if not has_predator():
		time *= Database.tune("predator", "absorb_time_factor", 2.0)
	return time


func _finish() -> void:
	var thing := target
	_stop()
	if thing is Harvestable:
		_swallow_item(thing)
	elif thing is WaterVolume:
		var room := int(Database.tune("traversal", "water_capacity", 40.0)) - Game.life.item_count("water")
		Game.add_item("water", mini(room, int(Database.tune("traversal", "water_per_gulp", 5.0))))
		Game.count("water_drunk")
	elif thing is Creature:
		if thing.is_corpse():
			_swallow_creature(thing, false)
		else:
			var roll := forced_roll if forced_roll >= 0.0 else randf()
			if roll < living_chance(thing):
				_swallow_creature(thing, true)
			else:
				_lockout = Database.tune("predator", "failed_devour_recover", 0.8)
				Game.count("devours_failed")
				Voice.say("devour_failed", {"target": thing.display_name()})


func _swallow_item(node: Harvestable) -> void:
	var item := Database.get_item(node.item_id)
	Game.add_ep(int(item.get("ep", 0)) * node.amount, "devour")
	Game.count("devours")
	Game.count("devoured_" + node.item_id, node.amount)
	if has_predator():
		Game.add_item(node.item_id, node.amount)
		enqueue_analysis("item", node.item_id)
	swallowed.emit(node.display_name())
	node.consume()


func _swallow_creature(creature: Creature, alive: bool) -> void:
	var devour: Dictionary = creature.data.get("devour", {})
	Game.count("devours")
	Game.count("devoured_alive" if alive else "devoured_remains")
	Voice.say("devoured_alive" if alive else "devoured", {"target": creature.display_name()})
	Game.add_ep(int(float(creature.get_ep()) * float(devour.get("ep_share", 0.2))), "devour")
	if has_predator():
		enqueue_analysis("species", creature.creature_id)
	swallowed.emit(creature.display_name())
	if alive:
		creature.remove_from_group(Combat.GROUP)
		Game.creature_died.emit(creature)
	creature.queue_free()


## While the body is open, hostile shots in reach are swallowed instead of
## landing. What they carried goes to the Stomach for Isolation.
func _swallow_projectiles() -> void:
	var reach := Database.tune("predator", "devour_range", 2.8)
	var origin := _player.get_aim_origin()
	for node in get_tree().get_nodes_in_group(Projectile.GROUP):
		var shot := node as Projectile
		if shot == null or shot.is_queued_for_deletion() or shot.get_faction() == _player.get_faction():
			continue
		if origin.distance_to(shot.global_position) > reach:
			continue
		var item_id := shot.swallowed_item()
		if item_id != "":
			Game.add_item(item_id)
		Game.count("projectiles_swallowed")
		shot.queue_free()


func _stop() -> void:
	if target is Harvestable and is_instance_valid(target):
		target.set_devour_progress(0.0)
	target = null
	progress = 0.0


# --- Analysis ----------------------------------------------------------------

func _analysis_rate() -> float:
	if Game.life.analysis_linked:
		return 1.0 / Database.tune("predator", "analysis_link_factor", 0.02)
	return 1.0


## Work a subject needs: its full time, or almost none if the soul knows it.
func _required(entry: Dictionary) -> float:
	if Soul.knows(str(entry["kind"]), str(entry["id"])):
		return Database.tune("predator", "analysis_known_time", 0.5) * _analysis_rate()
	return float(entry["time"])


func _tick_analysis(delta: float) -> void:
	var queue := Game.life.analysis_queue
	if queue.is_empty() or not has_predator():
		return
	var finished: Array[Dictionary] = []
	for i in mini(analysis_slots(), queue.size()):
		var entry := queue[i]
		entry["progress"] = float(entry["progress"]) + delta * _analysis_rate()
		if float(entry["progress"]) >= _required(entry):
			finished.append(entry)
	for entry in finished:
		queue.erase(entry)
		_complete(entry)
	if not finished.is_empty():
		analysis_changed.emit()


func _complete(entry: Dictionary) -> void:
	var life := Game.life
	var kind := str(entry["kind"])
	var id := str(entry["id"])
	var remembered := Soul.knows(kind, id)
	life.analysed[str(entry["key"])] = true
	Soul.record_analysis(kind, id, life.life_number)
	Game.count("analyses")
	Voice.say("analysis_remembered" if remembered else "analysis_complete", {"subject": Database.subject_name(kind, id)})

	if kind == "species":
		for gain: Dictionary in Database.get_creature(id).get("devour", {}).get("skills", []):
			Game.grant_skill(str(gain.get("skill", "")))
		if not life.forms.has(id):
			life.forms.append(id)
			Voice.say("form_recorded", {"form": Database.subject_name(kind, id)})
	for recipe_id: String in Database.recipes:
		var recipe := Database.get_recipe(recipe_id)
		if str(recipe.get("learned_from", "")) == str(entry["key"]) and not life.recipes.has(recipe_id):
			life.recipes.append(recipe_id)
			Soul.record_recipe(recipe_id, life.life_number)
			Voice.say("recipe_learned", {"recipe": str(recipe.get("name", recipe_id))})


# --- Isolation ---------------------------------------------------------------

func _tick_isolation(delta: float) -> void:
	if not has_predator():
		return
	var life := Game.life
	var harmful := ""
	for item_id: String in life.stomach:
		if str(Database.get_item(item_id).get("kind", "")) == "harmful":
			harmful = item_id
			break
	if harmful == "":
		_isolation_timer = 0.0
		return
	_isolation_timer += delta
	if _isolation_timer < Database.tune("predator", "isolation_seconds_per_item", 1.0):
		return
	_isolation_timer = 0.0
	Game.remove_item(harmful)
	life.magicules = minf(life.max_magicules,
			life.magicules + float(Database.get_item(harmful).get("isolation_magicules", 0.0)))
	Game.count("isolated")
