extends Node
## Read-only content database (autoload "Database").
##
## Every table lives in res://data/*.json so lore can be corrected without
## touching code. Problems found while loading are collected in `problems` and
## reported once at boot, so a bad edit to a data file is visible immediately
## instead of failing somewhere in gameplay.
## tools/validate_data.py runs the same checks, and more, outside the engine.

const DATA_DIR := "res://data/"
const LABELS: Array[String] = ["CANON", "DESIGN", "UNCONFIRMED"]

## EP-banded ranks in ascending order. Rank F has no band and is not in here.
var ranks: Array[Dictionary] = []
var ranks_by_id: Dictionary = {}
var danger_classes: Dictionary = {}
var informal_labels: Array[Dictionary] = []
var thresholds: Dictionary = {}

## Global [DESIGN] numbers, by section. Read them with tune().
var tuning: Dictionary = {}

var damage_types: Dictionary = {}
var statuses: Dictionary = {}
var resistances: Dictionary = {}
var resistance_merges: Array[Dictionary] = []

var skill_categories: Dictionary = {}
var skills: Dictionary = {}
## sub-function id -> id of the skill it belongs to
var sub_functions: Dictionary = {}
var fusions: Dictionary = {}

var creatures: Dictionary = {}
var items: Dictionary = {}
var recipes: Dictionary = {}
var dialogues: Dictionary = {}

var races: Dictionary = {}
var regions: Dictionary = {}
## int density level -> record
var density_levels: Dictionary = {}
var spin: Dictionary = {}

var voice_lines: Dictionary = {}

var _race_meta: Dictionary = {}

var problems: PackedStringArray = PackedStringArray()


func _enter_tree() -> void:
	reload()


func reload() -> void:
	problems = PackedStringArray()

	var rank_file := _read("ranks.json")
	ranks_by_id = _by_id(rank_file, "ranks", "ranks.json")
	danger_classes = _by_id(rank_file, "danger_classes", "ranks.json")
	thresholds = _by_id(rank_file, "thresholds", "ranks.json")
	informal_labels = _list(rank_file, "informal_labels", "ranks.json")
	ranks = _build_rank_bands()

	tuning = _read("tuning.json")
	var damage_file := _read("damage_types.json")
	damage_types = _by_id(damage_file, "damage_types", "damage_types.json")
	statuses = _by_id(damage_file, "statuses", "damage_types.json")
	var resistance_file := _read("resistances.json")
	resistances = _by_id(resistance_file, "resistances", "resistances.json")
	resistance_merges = _list(resistance_file, "merges", "resistances.json")

	var skill_file := _read("skills.json")
	skill_categories = _by_id(skill_file, "categories", "skills.json")
	skills = _by_id(skill_file, "skills", "skills.json")
	sub_functions = {}
	for skill_id: String in skills:
		for function: Variant in skills[skill_id].get("sub_functions", []):
			if function is Dictionary:
				sub_functions[str(function.get("id", ""))] = skill_id
	fusions = _by_id(_read("fusions.json"), "fusions", "fusions.json")
	creatures = _by_id(_read("creatures.json"), "creatures", "creatures.json")
	items = _by_id(_read("items.json"), "items", "items.json")
	recipes = _by_id(_read("recipes.json"), "recipes", "recipes.json")
	dialogues = _by_id(_read("dialogues.json"), "dialogues", "dialogues.json")

	var race_file := _read("races.json")
	races = _by_id(race_file, "races", "races.json")
	var race_meta: Variant = race_file.get("_meta", {})
	_race_meta = race_meta if race_meta is Dictionary else {}
	var region_file := _read("regions.json")
	regions = _by_id(region_file, "regions", "regions.json")
	density_levels = {}
	for level in _list(region_file, "density_levels", "regions.json"):
		density_levels[int(level.get("level", -1))] = level
	spin = _read("spin.json")

	var lines: Variant = _read("voice_lines.json").get("lines", {})
	voice_lines = lines if lines is Dictionary else {}

	_cross_check()

	if problems.is_empty():
		print("[Database] ", summary())
	else:
		for message in problems:
			push_error("[Database] " + message)


func summary() -> String:
	return "%d ranks, %d races, %d skills, %d fusions, %d resistances, %d creatures, %d regions, %d voice lines" % [
		ranks_by_id.size(), races.size(), skills.size(), fusions.size(),
		resistances.size(), creatures.size(), regions.size(), voice_lines.size(),
	]


# --- Tuning ------------------------------------------------------------------

## A [DESIGN] number from data/tuning.json, for example tune("combat", "resistance_factor").
func tune(section: String, key: String, fallback: float = 0.0) -> float:
	var group: Variant = tuning.get(section, {})
	if group is Dictionary and group.has(key):
		return float(group[key])
	push_warning("[Database] missing tuning value %s.%s" % [section, key])
	return fallback


# --- Ranks and existence points -------------------------------------------

## The rank whose EP band contains `ep`. Bands are half-open: min <= EP < max.
func rank_for_ep(ep: int) -> Dictionary:
	var found: Dictionary = {}
	for band in ranks:
		if ep < int(band["ep_min"]):
			break
		found = band
	return found


func rank_name(rank: Dictionary) -> String:
	return str(rank.get("name", "?"))


## Display name of a danger class id, or "" when the rank carries none.
func danger_class_name(danger_class_id: String) -> String:
	if danger_class_id == "":
		return ""
	return str(danger_classes.get(danger_class_id, {}).get("name", danger_class_id))


## Informal label that applies at this EP (for example "Million class"), or "".
func informal_label_for_ep(ep: int) -> String:
	var found := ""
	for entry in informal_labels:
		if ep >= int(entry.get("ep_min", 0)):
			found = str(entry.get("name", ""))
	return found


# --- Lookups ---------------------------------------------------------------

func get_race(race_id: String) -> Dictionary:
	return races.get(race_id, {})


## Name of a stage in a race's evolution line, falling back to the race name.
func stage_name(race_id: String, stage_index: int) -> String:
	var race := get_race(race_id)
	var line: Variant = race.get("evolution_line", [])
	if line is Array and stage_index >= 0 and stage_index < line.size():
		return str(line[stage_index].get("name", race_id))
	return str(race.get("name", race_id))


func get_skill(skill_id: String) -> Dictionary:
	return skills.get(skill_id, {})


func skill_name(skill_id: String) -> String:
	return str(get_skill(skill_id).get("name", skill_id))


func skill_category_name(skill_id: String) -> String:
	var category_id := str(get_skill(skill_id).get("category", ""))
	return str(skill_categories.get(category_id, {}).get("name", "Skill"))


## Magicule capacity a skill reserves once acquired in life.
func capacity_cost(skill_id: String) -> int:
	var skill := get_skill(skill_id)
	if skill.has("capacity_cost"):
		return int(skill["capacity_cost"])
	return int(tune("capacity_cost", str(skill.get("category", "")), 0.0))


func get_creature(creature_id: String) -> Dictionary:
	return creatures.get(creature_id, {})


func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func item_name(item_id: String) -> String:
	return str(get_item(item_id).get("name", item_id))


func get_dialogue(dialogue_id: String) -> Dictionary:
	return dialogues.get(dialogue_id, {})


func get_recipe(recipe_id: String) -> Dictionary:
	return recipes.get(recipe_id, {})


## Display name of an analysis subject, given its kind ("species" or "item").
func subject_name(kind: String, id: String) -> String:
	if kind == "species":
		return str(get_creature(id).get("name", id))
	return item_name(id)


func get_status(status_id: String) -> Dictionary:
	return statuses.get(status_id, {})


## A race's vitals: its own values laid over the table's defaults.
func race_vitals(race_id: String) -> Dictionary:
	var merged: Dictionary = {}
	var meta: Variant = _race_meta.get("default_vitals", {})
	if meta is Dictionary:
		merged = meta.duplicate()
	var own: Variant = get_race(race_id).get("vitals", {})
	if own is Dictionary:
		merged.merge(own, true)
	return merged


## Damage multiplier the given resistances apply to a damage type:
## 1.0 unprotected, the tuned factor with a Resistance, 0.0 with a Nullification.
func mitigation(resistance_ids: Array, damage_type_id: String) -> float:
	var factor := 1.0
	for resistance_id: Variant in resistance_ids:
		var resistance := get_resistance(str(resistance_id))
		if not (resistance.get("mitigates", []) as Array).has(damage_type_id):
			continue
		if str(resistance.get("grade", "")) == "nullification":
			return 0.0
		factor = minf(factor, tune("combat", "resistance_factor", 0.5))
	return factor


func get_resistance(resistance_id: String) -> Dictionary:
	return resistances.get(resistance_id, {})


func resistance_name(resistance_id: String) -> String:
	return str(get_resistance(resistance_id).get("name", resistance_id))


func get_damage_type(damage_type_id: String) -> Dictionary:
	return damage_types.get(damage_type_id, {})


func get_region(region_id: String) -> Dictionary:
	return regions.get(region_id, {})


func region_name(region_id: String) -> String:
	return str(get_region(region_id).get("name", region_id))


func density_level(level: int) -> Dictionary:
	return density_levels.get(level, {})


## Template text for a Voice of the World line. Missing keys return the key
## itself so the gap is visible on screen.
func voice_line(key: String) -> String:
	if voice_lines.has(key):
		return str(voice_lines[key])
	push_warning("[Database] missing voice line '%s'" % key)
	return key


# --- Loading ---------------------------------------------------------------

func _read(file_name: String) -> Dictionary:
	var path := DATA_DIR + file_name
	if not FileAccess.file_exists(path):
		_problem("%s: file not found" % file_name)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		_problem("%s: line %d: %s" % [file_name, json.get_error_line(), json.get_error_message()])
		return {}
	if not (json.data is Dictionary):
		_problem("%s: top level must be an object" % file_name)
		return {}
	return json.data


func _list(root: Dictionary, key: String, file_name: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var entries: Variant = root.get(key, [])
	if not (entries is Array):
		_problem("%s: '%s' must be a list" % [file_name, key])
		return out
	for entry: Variant in entries:
		if entry is Dictionary:
			out.append(entry)
		else:
			_problem("%s: every entry in '%s' must be an object" % [file_name, key])
	return out


func _by_id(root: Dictionary, key: String, file_name: String) -> Dictionary:
	var out: Dictionary = {}
	for entry in _list(root, key, file_name):
		var id := str(entry.get("id", ""))
		if id == "":
			_problem("%s: an entry in '%s' has no id" % [file_name, key])
			continue
		if out.has(id):
			_problem("%s: duplicate id '%s' in '%s'" % [file_name, id, key])
		if not LABELS.has(str(entry.get("label", ""))):
			_problem("%s: '%s' needs a label of CANON, DESIGN or UNCONFIRMED" % [file_name, id])
		out[id] = entry
	return out


func _build_rank_bands() -> Array[Dictionary]:
	var bands: Array[Dictionary] = []
	for rank: Dictionary in ranks_by_id.values():
		if rank.get("ep_min") != null:
			bands.append(rank)
	bands.sort_custom(_rank_band_before)
	return bands


func _rank_band_before(a: Dictionary, b: Dictionary) -> bool:
	return int(a["ep_min"]) < int(b["ep_min"])


func _cross_check() -> void:
	for id: String in ranks_by_id:
		_need(danger_classes, ranks_by_id[id].get("danger_class"), "ranks.json: '%s' danger_class" % id)

	for id: String in damage_types:
		_need(resistances, damage_types[id].get("imprint_resistance"), "damage_types.json: '%s' imprint_resistance" % id)
	for id: String in resistances:
		_need_all(damage_types, resistances[id].get("mitigates"), "resistances.json: '%s' mitigates" % id)
	for merge in resistance_merges:
		_need_all(resistances, merge.get("inputs"), "resistances.json: merge inputs")
		_need(resistances, merge.get("result"), "resistances.json: merge result")

	for id: String in skills:
		_need(skill_categories, skills[id].get("category"), "skills.json: '%s' category" % id)
	for id: String in statuses:
		_need(damage_types, statuses[id].get("damage_type"), "damage_types.json: status '%s' damage_type" % id)
	for id: String in skills:
		_check_attack(skills[id].get("active"), "skills.json: '%s' active" % id)
		var practice: Variant = skills[id].get("practice")
		if practice is Dictionary:
			_check_attack(practice.get("precursor"), "skills.json: '%s' practice precursor" % id)
	for id: String in races:
		var moveset: Variant = races[id].get("moveset", {})
		if moveset is Dictionary:
			for slot: String in moveset:
				_check_attack(moveset[slot], "races.json: '%s' moveset.%s" % [id, slot])
	for id: String in creatures:
		var creature: Dictionary = creatures[id]
		_need(ranks_by_id, creature.get("rank"), "creatures.json: '%s' rank" % id)
		_need_all(resistances, creature.get("resistances"), "creatures.json: '%s' resistances" % id)
		_need_all(damage_types, creature.get("weak_to"), "creatures.json: '%s' weak_to" % id)
		for attack: Variant in creature.get("attacks", []):
			_check_attack(attack, "creatures.json: '%s' attack" % id)
		var devour: Variant = creature.get("devour", {})
		if devour is Dictionary:
			for gain: Variant in devour.get("skills", []):
				_need(skills, gain.get("skill"), "creatures.json: '%s' devour skill" % id)

	for id: String in recipes:
		var recipe: Dictionary = recipes[id]
		for side: String in ["inputs", "output"]:
			var parts: Variant = recipe.get(side, {})
			if parts is Dictionary:
				for item_id: String in parts:
					_need(items, item_id, "recipes.json: '%s' %s" % [id, side])

	for id: String in dialogues:
		var nodes: Variant = dialogues[id].get("nodes", {})
		if not (nodes is Dictionary) or not nodes.has(str(dialogues[id].get("start", ""))):
			_problem("dialogues.json: '%s' needs nodes and a start node" % id)
			continue
		for node_id: String in nodes:
			var node: Dictionary = nodes[node_id]
			_need(nodes, node.get("next"), "dialogues.json: '%s' node '%s' next" % [id, node_id])
			for option: Variant in node.get("options", []):
				_need(nodes, option.get("next"), "dialogues.json: '%s' node '%s' option" % [id, node_id])

	var fusion_inputs: Dictionary = skills.duplicate()
	fusion_inputs.merge(sub_functions)
	for id: String in fusions:
		var fusion: Dictionary = fusions[id]
		_need_all(fusion_inputs, fusion.get("inputs"), "fusions.json: '%s' inputs" % id)
		_need(skills, fusion.get("result"), "fusions.json: '%s' result" % id)
		_need_all(skills, fusion.get("sacrifices"), "fusions.json: '%s' sacrifices" % id)
		_need_all(skills, fusion.get("absorbs"), "fusions.json: '%s' absorbs" % id)

	for id: String in regions:
		if not density_levels.has(int(regions[id].get("magicule_density", -1))):
			_problem("regions.json: '%s' magicule_density is not a density level" % id)
	for id: String in races:
		var race: Dictionary = races[id]
		_need(ranks_by_id, race.get("base_rank"), "races.json: '%s' base_rank" % id)
		_need_all(skills, race.get("intrinsic_skills"), "races.json: '%s' intrinsic_skills" % id)
		_need_all(regions, race.get("spawn_regions"), "races.json: '%s' spawn_regions" % id)

	var first: Variant = spin.get("first_life", {})
	if first is Dictionary:
		_need(races, first.get("race"), "spin.json: first_life race")
		_need(regions, first.get("region"), "spin.json: first_life region")
	else:
		_problem("spin.json: first_life must be an object")


func _check_attack(attack: Variant, where: String) -> void:
	if attack == null:
		return
	if not (attack is Dictionary):
		_problem("%s: must be an object" % where)
		return
	if str(attack.get("kind", "")) == "jet":
		return
	if not ["melee", "lunge", "projectile", "cone"].has(str(attack.get("kind", ""))):
		_problem("%s: kind must be melee, lunge, projectile, cone or jet" % where)
	_need(damage_types, attack.get("damage_type", "?"), "%s damage_type" % where)
	var status: Variant = attack.get("status")
	if status is Dictionary:
		_need(statuses, status.get("id", "?"), "%s status" % where)


## Records a problem unless `id` is empty (optional reference) or known.
func _need(table: Dictionary, id: Variant, where: String) -> void:
	if id == null or str(id) == "":
		return
	if not table.has(str(id)):
		_problem("%s: unknown id '%s'" % [where, str(id)])


func _need_all(table: Dictionary, ids: Variant, where: String) -> void:
	if ids == null:
		return
	if not (ids is Array):
		_problem("%s: must be a list" % where)
		return
	for id: Variant in ids:
		_need(table, id, where)


func _problem(message: String) -> void:
	problems.append(message)
