extends TestCase
## The sightless opening and Veldora: the voice that leads to him, the lesson
## in Mana Perception, the exchange of names, being carried by agreement, and
## what a second life remembers.


func _run() -> void:
	print("Veldora")
	populate = true
	sighted = false
	await start_main()
	player._invulnerable = 9999.0
	var life := Game.life
	var dialogue: DialoguePanel = main.get_node("HUD/DialoguePanel")
	var names: NamePanel = main.get_node("HUD/NamePanel")
	var veldora := _veldora()

	# A newborn slime cannot see.
	check(not Game.is_sighted(), "a newborn slime is sightless")
	check(veldora != null, "Veldora waits in his chamber")
	Game.grant_skill("sage", true)
	await seconds(4.0)
	check(main.get_node("HUD/SensesOverlay")._vignette.visible, "the world beyond touch is dark")
	check(_labels().has("a voice"), "a voice can be heard, and its direction is shown")
	check(spoken().contains("no eyes"), "the advisor explains the darkness")

	# Following the sound follows the passages.
	var level: Level = main.level
	check(veldora.sound_position(player.global_position).is_equal_approx(level.point("VoicePath1")),
			"the voice first seems to come from the way out of the birth chamber")
	check(veldora.sound_position(level.point("VoicePath1")).is_equal_approx(level.point("VoicePath2")),
			"reaching that point moves the sound further along")
	veldora.sound_position(level.point("VoicePath2"))
	veldora.sound_position(level.point("VoicePath3"))
	check(veldora.sound_position(level.point("VoicePath4")).is_equal_approx(veldora.global_position),
			"until it comes from Veldora himself")

	# First meeting, in thought-speech.
	player.respawn(level.point("VeldoraAudience"))
	await frames(30)
	check(player.interact_target() == veldora, "in his chamber he can be answered")
	await tap("interact")
	check(dialogue.is_open() and dialogue.current_text().contains("Can you hear me"), "he speaks first")
	check(not Game.can_control(), "the body waits during a conversation")
	dialogue.advance()
	check(dialogue.option_texts().size() == 2, "a first life has no memory of him to draw on")
	dialogue.choose(0)
	dialogue.advance()
	dialogue.advance()
	dialogue.advance()
	check(dialogue.option_texts().has("Can you help me see?"), "he can be asked for help")
	dialogue.choose(0)
	dialogue.advance()
	# The last line is closed with the real key: the same press must not
	# reach the body and start the next conversation.
	await tap("interact")
	await frames(6)
	check(not dialogue.is_open() and life.flags.has("mana_perception_taught"), "he teaches how to feel magicules")
	check(life.stats.get("talks", 0.0) == 1.0, "the key that ends a conversation does not begin another")
	check(Game.can_control() and Game.ui_locks == 0, "and the body answers again")
	check(Soul.remembers("met_veldora"), "the soul remembers meeting him")

	# The lesson: hold still and feel.
	Input.action_press("scan")
	await seconds(2.0)
	check(not Game.is_sighted() and Game.practice_progress("mana_perception") > 0.4, "feeling for magicules takes a few seconds")
	await seconds(2.3)
	Input.action_release("scan")
	check(life.has_skill("mana_perception") and Game.is_sighted(), "Mana Perception is acquired and the slime can see")
	await seconds(3.0)
	check(not main.get_node("HUD/SensesOverlay")._vignette.visible, "the darkness opens out")

	# Second meeting: friendship and the exchange of names.
	await tap("interact")
	check(dialogue.current_text().contains("Now you see me"), "seen at last, he has more to say")
	dialogue.advance()
	dialogue.advance()
	dialogue.advance()
	dialogue.choose(0)
	dialogue.advance()
	dialogue.advance()
	dialogue.advance()
	dialogue.advance()
	await frames(3)
	check(names.is_open(), "accepting his friendship opens the exchange of names")
	var ep_before := life.ep
	names.submit("Mizu", "Tempest")
	await frames(3)
	check(life.full_name() == "Mizu Tempest" and life.flags.has("veldora_named"), "the slime is named")
	check(life.ep == ep_before + 200, "being named adds to its existence")
	check(dialogue.is_open() and dialogue.current_text().contains("Mizu Tempest"), "he says the name back")
	dialogue.advance()
	check(dialogue.option_texts().size() == 2, "without Predator there is no way to carry him")
	dialogue.choose(0)
	check(dialogue.current_text().contains("find a way to hold a dragon"), "and he says so")
	dialogue.advance()
	dialogue.advance()
	await seconds(1.5)
	check(spoken().contains("Name registered: Mizu Tempest"), "the Voice registers the name")

	# With Predator he can be carried, seal and all, if both agree.
	Game.grant_skill("predator", true)
	await tap("interact")
	dialogue.advance()
	dialogue.choose(0)
	dialogue.advance()
	dialogue.choose(0)
	dialogue.advance()
	dialogue.advance()
	await frames(5)
	check(Voice.is_confirm_open(), "the Voice asks before something so large is devoured")
	var stood := player.global_position
	await tap("voice_yes")
	check(life.sealed == ["Veldora"] and life.flags.has("veldora_swallowed"), "by agreement, Veldora goes to the Stomach")
	await seconds(2.5)
	check(_veldora() == null and player.interact_target() == null, "and is gone from the chamber")
	check(player.global_position.distance_to(stood) < 0.3,
			"the seal is drawn in without shoving the slime (moved %.2f m)" % player.global_position.distance_to(stood))
	main.get_node("HUD/StatusSheet").open()
	var sheet_text: String = main.get_node("HUD/StatusSheet")._columns[2].text
	main.get_node("HUD/StatusSheet").close()
	check(sheet_text.contains("Veldora"), "the status sheet lists him as held by agreement")

	# A second life: the world has forgotten, the soul has not.
	Game.die("blade")
	await seconds(Game.REBIRTH_DELAY + 1.0)
	life = Game.life
	veldora = _veldora()
	check(veldora != null and not Game.is_sighted() and life.full_name() == "", "in a new life he is sealed again and the slime is blind and unnamed")
	player.respawn(level.point("VeldoraAudience"))
	await frames(30)
	await tap("interact")
	dialogue.advance()
	check(dialogue.option_texts().size() == 3, "a soul that met him before has an extra thing to say")
	dialogue.choose(2)
	check(dialogue.current_text().contains("heard me before"), "and he notices")
	dialogue.advance()
	dialogue.advance()
	check(is_equal_approx(Game.practice_needed("mana_perception"), 0.6), "the remembered lesson needs a fraction of the practice")
	Input.action_press("scan")
	await seconds(1.0)
	Input.action_release("scan")
	check(Game.is_sighted(), "so sight returns in a moment")


func _veldora() -> Veldora:
	for node in main.level.get_node("Spawned").get_children():
		if node is Veldora and not node.is_queued_for_deletion():
			return node
	return null


func _labels() -> Array:
	var labels := []
	for arc: Dictionary in main.get_node("HUD/SensesOverlay")._arcs:
		labels.append(arc["label"])
	return labels
