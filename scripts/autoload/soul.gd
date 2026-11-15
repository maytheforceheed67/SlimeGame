extends Node
## The soul (autoload "Soul"): everything that survives death.
##
## This is the only state written to disk between lives. It may hold nothing
## but the "carries over" column of the design document (section 3): memory,
## never the body. If a field would make a new body stronger without the
## player re-earning it, it does not belong here.

const SAVE_VERSION := 1
const PAST_LIVES_KEPT := 100

## Where the soul is stored. Tests point this at a scratch file.
var save_path := "user://soul.json"

var lives_lived := 0

## Arts already performed: art id -> mastery level.
var arts: Dictionary = {}
## Spell knowledge: spell id -> record.
var spells: Dictionary = {}
## Magic theory ranks: school id -> rank.
var magic_theory: Dictionary = {}
## Weapon mastery: weapon class id -> mastery.
var weapon_mastery: Dictionary = {}
## Analysis records: "species", "materials" and "recipes", each id -> record.
var codex: Dictionary = {}
## Map knowledge, lore and dialogue options unlocked by past lives.
var map_knowledge: Dictionary = {}
var lore: Dictionary = {}
## Dungeon records: deepest floor and floor notes.
var dungeon_records: Dictionary = {}

## What the last death grants the next birth (section 5). Replaced at every
## death, read at every birth: "resistances" (the imprint of the cause),
## "wish_skills", "wish_resistances" and "reel_weights" (the last thoughts).
var birth_grants: Dictionary = {}
## Short record of each finished life, oldest first.
var past_lives: Array = []


func _enter_tree() -> void:
	load_from_disk()


## Closes the book on a life. `imprint_resistance` is the Resistance that the
## cause of death leaves on the soul, or "" for none.
func record_death(life: LifeState, damage_type_id: String, imprint_resistance: String) -> void:
	lives_lived += 1
	past_lives.append({
		"life": life.life_number,
		"race": life.race_id,
		"stage": life.stage_index,
		"final_ep": life.ep,
		"cause": damage_type_id,
	})
	while past_lives.size() > PAST_LIVES_KEPT:
		past_lives.pop_front()
	birth_grants = {"resistances": [imprint_resistance] if imprint_resistance != "" else []}
	save_to_disk()


## Adds what the chosen last thoughts grant to the next birth (see Wishes).
func set_wishes(grants: Dictionary) -> void:
	birth_grants["wish_skills"] = grants.get("skills", [])
	birth_grants["wish_resistances"] = grants.get("resistances", [])
	birth_grants["reel_weights"] = grants.get("reel_weights", {})
	save_to_disk()


## Whether a past or present life has fully analysed this subject.
## `kind` is "species" or "item".
func knows(kind: String, id: String) -> bool:
	return (codex.get(_codex_section(kind), {}) as Dictionary).has(id)


## Records a finished analysis in the codex. Knowledge is saved at once: it
## belongs to the soul even if this life ends badly.
func record_analysis(kind: String, id: String, life_number: int) -> void:
	var section: Dictionary = codex.get(_codex_section(kind), {})
	var entry: Dictionary = section.get(id, {"first_life": life_number, "times": 0})
	entry["times"] = int(entry.get("times", 0)) + 1
	section[id] = entry
	codex[_codex_section(kind)] = section
	save_to_disk()


func record_recipe(recipe_id: String, life_number: int) -> void:
	var section: Dictionary = codex.get("recipes", {})
	if not section.has(recipe_id):
		section[recipe_id] = {"first_life": life_number}
		codex["recipes"] = section
		save_to_disk()


## Remembers a fact that is not an analysis: a lesson, a place, a meeting.
func remember(topic: String, life_number: int) -> void:
	if not lore.has(topic):
		lore[topic] = {"first_life": life_number}
		save_to_disk()


func remembers(topic: String) -> bool:
	return lore.has(topic)


## Whether a topic was first learned in a life before `life_number`.
func remembers_from_before(topic: String, life_number: int) -> bool:
	return lore.has(topic) and int(lore[topic].get("first_life", life_number)) < life_number


func _codex_section(kind: String) -> String:
	return "species" if kind == "species" else "materials"


## Wipes all memory and overwrites the save file.
func erase() -> void:
	_reset()
	save_to_disk()


func save_to_disk() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("[Soul] cannot write %s (error %d)" % [save_path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(_to_dictionary(), "\t"))
	file.close()


func load_from_disk() -> void:
	_reset()
	if not FileAccess.file_exists(save_path):
		return
	var raw := FileAccess.get_file_as_string(save_path)
	var json := JSON.new()
	if json.parse(raw) != OK or not (json.data is Dictionary):
		var unreadable_path := save_path + ".unreadable"
		push_warning("[Soul] %s is unreadable. A copy was kept as %s and the soul starts blank." % [save_path, unreadable_path])
		var copy := FileAccess.open(unreadable_path, FileAccess.WRITE)
		if copy != null:
			copy.store_string(raw)
			copy.close()
		return

	var data: Dictionary = json.data
	lives_lived = int(data.get("lives_lived", 0))
	arts = _dictionary(data, "arts")
	spells = _dictionary(data, "spells")
	magic_theory = _dictionary(data, "magic_theory")
	weapon_mastery = _dictionary(data, "weapon_mastery")
	codex = _dictionary(data, "codex")
	map_knowledge = _dictionary(data, "map_knowledge")
	lore = _dictionary(data, "lore")
	dungeon_records = _dictionary(data, "dungeon_records")
	birth_grants = _dictionary(data, "birth_grants")
	var lives: Variant = data.get("past_lives", [])
	past_lives = lives if lives is Array else []


func _reset() -> void:
	lives_lived = 0
	arts = {}
	spells = {}
	magic_theory = {}
	weapon_mastery = {}
	codex = {"species": {}, "materials": {}, "recipes": {}}
	map_knowledge = {}
	lore = {}
	dungeon_records = {}
	birth_grants = {}
	past_lives = []


func _to_dictionary() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"lives_lived": lives_lived,
		"arts": arts,
		"spells": spells,
		"magic_theory": magic_theory,
		"weapon_mastery": weapon_mastery,
		"codex": codex,
		"map_knowledge": map_knowledge,
		"lore": lore,
		"dungeon_records": dungeon_records,
		"birth_grants": birth_grants,
		"past_lives": past_lives,
	}


func _dictionary(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key, {})
	if value is Dictionary:
		return value
	return {}
