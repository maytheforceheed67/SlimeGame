extends TestCase
## Predator: predation, Stomach, Analysis, Isolation, potions, and the
## memory that makes a second life faster.


func _run() -> void:
	print("Predator")
	await start_main()
	await seconds(2.5)
	player._invulnerable = 9999.0
	var life := Game.life
	var predator := player.predator

	# With only the intrinsic Absorb, eating yields magicules and nothing else.
	var herb := _herb()
	await frames(3)
	check(predator.candidate == herb, "a herb in reach is the devour candidate")
	check(not predator.has_predator() and predator.can_devour(), "a slime can absorb without Predator")
	await hold("devour", 80)
	check(not is_instance_valid(herb), "holding devour takes the herb in")
	check(life.ep == 105, "absorbing it adds its magicules to EP")
	check(life.stomach.is_empty() and life.analysis_queue.is_empty(), "but nothing is kept or analysed")

	# Predator keeps what it swallows and starts analysing it.
	Game.grant_skill("predator", true)
	herb = _herb()
	await frames(3)
	await hold("devour", 40)
	check(life.item_count("hipokute_herb") == 1, "with Predator the herb goes to the Stomach")
	check(life.analysis_queue.size() == 1 and life.analysis_queue[0]["key"] == "item:hipokute_herb", "and joins the analysis queue")
	check(predator.time_left(life.analysis_queue[0]) > 45.0, "unlinked, a herb takes most of a minute")
	check(predator.analysis_slots() == 1, "Predator alone analyses one subject at a time")

	# Linking Analysis to Parallel Processing: about fifty times faster.
	Game.grant_skill("great_sage", true)
	check(predator.analysis_slots() == 3, "Great Sage adds two background slots")
	life.analysis_linked = true
	check(predator.time_left(life.analysis_queue[0]) < 1.05, "linked, the same herb takes about a second")
	await seconds(1.6)
	check(life.analysed.has("item:hipokute_herb") and life.analysis_queue.is_empty(), "the analysis completes")
	check(life.recipes.has("healing_potion"), "and teaches the healing potion")
	check(Soul.knows("item", "hipokute_herb"), "the soul's codex records it")
	await seconds(1.5)
	check(spoken().contains("Synthesis recorded: Healing Potion"), "the Voice announces the recipe")

	# A potion is synthesised from the herb and drunk.
	life.vitals.hp = 10.0
	check(Game.potions_available() == 1, "one herb is one potion in waiting")
	await tap("use_potion")
	var expected := 10.0 + 0.6 * life.vitals.max_hp
	check(life.vitals.hp >= expected and life.vitals.hp < expected + 1.0, "a potion restores 60% of maximum health")
	check(life.item_count("hipokute_herb") == 0 and Game.potions_available() == 0, "and uses up the herb")

	# Remains: EP now, skills and a form once analysed.
	var bat := _creature("giant_bat", Vector3(0.0, 0.0, -1.8))
	bat.take_hit({"amount": 9999.0, "damage_type": "impact"})
	await frames(20)
	var ep_before := life.ep
	await hold("devour", 90)
	check(not is_instance_valid(bat), "remains are devoured whole")
	check(life.ep == ep_before + 300, "a quarter of the bat's EP is absorbed")
	check(life.analysis_queue.size() == 1 and life.analysis_queue[0]["key"] == "species:giant_bat", "the species is queued for analysis")
	await seconds(2.5)
	check(life.has_skill("ultra_sound_waves") and life.has_skill("drain"), "analysis grants the bat's skills")
	check(life.forms == ["giant_bat"], "and records its form for Mimicry")
	check(is_equal_approx(life.max_magicules, float(life.ep) - 20.0), "each acquired skill reserves magicule capacity")
	Game.discard_skill("drain")
	check(not life.has_skill("drain") and is_equal_approx(life.max_magicules, float(life.ep) - 10.0),
			"discarding Drain returns its capacity")
	check(not Game.discard_skill("absorb"), "intrinsic skills cannot be discarded")

	# Remains that fade away in the middle of a devour.
	var fading := _creature("giant_bat", Vector3(0.0, 0.0, -1.8))
	fading.take_hit({"amount": 9999.0, "damage_type": "impact"})
	await frames(20)
	Input.action_press("devour")
	await frames(20)
	check(predator.target == fading and predator.progress > 0.2, "a devour is under way")
	fading.free()
	await frames(10)
	Input.action_release("devour")
	check(predator.target == null and is_zero_approx(predator.progress), "if the remains vanish, the devour simply stops")
	life.analysis_queue.clear()

	# Living prey: unlikely while it is alert, likely once staggered.
	var centipede := _creature("evil_centipede", Vector3(0.0, 0.0, -2.0))
	centipede.set_physics_process(false)
	await frames(5)
	check(predator.living_chance(centipede) < 0.1, "an alert, stronger creature is almost impossible to swallow")
	predator.forced_roll = 0.5
	await hold("devour", 110)
	check(is_instance_valid(centipede) and centipede.get_vitals().alive, "a failed attempt leaves it free")
	centipede.take_hit({"amount": 1.0, "damage_type": "impact", "stagger": 100.0})
	check(predator.living_chance(centipede) > 0.5, "staggering it opens the window")
	await seconds(1.0)
	ep_before = life.ep
	await hold("devour", 110)
	check(not is_instance_valid(centipede), "a staggered creature is swallowed alive")
	check(life.ep == ep_before + 550 and life.stats.get("devoured_alive", 0.0) == 1.0, "and yields its EP share")
	predator.forced_roll = -1.0

	# Isolation turns swallowed poison into magicules.
	life.analysis_queue.clear()
	Game.add_item("toxin", 2)
	life.magicules = 0.0
	await seconds(2.6)
	check(life.item_count("toxin") == 0, "Isolation breaks down toxin in the Stomach")
	check(life.magicules >= 30.0, "and converts it to magicules")

	# A shot in flight is swallowed instead of landing.
	player._invulnerable = 0.0
	life.vitals.hp = life.vitals.max_hp
	var spider := _creature("black_spider", Vector3(0.0, 0.0, -9.0))
	spider.set_physics_process(false)
	await frames(3)
	var web: Dictionary = spider.data["attacks"][0]
	var shot := Projectile.new()
	shot.setup(spider, web, Vector3(0.0, 0.0, 1.0))
	main.add_child(shot)
	shot.global_position = spider.get_aim_origin() + Vector3(0.0, -0.4, 1.5)
	await hold("devour", 40)
	check(is_equal_approx(life.vitals.hp, life.vitals.max_hp) and not life.vitals.has_status("webbed"),
			"a swallowed shot does no harm")
	check(life.stats.get("projectiles_swallowed", 0.0) == 1.0, "Predator swallows shots in flight")
	spider.queue_free()

	# Death, then a second life: the body forgets, the soul does not.
	Game.die("blade")
	await seconds(Game.REBIRTH_DELAY + 1.0)
	life = Game.life
	check(life.life_number == 2 and life.forms.is_empty() and not life.has_skill("ultra_sound_waves"),
			"a new body has none of the old skills or forms")
	check(life.recipes.is_empty() and life.stomach.is_empty(), "nor its recipes or Stomach")
	Game.grant_skill("predator", true)
	herb = _herb()
	await frames(3)
	await hold("devour", 40)
	check(predator.time_left(life.analysis_queue[0]) <= 0.5, "but a remembered subject analyses almost at once")
	await seconds(2.5)
	check(life.recipes.has("healing_potion"), "and the recipe returns once the new body has devoured the herb")
	check(spoken().contains("The soul already knew it"), "the Voice notes the memory")


func _herb() -> Harvestable:
	var herb := Harvestable.create("hipokute_herb")
	main.add_child(herb)
	herb.global_position = player.global_position + Vector3(0.0, 0.0, -1.5)
	return herb


func _creature(id: String, offset: Vector3) -> Creature:
	var creature := Creature.create(id)
	main.add_child(creature)
	creature.global_position = player.global_position + offset
	creature.home = creature.global_position
	return creature
