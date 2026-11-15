class_name Vitals
extends RefCounted
## Health, lingering statuses and resistance growth of one body. The player
## and every creature own one, so the world's rules apply to both alike: a
## boss that survives enough fire earns Heat Resistance exactly as the player
## does (design document, section 8.5).

signal damaged(amount: float, damage_type_id: String)
signal died(damage_type_id: String)
## `cause` is "granted", "exposure" (earned by surviving), "merge" or "upgrade".
signal resistance_gained(resistance_id: String, cause: String)
signal status_changed

var hp := 1.0
var max_hp := 1.0
var alive := true
## Shared with the owner (for the player this is LifeState.resistances).
var resistances: Array[String] = []
## Extra damage multipliers by damage type, from passive skills.
var damage_factors: Dictionary = {}
## status id -> {"remaining": s, "tick_damage": hp, "until_tick": s}
var statuses: Dictionary = {}
## damage type id -> damage survived since the last resistance step
var exposure: Dictionary = {}


func setup(maximum: float, owned_resistances: Array[String]) -> void:
	max_hp = maxf(1.0, maximum)
	hp = max_hp
	alive = true
	resistances = owned_resistances
	statuses.clear()
	exposure.clear()


## Changes maximum health, keeping the same fraction of it filled.
func set_max_hp(maximum: float) -> void:
	var fraction := hp / max_hp
	max_hp = maxf(1.0, maximum)
	hp = max_hp * fraction


func fraction() -> float:
	return clampf(hp / max_hp, 0.0, 1.0)


func heal(amount: float) -> float:
	if not alive or amount <= 0.0:
		return 0.0
	var before := hp
	hp = minf(max_hp, hp + amount)
	return hp - before


## Multiplier this body applies to incoming damage of a type.
func mitigation(damage_type_id: String) -> float:
	return Database.mitigation(resistances, damage_type_id) * float(damage_factors.get(damage_type_id, 1.0))


## Applies damage after mitigation and returns what was actually dealt.
func apply_damage(amount: float, damage_type_id: String) -> float:
	if not alive or amount <= 0.0:
		return 0.0
	var dealt := amount * mitigation(damage_type_id)
	if dealt <= 0.0:
		return 0.0
	hp = maxf(0.0, hp - dealt)
	damaged.emit(dealt, damage_type_id)
	if hp <= 0.0:
		alive = false
		statuses.clear()
		status_changed.emit()
		died.emit(damage_type_id)
	else:
		_expose(damage_type_id, dealt)
	return dealt


## Adds or refreshes a status. The matching Resistance halves its duration;
## a Nullification blocks it. Returns false when it did not take hold.
func add_status(status_id: String, duration: float, tick_damage: float = 0.0) -> bool:
	if not alive:
		return false
	var status := Database.get_status(status_id)
	if status.is_empty():
		return false
	var factor := Database.mitigation(resistances, str(status.get("damage_type", "")))
	if factor <= 0.0:
		return false
	var entry: Dictionary = statuses.get(status_id, {"remaining": 0.0, "tick_damage": 0.0, "until_tick": float(status.get("tick_interval", 1.0))})
	entry["remaining"] = maxf(float(entry["remaining"]), duration * factor)
	entry["tick_damage"] = maxf(float(entry["tick_damage"]), tick_damage)
	statuses[status_id] = entry
	status_changed.emit()
	return true


func has_status(status_id: String) -> bool:
	return statuses.has(status_id)


func clear_status(status_id: String) -> void:
	if statuses.erase(status_id):
		status_changed.emit()


## Slowest movement factor among active statuses (1.0 when unhindered).
func speed_factor() -> float:
	var factor := 1.0
	for status_id: String in statuses:
		factor = minf(factor, float(Database.get_status(status_id).get("speed_factor", 1.0)))
	return factor


func attacks_blocked() -> bool:
	for status_id: String in statuses:
		if Database.get_status(status_id).get("blocks_attacks", false):
			return true
	return false


## Advances statuses: counts them down and applies damage over time.
func tick(delta: float) -> void:
	if not alive or statuses.is_empty():
		return
	var ended := false
	for status_id: String in statuses.keys():
		var entry: Dictionary = statuses[status_id]
		var status := Database.get_status(status_id)
		entry["remaining"] = float(entry["remaining"]) - delta
		if status.has("tick_interval") and float(entry["tick_damage"]) > 0.0:
			entry["until_tick"] = float(entry["until_tick"]) - delta
			if float(entry["until_tick"]) <= 0.0:
				entry["until_tick"] = float(status["tick_interval"])
				apply_damage(float(entry["tick_damage"]), str(status.get("damage_type", "")))
				if not alive:
					return
		if float(entry["remaining"]) <= 0.0:
			statuses.erase(status_id)
			ended = true
	if ended:
		status_changed.emit()


## Adds a resistance, then applies every merge it completes (section 8.5).
func grant_resistance(resistance_id: String, cause: String = "granted") -> bool:
	if resistances.has(resistance_id) or not Database.resistances.has(resistance_id):
		return false
	resistances.append(resistance_id)
	resistance_gained.emit(resistance_id, cause)
	_apply_merges()
	return true


## The resistance this body would earn next from more exposure to a damage
## type: its first Resistance, or the upgrade of the one it already has.
func next_resistance_step(damage_type_id: String) -> String:
	var covering: Array[String] = []
	for resistance_id in resistances:
		if (Database.get_resistance(resistance_id).get("mitigates", []) as Array).has(damage_type_id):
			covering.append(resistance_id)
	if covering.is_empty():
		return str(Database.get_damage_type(damage_type_id).get("imprint_resistance", ""))
	for merge in Database.resistance_merges:
		var inputs: Array = merge.get("inputs", [])
		if inputs.size() == 1 and covering.has(str(inputs[0])) and not resistances.has(str(merge.get("result", ""))):
			return str(merge.get("result", ""))
	return ""


## Counts damage survived toward the next step of the merge tree. The price
## of a step depends only on what the body already holds against that damage
## type: the first Resistance costs the base amount, and each step beyond it
## costs exposure_step_factor times more.
func _expose(damage_type_id: String, dealt: float) -> void:
	var next := next_resistance_step(damage_type_id)
	if next == "":
		# Nothing more can be earned from this kind of damage.
		exposure.erase(damage_type_id)
		return
	exposure[damage_type_id] = float(exposure.get(damage_type_id, 0.0)) + dealt
	var needed := max_hp * Database.tune("combat", "exposure_to_resistance", 1.2) \
			* pow(Database.tune("combat", "exposure_step_factor", 3.0), _steps_held(damage_type_id))
	if float(exposure[damage_type_id]) < needed:
		return
	exposure[damage_type_id] = 0.0
	for merge in Database.resistance_merges:
		var inputs: Array = merge.get("inputs", [])
		if inputs.size() == 1 and str(merge.get("result", "")) == next and resistances.has(str(inputs[0])):
			resistances.erase(str(inputs[0]))
			resistances.append(next)
			resistance_gained.emit(next, "upgrade")
			_apply_merges()
			return
	grant_resistance(next, "exposure")


## How many steps of the merge tree the body holds against a damage type:
## 0 unprotected, 1 with a first Resistance, 2 with its upgrade, and so on.
func _steps_held(damage_type_id: String) -> int:
	var held := 0
	for resistance_id in resistances:
		if (Database.get_resistance(resistance_id).get("mitigates", []) as Array).has(damage_type_id):
			held = maxi(held, _depth(resistance_id))
	return held


## 1 for a Resistance that is not an upgrade of another, plus one per upgrade.
func _depth(resistance_id: String) -> int:
	for merge in Database.resistance_merges:
		var inputs: Array = merge.get("inputs", [])
		if inputs.size() == 1 and str(merge.get("result", "")) == resistance_id:
			return 1 + _depth(str(inputs[0]))
	return 1


func _apply_merges() -> void:
	var merged := true
	while merged:
		merged = false
		for merge in Database.resistance_merges:
			var inputs: Array = merge.get("inputs", [])
			var result := str(merge.get("result", ""))
			if inputs.size() < 2 or resistances.has(result):
				continue
			var complete := true
			for input: Variant in inputs:
				if not resistances.has(str(input)):
					complete = false
					break
			if not complete:
				continue
			for input: Variant in inputs:
				resistances.erase(str(input))
			resistances.append(result)
			resistance_gained.emit(result, "merge")
			merged = true
