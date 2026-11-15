class_name Advisor
extends Node
## The advisor skill (Sage, then Great Sage), a child of the player's body.
## It is a second voice, distinct from the Voice of the World: it appraises
## targets, offers the analysis link, and gives short tactical hints
## (design document, sections 6 and 9.2).
##
##   level 0  no advisor skill: this module stays silent
##   level 1  Sage: hints and a basic appraisal (rank and weaknesses)
##   level 2  Great Sage: full appraisal (EP, resistances, devour gains),
##            parallel analysis threads, and the link upgrade

## A target was appraised. `info` has "title" and "lines" for the readout.
signal scanned(info: Dictionary)

const SCAN_RANGE := 22.0
const HINT_INTERVAL := 0.5

var _player: Player
var _hint_timer := 0.0
var _asking_link := false


func _ready() -> void:
	_player = get_parent() as Player


## 0 without an advisor skill, 1 for Sage, 2 for Great Sage.
func level() -> int:
	var best := 0
	if Game.life == null:
		return best
	for skill_id in Game.life.skills:
		var passive: Variant = Database.get_skill(skill_id).get("passive")
		if passive is Dictionary:
			best = maxi(best, int(passive.get("advisor", 0)))
	return best


func _physics_process(delta: float) -> void:
	if not Game.is_alive() or level() == 0:
		return
	if Game.can_control() and Input.is_action_just_pressed("scan") and Game.is_sighted():
		scan()
	_hint_timer -= delta
	if _hint_timer <= 0.0:
		_hint_timer = HINT_INTERVAL
		_give_hints()
		_offer_link()


## Appraises what the player is aiming at: a creature, else something
## devourable nearby. Returns the readout, or {} when nothing is in range.
func scan() -> Dictionary:
	var info: Dictionary = {}
	var target := _scan_target()
	if target is Creature:
		info = _appraise_creature(target)
	elif target is Harvestable:
		var item := Database.get_item(target.item_id)
		info = {"title": target.display_name(), "lines": PackedStringArray([str(item.get("description", ""))])}
		Voice.advise("advisor_scan_item", {"name": target.display_name(), "description": str(item.get("description", ""))})
	else:
		Voice.advise("advisor_scan_nothing")
		return info
	Game.count("scans")
	scanned.emit(info)
	return info


## Links Predator's Analysis to Parallel Processing (Great Sage only).
func link_analysis() -> bool:
	if level() < 2 or Game.life.analysis_linked:
		return false
	Game.life.analysis_linked = true
	Soul.remember("analysis_link", Game.life.life_number)
	Voice.advise("advisor_link_done")
	return true


func _scan_target() -> Node3D:
	var target := _player.soft_target()
	if target != null:
		return target
	var origin := _player.get_aim_origin()
	var best: Node3D = null
	var best_distance := SCAN_RANGE
	for group: String in [Combat.GROUP, Creature.CORPSE_GROUP, Harvestable.GROUP]:
		for node in get_tree().get_nodes_in_group(group):
			var thing := node as Node3D
			if thing == null or thing == _player:
				continue
			var distance := origin.distance_to(thing.global_position)
			if distance < best_distance:
				best = thing
				best_distance = distance
	return best


func _appraise_creature(creature: Creature) -> Dictionary:
	var data := creature.data
	var rank := Database.rank_name(creature.get_rank())
	var weak_names := _names(data.get("weak_to", []), Database.damage_types)
	var weakness := "No known weakness." if weak_names.is_empty() else "Weak to %s." % ", ".join(weak_names)
	var lines := PackedStringArray()
	var danger := Database.danger_class_name(str(creature.get_rank().get("danger_class", "")))
	lines.append("Rank %s%s" % [rank, "" if danger == "" else "  ·  " + danger])

	if level() < 2:
		lines.append(weakness)
		Voice.advise("advisor_scan_creature_basic", {"name": creature.display_name(), "rank": rank, "weakness": weakness})
		return {"title": creature.display_name(), "lines": lines}

	Game.life.appraised[creature.creature_id] = true
	var vitals := creature.get_vitals()
	lines.append("%s EP" % UiStyle.format_int(creature.get_ep()))
	lines.append("Health %d / %d" % [ceili(vitals.hp), ceili(vitals.max_hp)])
	lines.append(weakness)
	var resists := _names(vitals.resistances, Database.resistances)
	if not resists.is_empty():
		lines.append("Has %s." % ", ".join(resists))
	var gains := PackedStringArray()
	for gain: Dictionary in data.get("devour", {}).get("skills", []):
		gains.append(Database.skill_name(str(gain.get("skill", ""))))
	var yields := "Yields nothing when devoured." if gains.is_empty() else "Devouring yields %s." % ", ".join(gains)
	lines.append(yields)
	for trait_text: String in data.get("traits", []):
		lines.append(trait_text)
	Voice.advise("advisor_scan_creature", {
		"name": creature.display_name(), "rank": rank, "ep": UiStyle.format_int(creature.get_ep()),
		"weakness": weakness, "yields": yields,
	})
	return {"title": creature.display_name(), "lines": lines}


func _names(ids: Array, table: Dictionary) -> PackedStringArray:
	var names := PackedStringArray()
	for id: Variant in ids:
		names.append(str(table.get(str(id), {}).get("name", id)))
	return names


# --- Hints -------------------------------------------------------------------

## Says a hint once per life.
func _hint_once(flag: String, key: String, params: Dictionary = {}) -> void:
	var life := Game.life
	if life.flags.has(flag):
		return
	life.flags[flag] = true
	Voice.advise(key, params)


func _give_hints() -> void:
	var life := Game.life
	var origin := _player.get_aim_origin()
	if not Game.is_sighted():
		_hint_once("hint_blind", "advisor_blind")
		return

	_hint_once("hint_goal", "advisor_goal")
	if life.flags.has("veldora_swallowed") and life.analysed.has("species:tempest_serpent"):
		_hint_once("hint_slice_done", "advisor_slice_done")

	if life.vitals.fraction() < Database.tune("death", "low_health_fraction", 0.3):
		if not life.flags.get("hint_low_health_active", false):
			life.flags["hint_low_health_active"] = true
			Voice.advise("advisor_low_health_potion" if Game.potions_available() > 0 else "advisor_low_health")
	elif life.vitals.fraction() > 0.6:
		life.flags["hint_low_health_active"] = false

	for node in get_tree().get_nodes_in_group(Combat.GROUP):
		var creature := node as Creature
		if creature == null or origin.distance_to(creature.global_position) > SCAN_RANGE:
			continue
		if not Combat.has_line_of_sight(_player, origin, creature.get_aim_origin()):
			continue
		var params := {"name": creature.display_name(), "rank": Database.rank_name(creature.get_rank())}
		var key := "advisor_threat_high" if creature.get_ep() > life.ep * 3 else "advisor_threat_even"
		_hint_once("hint_seen_" + creature.creature_id, key, params)
		if creature.is_staggered() and life.has_skill("predator"):
			_hint_once("hint_staggered", "advisor_staggered")

	if _player.in_water() and life.has_skill("predator"):
		_hint_once("hint_water", "advisor_water")
	for stat: String in ["water_spits", "water_spurts", "swim_seconds"]:
		if float(life.practice.get(stat, 0.0)) > 0.0:
			_hint_once("hint_practice", "advisor_practice")

	if life.has_skill("predator") and not life.analysed.has("item:hipokute_herb"):
		for node in get_tree().get_nodes_in_group(Harvestable.GROUP):
			var herb := node as Harvestable
			if herb != null and herb.item_id == "hipokute_herb" and origin.distance_to(herb.global_position) < 8.0:
				_hint_once("hint_herb", "advisor_herb")
				break


## The first upgrade the tutorial teaches: once an analysis is running,
## Great Sage offers to link it to Parallel Processing.
func _offer_link() -> void:
	var life := Game.life
	if level() < 2 or life.analysis_linked or _asking_link or life.flags.has("link_offered"):
		return
	if Soul.remembers_from_before("analysis_link", life.life_number):
		# A soul that made the link in an earlier life makes it again at once.
		life.flags["link_offered"] = true
		life.analysis_linked = true
		Voice.advise("advisor_link_remembered")
		return
	if (life.analysis_queue.is_empty() and life.analysed.is_empty()) or not Game.can_control():
		return
	life.flags["link_offered"] = true
	_asking_link = true
	Voice.advise("advisor_link_offer")
	var accepted: bool = await Voice.confirm("advisor_link_confirm")
	_asking_link = false
	if Game.life != life:
		return
	if accepted:
		link_analysis()
	else:
		Voice.advise("advisor_link_declined")
