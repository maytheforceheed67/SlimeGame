extends TestCase
## Foundation: data, Voice, movement, EP and rank, death and rebirth.


func _run() -> void:
	print("Foundation")
	check(Database.problems.is_empty(), "data tables load without problems")
	check(Database.rank_name(Database.rank_for_ep(999)) == "E", "999 EP is rank E")
	check(Database.rank_name(Database.rank_for_ep(1000)) == "D", "1,000 EP is rank D")
	check(Database.rank_name(Database.rank_for_ep(9500)) == "A-", "9,500 EP is rank A-")
	check(Database.rank_for_ep(450000).get("danger_class") == "disaster", "450,000 EP is Disaster class")
	check(Database.informal_label_for_ep(2000000) == "Million class", "2,000,000 EP is Million class")

	await start_main()
	var life := Game.life
	check(life != null and life.race_id == "slime", "the first life is a slime")
	check(life.region_id == "sealed_cave", "born in the Sealed Cave")
	check(life.skills.has("absorb") and life.skills.has("dissolve") and life.skills.has("self_regeneration"),
			"born with the three slime intrinsic skills")

	await seconds(3.0)
	check(spoken().contains("Vessel: Slime"), "the Voice announces the birth")
	check(spoken().contains("Self-Regeneration"), "the Voice announces intrinsic skills")
	check(player.is_on_floor(), "the slime rests on the cave floor")
	var orbs: Node = main.get_node("Orbs")
	check(orbs.get_child_count() == 10, "ten magicule motes are scattered")

	var start := player.global_position
	await hold("move_forward", 60)
	check(player.global_position.z < start.z - 2.0, "forward moves away from the camera")
	await hold("move_right", 60)
	check(player.global_position.x > start.x + 2.0, "right moves right")

	await frames(20)
	var ground_y := player.global_position.y
	await tap("jump")
	await frames(12)
	check(player.global_position.y > ground_y + 0.5, "hop leaves the ground")
	await frames(90)
	check(player.is_on_floor(), "and lands again")

	var orb_count := orbs.get_child_count()
	var ep_before := life.ep
	player.global_position = (orbs.get_child(0) as Node3D).global_position
	await frames(30)
	check(life.ep > ep_before, "touching a mote raises EP")
	check(orbs.get_child_count() == orb_count - 1, "and the mote is consumed")

	Game.add_ep(1000 - life.ep)
	await seconds(1.5)
	check(Database.rank_name(Database.rank_for_ep(life.ep)) == "D", "EP 1,000 reaches rank D")
	check(spoken().contains("Rank E is now rank D"), "the Voice announces the rank change")

	var answers: Array[bool] = []
	var ask := func() -> void: answers.append(await Voice.confirm("debug_confirm"))
	ask.call()
	await frames(2)
	check(Voice.is_confirm_open(), "a Yes/No prompt opens")
	await tap("voice_yes")
	check(answers == [true], "Y answers yes")
	ask.call()
	await frames(2)
	await tap("voice_no")
	check(answers == [true, false], "N answers no")

	player.global_position = Vector3(200.0, -30.0, 0.0)
	await frames(5)
	check(player.global_position.distance_to(Vector3(0.0, 1.0, 8.0)) < 2.0, "falling out of the world returns to spawn")
	await frames(60)

	Game.die("fire")
	await frames(2)
	check(not Game.is_alive(), "the life ends")
	check(Soul.lives_lived == 1, "the soul counts one life lived")
	check(Soul.birth_grants.get("resistances", []) == ["heat_resistance"], "death by fire imprints Heat Resistance")
	var frozen := player.global_position
	await hold("move_forward", 30)
	check(player.global_position.distance_to(frozen) < 0.2, "a dead body cannot be steered")

	await seconds(Game.REBIRTH_DELAY + 1.0)
	var reborn := Game.life
	check(reborn != life and Game.is_alive(), "a new life begins")
	check(reborn.life_number == 2, "it is life 2")
	check(reborn.ep == 100, "EP resets with the body")
	check(reborn.resistances == ["heat_resistance"], "the imprinted Resistance is granted at birth")
	check(orbs.get_child_count() == 10, "the motes are re-seeded")

	Soul.lives_lived = 0
	Soul.load_from_disk()
	check(Soul.lives_lived == 1, "the soul is restored from disk")
	Soul.erase()
	check(Soul.lives_lived == 0 and Soul.birth_grants.is_empty(), "erasing blanks the soul")
