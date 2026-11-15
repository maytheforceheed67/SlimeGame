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

var damage_types: Dictionary = {}
var resistances: Dictionary = {}
var resistance_merges: Array[Dictionary] = []

var skill_categories: Dictionary = {}
var skills: Dictionary = {}
var fusions: Dictionary = {}

var races: Dictionary = {}
var regions: Dictionary = {}
## int density level -> record
var density_levels: Dictionary = {}
var spin: Dictionary = {}

var voice_lines: Dictionary = {}

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

	damage_types = _by_id(_read("damage_types.json"), "damage_types", "damage_types.json")
	var resistance_file := _read("resistances.json")
	resistances = _by_id(resistance_file, "resistances", "resistances.json")
	resistance_merges = _list(resistance_file, "merges", "resistances.json")

	var skill_file := _read("skills.json")
	skill_categories = _by_id(skill_file, "categories", "skills.json")
	skills = _by_id(skill_file, "skills", "skills.json")
	fusions = _by_id(_read("fusions.json"), "fusions", "fusions.json")

	races = _by_id(_read("races.json"), "races", "races.json")
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
	return "%d ranks, %d races, %d skills, %d fusions, %d resistances, %d regions, %d voice lines" % [
		ranks_by_id.size(), races.size(), skills.size(), fusions.size(),
		resistances.size(), regions.size(), voice_lines.size(),
	]


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
	for id: String in fusions:
		var fusion: Dictionary = fusions[id]
		_need_all(skills, fusion.get("inputs"), "fusions.json: '%s' inputs" % id)
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
