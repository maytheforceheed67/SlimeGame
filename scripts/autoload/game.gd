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

## Seconds between death and the next birth. Stands in for the full death
## sequence (last thoughts, spin), which is a later milestone.
const REBIRTH_DELAY := 4.0

var life: LifeState = null


func _enter_tree() -> void:
	InputBindings.install()


func is_alive() -> bool:
	return life != null and life.alive


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

	Voice.say("life_begin", {
		"race": Database.stage_name(race_id, 0),
		"region": Database.region_name(life.region_id),
	})
	for skill_id: String in race.get("intrinsic_skills", []):
		grant_skill(skill_id)
	for resistance_id: String in Soul.birth_grants.get("resistances", []):
		grant_resistance(resistance_id, true)

	life_began.emit(life)


## Adds (or removes) existence points and announces any change of rank.
func add_ep(amount: int, _source: String = "") -> void:
	if not is_alive() or amount == 0:
		return
	var old_rank := Database.rank_for_ep(life.ep)
	life.ep = maxi(0, life.ep + amount)
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


func grant_skill(skill_id: String) -> bool:
	if life == null or life.skills.has(skill_id):
		return false
	if not Database.skills.has(skill_id):
		push_warning("[Game] unknown skill '%s'" % skill_id)
		return false
	life.skills.append(skill_id)
	skills_changed.emit()
	Voice.say("skill_acquired", {
		"category": Database.skill_category_name(skill_id),
		"skill": Database.skill_name(skill_id),
	})
	return true


## `from_imprint` marks a Resistance granted at birth by the previous death.
func grant_resistance(resistance_id: String, from_imprint: bool = false) -> bool:
	if life == null or life.resistances.has(resistance_id):
		return false
	if not Database.resistances.has(resistance_id):
		push_warning("[Game] unknown resistance '%s'" % resistance_id)
		return false
	life.resistances.append(resistance_id)
	skills_changed.emit()
	var params := {"resistance": Database.resistance_name(resistance_id)}
	if from_imprint:
		Voice.say("imprint_granted", params)
	else:
		Voice.say("resistance_acquired", params)
	return true


## Ends the current life. The damage type that dealt the killing blow leaves
## its Resistance on the soul for the next birth (design document, section 5).
func die(damage_type_id: String) -> void:
	if not is_alive():
		return
	life.alive = false

	var damage := Database.get_damage_type(damage_type_id)
	var imprint := str(damage.get("imprint_resistance", ""))
	Voice.say("death", {"cause": str(damage.get("name", damage_type_id))})
	if imprint != "":
		Voice.say("death_imprint", {"resistance": Database.resistance_name(imprint)})

	Soul.record_death(life, damage_type_id, imprint)
	life_ended.emit(life, damage_type_id)

	await get_tree().create_timer(REBIRTH_DELAY).timeout
	Voice.say("rebirth")
	begin_life()
