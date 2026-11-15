extends TestCase
## Combat: vitals, resistances, statuses, attacks and creature behaviour.


func _run() -> void:
	print("Combat")
	_test_vitals()
	await start_main()
	await _test_creatures()


func _fresh(max_hp: float, owned: Array[String] = []) -> Vitals:
	var vitals := Vitals.new()
	vitals.setup(max_hp, owned)
	return vitals


func _test_vitals() -> void:
	var vitals := _fresh(100.0)
	vitals.apply_damage(30.0, "fire")
	check(is_equal_approx(vitals.hp, 70.0), "damage lowers health")
	vitals.grant_resistance("heat_resistance")
	check(is_equal_approx(vitals.apply_damage(30.0, "fire"), 15.0), "a Resistance halves matching damage")
	check(is_equal_approx(vitals.apply_damage(10.0, "cold"), 10.0), "and leaves other damage alone")

	vitals = _fresh(100.0)
	var earned: Array[String] = []
	vitals.resistance_gained.connect(func(id: String, cause: String) -> void: earned.append(id + ":" + cause))
	for i in 7:
		vitals.apply_damage(20.0, "fire")
		vitals.heal(20.0)
	check(earned == ["heat_resistance:exposure"], "surviving enough fire earns Heat Resistance")

	vitals = _fresh(100.0)
	vitals.grant_resistance("cold_resistance")
	vitals.grant_resistance("heat_resistance")
	check(vitals.resistances == ["thermal_fluctuation_resistance"], "Cold + Heat merge into Thermal Fluctuation Resistance")
	vitals.grant_resistance("electricity_resistance")
	check(vitals.resistances.has("electricity_resistance") and vitals.resistances.size() == 2,
			"Electricity waits: the next merge needs the Nullification")

	# Each step of the merge tree costs three times the one before it, and
	# the price depends only on what the body already holds.
	vitals = _fresh(100.0, ["pierce_resistance"])
	for i in 13:
		vitals.apply_damage(40.0, "blade")
		vitals.heal(40.0)
	check(vitals.resistances == ["pierce_resistance"], "the step beyond a first Resistance costs more than the first did")
	for i in 6:
		vitals.apply_damage(40.0, "blade")
		vitals.heal(40.0)
	check(vitals.resistances == ["physical_attack_resistance"], "Pierce Resistance grows into Physical Attack Resistance")

	vitals = _fresh(100.0)
	for i in 40:
		vitals.apply_damage(50.0, "impact")
		vitals.heal(50.0)
	check(vitals.resistances.is_empty() and not vitals.exposure.has("impact"),
			"damage that teaches nothing earns nothing and is not banked")
	var fresh := _fresh(100.0, ["physical_attack_resistance"])
	var battered := _fresh(100.0)
	for i in 12:
		battered.apply_damage(50.0, "impact")
		battered.heal(50.0)
	battered.grant_resistance("physical_attack_resistance")
	var hits_fresh := _hits_until(fresh, "impact", "physical_attack_nullification")
	var hits_battered := _hits_until(battered, "impact", "physical_attack_nullification")
	check(hits_fresh == hits_battered and hits_fresh == 54, "the same step costs the same whatever was suffered before (%d and %d hits)" % [hits_fresh, hits_battered])

	vitals = _fresh(100.0)
	check(vitals.add_status("poisoned", 3.0, 5.0), "poison takes hold")
	for i in 61:
		vitals.tick(1.0 / 60.0)
	check(is_equal_approx(vitals.hp, 95.0), "poison ticks once a second")
	vitals.add_status("paralysed", 2.0)
	check(is_equal_approx(vitals.speed_factor(), 0.25) and vitals.attacks_blocked(), "paralysis slows and blocks attacks")
	for i in 240:
		vitals.tick(1.0 / 60.0)
	check(vitals.statuses.is_empty(), "statuses wear off")

	vitals = _fresh(100.0, ["poison_resistance"])
	vitals.add_status("poisoned", 4.0, 5.0)
	check(is_equal_approx(float(vitals.statuses["poisoned"]["remaining"]), 2.0), "a Resistance halves a status")
	vitals = _fresh(100.0, ["abnormal_condition_nullification"])
	check(not vitals.add_status("paralysed", 4.0), "a Nullification blocks a status")

	vitals = _fresh(50.0)
	var causes: Array[String] = []
	vitals.died.connect(func(type: String) -> void: causes.append(type))
	vitals.add_status("poisoned", 30.0, 60.0)
	for i in 70:
		vitals.tick(1.0 / 60.0)
	check(not vitals.alive and causes == ["poison"], "damage over time can kill, and names its cause")


## Hits of 40 a body takes before it holds `wanted`, healing between hits.
func _hits_until(vitals: Vitals, damage_type: String, wanted: String) -> int:
	for i in 400:
		if vitals.resistances.has(wanted):
			return i
		vitals.apply_damage(40.0, damage_type)
		vitals.heal(40.0)
	return -1


func _spawn(id: String, offset: Vector3) -> Creature:
	var creature := Creature.create(id)
	main.add_child(creature)
	creature.global_position = player.global_position + offset
	creature.home = creature.global_position
	return creature


## Puts the slime back at the cave's spawn point, healed and unhurried.
func _reset() -> void:
	player.respawn(main.level.spawn_position())
	Game.life.vitals.hp = Game.life.vitals.max_hp
	Game.life.vitals.statuses.clear()
	await frames(30)


func _test_creatures() -> void:
	var life := Game.life
	check(is_equal_approx(life.vitals.max_hp, 60.0), "a 100 EP slime has 60 health")
	check(is_equal_approx(Game.get_power(), 1.0), "and a damage multiplier of 1")
	await seconds(1.0)

	# A bat notices the slime, closes in and bites.
	var bat := _spawn("giant_bat", Vector3(0.0, 2.0, -9.0))
	await seconds(6.0)
	check(life.vitals.hp < life.vitals.max_hp, "a giant bat hunts and bites the slime")
	check(player.soft_target() == bat, "the nearest creature ahead is the soft target")

	# The slime's tackle hurts it back. (The slime is made untouchable for
	# the scripted parts so a lucky monster cannot end the test early.)
	player._invulnerable = 9999.0
	life.vitals.hp = life.vitals.max_hp
	var bat_hp := bat.get_vitals().hp
	for i in 12:
		life.vitals.hp = life.vitals.max_hp
		await tap("attack_light")
		await frames(30)
	check(bat.get_vitals().hp < bat_hp, "tackles damage the bat")
	check(bat.get_vitals().has_status("corroding") or bat.get_vitals().hp < bat_hp - 8.0, "Dissolve leaves a corrosive burn")

	# Killing blow leaves remains.
	var deaths: Array[Creature] = []
	Game.creature_died.connect(func(dead: Creature) -> void: deaths.append(dead))
	bat.take_hit({"amount": 9999.0, "damage_type": "impact", "attacker": player})
	await frames(5)
	check(bat.is_corpse() and bat.is_in_group(Creature.CORPSE_GROUP), "a slain creature leaves remains")
	check(not bat.is_in_group(Combat.GROUP) and deaths == [bat], "and stops being a combatant")
	bat.queue_free()

	# Stagger opens a window.
	await _reset()
	var lizard := _spawn("armorsaurus", Vector3(0.0, 0.5, -4.0))
	await frames(10)
	lizard.take_hit({"amount": 1.0, "damage_type": "impact", "stagger": 80.0, "attacker": player})
	check(lizard.is_staggered(), "enough stagger leaves a creature helpless")
	var dealt: float = lizard.take_hit({"amount": 40.0, "damage_type": "blade", "attacker": player})
	check(is_equal_approx(dealt, 20.0), "the armorsaurus resists physical attacks")
	await seconds(4.0)
	check(not lizard.is_staggered(), "stagger wears off")

	# A creature adapts mid-fight, and everyone hears it.
	for i in 20:
		lizard.take_hit({"amount": 30.0, "damage_type": "fire", "attacker": player})
		lizard.get_vitals().heal(30.0)
	await seconds(1.5)
	check(lizard.get_vitals().resistances.has("heat_resistance"), "a creature earns Heat Resistance from burns")
	check(spoken().contains("Armorsaurus has adapted"), "and the Voice broadcasts it")
	lizard.queue_free()
	await frames(5)

	# A leash holds: a creature that gives up a chase goes home and stays
	# there, even with its prey still in sight.
	await _reset()
	var hound := _spawn("evil_centipede", Vector3(0.0, 0.3, -5.0))
	hound.data = hound.data.duplicate(true)
	hound.data["stats"]["leash"] = 5.0
	await seconds(1.0)
	check(hound._target == player, "a creature notices prey inside its sight")
	player.respawn(hound.home + Vector3(0.0, 0.3, 11.0))
	var farthest := 0.0
	var gave_up := false
	var went_home := false
	for i in 420:
		await frames(1)
		var from_home := hound.global_position.distance_to(hound.home)
		farthest = maxf(farthest, from_home)
		if hound._returning:
			gave_up = true
			check_quietly(hound._target == null, "a creature on its way home took up the chase again")
		elif gave_up and from_home < 3.5:
			went_home = true
	check(farthest < 6.5, "it does not follow past its leash (%.1f m from home at most)" % farthest)
	check(gave_up and went_home, "and goes all the way home before it will hunt again")
	hound.queue_free()
	await frames(5)

	# Skill attack: Water Blade spends water and cuts at range.
	await _reset()
	Game.grant_skill("water_blade")
	life.stomach["water"] = 3
	var spider := _spawn("black_spider", Vector3(0.0, 0.5, -11.0))
	spider.set_physics_process(false)
	await frames(5)
	var spider_hp := spider.get_vitals().hp
	check(life.selected_skill == "water_blade", "the first active skill is bound to the skill button")
	await tap("attack_skill")
	await seconds(1.0)
	check(life.item_count("water") == 2, "Water Blade spends stored water")
	check(is_equal_approx(spider_hp - spider.get_vitals().hp, 30.0), "and cuts for its full damage at range")
	life.stomach["water"] = 0
	await tap("attack_skill")
	await seconds(0.6)
	check(is_equal_approx(spider_hp - spider.get_vitals().hp, 30.0), "without water it cannot be used")
	spider.queue_free()
	await frames(5)

	# The apex predator kills a newborn slime; the cause is recorded.
	await _reset()
	player._invulnerable = 0.0
	var serpent := _spawn("tempest_serpent", Vector3(0.0, 0.5, -5.0))
	for i in 600:
		if not life.alive:
			break
		await frames(1)
	serpent.set_physics_process(false)
	check(not life.alive, "the tempest serpent kills a 100 EP slime")
	check(Soul.lives_lived == 1 and Soul.past_lives[0]["cause"] in ["blade", "poison", "impact"],
			"the soul records the cause of death")
	serpent.queue_free()
	await seconds(Game.REBIRTH_DELAY + 1.0)
	check(Game.is_alive() and Game.life.life_number == 2, "and a new life follows")
	check(is_equal_approx(Game.life.vitals.hp, Game.life.vitals.max_hp), "born at full health")
