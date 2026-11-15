extends Node
## The run loop (autoload "Game"): birth, life, death, rebirth.
##
## Owns the current LifeState. Everything here is discarded on death; whatever
## must survive is handed to the Soul autoload at the moment of death.

signal life_began(new_life: LifeState)
signal life_ended(ended_life: LifeState, damage_type_id: String)
signal ep_changed(ep: int, delta: int)
signal rank_changed(old_rank: Dictionary, new_rank: Dictionary)
signal skills_changed
signal stomach_changed
## A hit landed somewhere in the world (for damage numbers).
signal hit_landed(world_position: Vector3, amount: float, damage_type_id: String, on_player: bool)
signal creature_died(creature: Creature)

## Seconds between death and the next birth when no death sequence is shown.
const REBIRTH_DELAY := 4.0

var life: LifeState = null
## Number of open screens that take over input (dialogue, status sheet...).
var ui_locks := 0
## When true, death waits for the death sequence screen to call begin_life().
var death_sequence_enabled := false

var _lifesteal := 0.0
var _regenerates := false


func _enter_tree() -> void:
	InputBindings.install()


func is_alive() -> bool:
	return life != null and life.alive


## True while the player may steer the body.
func can_control() -> bool:
	return is_alive() and ui_locks == 0 and not Voice.is_confirm_open()


## Damage multiplier of the player's body: EP is quantity, so it scales with
## the square root and leaves room for skill and technique to matter.
func get_power() -> float:
	if life == null:
		return 1.0
	return sqrt(maxf(1.0, float(life.ep)) / Database.tune("combat", "power_reference_ep", 100.0))


func get_lifesteal() -> float:
	return _lifesteal


## Adds to a tally that shapes the last-thought cards.
func count(stat: String, amount: float = 1.0) -> void:
	if life != null:
		life.stats[stat] = float(life.stats.get(stat, 0.0)) + amount


func _process(delta: float) -> void:
	if not is_alive():
		return
	var vitals := life.vitals
	if _regenerates and vitals.hp < vitals.max_hp:
		vitals.heal(vitals.max_hp * Database.tune("vitals", "self_regeneration_fraction_per_second", 0.01) * delta)
	var density := int(Database.get_region(life.region_id).get("magicule_density", 0))
	var regen := life.max_magicules * Database.tune("vitals", "magicule_regen_fraction_per_density", 0.004) * density
	life.magicules = minf(life.max_magicules, life.magicules + regen * delta)
	if vitals.fraction() < Database.tune("death", "low_health_fraction", 0.3):
		count("seconds_at_low_health", delta)


## Starts a new life. Until the reincarnation spin exists, every life is the
## first-life roll from data/spin.json: a slime in the Sealed Cave.
func begin_life() -> void:
	var first: Dictionary = Database.spin.get("first_life", {})
	var race_id := str(first.get("race", "slime"))
	var race := Database.get_race(race_id)

	life = LifeState.new()
	life.life_number = Soul.lives_lived + 1
	life.world_seed = randi()
	life.race_id = race_id
	life.origin_id = str(first.get("origin", ""))
	life.region_id = str(first.get("region", ""))
	life.ep = int(race.get("base_ep", 0))
	life.vitals.setup(_max_hp(), life.resistances)
	life.vitals.died.connect(die)
	life.vitals.resistance_gained.connect(_on_resistance_gained)

	Voice.say("life_begin", {
		"race": Database.stage_name(race_id, 0),
		"region": Database.region_name(life.region_id),
	})
	for skill_id: String in race.get("intrinsic_skills", []):
		grant_skill(skill_id, true)
	for skill_id: String in Soul.birth_grants.get("skills", []):
		grant_skill(skill_id, true)
	for resistance_id: String in Soul.birth_grants.get("resistances", []):
		grant_resistance(resistance_id, true)

	_refresh_vitals()
	life.vitals.hp = life.vitals.max_hp
	life.magicules = life.max_magicules
	life.stamina = Database.tune("vitals", "stamina_max", 100.0)
	life_began.emit(life)


## Adds (or removes) existence points and announces any change of rank.
func add_ep(amount: int, _source: String = "") -> void:
	if not is_alive() or amount == 0:
		return
	var old_rank := Database.rank_for_ep(life.ep)
	life.ep = maxi(0, life.ep + amount)
	_refresh_vitals()
	ep_changed.emit(life.ep, amount)

	var new_rank := Database.rank_for_ep(life.ep)
	if str(new_rank.get("id", "")) == str(old_rank.get("id", "")):
		return
	rank_changed.emit(old_rank, new_rank)
	Voice.say("rank_changed", {
		"old": Database.rank_name(old_rank),
		"new": Database.rank_name(new_rank),
	})
	var danger := str(new_rank.get("danger_class", ""))
	if danger != "" and danger != str(old_rank.get("danger_class", "")):
		Voice.say("danger_class_assigned", {"danger": Database.danger_class_name(danger)})


## Spends magicules if the body holds enough. Returns whether it did.
func spend_magicules(amount: float) -> bool:
	if life == null or life.magicules < amount:
		return false
	life.magicules -= amount
	return true


# --- Stomach -----------------------------------------------------------------

func add_item(item_id: String, amount: int = 1) -> void:
	if life == null or amount <= 0:
		return
	life.stomach[item_id] = life.item_count(item_id) + amount
	stomach_changed.emit()


## Removes items if the Stomach holds that many. Returns whether it did.
func remove_item(item_id: String, amount: int = 1) -> bool:
	if life == null or life.item_count(item_id) < amount:
		return false
	life.stomach[item_id] = life.item_count(item_id) - amount
	if life.item_count(item_id) <= 0:
		life.stomach.erase(item_id)
	stomach_changed.emit()
	return true


func can_craft(recipe_id: String) -> bool:
	if life == null or not life.recipes.has(recipe_id):
		return false
	var inputs: Dictionary = Database.get_recipe(recipe_id).get("inputs", {})
	for item_id: String in inputs:
		if life.item_count(item_id) < int(inputs[item_id]):
			return false
	return true


## Synthesises a known recipe inside the Stomach. Returns whether it did.
func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		return false
	var recipe := Database.get_recipe(recipe_id)
	var inputs: Dictionary = recipe.get("inputs", {})
	for item_id: String in inputs:
		remove_item(item_id, int(inputs[item_id]))
	var output: Dictionary = recipe.get("output", {})
	for item_id: String in output:
		add_item(item_id, int(output[item_id]))
	count("crafted")
	return true


## Potions ready to drink, counting those the Stomach could synthesise now.
func potions_available() -> int:
	if life == null:
		return 0
	var ready := life.item_count("healing_potion")
	if life.recipes.has("healing_potion"):
		ready += life.item_count("hipokute_herb")
	return ready


## Drinks a healing potion, synthesising one first if needed.
func use_potion() -> bool:
	if not is_alive() or life.vitals.hp >= life.vitals.max_hp:
		return false
	if life.item_count("healing_potion") <= 0 and not craft("healing_potion"):
		return false
	remove_item("healing_potion")
	life.vitals.heal(life.vitals.max_hp * float(Database.get_item("healing_potion").get("heal_fraction", 0.5)))
	count("potions_used")
	return true


## `at_birth` marks skills built into the body, which reserve no capacity.
func grant_skill(skill_id: String, at_birth: bool = false) -> bool:
	if life == null or life.skills.has(skill_id):
		return false
	if not Database.skills.has(skill_id):
		push_warning("[Game] unknown skill '%s'" % skill_id)
		return false
	life.skills.append(skill_id)
	if at_birth:
		life.birth_skills.append(skill_id)
	if life.selected_skill == "" and _is_selectable(skill_id):
		life.selected_skill = skill_id
	_refresh_vitals()
	skills_changed.emit()
	Voice.say("skill_acquired", {
		"category": Database.skill_category_name(skill_id),
		"skill": Database.skill_name(skill_id),
	})
	return true


## Discards a redundant skill, freeing the capacity it reserved.
func discard_skill(skill_id: String) -> bool:
	if life == null or not life.skills.has(skill_id):
		return false
	if str(Database.get_skill(skill_id).get("category", "")) == "intrinsic":
		return false
	life.skills.erase(skill_id)
	life.birth_skills.erase(skill_id)
	if life.selected_skill == skill_id:
		life.selected_skill = ""
		cycle_selected_skill()
	_refresh_vitals()
	skills_changed.emit()
	Voice.say("skill_discarded", {"skill": Database.skill_name(skill_id)})
	return true


## Owned skills that can be bound to the skill button.
func selectable_skills() -> Array[String]:
	var found: Array[String] = []
	if life != null:
		for skill_id in life.skills:
			if _is_selectable(skill_id):
				found.append(skill_id)
	return found


func cycle_selected_skill() -> void:
	var options := selectable_skills()
	if options.is_empty():
		life.selected_skill = ""
		return
	var index := options.find(life.selected_skill)
	life.selected_skill = options[(index + 1) % options.size()]
	skills_changed.emit()


## `from_imprint` marks a Resistance granted at birth by the previous death.
func grant_resistance(resistance_id: String, from_imprint: bool = false) -> bool:
	if life == null:
		return false
	if not Database.resistances.has(resistance_id):
		push_warning("[Game] unknown resistance '%s'" % resistance_id)
		return false
	_announce_next_resistance = "imprint" if from_imprint else "plain"
	var granted := life.vitals.grant_resistance(resistance_id)
	_announce_next_resistance = ""
	return granted


## Ends the current life. The damage type that dealt the killing blow leaves
## its Resistance on the soul for the next birth (design document, section 5).
func die(damage_type_id: String) -> void:
	if not is_alive():
		return
	life.alive = false
	life.vitals.alive = false

	var damage := Database.get_damage_type(damage_type_id)
	var imprint := str(damage.get("imprint_resistance", ""))
	Voice.say("death", {"cause": str(damage.get("name", damage_type_id))})
	if imprint != "":
		Voice.say("death_imprint", {"resistance": Database.resistance_name(imprint)})

	Soul.record_death(life, damage_type_id, imprint)
	life_ended.emit(life, damage_type_id)
	if death_sequence_enabled:
		return

	await get_tree().create_timer(REBIRTH_DELAY).timeout
	Voice.say("rebirth")
	begin_life()


var _announce_next_resistance := ""


func _on_resistance_gained(resistance_id: String, cause: String) -> void:
	skills_changed.emit()
	var params := {"resistance": Database.resistance_name(resistance_id)}
	if cause == "merge" or cause == "upgrade":
		Voice.say("resistance_merged", params)
	elif _announce_next_resistance == "imprint":
		Voice.say("imprint_granted", params)
	else:
		Voice.say("resistance_acquired", params)


func _is_selectable(skill_id: String) -> bool:
	var active: Variant = Database.get_skill(skill_id).get("active")
	return active is Dictionary and str(active.get("kind", "")) != "jet"


func _max_hp() -> float:
	var vitals := Database.race_vitals(life.race_id)
	return float(vitals.get("hp_base", 40.0)) + float(vitals.get("hp_scale", 2.0)) * sqrt(maxf(0.0, float(life.ep)))


## Recomputes everything derived from EP and skills: maximum health, magicule
## capacity (what skills acquired in life reserve is taken off) and passives.
func _refresh_vitals() -> void:
	life.vitals.set_max_hp(_max_hp())

	var reserved := 0
	_lifesteal = 0.0
	_regenerates = false
	var factors: Dictionary = {}
	for skill_id in life.skills:
		if not life.birth_skills.has(skill_id):
			reserved += Database.capacity_cost(skill_id)
		var passive: Variant = Database.get_skill(skill_id).get("passive")
		if not (passive is Dictionary):
			continue
		_lifesteal += float(passive.get("lifesteal", 0.0))
		if passive.get("hp_regen", false):
			_regenerates = true
		var taken: Variant = passive.get("damage_taken_factor")
		if taken is Dictionary:
			for damage_type_id: String in taken:
				factors[damage_type_id] = float(factors.get(damage_type_id, 1.0)) * float(taken[damage_type_id])
	life.vitals.damage_factors = factors

	var capacity := float(life.ep) * float(Database.race_vitals(life.race_id).get("capacity_factor", 1.0))
	var floor_value := capacity * Database.tune("vitals", "minimum_capacity_fraction", 0.1)
	life.max_magicules = maxf(floor_value, capacity - reserved)
	life.magicules = minf(life.magicules, life.max_magicules)
