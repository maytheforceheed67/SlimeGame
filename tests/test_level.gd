extends TestCase
## The Sealed Cave: per-life seeding, squeezing, clinging, swimming, and the
## water skills learned by practice.


func _run() -> void:
	print("Level")
	populate = true
	await start_main()
	await seconds(1.0)
	player._invulnerable = 9999.0
	var life := Game.life
	var level: Level = main.level

	# What a life finds is seeded by that life.
	var first := _census(level)
	check(first["tempest_serpent"] == 1, "the tempest serpent always waits in its lair")
	check(first["creatures"] >= 6 and first["hipokute_herb"] >= 8 and first["magic_ore"] >= 5,
			"the cave is stocked with creatures, herbs and ore")
	var first_layout := _layout(level)
	level.populate(life)
	await frames(3)
	check(_layout(level) == first_layout, "the same seed lays the cave out the same way")
	life.world_seed += 1
	level.populate(life)
	await frames(3)
	check(_layout(level) != first_layout, "a different seed lays it out differently")
	level.clear()
	await frames(3)
	check(level.get_node("Spawned").get_child_count() == 0, "clearing empties the cave")

	# Squeeze: the gap to the herb grotto is too low to walk through.
	await place_at_cell(36, 32)
	await hold("move_right", 120)
	check(player.global_position.x < 12.0, "a low gap stops an upright slime")
	Input.action_press("squeeze")
	await hold("move_right", 90)
	check(player.is_squeezed() and player.global_position.x > 13.0 and player.global_position.x < 20.0,
			"a flattened slime crawls into it")
	Input.action_release("squeeze")
	await frames(20)
	check(player.is_squeezed(), "and stays flat while there is rock overhead")
	life.skills.append("predator")
	life.forms.append("giant_bat")
	check(not player.set_form("giant_bat") and not player.in_form(), "and cannot take another shape with no room to stand")
	life.skills.erase("predator")
	life.forms.clear()
	await hold("move_right", 300)
	check(player.global_position.x > 20.5 and not player.is_squeezed(), "it stands up again on the far side")

	# Cling: the bat roost is five metres up a sheer wall.
	await place_at_cell(14, 41)
	life.stamina = 100.0
	Input.action_press("cling")
	await hold("move_forward", 200)
	Input.action_release("cling")
	await frames(40)
	check(player.global_position.y > 4.8 and player.global_position.z < -16.0, "clinging climbs the wall onto the ledge")
	check(life.stamina < 100.0 and life.stats.get("seconds_clinging", 0.0) > 1.0, "and costs stamina")
	await seconds(4.0)
	check(is_equal_approx(life.stamina, 100.0), "stamina returns on firm ground")
	await place_at_cell(14, 41)
	life.stamina = 8.0
	Input.action_press("cling")
	await hold("move_forward", 200)
	Input.action_release("cling")
	await frames(60)
	check(player.global_position.y < 2.0, "without stamina the slime slides back down")

	# Water: sink, learn to swim, drink, learn to jet.
	life.stamina = 100.0
	await place_at_cell(18, 47, 1.0)
	await seconds(2.5)
	check(player.in_water() and player.global_position.y < -2.5, "a slime that cannot swim sinks to the lake bed")
	await tap("jump")
	await frames(40)
	check(player.global_position.y > -1.8, "but it can push off the bed")
	await hold("move_left", 60 * 13)
	check(life.has_skill("water_current_motion"), "moving through water teaches Water Current Motion")
	await place_at_cell(18, 47, -2.0)
	Input.action_press("jump")
	await frames(90)
	Input.action_release("jump")
	check(player.global_position.y > -1.4, "with it the slime swims up at will")

	# The lake is several adjoining volumes; nudging across a seam and back
	# must not count as leaving the water.
	player.global_position = Vector3(37.0, -2.0, -4.6)
	player.velocity = Vector3.ZERO
	await frames(6)
	player.global_position = Vector3(37.0, -2.0, -3.9)
	player.velocity = Vector3.ZERO
	await frames(6)
	player.global_position = Vector3(37.0, -2.0, -4.6)
	player.velocity = Vector3.ZERO
	await frames(6)
	check(player.in_water(), "crossing a seam in the lake and turning back keeps the slime in water")

	Game.grant_skill("predator", true)
	await place_at_cell(18, 47, -2.0)
	await frames(3)
	check(player.predator.candidate is WaterVolume, "submerged, Predator can drink the lake")
	await hold("devour", 70)
	check(life.item_count("water") == 10, "each gulp stores five water")
	for i in 5:
		await place_at_cell(18, 47, -2.4)
		await tap("jump")
		await frames(20)
	check(life.has_skill("hydraulic_propulsion"), "five clumsy spurts teach Hydraulic Propulsion")
	check(life.item_count("water") == 5, "each spurt spends stored water")
	await place_at_cell(18, 47, -2.0)
	await tap("jump")
	await frames(3)
	check(player.velocity.length() > 12.0, "Hydraulic Propulsion is a jet dash")

	# Water Blade: practised on dry land with stored water.
	await place_at_cell(37, 27)
	Game.add_item("water", 20)
	check(life.selected_skill == "", "nothing is bound to the skill button yet")
	for i in 3:
		await tap("attack_skill")
		await frames(40)
	check(life.practice.get("water_spits", 0.0) == 3.0, "with nothing bound, the skill button spits stored water")
	# Owning another skill must not shut the practice out.
	Game.grant_skill("ultra_sound_waves")
	check(life.selected_skill == "ultra_sound_waves", "a first active skill binds itself")
	var magicules_before := life.magicules
	await tap("attack_skill")
	check(life.magicules < magicules_before - 10.0 and life.practice.get("water_spits", 0.0) == 3.0,
			"the bound skill is used, not the practice move")
	await frames(100)
	await tap("skill_next")
	check(life.selected_skill == "practice:water_blade" and Game.selected_skill_name() == "Water Spit (practice)",
			"the practice move can be bound in its place")
	for i in 4:
		await tap("attack_skill")
		await frames(40)
	check(not life.has_skill("water_blade") and life.practice.get("water_spits", 0.0) == 7.0, "seven spits are not yet a blade")
	await tap("attack_skill")
	await frames(40)
	check(life.has_skill("water_blade") and life.selected_skill == "water_blade", "the eighth spit becomes Water Blade")
	check(Soul.remembers("practice:water_blade"), "and the soul remembers how")

	# A later life relearns by practice far faster.
	Game.die("blade")
	await seconds(Game.REBIRTH_DELAY + 1.0)
	life = Game.life
	check(not life.has_skill("water_blade"), "a new body has to learn Water Blade again")
	check(is_equal_approx(Game.practice_needed("water_blade"), 1.2), "but the soul's memory cuts the practice to a fraction")
	Game.grant_skill("predator", true)
	Game.add_item("water", 5)
	for i in 2:
		await tap("attack_skill")
		await frames(40)
	check(life.has_skill("water_blade"), "two spits are enough the second time")


func _census(level: Level) -> Dictionary:
	var tally := {"creatures": 0, "tempest_serpent": 0, "hipokute_herb": 0, "magic_ore": 0}
	for node in level.get_node("Spawned").get_children():
		if node is Creature:
			tally["creatures"] += 1
			if node.creature_id == "tempest_serpent":
				tally["tempest_serpent"] += 1
		elif node is Harvestable:
			tally[node.item_id] = int(tally.get(node.item_id, 0)) + 1
	return tally


func _layout(level: Level) -> Array[String]:
	var entries: Array[String] = []
	for node in level.get_node("Spawned").get_children():
		if node.is_queued_for_deletion():
			continue
		var kind := "mote"
		var where: Vector3 = (node as Node3D).global_position
		if node is Creature:
			kind = node.creature_id
			where = node.home
		elif node is Harvestable:
			kind = node.item_id
		entries.append("%s@%s" % [kind, where.snapped(Vector3.ONE * 0.5)])
	entries.sort()
	return entries
