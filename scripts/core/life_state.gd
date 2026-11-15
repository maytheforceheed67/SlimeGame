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

var ep := 0
var skills: Array[String] = []
var resistances: Array[String] = []
var alive := true
