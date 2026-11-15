extends TestCase
## The advisor (Sage and Great Sage): appraisal, hints, the analysis link,
## and the status sheet.


func _run() -> void:
	print("Advisor")
	await start_main()
	await seconds(2.5)
	player._invulnerable = 9999.0
	var life := Game.life
	var advisor := player.advisor

	var bat := Creature.create("giant_bat")
	main.add_child(bat)
	bat.global_position = player.global_position + Vector3(0.0, 1.5, -6.0)
	bat.set_physics_process(false)
	await frames(5)

	# Without an advisor skill there is no second voice.
	check(advisor.level() == 0, "a body without Sage has no advisor")
	await tap("scan")
	await seconds(1.0)
	check(life.stats.get("scans", 0.0) == 0.0 and not spoken().contains("Assessment"), "so scanning does nothing")

	# Sage: hints and a basic appraisal.
	Game.grant_skill("sage", true)
	check(advisor.level() == 1, "Sage is a level 1 advisor")
	await seconds(1.5)
	check(spoken().contains("Giant Bat far exceeds this body"), "the advisor warns about a creature far above the body's EP")
	await tap("scan")
	await seconds(1.0)
	check(spoken().contains("Assessment: Giant Bat. Rank D."), "Sage appraises rank")
	check(not life.appraised.has("giant_bat"), "but does not read EP")

	# Great Sage: full appraisal.
	Game.grant_skill("great_sage", true)
	check(advisor.level() == 2, "Great Sage is a level 2 advisor")
	var readouts: Array[Dictionary] = []
	advisor.scanned.connect(func(info: Dictionary) -> void: readouts.append(info))
	await tap("scan")
	await seconds(1.0)
	check(life.appraised.has("giant_bat"), "Great Sage appraises EP, which then shows on nameplates")
	check(spoken().contains("1,200 EP") and spoken().contains("Devouring yields Ultra Sound Waves, Drain"),
			"and reports what devouring would yield")
	check(readouts.size() == 1 and readouts[0]["title"] == "Giant Bat", "the scan readout is published for the HUD")
	bat.queue_free()

	# The link upgrade is offered when the first analysis starts.
	Game.grant_skill("predator", true)
	var herb := Harvestable.create("hipokute_herb")
	main.add_child(herb)
	herb.global_position = player.global_position + Vector3(0.0, 0.0, -1.5)
	await frames(3)
	await hold("devour", 40)
	await seconds(1.2)
	check(Voice.is_confirm_open(), "Great Sage asks to link Analysis to Parallel Processing")
	check(not Game.can_control(), "the body waits while a question is open")
	await tap("voice_yes")
	check(life.analysis_linked, "answering yes makes the link")
	await seconds(2.0)
	check(life.analysed.has("item:hipokute_herb"), "and the herb is analysed in about a second")
	check(spoken().contains("Link established"), "the advisor confirms the link")

	# Low health.
	life.vitals.hp = 8.0
	await seconds(1.2)
	check(spoken().contains("Health is critical"), "the advisor warns at low health")
	life.vitals.hp = life.vitals.max_hp

	# Status sheet.
	var sheet: Control = main.get_node("HUD/StatusSheet")
	await tap("status_sheet")
	check(sheet.is_open() and get_tree().paused, "Tab opens the status sheet and pauses the world")
	check(not Game.can_control(), "the body cannot be steered while it is open")
	var text: String = sheet._columns[0].text + sheet._columns[1].text + sheet._columns[2].text
	check(text.contains("Great Sage") and text.contains("Predator") and text.contains("Absorb"), "it lists skills by tier")
	check(text.contains("Existence points: 105"), "with an advisor it shows numeric EP")
	check(text.contains("Healing Potion"), "and known recipes")
	Game.grant_skill("drain")
	sheet._on_action("discard:drain")
	check(not life.has_skill("drain"), "a skill can be discarded from the sheet")
	await tap("status_sheet")
	check(not sheet.is_open() and not get_tree().paused and Game.can_control(), "Tab closes it and the world resumes")
