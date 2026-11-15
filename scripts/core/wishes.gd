class_name Wishes
extends RefCounted
## Last thoughts (design document, section 5). When a life ends, the Voice of
## the World reads the dying mind: a handful of thoughts drawn from how that
## life was lived are offered as cards, and up to three shape the next birth.
##
## Cards live in data/wish_cards.json. This class picks the offer, turns the
## chosen cards into what the next life is born with, and describes results.

const MEMORY_PREFIX := "wish:"
## Score of a card that must be in the offer; far above any fitted score.
const ALWAYS_SCORE := 1000.0


## The cards offered for a life that ended by `cause`: those that fit it
## best first, between the tuned minimum and maximum.
static func offer(life: LifeState, cause: String) -> Array[Dictionary]:
	var scored: Array[Dictionary] = []
	for card_id: String in Database.wish_cards:
		var card: Dictionary = Database.wish_cards[card_id]
		var score := _score(card, life, cause)
		if card.get("first_death", false) and life.life_number == 1:
			# Always offered at the first death, whatever else fits.
			score = ALWAYS_SCORE
		scored.append({"card": card, "score": score})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))

	var minimum := int(Database.tune("death", "cards_min", 6.0))
	var maximum := int(Database.tune("death", "cards_max", 8.0))
	var cards: Array[Dictionary] = []
	for entry in scored:
		if cards.size() >= maximum:
			break
		if float(entry["score"]) >= 1.0 or cards.size() < minimum:
			cards.append(entry["card"])
	return cards


## The thoughts read at the very first death, before the first life.
static func prologue() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for card_id: String in Database.wish_cards:
		if Database.wish_cards[card_id].get("prologue", false):
			cards.append(Database.wish_cards[card_id])
	return cards


## What the chosen cards grant the next birth:
## {"skills": [ids], "resistances": [ids], "reel_weights": {reel: {value: weight}}}.
static func grants(cards: Array[Dictionary]) -> Dictionary:
	var skill_counts: Dictionary = {}
	var upgrades: Dictionary = {}
	var resistances: Array = []
	var reel_weights: Dictionary = {}
	for card in cards:
		var result: Dictionary = card.get("result", {})
		match str(result.get("kind", "nothing")):
			"skill":
				var skill_id := str(result.get("skill", ""))
				skill_counts[skill_id] = int(skill_counts.get(skill_id, 0)) + 1
				if result.has("stacks_into"):
					upgrades[skill_id] = str(result["stacks_into"])
			"resistance":
				resistances.append(str(result.get("resistance", "")))
			"reel_weight":
				var reel := str(result.get("reel", ""))
				var weights: Dictionary = reel_weights.get(reel, {})
				var value := str(result.get("value", ""))
				weights[value] = float(weights.get(value, 0.0)) + float(result.get("weight", 0.0))
				reel_weights[reel] = weights
	var skills: Array = []
	for skill_id: String in skill_counts:
		# The same wish made twice is granted in its stronger form.
		if int(skill_counts[skill_id]) >= 2 and upgrades.has(skill_id):
			skills.append(upgrades[skill_id])
		else:
			skills.append(skill_id)
	return {"skills": skills, "resistances": resistances, "reel_weights": reel_weights}


## What a card leads to, in words.
static func describe(card: Dictionary) -> String:
	var result: Dictionary = card.get("result", {})
	match str(result.get("kind", "nothing")):
		"skill":
			var skill_id := str(result.get("skill", ""))
			var text := "%s: %s" % [Database.skill_category_name(skill_id), Database.skill_name(skill_id)]
			if result.has("stacks_into"):
				text += "\n(wished twice: %s)" % Database.skill_name(str(result["stacks_into"]))
			return text
		"resistance":
			return Database.resistance_name(str(result.get("resistance", "")))
		"reel_weight":
			return "The next vessel leans toward %s" % str(Database.get_race(str(result.get("value", ""))).get("name", ""))
	return "Nothing"


## Whether the soul has seen this card's result before.
static func is_known(card: Dictionary) -> bool:
	return Soul.remembers(MEMORY_PREFIX + str(card.get("id", "")))


static func remember(cards: Array[Dictionary], life_number: int) -> void:
	for card in cards:
		Soul.remember(MEMORY_PREFIX + str(card.get("id", "")), life_number)


static func _score(card: Dictionary, life: LifeState, cause: String) -> float:
	var when: Dictionary = card.get("when", {})
	if when.get("always", false):
		return ALWAYS_SCORE
	var score := 0.0
	if when.has("stat"):
		score = float(life.stats.get(str(when["stat"]), 0.0)) / maxf(0.001, float(when.get("at_least", 1.0)))
	if when.has("cause") and (when["cause"] as Array).has(cause):
		score = maxf(score, 1.5)
	return score
