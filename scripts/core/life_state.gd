class_name LifeState
extends RefCounted
## One life: everything that belongs to the body and to this branch of the
## timeline. It is thrown away on death. Anything that must outlive the body
## belongs in the Soul autoload instead (design document, section 3).

var life_number := 1
## Seeds spawns, loot and optional events for this branch of the timeline.
var world_seed := 0

var race_id := ""
## Position in the race's evolution line (0 is the base form).
var stage_index := 0
var origin_id := ""
## Empty until the reincarnation spin exists.
var affinity_id := ""
var region_id := ""
## Names received in this life; empty while unnamed.
var given_name := ""
var family_name := ""

var ep := 0
var vitals := Vitals.new()
var magicules := 0.0
var max_magicules := 0.0
var stamina := 100.0
var skills: Array[String] = []
## Skills built into the body at birth (intrinsics, wishes). They reserve no
## magicule capacity; skills acquired during life do.
var birth_skills: Array[String] = []
## The same array object as vitals.resistances.
var resistances: Array[String] = []
var alive := true
## The active skill bound to the skill button, or "".
var selected_skill := ""

# --- Predator ---------------------------------------------------------------
## Stomach contents: item id -> count.
var stomach: Dictionary = {}
## Beings held in the Stomach by agreement (a battery for later costs).
var sealed: Array[String] = []
## Subjects waiting for or under analysis: {"key", "kind", "id", "time", "progress"}.
var analysis_queue: Array[Dictionary] = []
## Subjects fully analysed in this life: "species:<id>" or "item:<id>" -> true.
var analysed: Dictionary = {}
## Whether Predator's Analysis is linked to Great Sage's Parallel Processing.
var analysis_linked := false
## Recipes this body can synthesise.
var recipes: Array[String] = []
## Species available to Mimicry, and the form currently worn ("" = own body).
var forms: Array[String] = []
var form_id := ""

# --- Knowledge of this life --------------------------------------------------
## Species appraised by the advisor in this life: creature id -> true.
var appraised: Dictionary = {}
## Story and tutorial flags of this life.
var flags: Dictionary = {}
## Progress toward skills learned by practice: skill id -> amount.
var practice: Dictionary = {}
## Tallies that shape the last-thought cards: stat name -> amount.
var stats: Dictionary = {}


func has_skill(skill_id: String) -> bool:
	return skills.has(skill_id)


func item_count(item_id: String) -> int:
	return int(stomach.get(item_id, 0))


## Full name as shown on the status sheet, or "" while unnamed.
func full_name() -> String:
	if given_name == "":
		return ""
	return given_name if family_name == "" else "%s %s" % [given_name, family_name]
