extends Node
## The soul (autoload "Soul"): everything that survives death.
##
## This is the only state written to disk between lives. It may hold nothing
## but the "carries over" column of the design document (section 3): memory,
## never the body. If a field would make a new body stronger without the
## player re-earning it, it does not belong here.

const SAVE_PATH := "user://soul.json"
const UNREADABLE_PATH := "user://soul.unreadable.json"
const SAVE_VERSION := 1
const PAST_LIVES_KEPT := 100

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
## death, read at every birth. Currently only {"resistances": [id]}.
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


## Wipes all memory and overwrites the save file.
func erase() -> void:
	_reset()
	save_to_disk()


func save_to_disk() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[Soul] cannot write %s (error %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(_to_dictionary(), "\t"))
	file.close()


func load_from_disk() -> void:
	_reset()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var raw := FileAccess.get_file_as_string(SAVE_PATH)
	var json := JSON.new()
	if json.parse(raw) != OK or not (json.data is Dictionary):
		push_warning("[Soul] %s is unreadable. A copy was kept as %s and the soul starts blank." % [SAVE_PATH, UNREADABLE_PATH])
		var copy := FileAccess.open(UNREADABLE_PATH, FileAccess.WRITE)
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
